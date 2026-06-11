import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/profile/profile_service.dart';
import 'package:sms_autofill/sms_autofill.dart';

part 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> with CodeAutoFill {
  OtpCubit() : super(const OtpState());

  static const int otpLength = 6;
  static const Duration _mockVerifyDelay = Duration(seconds: 1);

  final List<TextEditingController> otpControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  void initializeAutoFill() {
    try {
      listenForCode();
    } catch (_) {
      // Auto-fill not available on this device/session.
    }
  }

  @override
  void codeUpdated() {
    final smsCode = code;
    if (smsCode == null || smsCode.length < otpLength) {
      return;
    }

    final match = RegExp(r'\d{6}').firstMatch(smsCode);
    if (match == null) {
      return;
    }

    final extractedCode = match.group(0)!;
    if (extractedCode.length != otpLength) {
      return;
    }

    _applyCode(extractedCode);
    verifyCode(extractedCode);
  }

  void onCodeChanged(int index, String value) {
    if (value.length == 1 && index < otpLength - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    if (index == otpLength - 1 && value.isNotEmpty) {
      final code = currentOtpCode;
      if (code.length == otpLength) {
        verifyCode(code);
      }
    }
  }

  String get currentOtpCode {
    return otpControllers.map((controller) => controller.text).join();
  }

  Future<void> verifyCurrentCode() async {
    await verifyCode(currentOtpCode);
  }

  Future<void> verifyCode(String otpCode) async {
    if (state.isLoading) {
      return;
    }

    if (otpCode.length != otpLength) {
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          errorMessage: 'Please enter the 6-digit code',
          infoMessage: null,
          uiEventId: state.uiEventId + 1,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: OtpStatus.loading,
        errorMessage: null,
        infoMessage: null,
      ),
    );

    try {
      await Future.delayed(_mockVerifyDelay);
      await ProfileService.setPhoneVerified(true);
      emit(
        state.copyWith(
          status: OtpStatus.success,
          errorMessage: null,
          infoMessage: null,
          uiEventId: state.uiEventId + 1,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          errorMessage: 'Invalid verification code',
          infoMessage: null,
          uiEventId: state.uiEventId + 1,
        ),
      );
      clearOtpInputs();
    }
  }

  void resendCode() {
    emit(
      state.copyWith(
        infoMessage: 'Code resent',
        uiEventId: state.uiEventId + 1,
      ),
    );
  }

  void clearMessages() {
    emit(
      state.copyWith(
        errorMessage: null,
        infoMessage: null,
      ),
    );
  }

  void resetStatus() {
    emit(state.copyWith(status: OtpStatus.initial));
  }

  bool shouldNavigateToDocuments(OtpState state) {
    return state.status == OtpStatus.success;
  }

  String? feedbackMessage(OtpState state) {
    final errorMessage = state.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return errorMessage;
    }

    final infoMessage = state.infoMessage;
    if (infoMessage != null && infoMessage.isNotEmpty) {
      return infoMessage;
    }

    return null;
  }

  void consumeStateMessages(OtpState state) {
    if (state.status == OtpStatus.success) {
      resetStatus();
      return;
    }

    if (state.errorMessage != null || state.infoMessage != null) {
      clearMessages();
    }
  }

  void clearOtpInputs() {
    for (final controller in otpControllers) {
      controller.clear();
    }
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes.first.requestFocus();
    }
  }

  void _applyCode(String code) {
    for (int index = 0; index < otpLength; index++) {
      otpControllers[index].text = code[index];
    }
  }

  @override
  Future<void> close() {
    cancel();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    return super.close();
  }
}
