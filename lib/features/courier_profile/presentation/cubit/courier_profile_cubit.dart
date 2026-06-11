import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/features/courier_profile/domain/entities/courier_profile.dart';
import 'package:gaseel_courier/features/courier_profile/domain/usecases/get_courier_profile_use_case.dart';

part 'courier_profile_state.dart';

class CourierProfileCubit extends Cubit<CourierProfileState> {
  CourierProfileCubit({
    required GetCourierProfileUseCase getCourierProfileUseCase,
  })  : _getCourierProfileUseCase = getCourierProfileUseCase,
        super(const CourierProfileState());

  final GetCourierProfileUseCase _getCourierProfileUseCase;
  bool _requestInProgress = false;

  @override
  void emit(CourierProfileState state) {
    _logStateTransition(this.state, state);
    super.emit(state);
  }

  Future<void> getCourierProfile() async {
    if (_requestInProgress) {
      _log(
          'Ignored duplicate request because courier profile call is already running.');
      return;
    }

    _requestInProgress = true;
    _logSection('FLOW START');
    _log('Action: fetch courier profile after all permissions granted.');
    emit(
      state.copyWith(
        status: CourierProfileStatus.loading,
        errorMessage: null,
      ),
    );

    final result = await _getCourierProfileUseCase();
    if (isClosed) {
      _requestInProgress = false;
      return;
    }

    await result.fold(
      (error) async {
        _log('API result: failure.');
        _log('Failure message: ${error.message}');
        emit(
          state.copyWith(
            status: CourierProfileStatus.failure,
            errorMessage: error.message,
          ),
        );
      },
      (profile) async {
        final cachedCourierTypeId = await SharedPrefHelper.getNullableInt(
          SharedPrefKeys.courierTypeId,
        );
        _log('API result: success.');
        _log('Courier name: ${profile.user.name}');
        _log('Courier type: ${profile.user.courierType}');
        _log('Courier type id cached: $cachedCourierTypeId');
        emit(
          state.copyWith(
            status: CourierProfileStatus.success,
            profile: profile,
            errorMessage: null,
            cachedCourierTypeId: cachedCourierTypeId,
          ),
        );
      },
    );

    _requestInProgress = false;
    _logSection('FLOW END');
  }

  void resetStatus() {
    emit(
      state.copyWith(
        status: CourierProfileStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint(
        '================ COURIER PROFILE CUBIT $title ================');
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[COURIER PROFILE CUBIT] $message');
  }

  void _logStateTransition(
    CourierProfileState previous,
    CourierProfileState next,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      '[COURIER PROFILE CUBIT] State: ${previous.status.name} -> ${next.status.name}',
    );
    if (next.errorMessage != null && next.errorMessage!.trim().isNotEmpty) {
      debugPrint('[COURIER PROFILE CUBIT] Error: ${next.errorMessage}');
    }
    if (next.profile != null) {
      debugPrint(
        '[COURIER PROFILE CUBIT] Response summary: '
        'courierTypeId=${next.profile!.user.courierTypeId}, '
        'currentStep=${next.profile!.state.currentStep}, '
        'documents=${next.profile!.documents.length}',
      );
    }
    if (next.cachedCourierTypeId != null) {
      debugPrint(
        '[COURIER PROFILE CUBIT] Cached courierTypeId=${next.cachedCourierTypeId}',
      );
    }
  }
}
