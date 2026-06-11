import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:gaseel_courier/features/auth/forget_password/domain/usecases/send_reset_otp_use_case.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  static const _defaultIsoCode = 'SA';
  static final _whitespaceRegex = RegExp(r'\s+');

  ForgetPasswordCubit({
    required SendResetOtpUseCase sendResetOtpUseCase,
  })  : _sendResetOtpUseCase = sendResetOtpUseCase,
        super(
          ForgetPasswordState(
            initialPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode),
            selectedPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode),
          ),
        ) {
    unawaited(_resolveDefaultPhoneCountryFromLocation());
  }

  final SendResetOtpUseCase _sendResetOtpUseCase;
  bool _userInteractedWithPhone = false;

  final formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  void onPhoneChanged(PhoneNumber number) {
    _userInteractedWithPhone = true;
    final sanitizedPhoneText = _normalizePhoneText(phoneController.text);
    if (sanitizedPhoneText != phoneController.text) {
      phoneController.value = TextEditingValue(
        text: sanitizedPhoneText,
        selection: TextSelection.collapsed(offset: sanitizedPhoneText.length),
      );
    }

    emit(
      state.copyWith(
        selectedPhoneNumber: number,
        e164Number: _normalizePhoneText(number.phoneNumber ?? ''),
        phoneInputValid: false,
        errorMessage: null,
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

  Future<void> onNext() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    emit(
      state.copyWith(
        status: ForgetPasswordStatus.loading,
        errorMessage: null,
        feedbackMessage: null,
      ),
    );

    final phoneNumber = _normalizePhoneText(state.e164Number);
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

    final response = await _sendResetOtpUseCase(phoneNumber: phoneNumber);

    response.fold(
      _emitFailure,
      (result) {
        emit(
          state.copyWith(
            status: ForgetPasswordStatus.success,
            e164Number: phoneNumber,
            otpExpiresInSeconds: result.expiresInSeconds,
            debugOtpCode: result.otpCode,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void resetStatus() {
    emit(
      state.copyWith(
        status: ForgetPasswordStatus.initial,
        errorMessage: null,
        feedbackMessage: null,
        debugOtpCode: null,
      ),
    );
  }

  void _emitFailure(ApiException error) {
    emit(
      state.copyWith(
        status: ForgetPasswordStatus.failure,
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
    emit(
      state.copyWith(
        initialPhoneNumber: detectedPhoneNumber,
        selectedPhoneNumber: detectedPhoneNumber,
        e164Number: '',
        phoneInputValid: false,
      ),
    );
  }

  @override
  Future<void> close() {
    phoneController.dispose();
    return super.close();
  }
}
