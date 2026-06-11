part of 'pickup_status_cubit.dart';

enum PickupStatusSubmissionStatus {
  initial,
  submitting,
  success,
  failure,
}

class PickupStatusState {
  const PickupStatusState({
    this.status = PickupStatusSubmissionStatus.initial,
    this.errorMessage,
    this.lastSubmittedStatus,
  });

  final PickupStatusSubmissionStatus status;
  final String? errorMessage;
  final int? lastSubmittedStatus;

  bool get isSubmitting => status == PickupStatusSubmissionStatus.submitting;

  PickupStatusState copyWith({
    PickupStatusSubmissionStatus? status,
    Object? errorMessage = _pickupUnset,
    Object? lastSubmittedStatus = _pickupUnset,
  }) {
    return PickupStatusState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _pickupUnset)
          ? this.errorMessage
          : errorMessage as String?,
      lastSubmittedStatus: identical(lastSubmittedStatus, _pickupUnset)
          ? this.lastSubmittedStatus
          : lastSubmittedStatus as int?,
    );
  }
}
