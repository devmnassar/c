part of 'delivery_completion_cubit.dart';

enum DeliveryCompletionAction {
  deliver,
  attemptDelivery,
}

enum DeliveryCompletionStatus {
  initial,
  submitting,
  success,
  failure,
}

class DeliveryCompletionState {
  const DeliveryCompletionState({
    this.status = DeliveryCompletionStatus.initial,
    this.currentAction,
    this.errorMessage,
    this.successMessage,
  });

  final DeliveryCompletionStatus status;
  final DeliveryCompletionAction? currentAction;
  final String? errorMessage;
  final String? successMessage;

  bool get isSubmitting => status == DeliveryCompletionStatus.submitting;
  bool get isDelivering =>
      isSubmitting && currentAction == DeliveryCompletionAction.deliver;
  bool get isAttemptingDelivery =>
      isSubmitting &&
      currentAction == DeliveryCompletionAction.attemptDelivery;

  DeliveryCompletionState copyWith({
    DeliveryCompletionStatus? status,
    Object? currentAction = _unset,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
  }) {
    return DeliveryCompletionState(
      status: status ?? this.status,
      currentAction: identical(currentAction, _unset)
          ? this.currentAction
          : currentAction as DeliveryCompletionAction?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}
