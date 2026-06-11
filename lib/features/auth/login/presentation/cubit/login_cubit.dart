import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaseel_courier/core/auth/auth_service.dart';
import 'package:gaseel_courier/core/firebase/fcm_token_service.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:gaseel_courier/features/auth/login/domain/entities/auth_user.dart';
import 'package:gaseel_courier/features/auth/login/domain/entities/login_credentials.dart';
import 'package:gaseel_courier/features/auth/login/domain/usecases/login_use_case.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginCubitState> {
  static const _defaultIsoCode = 'SA';
  static final _whitespaceRegex = RegExp(r'\s+');

  LoginCubit({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(
          LoginCubitState(
            initialPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode),
            selectedPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode),
          ),
        ) {
    unawaited(_resolveDefaultPhoneCountryFromLocation());
  }

  final LoginUseCase _loginUseCase;
  bool _userInteractedWithPhone = false;

  static LoginCubit get(BuildContext context) =>
      BlocProvider.of<LoginCubit>(context);

  final formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void onPhoneChanged(PhoneNumber number) {
    _userInteractedWithPhone = true;
    final sanitizedPhoneText = _normalizePhoneText(phoneController.text);
    if (sanitizedPhoneText != phoneController.text) {
      phoneController.value = TextEditingValue(
        text: sanitizedPhoneText,
        selection: TextSelection.collapsed(offset: sanitizedPhoneText.length),
      );
    }

    final normalizedPhoneNumber = _normalizePhoneText(number.phoneNumber ?? '');
    final nextPassword = state.password.trim();
    emit(
      state.copyWith(
        selectedPhoneNumber: number,
        e164Number: normalizedPhoneNumber,
        phoneText: sanitizedPhoneText,
        phoneInputValid: false,
        errorMessage: null,
        showValidationErrors: sanitizedPhoneText.isEmpty && nextPassword.isEmpty
            ? false
            : state.showValidationErrors,
      ),
    );
  }

  void onPasswordChanged(String value) {
    final nextPassword = value.trim();
    emit(
      state.copyWith(
        password: value,
        errorMessage: null,
        showValidationErrors:
            state.phoneText.trim().isEmpty && nextPassword.isEmpty
                ? false
                : state.showValidationErrors,
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

  Future<void> login() async {
    if (state.isLoading) {
      return;
    }

    _safeEmit(
      state.copyWith(
        showValidationErrors: true,
      ),
    );

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    debugPrint('================ LOGIN FLOW START ================');
    _safeEmit(
      state.copyWith(
        status: LoginStatus.loading,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );

    final phoneNumber = _normalizePhoneText(state.e164Number);
    debugPrint('[LOGIN CUBIT] phone: $phoneNumber');
    if (!state.phoneInputValid ||
        phoneNumber.isEmpty ||
        !phoneNumber.startsWith('+')) {
      _emitFailure(
        const ApiException(
          message: 'Enter a valid phone number for the selected country.',
        ),
      );
      return;
    }

    final credentials = LoginCredentials(
      phoneNumber: phoneNumber,
      password: state.password,
    );

    final response = await _loginUseCase.login(credentials);
    if (isClosed) return;

    ApiException? failure;
    AuthUser? user;
    response.fold(
      (error) => failure = error,
      (result) => user = result,
    );

    if (failure != null) {
      debugPrint('[LOGIN CUBIT] failure: ${failure!.message}');
      _emitFailure(failure!);
      return;
    }

    try {
      debugPrint('[LOGIN CUBIT] login success, storing session...');
      debugPrint('[LOGIN TOKEN] accessToken: ${user!.accessToken}');
      // debugPrint('[LOGIN TOKEN] refreshToken: ${user.refreshToken}');
      await _storeAuthSession(user!);
      await AuthService.login();
      await FcmTokenService.refreshAndCacheToken(reason: 'login_success');
      if (isClosed) return;
      _safeEmit(
        state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
          feedbackMessage: null,
        ),
      );
      debugPrint('[LOGIN CUBIT] session stored successfully.');
      debugPrint('================ LOGIN FLOW SUCCESS ================');
    } catch (_) {
      _emitFailure(
        const ApiException(
          message: 'Failed to save session data. Please try again.',
        ),
      );
    }
  }

  void resetStatus() {
    _safeEmit(
      state.copyWith(
        status: LoginStatus.initial,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );
  }

  void togglePasswordVisibility() {
    _safeEmit(state.copyWith(obscurePassword: !state.obscurePassword));
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
      requiredMessage: ValidationMessages.passwordRequired,
      minLengthMessage: ValidationMessages.passwordTooShort,
      maxLengthMessage: ValidationMessages.passwordTooLong,
    )(value);
  }

  void _emitFailure(ApiException error) {
    debugPrint('================ LOGIN FLOW FAILURE ================');
    _safeEmit(
      state.copyWith(
        status: LoginStatus.failure,
        errorMessage: error.message,
      ),
    );
    _emitFeedback(message: error.message, isError: true);
  }

  void _emitFeedback({
    required String message,
    required bool isError,
  }) {
    _safeEmit(
      state.copyWith(
        feedbackMessage: message,
        feedbackIsError: isError,
        feedbackCounter: state.feedbackCounter + 1,
      ),
    );
  }

  Future<void> _resolveDefaultPhoneCountryFromLocation() async {
    try {
      final cachedIsoCode = await SharedPrefHelper.getNullableString(
        SharedPrefKeys.cachedDetectedPhoneIsoCode,
      );
      if (isClosed) return;
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
      if (isClosed) return;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (isClosed) return;
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
    if (isClosed) {
      return;
    }
    if (_userInteractedWithPhone || phoneController.text.trim().isNotEmpty) {
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
    _safeEmit(
      state.copyWith(
        initialPhoneNumber: detectedPhoneNumber,
        selectedPhoneNumber: detectedPhoneNumber,
        e164Number: '',
        phoneText: '',
        phoneInputValid: false,
        showValidationErrors: false,
      ),
    );
  }

  void _safeEmit(LoginCubitState nextState) {
    if (isClosed) {
      return;
    }
    emit(nextState);
  }

  Future<void> _storeAuthSession(AuthUser data) async {
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
    phoneController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
