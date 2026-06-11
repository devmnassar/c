part of 'sign_up_cubit.dart';

enum SignUpStatus { initial, loading, success, failure }

class SignUpState {
  const SignUpState({
    this.status = SignUpStatus.initial,
    this.errorMessage,
    this.initialPhoneNumber,
    this.e164Number = '',
    this.nationalNumber = '',
    this.profilePhoto,
    this.obscurePassword = true,
    this.phoneVerified = false,
  });

  final SignUpStatus status;
  final String? errorMessage;
  final PhoneNumber? initialPhoneNumber;
  final String e164Number;
  final String nationalNumber;
  final File? profilePhoto;
  final bool obscurePassword;
  final bool phoneVerified;

  bool get loading => status == SignUpStatus.loading;

  SignUpState copyWith({
    SignUpStatus? status,
    Object? errorMessage = _unset,
    PhoneNumber? initialPhoneNumber,
    String? e164Number,
    String? nationalNumber,
    Object? profilePhoto = _unset,
    bool? obscurePassword,
    bool? phoneVerified,
  }) {
    return SignUpState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      e164Number: e164Number ?? this.e164Number,
      nationalNumber: nationalNumber ?? this.nationalNumber,
      profilePhoto: identical(profilePhoto, _unset)
          ? this.profilePhoto
          : profilePhoto as File?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }
}

const Object _unset = Object();
