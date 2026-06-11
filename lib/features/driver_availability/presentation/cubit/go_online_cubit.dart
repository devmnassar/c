import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_online_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_online_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_online_use_case.dart';

part 'go_online_state.dart';

class GoOnlineCubit extends Cubit<GoOnlineState> {
  GoOnlineCubit({
    required BuildGoOnlineRequestUseCase buildGoOnlineRequestUseCase,
    required GoOnlineUseCase goOnlineUseCase,
  })  : _buildGoOnlineRequestUseCase = buildGoOnlineRequestUseCase,
        _goOnlineUseCase = goOnlineUseCase,
        super(const GoOnlineState());

  final BuildGoOnlineRequestUseCase _buildGoOnlineRequestUseCase;
  final GoOnlineUseCase _goOnlineUseCase;
  bool _requestInProgress = false;

  @override
  void emit(GoOnlineState state) {
    _logStateTransition(this.state, state);
    super.emit(state);
  }

  Future<void> goOnline() async {
    if (_requestInProgress) {
      _log(
          'Ignored duplicate go-online request because one is already running.');
      return;
    }

    _requestInProgress = true;
    _logSection('FLOW START');
    _log('Action: Go To Online tapped.');
    _log('Step: Starting go-online flow.');
    emit(
      state.copyWith(
        status: GoOnlineStatus.loading,
        clearErrorMessage: true,
        clearResult: true,
      ),
    );

    _log('Step: Building request data from device and location services...');
    final requestResult = await _buildGoOnlineRequestUseCase();
    final request = requestResult.fold((error) {
      _log('Step failed: preparing request data.');
      _log('Failure message: ${error.message}');
      emit(
        state.copyWith(
          status: GoOnlineStatus.failure,
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

    _log('Step done: request data prepared successfully.');
    _log('Step: sending go-online API request...');
    final result = await _goOnlineUseCase(request);
    result.fold(
      (error) {
        _log('API result: failure.');
        _log('Failure message: ${error.message}');
        emit(
          state.copyWith(
            status: GoOnlineStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
      (value) {
        _log(
          'API result: success. isOnline=${value.isOnline}, '
          'driverId=${value.driverId}, onlineSessionId=${value.onlineSessionId}, '
          'nextRecommendedLocationUpdateSeconds=${value.nextRecommendedLocationUpdateSeconds}',
        );
        emit(
          state.copyWith(
            status: GoOnlineStatus.success,
            result: value,
            clearErrorMessage: true,
          ),
        );
      },
    );
    _requestInProgress = false;
    _log('Step: go-online flow finished.');
    _logSection('FLOW END');
  }

  void resetStatus() {
    _log('Action: reset cubit state to initial.');
    emit(
      state.copyWith(
        status: GoOnlineStatus.initial,
        clearErrorMessage: true,
      ),
    );
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[GO ONLINE CUBIT] $message');
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint('================ GO ONLINE CUBIT $title ================');
  }

  void _logStateTransition(GoOnlineState previous, GoOnlineState next) {
    if (!kDebugMode) return;
    debugPrint(
      '[GO ONLINE CUBIT] State: ${previous.status.name} -> ${next.status.name}',
    );
    if (next.errorMessage != null && next.errorMessage!.trim().isNotEmpty) {
      debugPrint('[GO ONLINE CUBIT] Error: ${next.errorMessage}');
    }
    final result = next.result;
    if (result != null) {
      debugPrint(
        '[GO ONLINE CUBIT] Result: isOnline=${result.isOnline}, '
        'driverId=${result.driverId}, onlineSessionId=${result.onlineSessionId}',
      );
    }
  }
}
