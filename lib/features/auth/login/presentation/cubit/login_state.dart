part of 'login_cubit.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginCubitState {
  const LoginCubitState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.feedbackMessage,
    this.feedbackCounter = 0,
    this.feedbackIsError = false,
    this.obscurePassword = true,
    this.initialPhoneNumber,
    this.selectedPhoneNumber,
    this.e164Number = '',
    this.phoneInputValid = false,
    this.password = '',
    this.phoneText = '',
    this.showValidationErrors = false,
  });

  final LoginStatus status;
  final String? errorMessage;
  final String? feedbackMessage;
  final int feedbackCounter;
  final bool feedbackIsError;
  final bool obscurePassword;
  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
  final String e164Number;
  final bool phoneInputValid;
  final String password;
  final String phoneText;
  final bool showValidationErrors;

  bool get isLoading => status == LoginStatus.loading;
  bool get hasAnyInput =>
      phoneText.trim().isNotEmpty || password.trim().isNotEmpty;

  LoginCubitState copyWith({
    LoginStatus? status,
    Object? errorMessage = _unset,
    Object? feedbackMessage = _unset,
    int? feedbackCounter,
    bool? feedbackIsError,
    bool? obscurePassword,
    PhoneNumber? initialPhoneNumber,
    PhoneNumber? selectedPhoneNumber,
    String? e164Number,
    bool? phoneInputValid,
    String? password,
    String? phoneText,
    bool? showValidationErrors,
  }) {
    return LoginCubitState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _unset)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackCounter: feedbackCounter ?? this.feedbackCounter,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      selectedPhoneNumber: selectedPhoneNumber ?? this.selectedPhoneNumber,
      e164Number: e164Number ?? this.e164Number,
      phoneInputValid: phoneInputValid ?? this.phoneInputValid,
      password: password ?? this.password,
      phoneText: phoneText ?? this.phoneText,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
    );
  }
}

const Object _unset = Object();
