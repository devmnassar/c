import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/delivery/presentation/cubit/delivery_completion_cubit.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_rider_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/upload_proof_photo_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/delivery_cubit_test_helpers.dart';

class MockUploadProofPhotoUseCase extends Mock
    implements UploadProofPhotoUseCase {}

class MockUpdateRiderStatusUseCase extends Mock
    implements UpdateRiderStatusUseCase {}

void main() {
  late MockUploadProofPhotoUseCase uploadProofPhotoUseCase;
  late MockUpdateRiderStatusUseCase updateRiderStatusUseCase;

  const orderId = '42';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(ProofPhotoType.deliveryProof);
  });

  setUp(() {
    uploadProofPhotoUseCase = MockUploadProofPhotoUseCase();
    updateRiderStatusUseCase = MockUpdateRiderStatusUseCase();
  });

  DeliveryCompletionCubit buildCubit() {
    return DeliveryCompletionCubit(
      uploadProofPhotoUseCase: uploadProofPhotoUseCase,
      updateRiderStatusUseCase: updateRiderStatusUseCase,
    );
  }

  group('DeliveryCompletionCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const DeliveryCompletionState());
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isDelivering, isFalse);
      expect(cubit.state.isAttemptingDelivery, isFalse);
    });

    test(
      'deliverOrder with missing proof file emits failure without submitting',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: '/tmp/does-not-exist.jpg',
        );

        expect(cubit.state.status, DeliveryCompletionStatus.failure);
        expect(cubit.state.currentAction, DeliveryCompletionAction.deliver);
        expect(
          cubit.state.errorMessage,
          'Selected proof photo could not be found.',
        );
        expect(cubit.state.isSubmitting, isFalse);
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );

    test(
      'deliverOrder with file over 10 MB emits failure without submitting',
      () async {
        final proofPhotoPath = await createTempProofPhoto(
          byteLength: (10 * 1024 * 1024) + 1,
        );
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );

        expect(cubit.state.status, DeliveryCompletionStatus.failure);
        expect(cubit.state.errorMessage, 'File exceeds the 10 MB limit.');
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );

    test(
      'deliverOrder with unsupported extension emits failure without submitting',
      () async {
        final proofPhotoPath = await createTempProofPhoto(extension: 'gif');
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );

        expect(cubit.state.status, DeliveryCompletionStatus.failure);
        expect(cubit.state.errorMessage, 'Only jpg and png files are allowed.');
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );

    blocTest<DeliveryCompletionCubit, DeliveryCompletionState>(
      'deliverOrder success emits submitting then success',
      build: () {
        when(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((invocation) async {
          final path = invocation.namedArguments[#filePath] as String;
          return Right(sampleUploadResult(orderId: orderId, filePath: path));
        });
        when(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );
      },
      expect: () => [
        isA<DeliveryCompletionState>()
            .having(
              (s) => s.status,
              'status',
              DeliveryCompletionStatus.submitting,
            )
            .having(
              (s) => s.currentAction,
              'action',
              DeliveryCompletionAction.deliver,
            )
            .having((s) => s.isDelivering, 'isDelivering', isTrue),
        isA<DeliveryCompletionState>()
            .having((s) => s.status, 'status', DeliveryCompletionStatus.success)
            .having(
              (s) => s.successMessage,
              'successMessage',
              'Order delivered successfully.',
            )
            .having((s) => s.isDelivering, 'isDelivering', isFalse),
      ],
      verify: (_) {
        verify(
          () => uploadProofPhotoUseCase(
            orderId: orderId,
            filePath: any(named: 'filePath'),
            photoType: ProofPhotoType.deliveryProof,
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
        verify(
          () => updateRiderStatusUseCase(orderId: orderId, status: 6),
        ).called(1);
      },
    );

    blocTest<DeliveryCompletionCubit, DeliveryCompletionState>(
      'deliverOrder upload failure emits submitting then failure',
      build: () {
        when(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer(
          (_) async => const Left(ApiException(message: 'Upload failed')),
        );
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );
      },
      expect: () => [
        isA<DeliveryCompletionState>().having(
          (s) => s.status,
          'status',
          DeliveryCompletionStatus.submitting,
        ),
        isA<DeliveryCompletionState>()
            .having((s) => s.status, 'status', DeliveryCompletionStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Upload failed'),
      ],
      verify: (_) {
        verifyNever(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<DeliveryCompletionCubit, DeliveryCompletionState>(
      'deliverOrder rider status failure after upload emits submitting then failure',
      build: () {
        when(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => Right(sampleUploadResult(orderId: orderId)));
        when(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Status update failed')),
        );
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.deliverOrder(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );
      },
      expect: () => [
        isA<DeliveryCompletionState>().having(
          (s) => s.status,
          'status',
          DeliveryCompletionStatus.submitting,
        ),
        isA<DeliveryCompletionState>()
            .having((s) => s.status, 'status', DeliveryCompletionStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Status update failed',
            ),
      ],
    );

    blocTest<DeliveryCompletionCubit, DeliveryCompletionState>(
      'attemptDelivery success uses attempted proof type and rider status 7',
      build: () {
        when(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => Right(sampleUploadResult(orderId: orderId)));
        when(
          () => updateRiderStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.attemptDelivery(
          orderId: orderId,
          proofPhotoPath: proofPhotoPath,
        );
      },
      expect: () => [
        isA<DeliveryCompletionState>()
            .having(
              (s) => s.status,
              'status',
              DeliveryCompletionStatus.submitting,
            )
            .having(
              (s) => s.currentAction,
              'action',
              DeliveryCompletionAction.attemptDelivery,
            )
            .having(
              (s) => s.isAttemptingDelivery,
              'isAttemptingDelivery',
              isTrue,
            ),
        isA<DeliveryCompletionState>()
            .having((s) => s.status, 'status', DeliveryCompletionStatus.success)
            .having(
              (s) => s.successMessage,
              'successMessage',
              'Attempted delivery marked successfully.',
            ),
      ],
      verify: (_) {
        verify(
          () => uploadProofPhotoUseCase(
            orderId: orderId,
            filePath: any(named: 'filePath'),
            photoType: ProofPhotoType.attemptedDeliveryProof,
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
        verify(
          () => updateRiderStatusUseCase(orderId: orderId, status: 7),
        ).called(1);
      },
    );

    test('reset returns cubit to initial state', () async {
      when(
        () => uploadProofPhotoUseCase(
          orderId: any(named: 'orderId'),
          filePath: any(named: 'filePath'),
          photoType: any(named: 'photoType'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer(
        (_) async => const Left(ApiException(message: 'Upload failed')),
      );

      final cubit = buildCubit();
      addTearDown(cubit.close);
      final proofPhotoPath = await createTempProofPhoto();

      await cubit.deliverOrder(
        orderId: orderId,
        proofPhotoPath: proofPhotoPath,
      );
      expect(cubit.state.status, isNot(DeliveryCompletionStatus.initial));

      cubit.reset();
      expect(cubit.state, const DeliveryCompletionState());
    });
  });
}
