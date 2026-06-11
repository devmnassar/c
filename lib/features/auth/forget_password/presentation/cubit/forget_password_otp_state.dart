part of 'forget_password_otp_cubit.dart';

enum ForgetPasswordOtpStatus { initial, loading, success, failure }

class ForgetPasswordOtpState {
  const ForgetPasswordOtpState({
    this.status = ForgetPasswordOtpStatus.initial,
    this.phoneNumber = '',
    this.debugOtpCode,
    this.errorMessage,
    this.feedbackMessage,
    this.feedbackCounter = 0,
    this.feedbackIsError = false,
    this.otpSecondsRemaining = 0,
    this.resendCooldownRemaining = 0,
  });

  final ForgetPasswordOtpStatus status;
  final String phoneNumber;
  final String? debugOtpCode;
  final String? errorMessage;
  final String? feedbackMessage;
  final int feedbackCounter;
  final bool feedbackIsError;
  final int otpSecondsRemaining;
  final int resendCooldownRemaining;

  bool get loading => status == ForgetPasswordOtpStatus.loading;
  bool get isOtpExpired => otpSecondsRemaining <= 0;
  bool get canResend => isOtpExpired && resendCooldownRemaining <= 0;

  ForgetPasswordOtpState copyWith({
    ForgetPasswordOtpStatus? status,
    String? phoneNumber,
    Object? debugOtpCode = _unset,
    Object? errorMessage = _unset,
    Object? feedbackMessage = _unset,
    int? feedbackCounter,
    bool? feedbackIsError,
    int? otpSecondsRemaining,
    int? resendCooldownRemaining,
  }) {
    return ForgetPasswordOtpState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      debugOtpCode: identical(debugOtpCode, _unset)
          ? this.debugOtpCode
          : debugOtpCode as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _unset)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      otpSecondsRemaining: otpSecondsRemaining ?? this.otpSecondsRemaining,
      resendCooldownRemaining:
          resendCooldownRemaining ?? this.resendCooldownRemaining,
    );
  }
}

const Object _unset = Object();
