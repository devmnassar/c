part of 'courier_location_sync_cubit.dart';

enum CourierLocationSyncStatus {
  stopped,
  running,
  failure,
}

class CourierLocationSyncState {
  const CourierLocationSyncState({
    this.status = CourierLocationSyncStatus.stopped,
    this.intervalSeconds = CourierLocationSyncCubit.defaultIntervalSeconds,
    this.lastSentAtUtc,
    this.errorMessage,
  });

  final CourierLocationSyncStatus status;
  final int intervalSeconds;
  final DateTime? lastSentAtUtc;
  final String? errorMessage;

  CourierLocationSyncState copyWith({
    CourierLocationSyncStatus? status,
    int? intervalSeconds,
    DateTime? lastSentAtUtc,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CourierLocationSyncState(
      status: status ?? this.status,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      lastSentAtUtc: lastSentAtUtc ?? this.lastSentAtUtc,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
