import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/heartbeat_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/heartbeat_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/build_heartbeat_request_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/domain/usecases/heartbeat_use_case.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/heartbeat_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/driver_availability_cubit_test_helpers.dart';

void _pumpAsync(FakeAsync async, {int iterations = 50}) {
  for (var i = 0; i < iterations; i++) {
    async.elapse(Duration.zero);
    async.flushMicrotasks();
  }
}

class MockBuildHeartbeatRequestUseCase extends Mock
    implements BuildHeartbeatRequestUseCase {}

class MockHeartbeatUseCase extends Mock implements HeartbeatUseCase {}

void main() {
  late MockBuildHeartbeatRequestUseCase buildHeartbeatRequestUseCase;
  late MockHeartbeatUseCase heartbeatUseCase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(sampleHeartbeatRequest());
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    buildHeartbeatRequestUseCase = MockBuildHeartbeatRequestUseCase();
    heartbeatUseCase = MockHeartbeatUseCase();
    SharedPreferences.setMockInitialValues({});
  });

  HeartbeatCubit buildCubit() {
    return HeartbeatCubit(
      buildHeartbeatRequestUseCase: buildHeartbeatRequestUseCase,
      heartbeatUseCase: heartbeatUseCase,
    );
  }

  void stubHeartbeatSuccess({
    HeartbeatRequest? request,
    HeartbeatResult? result,
    int matchingIntervalSeconds = 30,
  }) {
    final req = request ?? sampleHeartbeatRequest();
    final res =
        result ??
        sampleHeartbeatResult(
          nextHeartbeatAfterSeconds: matchingIntervalSeconds,
        );
    when(
      () => buildHeartbeatRequestUseCase(),
    ).thenAnswer((_) async => Right(req));
    when(() => heartbeatUseCase(any())).thenAnswer((_) async => Right(res));
  }

  group('HeartbeatCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const HeartbeatState());
      expect(cubit.state.status, HeartbeatStatus.initial);
      expect(cubit.state.result, isNull);
      expect(cubit.state.intervalSeconds, 30);
      expect(cubit.state.message, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.feedbackCounter, 0);
    });

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat success emits running then running with result',
      build: () {
        stubHeartbeatSuccess();
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(initialIntervalSeconds: 30),
      expect: () => [
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.running)
            .having((s) => s.intervalSeconds, 'intervalSeconds', 30)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.running)
            .having((s) => s.result?.driverId, 'driverId', 42)
            .having((s) => s.result?.isOnline, 'isOnline', isTrue)
            .having(
              (s) => s.result?.nextHeartbeatAfterSeconds,
              'nextHeartbeatAfterSeconds',
              30,
            )
            .having((s) => s.message, 'message', 'Heartbeat ok'),
      ],
      verify: (_) {
        verify(() => buildHeartbeatRequestUseCase()).called(1);
        verify(() => heartbeatUseCase(any())).called(1);
      },
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat uses default interval when initialIntervalSeconds is zero',
      build: () {
        stubHeartbeatSuccess();
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(initialIntervalSeconds: 0),
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.intervalSeconds,
          'intervalSeconds',
          30,
        ),
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
      ],
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat failure when request build fails emits running then failure',
      build: () {
        when(() => buildHeartbeatRequestUseCase()).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Heartbeat context failed')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(),
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Heartbeat context failed',
            ),
      ],
      verify: (_) {
        verifyNever(() => heartbeatUseCase(any()));
      },
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat failure when API fails emits running then failure',
      build: () {
        final request = sampleHeartbeatRequest();
        when(
          () => buildHeartbeatRequestUseCase(),
        ).thenAnswer((_) async => Right(request));
        when(() => heartbeatUseCase(any())).thenAnswer(
          (_) async =>
              const Left(ApiException(message: 'Heartbeat API failed')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(),
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Heartbeat API failed',
            ),
      ],
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat skips API when internet is unavailable',
      build: () {
        when(() => buildHeartbeatRequestUseCase()).thenAnswer(
          (_) async =>
              Right(sampleHeartbeatRequest(isInternetAvailable: false)),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(),
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.running)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verifyNever(() => heartbeatUseCase(any()));
      },
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'startHeartbeat server forced offline writes courier_online false and emits serverForcedOffline',
      build: () {
        stubHeartbeatSuccess(
          result: sampleHeartbeatResult(
            isOnline: false,
            responseSucceeded: true,
            message: 'Session ended',
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startHeartbeat(),
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>()
            .having(
              (s) => s.status,
              'status',
              HeartbeatStatus.serverForcedOffline,
            )
            .having((s) => s.message, 'message', 'Session ended')
            .having((s) => s.feedbackCounter, 'feedbackCounter', 1),
      ],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(HeartbeatCubit.courierOnlineKey), isFalse);
      },
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'stopHeartbeat emits stopped',
      build: () {
        stubHeartbeatSuccess();
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.startHeartbeat();
        await cubit.stopHeartbeat(reason: 'Test stop');
      },
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>()
            .having((s) => s.status, 'status', HeartbeatStatus.stopped)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<HeartbeatCubit, HeartbeatState>(
      'clearTransientMessage clears message while keeping status',
      build: () {
        stubHeartbeatSuccess(
          result: sampleHeartbeatResult(message: 'Server note'),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.startHeartbeat();
        cubit.clearTransientMessage();
      },
      expect: () => [
        isA<HeartbeatState>().having(
          (s) => s.status,
          'status',
          HeartbeatStatus.running,
        ),
        isA<HeartbeatState>().having(
          (s) => s.message,
          'message',
          'Server note',
        ),
        isA<HeartbeatState>()
            .having((s) => s.message, 'message', isNull)
            .having((s) => s.status, 'status', HeartbeatStatus.running),
      ],
    );

    test('runHeartbeatNow is skipped when heartbeat is not active', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.runHeartbeatNow();

      verifyNever(() => buildHeartbeatRequestUseCase());
      expect(cubit.state.status, HeartbeatStatus.initial);
    });

    test(
      'duplicate startHeartbeat runs immediate tick again when already active',
      () async {
        stubHeartbeatSuccess(matchingIntervalSeconds: 10);
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.startHeartbeat(initialIntervalSeconds: 10);
        await cubit.startHeartbeat(initialIntervalSeconds: 20);

        verify(() => buildHeartbeatRequestUseCase()).called(2);
        verify(() => heartbeatUseCase(any())).called(2);
      },
    );

    test('periodic timer triggers additional heartbeat after interval', () {
      fakeAsync((async) {
        stubHeartbeatSuccess(matchingIntervalSeconds: 5);
        final cubit = buildCubit();

        unawaited(cubit.startHeartbeat(initialIntervalSeconds: 5));
        _pumpAsync(async);

        async.elapse(const Duration(seconds: 5));
        _pumpAsync(async);

        verify(() => heartbeatUseCase(any())).called(2);

        cubit.close();
      });
    });

    test('stopHeartbeat prevents further periodic heartbeat calls', () {
      fakeAsync((async) {
        stubHeartbeatSuccess(matchingIntervalSeconds: 5);
        final cubit = buildCubit();

        unawaited(cubit.startHeartbeat(initialIntervalSeconds: 5));
        _pumpAsync(async);

        unawaited(cubit.stopHeartbeat());
        _pumpAsync(async);

        async.elapse(const Duration(seconds: 10));
        _pumpAsync(async);

        verify(() => heartbeatUseCase(any())).called(1);

        cubit.close();
      });
    });

    test(
      'server nextHeartbeatAfterSeconds reschedules timer to new interval',
      () {
        fakeAsync((async) {
          final request = sampleHeartbeatRequest();
          when(
            () => buildHeartbeatRequestUseCase(),
          ).thenAnswer((_) async => Right(request));
          when(() => heartbeatUseCase(any())).thenAnswer(
            (_) async =>
                Right(sampleHeartbeatResult(nextHeartbeatAfterSeconds: 5)),
          );

          final cubit = buildCubit();

          unawaited(cubit.startHeartbeat(initialIntervalSeconds: 30));
          _pumpAsync(async);

          expect(cubit.state.intervalSeconds, 5);

          async.elapse(const Duration(seconds: 5));
          _pumpAsync(async);

          verify(() => heartbeatUseCase(any())).called(2);

          cubit.close();
        });
      },
    );

    test(
      'runHeartbeatNow skips tick while previous request is in progress',
      () {
        fakeAsync((async) {
          final request = sampleHeartbeatRequest();
          final completer = Completer<Either<ApiException, HeartbeatResult>>();

          when(
            () => buildHeartbeatRequestUseCase(),
          ).thenAnswer((_) async => Right(request));
          when(
            () => heartbeatUseCase(any()),
          ).thenAnswer((_) => completer.future);

          final cubit = buildCubit();

          unawaited(cubit.startHeartbeat(initialIntervalSeconds: 5));
          _pumpAsync(async);

          cubit.runHeartbeatNow();
          _pumpAsync(async);

          verify(() => heartbeatUseCase(any())).called(1);

          completer.complete(Right(sampleHeartbeatResult()));
          _pumpAsync(async);

          cubit.close();
        });
      },
    );
  });
}
