import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/send_reset_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/verify_reset_otp_use_case.dart';

part 'forget_password_otp_state.dart';

class ForgetPasswordOtpCubit extends Cubit<ForgetPasswordOtpState> {
  ForgetPasswordOtpCubit({
    required SendResetOtpUseCase sendResetOtpUseCase,
    required VerifyResetOtpUseCase verifyResetOtpUseCase,
  })  : _sendResetOtpUseCase = sendResetOtpUseCase,
        _verifyResetOtpUseCase = verifyResetOtpUseCase,
        super(const ForgetPasswordOtpState());

  static const int otpLength = 6;
  static const int fallbackOtpDurationSeconds = 120;
  static const int resendCooldownSeconds = 60;

  final SendResetOtpUseCase _sendResetOtpUseCase;
  final VerifyResetOtpUseCase _verifyResetOtpUseCase;

  final List<TextEditingController> otpControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;

  void initialize({
    required String phoneNumber,
    int? expiresInSeconds,
    String? debugOtpCode,
    String? message,
  }) {
    _clearOtpInputs();
    emit(
      state.copyWith(
        status: ForgetPasswordOtpStatus.initial,
        phoneNumber: phoneNumber,
        debugOtpCode: debugOtpCode,
        otpSecondsRemaining:
            _safeOtpDuration(expiresInSeconds ?? fallbackOtpDurationSeconds),
        resendCooldownRemaining: 0,
        errorMessage: null,
      ),
    );
    if (message != null && message.trim().isNotEmpty) {
      _emitFeedback(message: message, isError: false);
    }
    _startTimer();
  }

  void onCodeChanged(int index, String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized != value) {
      otpControllers[index].text = sanitized;
      otpControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: otpControllers[index].text.length),
      );
    }

    if (sanitized.length == 1 && index < otpLength - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (sanitized.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    if ((state.errorMessage ?? '').isNotEmpty) {
      emit(
        state.copyWith(
          status: ForgetPasswordOtpStatus.initial,
          errorMessage: null,
        ),
      );
    }
  }

  String get currentOtpCode {
    return otpControllers.map((controller) => controller.text).join();
  }

  Future<void> verifyOtp() async {
    if (state.loading) return;

    if (state.isOtpExpired) {
      _emitFailure(
        const ApiException(
          message: 'OTP expired. Please wait for resend and try again.',
        ),
      );
      return;
    }

    final otpCode = currentOtpCode;
    if (otpCode.length != otpLength) {
      _emitFailure(
        const ApiException(message: 'Please enter the 6-digit code'),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ForgetPasswordOtpStatus.loading,
        errorMessage: null,
      ),
    );

    final response = await _verifyResetOtpUseCase(
      phoneNumber: state.phoneNumber,
      code: otpCode,
    );

    response.fold(
      _emitFailure,
      (result) {
        if (!result.isVerified) {
          emit(
            state.copyWith(
              status: ForgetPasswordOtpStatus.initial,
              errorMessage: result.message,
            ),
          );
          _emitFeedback(message: result.message, isError: true);
          return;
        }

        _timer?.cancel();
        emit(
          state.copyWith(
            status: ForgetPasswordOtpStatus.success,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> resendOtp() async {
    if (state.loading) return;
    if (!state.canResend) {
      _emitFailure(
        const ApiException(
            message: 'Please wait before requesting another OTP.'),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ForgetPasswordOtpStatus.loading,
        errorMessage: null,
      ),
    );

    final response = await _sendResetOtpUseCase(phoneNumber: state.phoneNumber);

    response.fold(
      _emitFailure,
      (result) {
        _clearOtpInputs();
        emit(
          state.copyWith(
            status: ForgetPasswordOtpStatus.initial,
            otpSecondsRemaining: _safeOtpDuration(result.expiresInSeconds),
            resendCooldownRemaining: 0,
            debugOtpCode: result.otpCode,
            errorMessage: null,
          ),
        );
        _emitFeedback(message: result.message, isError: false);
        _startTimer();
      },
    );
  }

  int _safeOtpDuration(int value) {
    return value > 0 ? value : fallbackOtpDurationSeconds;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int nextOtp = state.otpSecondsRemaining;
      int nextCooldown = state.resendCooldownRemaining;

      if (nextOtp > 0) {
        nextOtp -= 1;
        if (nextOtp == 0 && nextCooldown == 0) {
          nextCooldown = resendCooldownSeconds;
        }
      } else if (nextCooldown > 0) {
        nextCooldown -= 1;
      }

      emit(
        state.copyWith(
          status: ForgetPasswordOtpStatus.initial,
          otpSecondsRemaining: nextOtp,
          resendCooldownRemaining: nextCooldown,
        ),
      );

      if (nextOtp == 0 && nextCooldown == 0) {
        timer.cancel();
      }
    });
  }

  void _emitFailure(ApiException error) {
    emit(
      state.copyWith(
        status: ForgetPasswordOtpStatus.failure,
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

  void _clearOtpInputs() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  void resetStatus() {
    emit(
      state.copyWith(
        status: ForgetPasswordOtpStatus.initial,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    return super.close();
  }
}
