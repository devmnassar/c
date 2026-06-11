part of 'sign_up_phone_number_cubit.dart';

@immutable
enum SignUpStartStatus { initial, loading, success, failure }

class SignUpStartState {
  const SignUpStartState({
    this.status = SignUpStartStatus.initial,
    this.errorMessage,
    this.initialPhoneNumber,
    this.e164Number = '',
    this.nationalNumber = '',
  });

  final SignUpStartStatus status;
  final String? errorMessage;
  final PhoneNumber? initialPhoneNumber;
  final String e164Number;
  final String nationalNumber;

  bool get loading => status == SignUpStartStatus.loading;

  SignUpStartState copyWith({
    SignUpStartStatus? status,
    Object? errorMessage = _unset,
    PhoneNumber? initialPhoneNumber,
    String? e164Number,
    String? nationalNumber,
  }) {
    return SignUpStartState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      e164Number: e164Number ?? this.e164Number,
      nationalNumber: nationalNumber ?? this.nationalNumber,
    );
  }
}

const Object _unset = Object();
