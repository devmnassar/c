part of 'heartbeat_cubit.dart';

enum HeartbeatStatus {
  initial,
  running,
  stopped,
  failure,
  serverForcedOffline,
}

class HeartbeatState {
  const HeartbeatState({
    this.status = HeartbeatStatus.initial,
    this.result,
    this.intervalSeconds = 30,
    this.message,
    this.errorMessage,
    this.feedbackCounter = 0,
  });

  final HeartbeatStatus status;
  final HeartbeatResult? result;
  final int intervalSeconds;
  final String? message;
  final String? errorMessage;
  final int feedbackCounter;

  HeartbeatState copyWith({
    HeartbeatStatus? status,
    HeartbeatResult? result,
    int? intervalSeconds,
    String? message,
    String? errorMessage,
    int? feedbackCounter,
    bool clearErrorMessage = false,
  }) {
    return HeartbeatState(
      status: status ?? this.status,
      result: result ?? this.result,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      message: message,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
    );
  }
}
