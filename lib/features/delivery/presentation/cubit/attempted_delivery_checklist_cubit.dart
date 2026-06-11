import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_answer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_question.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_order_checklist_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/submit_order_checklist_use_case.dart';

part 'attempted_delivery_checklist_state.dart';

const Object _checklistUnset = Object();

class AttemptedDeliveryChecklistCubit
    extends Cubit<AttemptedDeliveryChecklistState> {
  AttemptedDeliveryChecklistCubit({
    required GetOrderChecklistUseCase getOrderChecklistUseCase,
    required SubmitOrderChecklistUseCase submitOrderChecklistUseCase,
  })  : _getOrderChecklistUseCase = getOrderChecklistUseCase,
        _submitOrderChecklistUseCase = submitOrderChecklistUseCase,
        super(const AttemptedDeliveryChecklistState());

  final GetOrderChecklistUseCase _getOrderChecklistUseCase;
  final SubmitOrderChecklistUseCase _submitOrderChecklistUseCase;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(
      '================ ATTEMPTED DELIVERY CHECKLIST CUBIT ================',
    );
    debugPrint('[ATTEMPTED DELIVERY CHECKLIST CUBIT] $message');
  }

  void _emitAndLog(
    AttemptedDeliveryChecklistState nextState, {
    required String reason,
  }) {
    _log(
      'State -> ${nextState.status.name} '
      'reason=$reason, '
      'questions=${nextState.questions.length}, '
      'isComplete=${nextState.isComplete}, '
      'submitSuccess=${nextState.submitSuccess}, '
      'errorMessage=${nextState.errorMessage}',
    );
    emit(nextState);
  }

  Future<bool> loadChecklist({
    required String orderId,
  }) async {
    _log('loadChecklist started. orderId=$orderId');
    _emitAndLog(
      state.copyWith(
        status: AttemptedDeliveryChecklistStatus.loading,
        errorMessage: null,
        submitSuccess: false,
      ),
      reason: 'loadChecklist started for orderId=$orderId',
    );

    final result = await _getOrderChecklistUseCase(orderId: orderId);
    return result.fold(
      (error) {
        _log('loadChecklist failed: ${error.message}');
        _emitAndLog(
          state.copyWith(
            status: AttemptedDeliveryChecklistStatus.failure,
            errorMessage: error.message,
            submitSuccess: false,
          ),
          reason: 'loadChecklist failure for orderId=$orderId',
        );
        return false;
      },
      (questions) {
        _log('loadChecklist success. questions=${questions.length}');
        _emitAndLog(
          state.copyWith(
            status: AttemptedDeliveryChecklistStatus.ready,
            questions: questions,
            errorMessage: null,
            submitSuccess: false,
          ),
          reason: 'loadChecklist success for orderId=$orderId',
        );
        return true;
      },
    );
  }

  void answerQuestion({
    required int questionId,
    required bool answer,
  }) {
    final updatedQuestions = state.questions
        .map(
          (question) => question.questionId == questionId
              ? question.copyWith(answer: answer)
              : question,
        )
        .toList(growable: false);
    _log('answerQuestion questionId=$questionId answer=$answer');
    _emitAndLog(
      state.copyWith(
        status: AttemptedDeliveryChecklistStatus.ready,
        questions: updatedQuestions,
        errorMessage: null,
        submitSuccess: false,
      ),
      reason: 'answerQuestion questionId=$questionId updated',
    );
  }

  void showLocalError(String message) {
    _emitAndLog(
      state.copyWith(
        status: AttemptedDeliveryChecklistStatus.ready,
        errorMessage: message,
      ),
      reason: 'showLocalError called',
    );
  }

  Future<bool> submitChecklist({
    required String orderId,
  }) async {
    if (!state.isComplete) {
      const message = 'Please answer all checklist questions first.';
      _log('submitChecklist blocked: $message');
      _emitAndLog(
        state.copyWith(
          status: AttemptedDeliveryChecklistStatus.failure,
          errorMessage: message,
          submitSuccess: false,
        ),
        reason: 'submitChecklist blocked because checklist is incomplete',
      );
      return false;
    }

    _emitAndLog(
      state.copyWith(
        status: AttemptedDeliveryChecklistStatus.submitting,
        errorMessage: null,
      ),
      reason: 'submitChecklist started for orderId=$orderId',
    );
    final answers = state.questions
        .map(
          (question) => OrderChecklistAnswer(
            questionId: question.questionId,
            answer: question.answer ?? false,
          ),
        )
        .toList(growable: false);
    _log(
      'submitChecklist payload. orderId=$orderId, '
      'answers=${answers.map((item) => '{questionId: ${item.questionId}, answer: ${item.answer}}').join(', ')}',
    );

    final result = await _submitOrderChecklistUseCase(
      orderId: orderId,
      answers: answers,
    );

    return result.fold(
      (error) {
        _log('submitChecklist failed: ${error.message}');
        _emitAndLog(
          state.copyWith(
            status: AttemptedDeliveryChecklistStatus.ready,
            errorMessage: error.message,
            submitSuccess: false,
          ),
          reason: 'submitChecklist failure for orderId=$orderId',
        );
        return false;
      },
      (_) {
        _log('submitChecklist success');
        _emitAndLog(
          state.copyWith(
            status: AttemptedDeliveryChecklistStatus.ready,
            errorMessage: null,
            submitSuccess: true,
          ),
          reason: 'submitChecklist success for orderId=$orderId',
        );
        return true;
      },
    );
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }
    _emitAndLog(
      state.copyWith(errorMessage: null),
      reason: 'clearError called',
    );
  }

  void reset() {
    _log('reset to initial state');
    _emitAndLog(
      const AttemptedDeliveryChecklistState(),
      reason: 'reset called',
    );
  }
}
