import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/heartbeat_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_heartbeat_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/heartbeat_use_case.dart';

part 'heartbeat_state.dart';

class HeartbeatCubit extends Cubit<HeartbeatState> {
  HeartbeatCubit({
    required BuildHeartbeatRequestUseCase buildHeartbeatRequestUseCase,
    required HeartbeatUseCase heartbeatUseCase,
  })  : _buildHeartbeatRequestUseCase = buildHeartbeatRequestUseCase,
        _heartbeatUseCase = heartbeatUseCase,
        super(const HeartbeatState());

  static const String courierOnlineKey = 'courier_online';

  final BuildHeartbeatRequestUseCase _buildHeartbeatRequestUseCase;
  final HeartbeatUseCase _heartbeatUseCase;

  Timer? _heartbeatTimer;
  bool _requestInProgress = false;
  bool _isHeartbeatActive = false;
  int _heartbeatSessionId = 0;

  @override
  void emit(HeartbeatState state) {
    _logStateTransition(this.state, state);
    super.emit(state);
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }

  Future<void> startHeartbeat({int initialIntervalSeconds = 30}) async {
    final interval = initialIntervalSeconds > 0 ? initialIntervalSeconds : 30;
    _logSection('START');
    _log('Action: start heartbeat timer.');
    _log('Interval seconds: $interval');
    _log('First heartbeat call will run immediately, then continue on timer.');
    _isHeartbeatActive = true;
    _heartbeatSessionId++;
    emit(
      state.copyWith(
        status: HeartbeatStatus.running,
        intervalSeconds: interval,
        clearErrorMessage: true,
      ),
    );

    await runHeartbeatNow();

    if (!_isHeartbeatActive || isClosed || _heartbeatTimer != null) {
      return;
    }

    _scheduleTimer(state.intervalSeconds);
  }

  Future<void> stopHeartbeat({String reason = 'Stopped manually'}) async {
    _logSection('STOP');
    _log('Action: stop heartbeat timer.');
    _log('Reason: $reason');
    _isHeartbeatActive = false;
    _heartbeatSessionId++;
    _cancelTimer();
    emit(
      state.copyWith(
        status: HeartbeatStatus.stopped,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> runHeartbeatNow() async {
    if (_requestInProgress) {
      _log(
          'Skipped heartbeat tick because a previous request is still running.');
      return;
    }
    if (!_isHeartbeatActive) {
      _log('Skipped heartbeat tick because heartbeat is not active.');
      return;
    }

    _requestInProgress = true;
    final activeRequestToken = _heartbeatSessionId;
    _logSection('TICK');
    _log('Step: preparing heartbeat request...');
    final requestResult = await _buildHeartbeatRequestUseCase();
    final request = requestResult.fold((error) {
      _log('Step failed: preparing heartbeat request.');
      _log('Failure message: ${error.message}');
      emit(
        state.copyWith(
          status: HeartbeatStatus.failure,
          errorMessage: error.message,
        ),
      );
      return null;
    }, (value) => value);

    if (request == null) {
      _requestInProgress = false;
      return;
    }

    if (request.isInternetAvailable == false) {
      _log('Heartbeat skipped because internet is not available.');
      emit(
        state.copyWith(
          status: HeartbeatStatus.running,
          clearErrorMessage: true,
        ),
      );
      _requestInProgress = false;
      return;
    }

    _log('Step: sending heartbeat API request...');
    final result = await _heartbeatUseCase(request);
    await result.fold(
      (error) async {
        if (!_isHeartbeatActive || activeRequestToken != _heartbeatSessionId) {
          _log('Ignored heartbeat failure because heartbeat was stopped.');
          return;
        }
        _log('Heartbeat API failed: ${error.message}');
        emit(
          state.copyWith(
            status: HeartbeatStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
      (value) async {
        if (!_isHeartbeatActive || activeRequestToken != _heartbeatSessionId) {
          _log('Ignored heartbeat response because heartbeat was stopped.');
          return;
        }
        _log(
          'Heartbeat API succeeded. responseSucceeded=${value.responseSucceeded}, '
          'isOnline=${value.isOnline}, isActive=${value.isActive}, '
          'nextHeartbeatAfterSeconds=${value.nextHeartbeatAfterSeconds}, '
          'activeSessionMissing=${value.activeSessionMissing}',
        );

        if (!value.responseSucceeded || !value.isOnline) {
          await SharedPrefHelper.setData(courierOnlineKey, false);
          _cancelTimer();
          emit(
            state.copyWith(
              status: HeartbeatStatus.serverForcedOffline,
              result: value,
              message: value.message,
              clearErrorMessage: true,
              feedbackCounter: state.feedbackCounter + 1,
            ),
          );
          return;
        }

        final nextInterval = value.nextHeartbeatAfterSeconds > 0
            ? value.nextHeartbeatAfterSeconds
            : state.intervalSeconds;

        if (nextInterval != state.intervalSeconds) {
          _log(
              'Server updated next heartbeat interval to $nextInterval seconds.');
          _scheduleTimer(nextInterval);
        }

        emit(
          state.copyWith(
            status: HeartbeatStatus.running,
            result: value,
            intervalSeconds: nextInterval,
            message: value.message,
            clearErrorMessage: true,
          ),
        );
      },
    );

    _requestInProgress = false;
  }

  void clearTransientMessage() {
    emit(
      state.copyWith(
        message: null,
      ),
    );
  }

  void _scheduleTimer(int intervalSeconds) {
    _cancelTimer();
    _heartbeatTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      runHeartbeatNow();
    });
  }

  void _cancelTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[HEARTBEAT CUBIT] $message');
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint('================ HEARTBEAT CUBIT $title ================');
  }

  void _logStateTransition(HeartbeatState previous, HeartbeatState next) {
    if (!kDebugMode) return;
    debugPrint(
      '[HEARTBEAT CUBIT] State: ${previous.status.name} -> ${next.status.name}',
    );
    debugPrint(
      '[HEARTBEAT CUBIT] Interval seconds: ${previous.intervalSeconds} -> ${next.intervalSeconds}',
    );
    if (next.message != null && next.message!.trim().isNotEmpty) {
      debugPrint('[HEARTBEAT CUBIT] Message: ${next.message}');
    }
    if (next.errorMessage != null && next.errorMessage!.trim().isNotEmpty) {
      debugPrint('[HEARTBEAT CUBIT] Error: ${next.errorMessage}');
    }
    final result = next.result;
    if (result != null) {
      debugPrint(
        '[HEARTBEAT CUBIT] Result: responseSucceeded=${result.responseSucceeded}, '
        'isOnline=${result.isOnline}, isActive=${result.isActive}, '
        'nextHeartbeatAfterSeconds=${result.nextHeartbeatAfterSeconds}, '
        'activeSessionMissing=${result.activeSessionMissing}',
      );
    }
  }
}
