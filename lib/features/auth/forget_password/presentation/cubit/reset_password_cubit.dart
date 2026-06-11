import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/reset_password_use_case.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _resetPasswordUseCase = resetPasswordUseCase,
        super(const ResetPasswordState());

  final ResetPasswordUseCase _resetPasswordUseCase;

  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void setPhoneNumber(String phoneNumber) {
    emit(state.copyWith(phoneNumber: phoneNumber));
  }

  String? passwordValidator(String? value) {
    return Validators.passwordValidatorWithOptions(
      minLength: 8,
      maxLength: 30,
      requireUppercase: false,
      requireLowercase: false,
      requireDigit: false,
      requireSpecialChar: false,
      minLengthMessage: ValidationMessages.passwordTooShort,
      maxLengthMessage: ValidationMessages.passwordTooLong,
    )(value);
  }

  String? confirmPasswordValidator(String? value) {
    return Validators.confirmPasswordValidator(
      passwordValue: () => passwordController.text,
      minLength: 8,
      maxLength: 30,
      requireUppercase: false,
      requireLowercase: false,
      requireDigit: false,
      requireSpecialChar: false,
      minLengthMessage: ValidationMessages.passwordTooShort,
      maxLengthMessage: ValidationMessages.passwordTooLong,
      mismatchMessage: 'Password and confirm password must be the same',
    )(value);
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void toggleConfirmPasswordVisibility() {
    emit(
      state.copyWith(
        obscureConfirmPassword: !state.obscureConfirmPassword,
      ),
    );
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (state.phoneNumber.trim().isEmpty) {
      _emitFailure(
        const ApiException(
          message:
              'Phone number is missing. Please restart forgot password flow.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ResetPasswordStatus.loading,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );

    final response = await _resetPasswordUseCase(
      phoneNumber: state.phoneNumber,
      newPassword: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    response.fold(
      _emitFailure,
      (result) {
        emit(
          state.copyWith(
            status: ResetPasswordStatus.success,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void resetStatus() {
    emit(
      state.copyWith(
        status: ResetPasswordStatus.initial,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );
  }

  void _emitFailure(ApiException error) {
    emit(
      state.copyWith(
        status: ResetPasswordStatus.failure,
        errorMessage: error.message,
      ),
    );
    _emitFeedback(message: error.message, isError: true);
  }

  void _emitFeedback({
    required String message,
    required bool isError,
  }) {
    emit(
      state.copyWith(
        feedbackMessage: message,
        feedbackIsError: isError,
        feedbackCounter: state.feedbackCounter + 1,
      ),
    );
  }

  @override
  Future<void> close() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }
}
