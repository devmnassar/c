part of 'reset_password_cubit.dart';

enum ResetPasswordStatus { initial, loading, success, failure }

class ResetPasswordState {
  const ResetPasswordState({
    this.status = ResetPasswordStatus.initial,
    this.phoneNumber = '',
    this.errorMessage,
    this.feedbackMessage,
    this.feedbackCounter = 0,
    this.feedbackIsError = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final ResetPasswordStatus status;
  final String phoneNumber;
  final String? errorMessage;
  final String? feedbackMessage;
  final int feedbackCounter;
  final bool feedbackIsError;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  bool get loading => status == ResetPasswordStatus.loading;

  ResetPasswordState copyWith({
    ResetPasswordStatus? status,
    String? phoneNumber,
    Object? errorMessage = _unset,
    Object? feedbackMessage = _unset,
    int? feedbackCounter,
    bool? feedbackIsError,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return ResetPasswordState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _unset)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

const Object _unset = Object();
