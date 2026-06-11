import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_offline_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_offline_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_offline_use_case.dart';

part 'go_offline_state.dart';

class GoOfflineCubit extends Cubit<GoOfflineState> {
  GoOfflineCubit({
    required BuildGoOfflineRequestUseCase buildGoOfflineRequestUseCase,
    required GoOfflineUseCase goOfflineUseCase,
  })  : _buildGoOfflineRequestUseCase = buildGoOfflineRequestUseCase,
        _goOfflineUseCase = goOfflineUseCase,
        super(const GoOfflineState());

  final BuildGoOfflineRequestUseCase _buildGoOfflineRequestUseCase;
  final GoOfflineUseCase _goOfflineUseCase;
  bool _requestInProgress = false;

  @override
  void emit(GoOfflineState state) {
    _logStateTransition(this.state, state);
    super.emit(state);
  }

  Future<void> goOffline({String reason = 'UserRequested'}) async {
    if (_requestInProgress) {
      _log(
          'Ignored duplicate go-offline request because one is already running.');
      return;
    }

    _requestInProgress = true;
    _logSection('FLOW START');
    _log('Action: Go Offline triggered.');
    _log('Reason: $reason');
    _log('Step: starting go-offline flow.');
    emit(
      state.copyWith(
        status: GoOfflineStatus.loading,
        clearErrorMessage: true,
        clearResult: true,
      ),
    );

    final requestResult = await _buildGoOfflineRequestUseCase(reason: reason);
    final request = requestResult.fold((error) {
      _log('Step failed: preparing go-offline request.');
      _log('Failure message: ${error.message}');
      emit(
        state.copyWith(
          status: GoOfflineStatus.failure,
          errorMessage: error.message,
        ),
      );
      return null;
    }, (value) => value);

    if (request == null) {
      _requestInProgress = false;
      _log('Flow stopped before API call.');
      _logSection('FLOW END');
      return;
    }

    _log('Step done: go-offline request prepared successfully.');
    _log('Step: sending go-offline API request...');
    final result = await _goOfflineUseCase(request);
    result.fold(
      (error) {
        _log('API result: failure.');
        _log('Failure message: ${error.message}');
        emit(
          state.copyWith(
            status: GoOfflineStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
      (value) {
        _log(
          'API result: success. isOnline=${value.isOnline}, '
          'driverId=${value.driverId}, onlineSessionId=${value.onlineSessionId}, '
          'offlineAtUtc=${value.offlineAtUtc}',
        );
        emit(
          state.copyWith(
            status: GoOfflineStatus.success,
            result: value,
            clearErrorMessage: true,
          ),
        );
      },
    );

    _requestInProgress = false;
    _log('Step: go-offline flow finished.');
    _logSection('FLOW END');
  }

  void resetStatus() {
    _log('Action: reset cubit state to initial.');
    emit(
      state.copyWith(
        status: GoOfflineStatus.initial,
        clearErrorMessage: true,
      ),
    );
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[GO OFFLINE CUBIT] $message');
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint('================ GO OFFLINE CUBIT $title ================');
  }

  void _logStateTransition(GoOfflineState previous, GoOfflineState next) {
    if (!kDebugMode) return;
    debugPrint(
      '[GO OFFLINE CUBIT] State: ${previous.status.name} -> ${next.status.name}',
    );
    if (next.errorMessage != null && next.errorMessage!.trim().isNotEmpty) {
      debugPrint('[GO OFFLINE CUBIT] Error: ${next.errorMessage}');
    }
    final result = next.result;
    if (result != null) {
      debugPrint(
        '[GO OFFLINE CUBIT] Result: isOnline=${result.isOnline}, '
        'driverId=${result.driverId}, onlineSessionId=${result.onlineSessionId}, '
        'offlineAtUtc=${result.offlineAtUtc}',
      );
    }
  }
}
