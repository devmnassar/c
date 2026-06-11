part of 'login_cubit.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginCubitState {
  const LoginCubitState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.obscurePassword = true,
  });

  final LoginStatus status;
  final String? errorMessage;
  final bool obscurePassword;

  bool get isLoading => status == LoginStatus.loading;

  LoginCubitState copyWith({
    LoginStatus? status,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return LoginCubitState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}
