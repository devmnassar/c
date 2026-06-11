import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_pickup_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/upload_proof_photo_use_case.dart';
import 'package:gaseel_courier/features/trip/presentation/cubit/pickup_status_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/trip_cubit_test_helpers.dart';

class MockUpdatePickupStatusUseCase extends Mock
    implements UpdatePickupStatusUseCase {}

class MockUploadProofPhotoUseCase extends Mock
    implements UploadProofPhotoUseCase {}

void main() {
  late MockUpdatePickupStatusUseCase updatePickupStatusUseCase;
  late MockUploadProofPhotoUseCase uploadProofPhotoUseCase;

  const orderId = '42';
  const pickupStatusEnRoute = 1;
  const pickupStatusPickedUp = 3;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(ProofPhotoType.pickupProof);
  });

  setUp(() {
    updatePickupStatusUseCase = MockUpdatePickupStatusUseCase();
    uploadProofPhotoUseCase = MockUploadProofPhotoUseCase();
  });

  PickupStatusCubit buildCubit() {
    return PickupStatusCubit(
      updatePickupStatusUseCase: updatePickupStatusUseCase,
      uploadProofPhotoUseCase: uploadProofPhotoUseCase,
    );
  }

  group('PickupStatusCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const PickupStatusState());
      expect(cubit.state.status, PickupStatusSubmissionStatus.initial);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.lastSubmittedStatus, isNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    blocTest<PickupStatusCubit, PickupStatusState>(
      'submitStatus without proof photo success emits submitting then success',
      build: () {
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      act: (cubit) =>
          cubit.submitStatus(orderId: orderId, status: pickupStatusEnRoute),
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusEnRoute,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.success,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusEnRoute,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
        verify(
          () => updatePickupStatusUseCase(
            orderId: orderId,
            status: pickupStatusEnRoute,
          ),
        ).called(1);
      },
    );

    blocTest<PickupStatusCubit, PickupStatusState>(
      'submitStatus without proof photo failure emits submitting then failure',
      build: () {
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Status update failed')),
        );
        return buildCubit();
      },
      act: (cubit) =>
          cubit.submitStatus(orderId: orderId, status: pickupStatusEnRoute),
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusEnRoute,
            ),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Status update failed',
            ),
      ],
    );

    test(
      'submitStatus with missing proof file emits failure without upload or status update',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);

        final success = await cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusPickedUp,
          proofPhotoPath: '/tmp/does-not-exist.jpg',
          proofPhotoType: ProofPhotoType.pickupProof,
        );

        expect(success, isFalse);
        expect(cubit.state.status, PickupStatusSubmissionStatus.failure);
        expect(
          cubit.state.errorMessage,
          'Selected proof photo could not be found.',
        );
        expect(cubit.state.lastSubmittedStatus, pickupStatusPickedUp);
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
        verifyNever(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<PickupStatusCubit, PickupStatusState>(
      'submitStatus upload failure emits submitting then failure without status update',
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
        await cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusPickedUp,
          proofPhotoPath: proofPhotoPath,
          proofPhotoType: ProofPhotoType.pickupProof,
        );
      },
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusPickedUp,
            ),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.failure,
            )
            .having((s) => s.errorMessage, 'errorMessage', 'Upload failed'),
      ],
      verify: (_) {
        verify(
          () => uploadProofPhotoUseCase(
            orderId: orderId,
            filePath: any(named: 'filePath'),
            photoType: ProofPhotoType.pickupProof,
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
        verifyNever(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    blocTest<PickupStatusCubit, PickupStatusState>(
      'submitStatus upload success then status update success emits submitting then success',
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
          return Right(
            samplePickupUploadResult(orderId: orderId, filePath: path),
          );
        });
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusPickedUp,
          proofPhotoPath: proofPhotoPath,
          proofPhotoType: ProofPhotoType.pickupProof,
        );
      },
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusPickedUp,
            ),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.success,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusPickedUp,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () => uploadProofPhotoUseCase(
            orderId: orderId,
            filePath: any(named: 'filePath'),
            photoType: ProofPhotoType.pickupProof,
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
        verify(
          () => updatePickupStatusUseCase(
            orderId: orderId,
            status: pickupStatusPickedUp,
          ),
        ).called(1);
      },
    );

    blocTest<PickupStatusCubit, PickupStatusState>(
      'submitStatus upload success then status update failure emits submitting then failure',
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
          return Right(
            samplePickupUploadResult(orderId: orderId, filePath: path),
          );
        });
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Pickup status update failed')),
        );
        return buildCubit();
      },
      act: (cubit) async {
        final proofPhotoPath = await createTempProofPhoto();
        await cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusPickedUp,
          proofPhotoPath: proofPhotoPath,
          proofPhotoType: ProofPhotoType.pickupProof,
        );
      },
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusPickedUp,
            ),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Pickup status update failed',
            ),
      ],
      verify: (_) {
        verify(
          () => uploadProofPhotoUseCase(
            orderId: orderId,
            filePath: any(named: 'filePath'),
            photoType: ProofPhotoType.pickupProof,
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).called(1);
        verify(
          () => updatePickupStatusUseCase(
            orderId: orderId,
            status: pickupStatusPickedUp,
          ),
        ).called(1);
      },
    );

    test(
      'submitStatus skips upload when proofPhotoType is null even with file path',
      () async {
        final proofPhotoPath = await createTempProofPhoto();
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const Right(true));

        final cubit = buildCubit();
        addTearDown(cubit.close);

        final success = await cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusEnRoute,
          proofPhotoPath: proofPhotoPath,
          proofPhotoType: null,
        );

        expect(success, isTrue);
        expect(cubit.state.status, PickupStatusSubmissionStatus.success);
        verifyNever(
          () => uploadProofPhotoUseCase(
            orderId: any(named: 'orderId'),
            filePath: any(named: 'filePath'),
            photoType: any(named: 'photoType'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
        verify(
          () => updatePickupStatusUseCase(
            orderId: orderId,
            status: pickupStatusEnRoute,
          ),
        ).called(1);
      },
    );

    test('submitStatus skips upload when proofPhotoPath is empty', () async {
      when(
        () => updatePickupStatusUseCase(
          orderId: any(named: 'orderId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Right(true));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final success = await cubit.submitStatus(
        orderId: orderId,
        status: pickupStatusEnRoute,
        proofPhotoPath: '   ',
        proofPhotoType: ProofPhotoType.pickupProof,
      );

      expect(success, isTrue);
      expect(cubit.state.status, PickupStatusSubmissionStatus.success);
      verifyNever(
        () => uploadProofPhotoUseCase(
          orderId: any(named: 'orderId'),
          filePath: any(named: 'filePath'),
          photoType: any(named: 'photoType'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      );
      verify(
        () => updatePickupStatusUseCase(
          orderId: orderId,
          status: pickupStatusEnRoute,
        ),
      ).called(1);
    });

    test(
      'submitStatus does not ignore duplicate call while in progress',
      () async {
        final completer = Completer<Either<ApiException, bool>>();
        when(
          () => updatePickupStatusUseCase(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) => completer.future);

        final cubit = buildCubit();
        addTearDown(cubit.close);

        final first = cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusEnRoute,
        );
        final second = cubit.submitStatus(
          orderId: orderId,
          status: pickupStatusPickedUp,
        );

        expect(cubit.state.status, PickupStatusSubmissionStatus.submitting);
        expect(cubit.state.lastSubmittedStatus, pickupStatusPickedUp);

        completer.complete(const Right(true));
        final results = await Future.wait([first, second]);

        expect(results, everyElement(isTrue));
        expect(cubit.state.status, PickupStatusSubmissionStatus.success);
        verify(
          () => updatePickupStatusUseCase(
            orderId: orderId,
            status: any(named: 'status'),
          ),
        ).called(2);
      },
    );

    blocTest<PickupStatusCubit, PickupStatusState>(
      'reset returns state to initial',
      build: () {
        when(
          () => updatePickupStatusUseCase(
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
        await cubit.submitStatus(orderId: orderId, status: pickupStatusEnRoute);
        cubit.reset();
      },
      expect: () => [
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.submitting,
            )
            .having(
              (s) => s.lastSubmittedStatus,
              'lastSubmittedStatus',
              pickupStatusEnRoute,
            ),
        isA<PickupStatusState>()
            .having(
              (s) => s.status,
              'status',
              PickupStatusSubmissionStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Status update failed',
            ),
        const PickupStatusState(),
      ],
    );
  });
}
