import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// SignalR client for `/hubs/operations` (courier location + future realtime events).
class OperationsHubDataSource {
  HubConnection? _connection;
  Future<void>? _connectFuture;

  Future<void> ensureConnected() async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    if (_connectFuture != null) {
      await _connectFuture;
      return;
    }

    _connectFuture = _connect();
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> updateLocation(Map<String, dynamic> payload) async {
    await ensureConnected();
    final connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      throw StateError('Operations hub is not connected.');
    }

    await connection.invoke('UpdateLocation', args: [payload]);
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) {
      return;
    }

    try {
      await connection.stop();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[OperationsHub] disconnect failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _connect() async {
    await disconnect();

    final token = (await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken))
        .trim();
    if (token.isEmpty) {
      throw StateError('Missing access token for SignalR hub.');
    }

    if (kDebugMode) {
      debugPrint(
        '[OperationsHub] connecting to ${ApiConstants.operationsHubUrl}',
      );
    }

    final connection = HubConnectionBuilder()
        .withUrl(
          ApiConstants.operationsHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                (await SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken))
                    .trim(),
          ),
        )
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .build();

    connection.onreconnected(({String? connectionId}) {
      if (kDebugMode) {
        debugPrint('[OperationsHub] reconnected (connectionId=$connectionId)');
      }
    });

    connection.onclose(({Exception? error}) {
      if (kDebugMode) {
        debugPrint('[OperationsHub] closed: $error');
      }
    });

    _connection = connection;
    await connection.start();

    if (kDebugMode) {
      debugPrint('[OperationsHub] connected');
    }
  }
}
