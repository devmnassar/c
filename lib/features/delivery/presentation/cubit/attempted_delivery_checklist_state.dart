part of 'attempted_delivery_checklist_cubit.dart';

enum AttemptedDeliveryChecklistStatus {
  initial,
  loading,
  ready,
  submitting,
  failure,
}

class AttemptedDeliveryChecklistState {
  const AttemptedDeliveryChecklistState({
    this.status = AttemptedDeliveryChecklistStatus.initial,
    this.questions = const <OrderChecklistQuestion>[],
    this.errorMessage,
    this.submitSuccess = false,
  });

  final AttemptedDeliveryChecklistStatus status;
  final List<OrderChecklistQuestion> questions;
  final String? errorMessage;
  final bool submitSuccess;

  bool get isLoading => status == AttemptedDeliveryChecklistStatus.loading;
  bool get isSubmitting =>
      status == AttemptedDeliveryChecklistStatus.submitting;
  bool get hasQuestions => questions.isNotEmpty;
  bool get isComplete =>
      hasQuestions && questions.every((question) => question.answer != null);

  AttemptedDeliveryChecklistState copyWith({
    AttemptedDeliveryChecklistStatus? status,
    List<OrderChecklistQuestion>? questions,
    Object? errorMessage = _checklistUnset,
    bool? submitSuccess,
  }) {
    return AttemptedDeliveryChecklistState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      errorMessage: identical(errorMessage, _checklistUnset)
          ? this.errorMessage
          : errorMessage as String?,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}
