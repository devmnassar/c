import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/incoming/presentation/cubit/incoming_order_cubit.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_mock.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/accept_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/get_current_order_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/reject_order_offer_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_pickup_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_rider_status_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/incoming_cubit_test_helpers.dart';

class MockGetCurrentOrderUseCase extends Mock
    implements GetCurrentOrderUseCase {}

class MockGetCurrentOfferUseCase extends Mock
    implements GetCurrentOfferUseCase {}

class MockAcceptOrderOfferUseCase extends Mock
    implements AcceptOrderOfferUseCase {}

class MockRejectOrderOfferUseCase extends Mock
    implements RejectOrderOfferUseCase {}

class MockUpdateRiderStatusUseCase extends Mock
    implements UpdateRiderStatusUseCase {}

class MockUpdatePickupStatusUseCase extends Mock
    implements UpdatePickupStatusUseCase {}

void main() {
  late MockGetCurrentOrderUseCase getCurrentOrderUseCase;
  late MockGetCurrentOfferUseCase getCurrentOfferUseCase;
  late MockAcceptOrderOfferUseCase acceptOrderOfferUseCase;
  late MockRejectOrderOfferUseCase rejectOrderOfferUseCase;
  late MockUpdateRiderStatusUseCase updateRiderStatusUseCase;
  late MockUpdatePickupStatusUseCase updatePickupStatusUseCase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(MobileOrderType.delivery);
  });

  setUp(() {
    getCurrentOrderUseCase = MockGetCurrentOrderUseCase();
    getCurrentOfferUseCase = MockGetCurrentOfferUseCase();
    acceptOrderOfferUseCase = MockAcceptOrderOfferUseCase();
    rejectOrderOfferUseCase = MockRejectOrderOfferUseCase();
    updateRiderStatusUseCase = MockUpdateRiderStatusUseCase();
    updatePickupStatusUseCase = MockUpdatePickupStatusUseCase();
  });

  IncomingOrderCubit buildCubit() {
    return IncomingOrderCubit(
      getCurrentOrderUseCase: getCurrentOrderUseCase,
      getCurrentOfferUseCase: getCurrentOfferUseCase,
      acceptOrderOfferUseCase: acceptOrderOfferUseCase,
      rejectOrderOfferUseCase: rejectOrderOfferUseCase,
      updateRiderStatusUseCase: updateRiderStatusUseCase,
      updatePickupStatusUseCase: updatePickupStatusUseCase,
    );
  }

  group('IncomingOrderCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const IncomingOrderState());
      expect(cubit.state.status, IncomingOrderStatus.initial);
      expect(cubit.state.actionStatus, IncomingOrderActionStatus.initial);
      expect(cubit.state.flowType, IncomingOrderFlowType.fullTimeCurrentOrder);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isSubmitting, isFalse);
    });

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with showEmptyState emits empty without API calls',
      build: buildCubit,
      act: (cubit) => cubit.loadCurrentOrder(showEmptyState: true),
      expect: () => [
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.empty)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.freelancerOffer,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'No current offer found.',
            ),
      ],
      verify: (_) {
        verifyNever(() => getCurrentOrderUseCase());
        verifyNever(() => getCurrentOfferUseCase());
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with initialOffer emits success without API calls',
      build: buildCubit,
      act: (cubit) {
        final offer = sampleMobileOrderOffer();
        return cubit.loadCurrentOrder(initialOffer: offer);
      },
      expect: () => [
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.freelancerOffer,
            )
            .having((s) => s.currentOrderId, 'currentOrderId', 42)
            .having((s) => s.offer?.offerId, 'offerId', 101)
            .having((s) => s.order, 'order', isNotNull),
      ],
      verify: (_) {
        verifyNever(() => getCurrentOrderUseCase());
        verifyNever(() => getCurrentOfferUseCase());
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with initialOrder emits route order then API success',
      build: () {
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) async => Right(sampleMobileOrder()));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(initialOrder: sampleOrderMock()),
      expect: () => [
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.fullTimeCurrentOrder,
            )
            .having((s) => s.order?.id, 'orderId', '42'),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having((s) => s.currentOrderId, 'currentOrderId', 42),
      ],
      verify: (_) {
        verify(() => getCurrentOrderUseCase()).called(1);
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with initialOrder keeps success when API fails',
      build: () {
        when(() => getCurrentOrderUseCase()).thenAnswer(
          (_) async => const Left(ApiException(message: 'Network down')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(initialOrder: sampleOrderMock()),
      expect: () => [
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having((s) => s.order?.id, 'orderId', '42'),
      ],
      verify: (_) {
        verify(() => getCurrentOrderUseCase()).called(1);
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder without initial data emits loading then success',
      build: () {
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) async => Right(sampleMobileOrder()));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.status,
          'status',
          IncomingOrderStatus.loading,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having((s) => s.currentOrderId, 'currentOrderId', 42)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.fullTimeCurrentOrder,
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder without initial data emits loading then failure',
      build: () {
        when(() => getCurrentOrderUseCase()).thenAnswer(
          (_) async => const Left(ApiException(message: 'Order fetch failed')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.status,
          'status',
          IncomingOrderStatus.loading,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Order fetch failed',
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder without initial data emits loading then empty when order is null',
      build: () {
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.status,
          'status',
          IncomingOrderStatus.loading,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.empty)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'No current order found.',
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with loadCurrentOfferOnOpen emits loading then offer success',
      build: () {
        when(
          () => getCurrentOfferUseCase(),
        ).thenAnswer((_) async => Right(sampleMobileOrderOffer()));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(loadCurrentOfferOnOpen: true),
      expect: () => [
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.loading)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.freelancerOffer,
            ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.success)
            .having((s) => s.offer?.offerId, 'offerId', 101),
      ],
      verify: (_) {
        verify(() => getCurrentOfferUseCase()).called(1);
        verifyNever(() => getCurrentOrderUseCase());
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with loadCurrentOfferOnOpen emits empty when offer is null',
      build: () {
        when(
          () => getCurrentOfferUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(loadCurrentOfferOnOpen: true),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.status,
          'status',
          IncomingOrderStatus.loading,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.empty)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'No current offer found.',
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'loadCurrentOrder with loadCurrentOfferOnOpen emits failure on offer error',
      build: () {
        when(() => getCurrentOfferUseCase()).thenAnswer(
          (_) async => const Left(ApiException(message: 'Offer unavailable')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadCurrentOrder(loadCurrentOfferOnOpen: true),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.status,
          'status',
          IncomingOrderStatus.loading,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.status, 'status', IncomingOrderStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Offer unavailable'),
      ],
    );

    test(
      'loadCurrentOrder ignores duplicate call while load is in progress',
      () async {
        final completer = Completer<Either<ApiException, MobileOrder?>>();
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) => completer.future);

        final cubit = buildCubit();
        addTearDown(cubit.close);

        final firstLoad = cubit.loadCurrentOrder();
        await cubit.loadCurrentOrder();

        verify(() => getCurrentOrderUseCase()).called(1);

        completer.complete(Right(sampleMobileOrder()));
        await firstLoad;

        expect(cubit.state.status, IncomingOrderStatus.success);
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptDeliveryOrder full-time success updates rider status step 1',
      build: () {
        when(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      seed: () => IncomingOrderState(
        status: IncomingOrderStatus.success,
        flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
        currentOrderId: 42,
        order: sampleOrderMock(),
      ),
      act: (cubit) => cubit.acceptDeliveryOrder(),
      expect: () => [
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.submitting,
            )
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.success,
            )
            .having((s) => s.actionErrorMessage, 'actionErrorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () => updateRiderStatusUseCase(orderId: '42', status: 1),
        ).called(1);
        verifyNever(() => acceptOrderOfferUseCase(any()));
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptDeliveryOrder full-time failure emits action failure',
      build: () {
        when(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => const Left(ApiException(message: 'Rider update failed')),
        );
        return buildCubit();
      },
      seed: () => IncomingOrderState(
        status: IncomingOrderStatus.success,
        currentOrderId: 42,
        order: sampleOrderMock(),
      ),
      act: (cubit) => cubit.acceptDeliveryOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.failure,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'Rider update failed',
            ),
      ],
    );

    test(
      'acceptDeliveryOrder fails when currentOrderId is missing in full-time flow',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);

        final accepted = await cubit.acceptDeliveryOrder();

        expect(accepted, isFalse);
        expect(cubit.state.actionStatus, IncomingOrderActionStatus.failure);
        expect(
          cubit.state.actionErrorMessage,
          'No valid current order id is stored yet.',
        );
        verifyNever(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptPickupOrder full-time success updates pickup status step 1',
      build: () {
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      seed: () => IncomingOrderState(
        status: IncomingOrderStatus.success,
        flowType: IncomingOrderFlowType.fullTimeCurrentOrder,
        currentOrderId: 55,
        order: sampleOrderMock(id: '55', type: OrderTypeMock.pickup),
      ),
      act: (cubit) => cubit.acceptPickupOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => updatePickupStatusUseCase(orderId: '55', status: 1),
        ).called(1);
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptPickupOrder full-time failure emits action failure',
      build: () {
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Pickup update failed')),
        );
        return buildCubit();
      },
      seed: () => IncomingOrderState(
        status: IncomingOrderStatus.success,
        currentOrderId: 55,
      ),
      act: (cubit) => cubit.acceptPickupOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.failure,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'Pickup update failed',
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptDeliveryOrder freelancer flow accepts offer then fetches current order',
      build: () {
        when(
          () => acceptOrderOfferUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) async => Right(sampleMobileOrder(id: 42)));
        return buildCubit();
      },
      seed: () {
        final offer = sampleMobileOrderOffer();
        return IncomingOrderState(
          status: IncomingOrderStatus.success,
          flowType: IncomingOrderFlowType.freelancerOffer,
          currentOrderId: offer.orderId,
          offer: offer,
          order: sampleOrderMock(),
        );
      },
      act: (cubit) => cubit.acceptDeliveryOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having((s) => s.currentOrderId, 'currentOrderId', 42)
            .having(
              (s) => s.flowType,
              'flowType',
              IncomingOrderFlowType.freelancerOffer,
            ),
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => acceptOrderOfferUseCase(101)).called(1);
        verify(() => getCurrentOrderUseCase()).called(1);
        verifyNever(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptDeliveryOrder freelancer flow fails when accept API fails',
      build: () {
        when(() => acceptOrderOfferUseCase(any())).thenAnswer(
          (_) async => const Left(ApiException(message: 'Accept rejected')),
        );
        return buildCubit();
      },
      seed: () {
        final offer = sampleMobileOrderOffer();
        return IncomingOrderState(
          status: IncomingOrderStatus.success,
          flowType: IncomingOrderFlowType.freelancerOffer,
          offer: offer,
        );
      },
      act: (cubit) => cubit.acceptDeliveryOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.failure,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'Accept rejected',
            ),
      ],
      verify: (_) {
        verifyNever(() => getCurrentOrderUseCase());
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'acceptPickupOrder freelancer flow fails when current order missing after accept',
      build: () {
        when(
          () => acceptOrderOfferUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => getCurrentOrderUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return buildCubit();
      },
      seed: () {
        final offer = sampleMobileOrderOffer(orderType: MobileOrderType.pickup);
        return IncomingOrderState(
          status: IncomingOrderStatus.success,
          flowType: IncomingOrderFlowType.freelancerOffer,
          offer: offer,
        );
      },
      act: (cubit) => cubit.acceptPickupOrder(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.failure,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'Offer was accepted, but no active order was returned yet.',
            ),
      ],
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'rejectCurrentOffer success emits submitting then success',
      build: () {
        when(
          () => rejectOrderOfferUseCase(any()),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      seed: () {
        final offer = sampleMobileOrderOffer();
        return IncomingOrderState(
          status: IncomingOrderStatus.success,
          flowType: IncomingOrderFlowType.freelancerOffer,
          offer: offer,
        );
      },
      act: (cubit) => cubit.rejectCurrentOffer(),
      expect: () => [
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.submitting,
            )
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.success,
            )
            .having((s) => s.actionErrorMessage, 'actionErrorMessage', isNull),
      ],
      verify: (_) {
        verify(() => rejectOrderOfferUseCase(101)).called(1);
      },
    );

    blocTest<IncomingOrderCubit, IncomingOrderState>(
      'rejectCurrentOffer failure emits submitting then action failure',
      build: () {
        when(() => rejectOrderOfferUseCase(any())).thenAnswer(
          (_) async => const Left(ApiException(message: 'Reject failed')),
        );
        return buildCubit();
      },
      seed: () => IncomingOrderState(
        status: IncomingOrderStatus.success,
        offer: sampleMobileOrderOffer(),
      ),
      act: (cubit) => cubit.rejectCurrentOffer(),
      expect: () => [
        isA<IncomingOrderState>().having(
          (s) => s.actionStatus,
          'actionStatus',
          IncomingOrderActionStatus.submitting,
        ),
        isA<IncomingOrderState>()
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              IncomingOrderActionStatus.failure,
            )
            .having(
              (s) => s.actionErrorMessage,
              'actionErrorMessage',
              'Reject failed',
            ),
      ],
    );

    test('rejectCurrentOffer fails when offer is null', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      final rejected = await cubit.rejectCurrentOffer();

      expect(rejected, isFalse);
      expect(cubit.state.actionStatus, IncomingOrderActionStatus.failure);
      expect(
        cubit.state.actionErrorMessage,
        'No active offer is available to reject.',
      );
      verifyNever(() => rejectOrderOfferUseCase(any()));
    });
  });
}
