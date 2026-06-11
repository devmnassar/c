import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/firebase/fcm_token_service.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/entities/register_auth_result.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/register_with_phone_use_case.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/send_register_otp_use_case.dart';
import 'package:gaseel_courier/features/auth/sign_up/domain/usecases/verify_register_otp_use_case.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'sign_up_phone_number_state.dart';

class SignUpPhoneNumberCubit extends Cubit<SignUpPhoneNumberState> {
  static final _whitespaceRegex = RegExp(r'\s+');

  SignUpPhoneNumberCubit({
    required SendRegisterOtpUseCase sendRegisterOtpUseCase,
    required VerifyRegisterOtpUseCase verifyRegisterOtpUseCase,
    required RegisterWithPhoneUseCase registerWithPhoneUseCase,
  })  : _sendRegisterOtpUseCase = sendRegisterOtpUseCase,
        _verifyRegisterOtpUseCase = verifyRegisterOtpUseCase,
        _registerWithPhoneUseCase = registerWithPhoneUseCase,
        super(const SignUpPhoneNumberState()) {
    _setDefaultPhoneNumber();
    unawaited(_resolveDefaultPhoneCountryFromLocation());
  }

  // Constants
  static const _defaultIsoCode = 'SA';
  static const int otpLength = 6;
  static const int fallbackOtpDurationSeconds = 120;
  static const int resendCooldownSeconds = 60;

  // Dependencies
  final SendRegisterOtpUseCase _sendRegisterOtpUseCase;
  final VerifyRegisterOtpUseCase _verifyRegisterOtpUseCase;
  final RegisterWithPhoneUseCase _registerWithPhoneUseCase;

  // Form and controllers
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  Timer? _otpTimer;
  bool _userInteractedWithPhone = false;

  // Validation and input handlers
  void onPhoneChanged(PhoneNumber number) {
    _userInteractedWithPhone = true;
    final sanitizedPhoneText = _normalizePhoneText(phoneController.text);
    if (sanitizedPhoneText != phoneController.text) {
      phoneController.value = TextEditingValue(
        text: sanitizedPhoneText,
        selection: TextSelection.collapsed(offset: sanitizedPhoneText.length),
      );
    }

    final e164 = _normalizePhoneText(number.phoneNumber ?? '');
    emit(
      state.copyWith(
        selectedPhoneNumber: number,
        e164Number: e164,
        nationalNumber: sanitizedPhoneText,
        phoneInputValid: false,
        errorMessage: null,
        debugOtpCode: null,
        phoneVerified: false,
      ),
    );
  }

  void onPhoneValidated(bool isValid) {
    emit(
      state.copyWith(
        phoneInputValid: isValid,
        errorMessage: null,
      ),
    );
  }

  String? phoneValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return ValidationMessages.phoneRequired;
    }
    if (!state.phoneInputValid) {
      return ValidationMessages.phoneInvalid;
    }
    return null;
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

  void onOtpCodeChanged(int index, String value) {
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
          status: SignUpStartStatus.otpReady,
          errorMessage: null,
        ),
      );
    }
  }

  String get currentOtpCode {
    return otpControllers.map((controller) => controller.text).join();
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

  void clearError() {
    emit(
      state.copyWith(
        status: state.showOtpCard
            ? SignUpStartStatus.otpReady
            : SignUpStartStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        feedbackMessage: null,
      ),
    );
  }

  void resetStatus() {
    emit(state.copyWith(status: SignUpStartStatus.initial, errorMessage: null));
  }

  /// Sends register OTP to backend using `/api/otp/register/send`.
  Future<void> onNext() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    emit(state.copyWith(status: SignUpStartStatus.loading, errorMessage: null));

    final rawInput = _normalizePhoneText(phoneController.text);
    final e164Number = _normalizePhoneText(state.e164Number);
    debugPrint('[PHONE-DEBUG] raw_input="$rawInput"');
    debugPrint(
      '[PHONE-DEBUG] selected_iso="${(state.selectedPhoneNumber ?? state.initialPhoneNumber)?.isoCode}"',
    );
    debugPrint(
      '[PHONE-DEBUG] selected_dial_code="${(state.selectedPhoneNumber ?? state.initialPhoneNumber)?.dialCode}"',
    );
    debugPrint('[PHONE-DEBUG] input_valid="${state.phoneInputValid}"');
    debugPrint('[PHONE-DEBUG] e164_from_widget="$e164Number"');

    if (!state.phoneInputValid ||
        e164Number.isEmpty ||
        !e164Number.startsWith('+')) {
      _emitFailure(
        const ApiException(
          message: 'Enter a valid phone number for the selected country.',
        ),
      );
      return;
    }
    final normalizedPhoneNumber = e164Number;

    final response = await _sendRegisterOtpUseCase(
      phoneNumber: normalizedPhoneNumber,
    );
    response.fold(
      _emitFailure,
      (result) => _emitOtpReadyState(
        phoneNumber: normalizedPhoneNumber,
        expiresInSeconds: result.expiresInSeconds,
        otpCode: result.otpCode,
      ),
    );
  }

  /// Verifies OTP against backend `/api/otp/register/verify`.
  Future<void> verifyOtp() async {
    if (state.otpActionLoading) return;

    if (state.isOtpExpired) {
      emit(
        state.copyWith(
          status: SignUpStartStatus.failure,
          errorMessage: 'OTP expired. Please resend the code first.',
        ),
      );
      return;
    }

    final otpCode = currentOtpCode;
    if (otpCode.length != otpLength) {
      emit(
        state.copyWith(
          status: SignUpStartStatus.failure,
          errorMessage: 'Please enter the 6-digit code',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStartStatus.otpActionLoading,
        errorMessage: null,
      ),
    );

    final response = await _verifyRegisterOtpUseCase(
      phoneNumber: _normalizePhoneText(state.e164Number),
      code: otpCode,
    );

    response.fold(
      _emitFailure,
      (result) {
        if (!result.isVerified) {
          emit(
            state.copyWith(
              status: SignUpStartStatus.otpReady,
              errorMessage: result.message,
            ),
          );
          return;
        }

        _otpTimer?.cancel();
        emit(
          state.copyWith(
            status: SignUpStartStatus.initial,
            errorMessage: null,
            debugOtpCode: null,
            showOtpCard: false,
            phoneVerified: true,
          ),
        );
        _emitFeedback(message: result.message, isError: false);
      },
    );
  }

  /// Completes account creation using `/api/auth/register` after successful OTP verification.
  Future<void> submitSignUp() async {
    if (state.otpActionLoading || state.loading) return;
    if (!state.phoneVerified) {
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStartStatus.loading,
        errorMessage: null,
      ),
    );

    final response = await _registerWithPhoneUseCase(
      phoneNumber: _normalizePhoneText(state.e164Number),
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    ApiException? failure;
    RegisterAuthResult? registerResult;
    response.fold(
      (error) => failure = error,
      (result) => registerResult = result,
    );

    if (failure != null) {
      _emitFailure(failure!);
      return;
    }

    try {
      await _storeAuthSession(registerResult!);
      await FcmTokenService.refreshAndCacheToken(reason: 'register_success');
      emit(
        state.copyWith(
          status: SignUpStartStatus.success,
          errorMessage: null,
        ),
      );
    } catch (_) {
      _emitFailure(
        const ApiException(
          message: 'Failed to save session data. Please try again.',
        ),
      );
    }
  }

  /// Requests a new OTP from `/api/otp/register/send` and restarts countdown.
  Future<void> resendOtp() async {
    if (state.otpActionLoading) return;
    if (!state.canResend) {
      _emitFailure(
        const ApiException(
            message: 'Please wait before requesting another OTP.'),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignUpStartStatus.otpActionLoading,
        errorMessage: null,
      ),
    );

    final response = await _sendRegisterOtpUseCase(
      phoneNumber: _normalizePhoneText(state.e164Number),
    );
    response.fold(
      _emitFailure,
      (result) => _emitOtpReadyState(
        phoneNumber: _normalizePhoneText(state.e164Number),
        expiresInSeconds: result.expiresInSeconds,
        otpCode: result.otpCode,
      ),
    );
  }

  // Private helpers
  void _setDefaultPhoneNumber() {
    final defaultPhoneNumber = PhoneNumber(isoCode: _defaultIsoCode);
    emit(
      state.copyWith(
        initialPhoneNumber: defaultPhoneNumber,
        selectedPhoneNumber: defaultPhoneNumber,
        phoneInputValid: false,
      ),
    );
  }

  Future<void> _resolveDefaultPhoneCountryFromLocation() async {
    try {
      final cachedIsoCode = await SharedPrefHelper.getNullableString(
        SharedPrefKeys.cachedDetectedPhoneIsoCode,
      );
      if (_isValidIsoCode(cachedIsoCode)) {
        _applyDetectedPhoneCountry(cachedIsoCode!);
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return;
      }

      final isoCode = placemarks.first.isoCountryCode?.toUpperCase();
      if (!_isValidIsoCode(isoCode)) {
        return;
      }

      await SharedPrefHelper.setData(
        SharedPrefKeys.cachedDetectedPhoneIsoCode,
        isoCode!,
      );
      _applyDetectedPhoneCountry(isoCode);
    } catch (_) {
      // Keep the fallback country when location lookup is unavailable.
    }
  }

  bool _isValidIsoCode(String? isoCode) {
    return isoCode != null && RegExp(r'^[A-Z]{2}$').hasMatch(isoCode);
  }

  String _normalizePhoneText(String value) {
    return value.replaceAll(_whitespaceRegex, '');
  }

  void _applyDetectedPhoneCountry(String isoCode) {
    if (_userInteractedWithPhone ||
        phoneController.text.trim().isNotEmpty ||
        state.phoneVerified ||
        state.showOtpCard) {
      return;
    }

    final normalizedIsoCode = isoCode.toUpperCase();
    final currentIsoCode = (state.selectedPhoneNumber?.isoCode ??
            state.initialPhoneNumber?.isoCode ??
            '')
        .toUpperCase();
    if (currentIsoCode == normalizedIsoCode) {
      return;
    }

    final detectedPhoneNumber = PhoneNumber(isoCode: normalizedIsoCode);
    emit(
      state.copyWith(
        initialPhoneNumber: detectedPhoneNumber,
        selectedPhoneNumber: detectedPhoneNumber,
        e164Number: '',
        nationalNumber: '',
        phoneInputValid: false,
      ),
    );
  }

  void _emitOtpReadyState({
    required String phoneNumber,
    required int expiresInSeconds,
    String? otpCode,
  }) {
    _clearOtpInputs();
    emit(
      state.copyWith(
        status: SignUpStartStatus.otpReady,
        errorMessage: null,
        showOtpCard: true,
        otpSecondsRemaining: _safeOtpDuration(expiresInSeconds),
        resendCooldownRemaining: 0,
        e164Number: phoneNumber,
        debugOtpCode: otpCode,
      ),
    );
    _startOtpTimer();
    _focusFirstOtpField();
  }

  int _safeOtpDuration(int value) {
    return value > 0 ? value : fallbackOtpDurationSeconds;
  }

  void _focusFirstOtpField() {
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes.first.requestFocus();
    }
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          status: SignUpStartStatus.otpReady,
          otpSecondsRemaining: nextOtp,
          resendCooldownRemaining: nextCooldown,
        ),
      );

      if (nextOtp == 0 && nextCooldown == 0) {
        timer.cancel();
      }
    });
  }

  void _clearOtpInputs() {
    for (final controller in otpControllers) {
      controller.clear();
    }
  }

  void _emitFailure(ApiException error) {
    emit(
      state.copyWith(
        status: SignUpStartStatus.failure,
        errorMessage: _extractMessage(error),
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

  String _extractMessage(ApiException error) {
    return error.message;
  }

  Future<void> _storeAuthSession(RegisterAuthResult data) async {
    await SharedPrefHelper.setSecuredString(
      SharedPrefKeys.userToken,
      data.accessToken,
    );
    await SharedPrefHelper.setSecuredString(
      SharedPrefKeys.refreshToken,
      data.refreshToken,
    );
    await SharedPrefHelper.setData(SharedPrefKeys.authUserId, data.userId);
    await SharedPrefHelper.setData(SharedPrefKeys.authUserName, data.userName);
    await SharedPrefHelper.setData(
      SharedPrefKeys.authPhoneNumber,
      data.phoneNumber,
    );
    await SharedPrefHelper.setData(SharedPrefKeys.authIsActive, data.isActive);
    await SharedPrefHelper.setData(
      SharedPrefKeys.authIsRejected,
      data.isRejected,
    );
    await SharedPrefHelper.setData(
      SharedPrefKeys.authIsPhoneVerified,
      data.isPhoneVerified,
    );
    await SharedPrefHelper.setData(
      SharedPrefKeys.authExpiresInMinutes,
      data.expiresInMinutes,
    );
  }

  @override
  Future<void> close() {
    _otpTimer?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    return super.close();
  }
}
