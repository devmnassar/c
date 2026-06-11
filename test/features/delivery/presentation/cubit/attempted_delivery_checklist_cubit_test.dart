import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/delivery/presentation/cubit/attempted_delivery_checklist_cubit.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_answer.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_order_checklist_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/submit_order_checklist_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/delivery_cubit_test_helpers.dart';

class MockGetOrderChecklistUseCase extends Mock
    implements GetOrderChecklistUseCase {}

class MockSubmitOrderChecklistUseCase extends Mock
    implements SubmitOrderChecklistUseCase {}

void main() {
  late MockGetOrderChecklistUseCase getOrderChecklistUseCase;
  late MockSubmitOrderChecklistUseCase submitOrderChecklistUseCase;

  const orderId = '42';

  setUpAll(() {
    registerFallbackValue(
      const OrderChecklistAnswer(questionId: 0, answer: false),
    );
  });

  setUp(() {
    getOrderChecklistUseCase = MockGetOrderChecklistUseCase();
    submitOrderChecklistUseCase = MockSubmitOrderChecklistUseCase();
  });

  AttemptedDeliveryChecklistCubit buildCubit() {
    return AttemptedDeliveryChecklistCubit(
      getOrderChecklistUseCase: getOrderChecklistUseCase,
      submitOrderChecklistUseCase: submitOrderChecklistUseCase,
    );
  }

  group('AttemptedDeliveryChecklistCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const AttemptedDeliveryChecklistState());
      expect(cubit.state.status, AttemptedDeliveryChecklistStatus.initial);
      expect(cubit.state.questions, isEmpty);
      expect(cubit.state.hasQuestions, isFalse);
      expect(cubit.state.isComplete, isFalse);
      expect(cubit.state.submitSuccess, isFalse);
    });

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'loadChecklist success emits loading then ready with questions',
      build: () {
        when(
          () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
        ).thenAnswer((_) async => Right(sampleChecklistQuestions()));
        return buildCubit();
      },
      act: (cubit) => cubit.loadChecklist(orderId: orderId),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.loading,
            )
            .having((s) => s.isLoading, 'isLoading', isTrue),
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.ready,
            )
            .having((s) => s.questions.length, 'questionCount', 2)
            .having((s) => s.hasQuestions, 'hasQuestions', isTrue)
            .having((s) => s.isComplete, 'isComplete', isFalse),
      ],
      verify: (_) {
        verify(() => getOrderChecklistUseCase(orderId: orderId)).called(1);
      },
    );

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'loadChecklist failure emits loading then failure with error',
      build: () {
        when(
          () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Checklist unavailable')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadChecklist(orderId: orderId),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>().having(
          (s) => s.status,
          'status',
          AttemptedDeliveryChecklistStatus.loading,
        ),
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Checklist unavailable',
            ),
      ],
    );

    test(
      'loadChecklist returns false on failure and true on success',
      () async {
        when(
          () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Checklist unavailable')),
        );

        final failureCubit = buildCubit();
        addTearDown(failureCubit.close);
        expect(await failureCubit.loadChecklist(orderId: orderId), isFalse);

        when(
          () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
        ).thenAnswer((_) async => Right(sampleChecklistQuestions()));

        final successCubit = buildCubit();
        addTearDown(successCubit.close);
        expect(await successCubit.loadChecklist(orderId: orderId), isTrue);
      },
    );

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'answerQuestion updates the matching question answer',
      build: () {
        when(
          () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
        ).thenAnswer((_) async => Right(sampleChecklistQuestions()));
        return buildCubit();
      },
      seed: () => AttemptedDeliveryChecklistState(
        status: AttemptedDeliveryChecklistStatus.ready,
        questions: sampleChecklistQuestions(),
      ),
      act: (cubit) => cubit.answerQuestion(questionId: 1, answer: true),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.ready,
            )
            .having(
              (s) => s.questions.firstWhere((q) => q.questionId == 1).answer,
              'answer',
              isTrue,
            )
            .having((s) => s.isComplete, 'isComplete', isFalse),
      ],
    );

    test('isComplete is true only when every question has an answer', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      when(
        () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
      ).thenAnswer((_) async => Right(sampleChecklistQuestions()));

      await cubit.loadChecklist(orderId: orderId);
      expect(cubit.state.isComplete, isFalse);

      cubit.answerQuestion(questionId: 1, answer: true);
      expect(cubit.state.isComplete, isFalse);

      cubit.answerQuestion(questionId: 2, answer: false);
      expect(cubit.state.isComplete, isTrue);
    });

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'submitChecklist blocked when incomplete emits failure status',
      build: buildCubit,
      seed: () => AttemptedDeliveryChecklistState(
        status: AttemptedDeliveryChecklistStatus.ready,
        questions: sampleChecklistQuestions(),
      ),
      act: (cubit) => cubit.submitChecklist(orderId: orderId),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Please answer all checklist questions first.',
            ),
      ],
      verify: (_) {
        verifyNever(
          () => submitOrderChecklistUseCase(
            orderId: any(named: 'orderId'),
            answers: any(named: 'answers'),
          ),
        );
      },
    );

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'submitChecklist success emits submitting then ready with submitSuccess true',
      build: () {
        when(
          () => submitOrderChecklistUseCase(
            orderId: any(named: 'orderId'),
            answers: any(named: 'answers'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      seed: () => AttemptedDeliveryChecklistState(
        status: AttemptedDeliveryChecklistStatus.ready,
        questions: sampleChecklistQuestions(withAnswers: true),
      ),
      act: (cubit) => cubit.submitChecklist(orderId: orderId),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.submitting,
            )
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.ready,
            )
            .having((s) => s.submitSuccess, 'submitSuccess', isTrue)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        final captured =
            verify(
                  () => submitOrderChecklistUseCase(
                    orderId: orderId,
                    answers: captureAny(named: 'answers'),
                  ),
                ).captured.single
                as List<OrderChecklistAnswer>;
        expect(captured, hasLength(2));
        expect(captured[0].questionId, 1);
        expect(captured[0].answer, isTrue);
        expect(captured[1].questionId, 2);
        expect(captured[1].answer, isFalse);
      },
    );

    blocTest<AttemptedDeliveryChecklistCubit, AttemptedDeliveryChecklistState>(
      'submitChecklist failure returns to ready status with error (not failure status)',
      build: () {
        when(
          () => submitOrderChecklistUseCase(
            orderId: any(named: 'orderId'),
            answers: any(named: 'answers'),
          ),
        ).thenAnswer(
          (_) async => const Left(ApiException(message: 'Submit rejected')),
        );
        return buildCubit();
      },
      seed: () => AttemptedDeliveryChecklistState(
        status: AttemptedDeliveryChecklistStatus.ready,
        questions: sampleChecklistQuestions(withAnswers: true),
      ),
      act: (cubit) => cubit.submitChecklist(orderId: orderId),
      expect: () => [
        isA<AttemptedDeliveryChecklistState>().having(
          (s) => s.status,
          'status',
          AttemptedDeliveryChecklistStatus.submitting,
        ),
        isA<AttemptedDeliveryChecklistState>()
            .having(
              (s) => s.status,
              'status',
              AttemptedDeliveryChecklistStatus.ready,
            )
            .having((s) => s.submitSuccess, 'submitSuccess', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', 'Submit rejected'),
      ],
    );

    test('showLocalError sets error while staying ready', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.showLocalError('Local validation error');

      expect(cubit.state.status, AttemptedDeliveryChecklistStatus.ready);
      expect(cubit.state.errorMessage, 'Local validation error');
    });

    test('clearError removes error message when present', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.showLocalError('Local validation error');
      cubit.clearError();

      expect(cubit.state.errorMessage, isNull);
    });

    test('reset returns cubit to initial state', () async {
      when(
        () => getOrderChecklistUseCase(orderId: any(named: 'orderId')),
      ).thenAnswer((_) async => Right(sampleChecklistQuestions()));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.loadChecklist(orderId: orderId);
      expect(cubit.state.questions, isNotEmpty);

      cubit.reset();
      expect(cubit.state, const AttemptedDeliveryChecklistState());
    });
  });
}
