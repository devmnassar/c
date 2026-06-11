import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_online_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_go_online_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/go_online_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/go_online_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/driver_availability_cubit_test_helpers.dart';

class MockBuildGoOnlineRequestUseCase extends Mock
    implements BuildGoOnlineRequestUseCase {}

class MockGoOnlineUseCase extends Mock implements GoOnlineUseCase {}

void main() {
  late MockBuildGoOnlineRequestUseCase buildGoOnlineRequestUseCase;
  late MockGoOnlineUseCase goOnlineUseCase;

  setUpAll(() {
    registerFallbackValue(sampleGoOnlineRequest());
  });

  setUp(() {
    buildGoOnlineRequestUseCase = MockBuildGoOnlineRequestUseCase();
    goOnlineUseCase = MockGoOnlineUseCase();
  });

  GoOnlineCubit buildCubit() {
    return GoOnlineCubit(
      buildGoOnlineRequestUseCase: buildGoOnlineRequestUseCase,
      goOnlineUseCase: goOnlineUseCase,
    );
  }

  group('GoOnlineCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const GoOnlineState());
      expect(cubit.state.status, GoOnlineStatus.initial);
      expect(cubit.state.result, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isLoading, isFalse);
    });

    blocTest<GoOnlineCubit, GoOnlineState>(
      'goOnline success emits loading then success with result',
      build: () {
        final request = sampleGoOnlineRequest();
        final result = sampleGoOnlineResult();
        when(
          () => buildGoOnlineRequestUseCase(),
        ).thenAnswer((_) async => Right(request));
        when(
          () => goOnlineUseCase(request),
        ).thenAnswer((_) async => Right(result));
        return buildCubit();
      },
      act: (cubit) => cubit.goOnline(),
      expect: () => [
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.loading)
            .having((s) => s.result, 'result', isNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.success)
            .having((s) => s.result?.driverId, 'driverId', 42)
            .having((s) => s.result?.isOnline, 'isOnline', isTrue)
            .having(
              (s) => s.result?.onlineSessionId,
              'onlineSessionId',
              'session-online-1',
            )
            .having(
              (s) => s.result?.nextRecommendedLocationUpdateSeconds,
              'nextRecommendedLocationUpdateSeconds',
              30,
            )
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(() => buildGoOnlineRequestUseCase()).called(1);
        verify(() => goOnlineUseCase(any())).called(1);
      },
    );

    blocTest<GoOnlineCubit, GoOnlineState>(
      'goOnline failure when request build fails emits loading then failure',
      build: () {
        when(() => buildGoOnlineRequestUseCase()).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Location unavailable')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.goOnline(),
      expect: () => [
        isA<GoOnlineState>().having(
          (s) => s.status,
          'status',
          GoOnlineStatus.loading,
        ),
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Location unavailable',
            ),
      ],
      verify: (_) {
        verify(() => buildGoOnlineRequestUseCase()).called(1);
        verifyNever(() => goOnlineUseCase(any()));
      },
    );

    blocTest<GoOnlineCubit, GoOnlineState>(
      'goOnline failure when API fails emits loading then failure',
      build: () {
        final request = sampleGoOnlineRequest();
        when(
          () => buildGoOnlineRequestUseCase(),
        ).thenAnswer((_) async => Right(request));
        when(() => goOnlineUseCase(request)).thenAnswer(
          (_) async => const Left(ApiException(message: 'Go online failed')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.goOnline(),
      expect: () => [
        isA<GoOnlineState>().having(
          (s) => s.status,
          'status',
          GoOnlineStatus.loading,
        ),
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Go online failed'),
      ],
    );

    test(
      'goOnline ignores duplicate call while request is in progress',
      () async {
        final request = sampleGoOnlineRequest();
        final completer = Completer<Either<ApiException, GoOnlineRequest>>();

        when(
          () => buildGoOnlineRequestUseCase(),
        ).thenAnswer((_) => completer.future);
        when(
          () => goOnlineUseCase(any()),
        ).thenAnswer((_) async => Right(sampleGoOnlineResult()));

        final cubit = buildCubit();
        addTearDown(cubit.close);

        final first = cubit.goOnline();
        final second = cubit.goOnline();

        verify(() => buildGoOnlineRequestUseCase()).called(1);

        completer.complete(Right(request));
        await first;
        await second;

        expect(cubit.state.status, GoOnlineStatus.success);
        verify(() => goOnlineUseCase(request)).called(1);
      },
    );

    blocTest<GoOnlineCubit, GoOnlineState>(
      'resetStatus returns status to initial and clears error message',
      build: () {
        when(() => buildGoOnlineRequestUseCase()).thenAnswer(
          (_) async => const Left(ApiException(message: 'Build failed')),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.goOnline();
        cubit.resetStatus();
      },
      expect: () => [
        isA<GoOnlineState>().having(
          (s) => s.status,
          'status',
          GoOnlineStatus.loading,
        ),
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Build failed'),
        isA<GoOnlineState>()
            .having((s) => s.status, 'status', GoOnlineStatus.initial)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );
  });
}
