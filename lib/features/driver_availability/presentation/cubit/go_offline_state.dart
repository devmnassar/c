part of 'go_offline_cubit.dart';

enum GoOfflineStatus {
  initial,
  loading,
  success,
  failure,
}

class GoOfflineState {
  const GoOfflineState({
    this.status = GoOfflineStatus.initial,
    this.result,
    this.errorMessage,
  });

  final GoOfflineStatus status;
  final GoOfflineResult? result;
  final String? errorMessage;

  bool get isLoading => status == GoOfflineStatus.loading;

  GoOfflineState copyWith({
    GoOfflineStatus? status,
    GoOfflineResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return GoOfflineState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
