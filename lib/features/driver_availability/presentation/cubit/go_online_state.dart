part of 'go_online_cubit.dart';

enum GoOnlineStatus {
  initial,
  loading,
  success,
  failure,
}

class GoOnlineState {
  const GoOnlineState({
    this.status = GoOnlineStatus.initial,
    this.result,
    this.errorMessage,
  });

  final GoOnlineStatus status;
  final GoOnlineResult? result;
  final String? errorMessage;

  bool get isLoading => status == GoOnlineStatus.loading;

  GoOnlineState copyWith({
    GoOnlineStatus? status,
    GoOnlineResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return GoOnlineState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
