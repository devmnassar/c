part of 'sign_up_phone_number_cubit.dart';

@immutable
enum SignUpStartStatus {
  initial,
  loading,
  otpReady,
  otpActionLoading,
  success,
  failure,
}

class SignUpPhoneNumberState {
  const SignUpPhoneNumberState({
    this.status = SignUpStartStatus.initial,
    this.errorMessage,
    this.feedbackMessage,
    this.debugOtpCode,
    this.initialPhoneNumber,
    this.selectedPhoneNumber,
    this.e164Number = '',
    this.nationalNumber = '',
    this.feedbackCounter = 0,
    bool? feedbackIsError,
    bool? showOtpCard,
    int? otpSecondsRemaining,
    int? resendCooldownRemaining,
    bool? phoneVerified,
    bool? phoneInputValid,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  })  : _showOtpCard = showOtpCard,
        _feedbackIsError = feedbackIsError,
        _otpSecondsRemaining = otpSecondsRemaining,
        _resendCooldownRemaining = resendCooldownRemaining,
        _phoneVerified = phoneVerified,
        _phoneInputValid = phoneInputValid,
        _obscurePassword = obscurePassword,
        _obscureConfirmPassword = obscureConfirmPassword;

  final SignUpStartStatus status;
  final String? errorMessage;
  final String? feedbackMessage;
  final String? debugOtpCode;
  final int feedbackCounter;
  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
  final String e164Number;
  final String nationalNumber;
  final bool? _feedbackIsError;
  final bool? _showOtpCard;
  final int? _otpSecondsRemaining;
  final int? _resendCooldownRemaining;
  final bool? _phoneVerified;
  final bool? _phoneInputValid;
  final bool? _obscurePassword;
  final bool? _obscureConfirmPassword;

  bool get feedbackIsError => _feedbackIsError ?? false;
  bool get showOtpCard => _showOtpCard ?? false;
  int get otpSecondsRemaining => _otpSecondsRemaining ?? 0;
  int get resendCooldownRemaining => _resendCooldownRemaining ?? 0;
  bool get phoneVerified => _phoneVerified ?? false;
  bool get phoneInputValid => _phoneInputValid ?? false;
  bool get obscurePassword => _obscurePassword ?? true;
  bool get obscureConfirmPassword => _obscureConfirmPassword ?? true;

  bool get loading => status == SignUpStartStatus.loading;
  bool get otpActionLoading => status == SignUpStartStatus.otpActionLoading;
  bool get isOtpExpired => showOtpCard && otpSecondsRemaining <= 0;
  bool get canResend =>
      showOtpCard && isOtpExpired && resendCooldownRemaining <= 0;

  SignUpPhoneNumberState copyWith({
    SignUpStartStatus? status,
    Object? errorMessage = _unset,
    Object? feedbackMessage = _unset,
    Object? debugOtpCode = _unset,
    int? feedbackCounter,
    bool? feedbackIsError,
    PhoneNumber? initialPhoneNumber,
    PhoneNumber? selectedPhoneNumber,
    String? e164Number,
    String? nationalNumber,
    bool? showOtpCard,
    int? otpSecondsRemaining,
    int? resendCooldownRemaining,
    bool? phoneVerified,
    bool? phoneInputValid,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return SignUpPhoneNumberState(
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
      nationalNumber: nationalNumber ?? this.nationalNumber,
      showOtpCard: showOtpCard ?? this.showOtpCard,
      otpSecondsRemaining: otpSecondsRemaining ?? this.otpSecondsRemaining,
      resendCooldownRemaining:
          resendCooldownRemaining ?? this.resendCooldownRemaining,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      phoneInputValid: phoneInputValid ?? this.phoneInputValid,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

const Object _unset = Object();
