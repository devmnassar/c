part of 'courier_profile_cubit.dart';

enum CourierProfileStatus { initial, loading, success, failure }

class CourierProfileState {
  const CourierProfileState({
    this.status = CourierProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.cachedCourierTypeId,
  });

  final CourierProfileStatus status;
  final CourierProfile? profile;
  final String? errorMessage;
  final int? cachedCourierTypeId;

  bool get isLoading => status == CourierProfileStatus.loading;

  CourierProfileState copyWith({
    CourierProfileStatus? status,
    Object? profile = _unset,
    Object? errorMessage = _unset,
    Object? cachedCourierTypeId = _unset,
  }) {
    return CourierProfileState(
      status: status ?? this.status,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as CourierProfile?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      cachedCourierTypeId: identical(cachedCourierTypeId, _unset)
          ? this.cachedCourierTypeId
          : cachedCourierTypeId as int?,
    );
  }
}

const Object _unset = Object();
