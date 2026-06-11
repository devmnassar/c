typedef FieldValidator = String? Function(String? value);

enum PhoneRegion {
  auto,
  egypt,
  saudi,
  international,
}

class ValidationMessages {
  ValidationMessages._();

  static const String requiredField = 'This field is required';
  static const String nameRequired = 'Name is required';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email';
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid = 'Enter a valid phone number';
  static const String saudiPhoneInvalid = 'Enter a valid Saudi mobile number';
  static const String passwordRequired = 'Password is required';
  static const String confirmPasswordRequired = 'Confirm password is required';
  static const String passwordsMustMatch =
      'Password and confirm password must be the same';
}

class AppValidators {
  AppValidators._();

  static String? required(
    String? value, {
    String message = ValidationMessages.requiredField,
  }) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(
    String? value, {
    bool required = true,
    bool gmailOnly = false,
    String requiredMessage = ValidationMessages.emailRequired,
    String invalidMessage = ValidationMessages.emailInvalid,
  }) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) {
      return required ? requiredMessage : null;
    }

    final pattern = gmailOnly
        ? RegExp(r'^[^@\s]+@gmail\.com$')
        : RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!pattern.hasMatch(text)) {
      return invalidMessage;
    }

    return null;
  }

  /// Normalizes phone input to backend-friendly format per country rules.
  /// Keeps behavior unchanged for non-Egypt numbers.
  static String normalizePhoneForSubmission(
    String raw, {
    String? isoCode,
  }) {
    final trimmed = raw.trim();
    final countryCode = isoCode?.toUpperCase();

    if (countryCode == 'EG') {
      final digits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (RegExp(r'^1[0125]\d{8}$').hasMatch(digits)) {
        return '0$digits';
      }
      if (RegExp(r'^01[0125]\d{8}$').hasMatch(digits)) {
        return digits;
      }
    }

    return trimmed;
  }

  /// Password validator with flexible rules and customizable messages.
  static String? password(
    String? value, {
    bool required = true,
    int minLength = 6,
    int? maxLength,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecialChar = true,
    bool allowSpaces = false,
    String requiredMessage = 'Password is required',
    String minLengthMessage = 'Password is too short',
    String? maxLengthMessage,
    String uppercaseMessage = 'Password must contain an uppercase letter',
    String lowercaseMessage = 'Password must contain a lowercase letter',
    String digitMessage = 'Password must contain a number',
    String specialCharMessage = 'Password must contain a special character',
    String spacesMessage = 'Password must not contain spaces',
  }) {
    final text = value ?? '';

    if (text.trim().isEmpty) {
      return required ? requiredMessage : null;
    }

    if (text.length < minLength) return minLengthMessage;

    if (maxLength != null && text.length > maxLength) {
      return maxLengthMessage ??
          'Password must be at most $maxLength characters';
    }

    if (!allowSpaces && text.contains(RegExp(r'\s'))) {
      return spacesMessage;
    }

    if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(text)) {
      return uppercaseMessage;
    }

    if (requireLowercase && !RegExp(r'[a-z]').hasMatch(text)) {
      return lowercaseMessage;
    }

    if (requireDigit && !RegExp(r'\d').hasMatch(text)) {
      return digitMessage;
    }

    if (requireSpecialChar &&
        !RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]`~]').hasMatch(text)) {
      return specialCharMessage;
    }

    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String passwordValue,
    bool required = true,
    int minLength = 6,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecialChar = true,
    bool allowSpaces = false,
    String requiredMessage = ValidationMessages.confirmPasswordRequired,
    String minLengthMessage = 'Password is too short',
    String uppercaseMessage = 'Password must contain an uppercase letter',
    String lowercaseMessage = 'Password must contain a lowercase letter',
    String digitMessage = 'Password must contain a number',
    String specialCharMessage = 'Password must contain a special character',
    String spacesMessage = 'Password must not contain spaces',
    String mismatchMessage = ValidationMessages.passwordsMustMatch,
  }) {
    final validationMessage = password(
      value,
      required: required,
      minLength: minLength,
      requireUppercase: requireUppercase,
      requireLowercase: requireLowercase,
      requireDigit: requireDigit,
      requireSpecialChar: requireSpecialChar,
      allowSpaces: allowSpaces,
      requiredMessage: requiredMessage,
      minLengthMessage: minLengthMessage,
      uppercaseMessage: uppercaseMessage,
      lowercaseMessage: lowercaseMessage,
      digitMessage: digitMessage,
      specialCharMessage: specialCharMessage,
      spacesMessage: spacesMessage,
    );

    if (validationMessage != null) {
      return validationMessage;
    }

    if ((value ?? '') != passwordValue) {
      return mismatchMessage;
    }

    return null;
  }

  /// Phone validator for Egypt, Saudi, and international numbers.
  /// Supports Arabic digits and inputs with spaces/dashes/brackets.
  static String? phone(
    String? value, {
    String? isoCode,
    PhoneRegion region = PhoneRegion.auto,
    bool required = true,
    bool allowPlusPrefix = true,
    bool allowSaudiLeadingZero = true,
    bool allowSaudiCountryCode = true,
    int minInternationalDigits = 8,
    int maxInternationalDigits = 15,
    String requiredMessage = 'Phone number is required',
    String invalidMessage = 'Enter a valid phone number',
    String? saudiInvalidMessage,
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return required ? requiredMessage : null;
    final resolvedRegion = _resolvePhoneRegion(region, isoCode);

    final normalizedRaw = _normalizeArabicDigits(raw);
    final hasPlus = normalizedRaw.startsWith('+');
    final digits = normalizedRaw.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return invalidMessage;
    if (!allowPlusPrefix && hasPlus) return invalidMessage;

    switch (resolvedRegion) {
      case PhoneRegion.egypt:
        return _isEgyptPhoneValid(normalizedRaw, digits)
            ? null
            : invalidMessage;
      case PhoneRegion.saudi:
        return _isSaudiPhoneValid(
          normalizedRaw,
          digits,
          allowLeadingZero: allowSaudiLeadingZero,
          allowCountryCode: allowSaudiCountryCode,
        )
            ? null
            : (saudiInvalidMessage ?? ValidationMessages.saudiPhoneInvalid);
      case PhoneRegion.international:
        return _isInternationalPhoneValid(
          hasPlus,
          digits,
          minDigits: minInternationalDigits,
          maxDigits: maxInternationalDigits,
        )
            ? null
            : invalidMessage;
      case PhoneRegion.auto:
        if (_isEgyptPhoneValid(normalizedRaw, digits)) return null;
        if (_isSaudiPhoneValid(
          normalizedRaw,
          digits,
          allowLeadingZero: allowSaudiLeadingZero,
          allowCountryCode: allowSaudiCountryCode,
        )) {
          return null;
        }
        if (_isInternationalPhoneValid(
          hasPlus,
          digits,
          minDigits: minInternationalDigits,
          maxDigits: maxInternationalDigits,
        )) {
          return null;
        }
        return invalidMessage;
    }
  }

  static PhoneRegion _resolvePhoneRegion(PhoneRegion region, String? isoCode) {
    if (region != PhoneRegion.auto) return region;

    final code = isoCode?.toUpperCase();
    if (code == 'SA') return PhoneRegion.saudi;
    if (code == 'EG') return PhoneRegion.egypt;
    return PhoneRegion.international;
  }

  static bool _isEgyptPhoneValid(String raw, String digits) {
    // Local: 010/011/012/015 + 8 digits => 11 total
    final localWithLeadingZero = RegExp(r'^01[0125]\d{8}$');
    if (localWithLeadingZero.hasMatch(digits)) return true;

    // Local without leading 0 when +20 is selected in UI.
    // 10/11/12/15 + 8 digits => 10 total
    final localWithoutLeadingZero = RegExp(r'^1[0125]\d{8}$');
    if (localWithoutLeadingZero.hasMatch(digits)) return true;

    // International with +20 or 20
    // +2010XXXXXXXX / 2010XXXXXXXX
    final international = RegExp(r'^\+?20(10|11|12|15)\d{8}$');
    if (international.hasMatch(raw.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return true;
    }

    return false;
  }

  static bool _isSaudiPhoneValid(
    String raw,
    String digits, {
    required bool allowLeadingZero,
    required bool allowCountryCode,
  }) {
    // Local mobile: 5XXXXXXXX (9 digits)
    if (RegExp(r'^5\d{8}$').hasMatch(digits)) return true;

    // Local with leading 0: 05XXXXXXXX (10 digits)
    if (allowLeadingZero && RegExp(r'^05\d{8}$').hasMatch(digits)) return true;

    // International with +966 or 966
    // +9665XXXXXXXX / 9665XXXXXXXX
    if (allowCountryCode &&
        RegExp(r'^\+?9665\d{8}$')
            .hasMatch(raw.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return true;
    }

    return false;
  }

  static bool _isInternationalPhoneValid(
    bool hasPlus,
    String digits, {
    required int minDigits,
    required int maxDigits,
  }) {
    // E.164 allows up to 15 digits, practical min usually 8.
    if (digits.length < minDigits || digits.length > maxDigits) return false;

    // Keep it permissive for non-EG/KSA countries.
    // If plus is provided, it's definitely international format.
    if (hasPlus) return true;

    // Without plus: still allow for apps storing plain country-code numbers.
    return true;
  }

  static String _normalizeArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      switch (rune) {
        case 0x0660:
          buffer.write('0');
          break;
        case 0x0661:
          buffer.write('1');
          break;
        case 0x0662:
          buffer.write('2');
          break;
        case 0x0663:
          buffer.write('3');
          break;
        case 0x0664:
          buffer.write('4');
          break;
        case 0x0665:
          buffer.write('5');
          break;
        case 0x0666:
          buffer.write('6');
          break;
        case 0x0667:
          buffer.write('7');
          break;
        case 0x0668:
          buffer.write('8');
          break;
        case 0x0669:
          buffer.write('9');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString();
  }
}

/// Backward-friendly alias in case some files already call `Validators`.
class Validators extends AppValidators {
  Validators._() : super._();
}
