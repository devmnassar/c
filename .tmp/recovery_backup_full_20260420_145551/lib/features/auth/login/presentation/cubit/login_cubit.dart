import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../data/datasources/login_local_data_source.dart';
import '../../data/repositories/login_repository_impl.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/usecases/login_use_case.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginCubitState> {
  LoginCubit({LoginUseCase? loginUseCase})
      : _loginUseCase = loginUseCase ??
            LoginUseCase(
              LoginRepositoryImpl(LoginLocalDataSource()),
            ),
        super(
          LoginCubitState(
            initialPhoneNumber: PhoneNumber(isoCode: 'SA'),
            selectedPhoneNumber: PhoneNumber(isoCode: 'SA'),
          ),
        );

  final LoginUseCase _loginUseCase;

  static LoginCubit get(BuildContext context) =>
      BlocProvider.of<LoginCubit>(context);

  final formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void onPhoneChanged(PhoneNumber number) {
    emit(state.copyWith(selectedPhoneNumber: number));
  }

  String _normalizedPhoneForLogin() {
    final isoCode = (state.selectedPhoneNumber ?? state.initialPhoneNumber)
        ?.isoCode
        ?.toUpperCase();
    return AppValidators.normalizePhoneForSubmission(
      phoneController.text,
      isoCode: isoCode,
    );
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading));

    try {
      // Keep the same UX timing used before moving logic to cubit.
      await Future.delayed(const Duration(seconds: 1));
      final credentials = LoginCredentials(
        phoneNumber: _normalizedPhoneForLogin(),
        password: passwordController.text,
      );
      //  await _loginUseCase(credentials);
     
  
      emit(state.copyWith(status: LoginStatus.success));
    } catch (_) {
      emit(state.copyWith(status: LoginStatus.failure));
    }
  }

  void resetStatus() {
    emit(state.copyWith(status: LoginStatus.initial));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  @override
  Future<void> close() {
    phoneController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
