import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/driver_availability/data/datasources/go_online_context_local_data_source.dart';
import 'package:gaseel_courier/features/driver_availability/data/datasources/operations_hub_data_source.dart';

part 'courier_location_sync_state.dart';

/// Sends courier GPS to the backend via SignalR `UpdateLocation`.
class CourierLocationSyncCubit extends Cubit<CourierLocationSyncState> {
  CourierLocationSyncCubit({
    required OperationsHubDataSource operationsHubDataSource,
    required GoOnlineContextLocalDataSource locationDataSource,
  })  : _operationsHubDataSource = operationsHubDataSource,
        _locationDataSource = locationDataSource,
        super(const CourierLocationSyncState());

  static const int defaultIntervalSeconds = 5;

  final OperationsHubDataSource _operationsHubDataSource;
  final GoOnlineContextLocalDataSource _locationDataSource;

  Timer? _timer;
  bool _requestInProgress = false;
  bool _isActive = false;
  int _sessionId = 0;

  @override
  Future<void> close() async {
    await stopLocationSync(reason: 'Cubit disposed');
    return super.close();
  }

  Future<void> startLocationSync({
    int intervalSeconds = defaultIntervalSeconds,
  }) async {
    final interval = intervalSeconds > 0 ? intervalSeconds : defaultIntervalSeconds;
    _logSection('START');
    _log('Starting SignalR location sync every $interval seconds.');

    _isActive = true;
    _sessionId++;
    _scheduleTimer(interval);

    emit(
      state.copyWith(
        status: CourierLocationSyncStatus.running,
        intervalSeconds: interval,
        clearErrorMessage: true,
      ),
    );

    await _sendLocationNow();
  }

  Future<void> stopLocationSync({String reason = 'Stopped manually'}) async {
    _logSection('STOP');
    _log('Stopping SignalR location sync. Reason: $reason');

    _isActive = false;
    _sessionId++;
    _cancelTimer();
    await _operationsHubDataSource.disconnect();

    emit(
      state.copyWith(
        status: CourierLocationSyncStatus.stopped,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _sendLocationNow() async {
    if (!_isActive || _requestInProgress) {
      return;
    }

    final activeSession = _sessionId;
    _requestInProgress = true;

    try {
      final position =
          await _locationDataSource.getOptionalCurrentOrLastKnownPosition();
      if (!_isActive || activeSession != _sessionId) {
        return;
      }

      if (position == null) {
        _log('Skipped SignalR location update: GPS unavailable.');
        return;
      }

      if (position.isMocked) {
        _log('Skipped SignalR location update: mock location detected.');
        emit(
          state.copyWith(
            status: CourierLocationSyncStatus.failure,
            errorMessage: 'Mock location is not allowed.',
          ),
        );
        return;
      }

      await _operationsHubDataSource.updateLocation({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'heading': position.heading,
        'speed': position.speed,
        'isMockLocation': position.isMocked,
        'clientTimestampUtc': DateTime.now().toUtc().toIso8601String(),
      });

      if (!_isActive || activeSession != _sessionId) {
        return;
      }

      emit(
        state.copyWith(
          status: CourierLocationSyncStatus.running,
          lastSentAtUtc: DateTime.now().toUtc(),
          clearErrorMessage: true,
        ),
      );
      _log(
        'SignalR UpdateLocation sent: '
        'lat=${position.latitude}, lng=${position.longitude}',
      );
    } catch (error, stackTrace) {
      if (!_isActive || activeSession != _sessionId) {
        return;
      }

      _log('SignalR UpdateLocation failed: $error');
      if (kDebugMode) {
        debugPrint('$stackTrace');
      }

      emit(
        state.copyWith(
          status: CourierLocationSyncStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _requestInProgress = false;
    }
  }

  void _scheduleTimer(int intervalSeconds) {
    _cancelTimer();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      unawaited(_sendLocationNow());
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[LOCATION SYNC CUBIT] $message');
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint('================ LOCATION SYNC CUBIT $title ================');
  }
}
