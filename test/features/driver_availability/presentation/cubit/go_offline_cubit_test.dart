import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_offline_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_offline_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_offline_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/go_offline_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/driver_availability_cubit_test_helpers.dart';

class MockBuildGoOfflineRequestUseCase extends Mock
    implements BuildGoOfflineRequestUseCase {}

class MockGoOfflineUseCase extends Mock implements GoOfflineUseCase {}

void main() {
  late MockBuildGoOfflineRequestUseCase buildGoOfflineRequestUseCase;
  late MockGoOfflineUseCase goOfflineUseCase;

  setUpAll(() {
    registerFallbackValue(sampleGoOfflineRequest());
  });

  setUp(() {
    buildGoOfflineRequestUseCase = MockBuildGoOfflineRequestUseCase();
    goOfflineUseCase = MockGoOfflineUseCase();
  });

  GoOfflineCubit buildCubit() {
    return GoOfflineCubit(
      buildGoOfflineRequestUseCase: buildGoOfflineRequestUseCase,
      goOfflineUseCase: goOfflineUseCase,
    );
  }

  group('GoOfflineCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const GoOfflineState());
      expect(cubit.state.status, GoOfflineStatus.initial);
      expect(cubit.state.result, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isLoading, isFalse);
    });

    blocTest<GoOfflineCubit, GoOfflineState>(
      'goOffline success emits loading then success with result',
      build: () {
        final request = sampleGoOfflineRequest();
        final result = sampleGoOfflineResult();
        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(request));
        when(
          () => goOfflineUseCase(request),
        ).thenAnswer((_) async => Right(result));
        return buildCubit();
      },
      act: (cubit) => cubit.goOffline(),
      expect: () => [
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.loading)
            .having((s) => s.result, 'result', isNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.success)
            .having((s) => s.result?.driverId, 'driverId', 42)
            .having((s) => s.result?.isOnline, 'isOnline', isFalse)
            .having(
              (s) => s.result?.onlineSessionId,
              'onlineSessionId',
              'session-online-1',
            )
            .having((s) => s.result?.offlineAtUtc, 'offlineAtUtc', isNotNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () => buildGoOfflineRequestUseCase(reason: 'UserRequested'),
        ).called(1);
        verify(() => goOfflineUseCase(any())).called(1);
      },
    );

    blocTest<GoOfflineCubit, GoOfflineState>(
      'goOffline passes custom reason to request builder',
      build: () {
        final request = sampleGoOfflineRequest(reason: 'AppBackgrounded');
        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer((invocation) async {
          final reason = invocation.namedArguments[#reason] as String;
          expect(reason, 'AppBackgrounded');
          return Right(request);
        });
        when(
          () => goOfflineUseCase(request),
        ).thenAnswer((_) async => Right(sampleGoOfflineResult()));
        return buildCubit();
      },
      act: (cubit) => cubit.goOffline(reason: 'AppBackgrounded'),
      expect: () => [
        isA<GoOfflineState>().having(
          (s) => s.status,
          'status',
          GoOfflineStatus.loading,
        ),
        isA<GoOfflineState>().having(
          (s) => s.status,
          'status',
          GoOfflineStatus.success,
        ),
      ],
    );

    blocTest<GoOfflineCubit, GoOfflineState>(
      'goOffline failure when request build fails emits loading then failure',
      build: () {
        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Offline context unavailable')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.goOffline(),
      expect: () => [
        isA<GoOfflineState>().having(
          (s) => s.status,
          'status',
          GoOfflineStatus.loading,
        ),
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Offline context unavailable',
            ),
      ],
      verify: (_) {
        verifyNever(() => goOfflineUseCase(any()));
      },
    );

    blocTest<GoOfflineCubit, GoOfflineState>(
      'goOffline failure when API fails emits loading then failure',
      build: () {
        final request = sampleGoOfflineRequest();
        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer((_) async => Right(request));
        when(() => goOfflineUseCase(request)).thenAnswer(
          (_) async => const Left(ApiException(message: 'Go offline failed')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.goOffline(),
      expect: () => [
        isA<GoOfflineState>().having(
          (s) => s.status,
          'status',
          GoOfflineStatus.loading,
        ),
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Go offline failed'),
      ],
    );

    test(
      'goOffline ignores duplicate call while request is in progress',
      () async {
        final request = sampleGoOfflineRequest();
        final completer = Completer<Either<ApiException, GoOfflineRequest>>();

        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer((_) => completer.future);
        when(
          () => goOfflineUseCase(any()),
        ).thenAnswer((_) async => Right(sampleGoOfflineResult()));

        final cubit = buildCubit();
        addTearDown(cubit.close);

        final first = cubit.goOffline();
        final second = cubit.goOffline();

        verify(
          () => buildGoOfflineRequestUseCase(reason: 'UserRequested'),
        ).called(1);

        completer.complete(Right(request));
        await first;
        await second;

        expect(cubit.state.status, GoOfflineStatus.success);
        verify(() => goOfflineUseCase(request)).called(1);
      },
    );

    blocTest<GoOfflineCubit, GoOfflineState>(
      'resetStatus returns status to initial and clears error message',
      build: () {
        when(
          () => buildGoOfflineRequestUseCase(reason: any(named: 'reason')),
        ).thenAnswer(
          (_) async => const Left(ApiException(message: 'Build failed')),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.goOffline();
        cubit.resetStatus();
      },
      expect: () => [
        isA<GoOfflineState>().having(
          (s) => s.status,
          'status',
          GoOfflineStatus.loading,
        ),
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Build failed'),
        isA<GoOfflineState>()
            .having((s) => s.status, 'status', GoOfflineStatus.initial)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );
  });
}
