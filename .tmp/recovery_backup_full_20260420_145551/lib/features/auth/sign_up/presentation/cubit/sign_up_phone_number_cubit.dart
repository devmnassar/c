import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'sign_up_phone_number_state.dart';

class SignUpStartCubit extends Cubit<SignUpStartState> {
  SignUpStartCubit() : super(const SignUpStartState()) {
    _setDefaultPhoneNumber();
  }

  static const _defaultIsoCode = 'SA';

  final phoneController = TextEditingController();

  void _setDefaultPhoneNumber() {
    emit(
      state.copyWith(initialPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode)),
    );
  }

  void onPhoneChanged(PhoneNumber number) {
    emit(
      state.copyWith(
        e164Number: number.phoneNumber ?? '',
        nationalNumber: phoneController.text,
      ),
    );
  }

  Future<void> onNext() async {
    final phoneNumber = state.e164Number.trim();
    final nationalNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty || nationalNumber.isEmpty) {
      emit(
        state.copyWith(
          status: SignUpStartStatus.failure,
          errorMessage: 'Phone number is required',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignUpStartStatus.loading, errorMessage: null));

    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(
          status: SignUpStartStatus.success, errorMessage: null));
    } catch (_) {
      emit(
        state.copyWith(
          status: SignUpStartStatus.failure,
          errorMessage: 'Something went wrong, please try again.',
        ),
      );
    }
  }

  void resetStatus() {
    emit(state.copyWith(status: SignUpStartStatus.initial, errorMessage: null));
  }

  @override
  Future<void> close() {
    phoneController.dispose();
    return super.close();
  }
}
