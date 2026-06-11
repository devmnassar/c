part of 'forget_password_cubit.dart';

enum ForgetPasswordStatus { initial, loading, success, failure }

class ForgetPasswordState {
  const ForgetPasswordState({
    this.status = ForgetPasswordStatus.initial,
    this.errorMessage,
    this.feedbackMessage,
    this.debugOtpCode,
    this.feedbackCounter = 0,
    this.feedbackIsError = false,
    this.initialPhoneNumber,
    this.selectedPhoneNumber,
    this.e164Number = '',
    this.phoneInputValid = false,
    this.otpExpiresInSeconds = 0,
  });

  final ForgetPasswordStatus status;
  final String? errorMessage;
  final String? feedbackMessage;
  final String? debugOtpCode;
  final int feedbackCounter;
  final bool feedbackIsError;
  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
  final String e164Number;
  final bool phoneInputValid;
  final int otpExpiresInSeconds;

  bool get loading => status == ForgetPasswordStatus.loading;

  ForgetPasswordState copyWith({
    ForgetPasswordStatus? status,
    Object? errorMessage = _unset,
    Object? feedbackMessage = _unset,
    Object? debugOtpCode = _unset,
    int? feedbackCounter,
    bool? feedbackIsError,
    PhoneNumber? initialPhoneNumber,
    PhoneNumber? selectedPhoneNumber,
    String? e164Number,
    bool? phoneInputValid,
    int? otpExpiresInSeconds,
  }) {
    return ForgetPasswordState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _unset)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      debugOtpCode: identical(debugOtpCode, _unset)
          ? this.debugOtpCode
          : debugOtpCode as String?,
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      selectedPhoneNumber: selectedPhoneNumber ?? this.selectedPhoneNumber,
      e164Number: e164Number ?? this.e164Number,
      phoneInputValid: phoneInputValid ?? this.phoneInputValid,
      otpExpiresInSeconds: otpExpiresInSeconds ?? this.otpExpiresInSeconds,
    );
  }
}

const Object _unset = Object();
