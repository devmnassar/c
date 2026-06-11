import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    required this.initialPhoneNumber,
    this.selectedPhoneNumber,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.onValidated,
    this.validator,
  });

  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<PhoneNumber> onChanged;
  final ValueChanged<bool>? onValidated;
  final String? Function(String?)? validator;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late String _currentIsoCode;

  @override
  void initState() {
    super.initState();
    _currentIsoCode = _resolveIsoCode();
  }

  @override
  void didUpdateWidget(covariant PhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIsoCode = _resolveIsoCode();
    final initialIsoChanged = oldWidget.initialPhoneNumber?.isoCode !=
        widget.initialPhoneNumber?.isoCode;
    final selectedIsoChanged = oldWidget.selectedPhoneNumber?.isoCode !=
        widget.selectedPhoneNumber?.isoCode;

    if ((initialIsoChanged || selectedIsoChanged) &&
        nextIsoCode != _currentIsoCode) {
      setState(() {
        _currentIsoCode = nextIsoCode;
      });
    }
  }

  String _resolveIsoCode() {
    return (widget.selectedPhoneNumber?.isoCode ??
            widget.initialPhoneNumber?.isoCode ??
            '')
        .toUpperCase();
  }

  String _hintText() {
    return _currentIsoCode == 'SA' ? '5xxxxxxxx' : 'Phone number';
  }

  PhoneNumber? _safeInitialValue() {
    final candidate = widget.selectedPhoneNumber ??
        widget.initialPhoneNumber ??
        PhoneNumber(isoCode: 'SA');
    final fallbackIso = _currentIsoCode.isNotEmpty ? _currentIsoCode : 'SA';

    // Keep initial value country-only. Some package transitions produce
    // short values like "+20" which crash during parse/validation.
    return PhoneNumber(
      isoCode: (candidate.isoCode?.isNotEmpty ?? false)
          ? candidate.isoCode
          : fallbackIso,
      dialCode: candidate.dialCode,
    );
  }

  void _handleInputChanged(PhoneNumber number) {
    final nextIsoCode = (number.isoCode ?? '').toUpperCase();
    if (nextIsoCode.isNotEmpty && nextIsoCode != _currentIsoCode) {
      // Defer so intl_phone_number_input can finish closing the country sheet
      // before we rebuild; avoids Directionality.of on a defunct Element.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (nextIsoCode != _currentIsoCode) {
          setState(() => _currentIsoCode = nextIsoCode);
        }
      });
    }
    widget.onChanged(number);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const fieldFillColor = Color(0xFFF3F4F6);
    const fieldLabelColor = Color(0xFF374151);
    const fieldHintColor = Color(0xFF9CA3AF);
    const fieldTextColor = Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: fieldLabelColor,
          ),
        ),
        SizedBox(height: 10.h),
        InternationalPhoneNumberInput(
          onInputChanged: _handleInputChanged,
          onInputValidated: widget.onValidated,
          selectorConfig: SelectorConfig(
            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
            showFlags: true,
            setSelectorButtonAsPrefixIcon: true,
            leadingPadding: 16.w,
          ),
          initialValue: _safeInitialValue(),
          textFieldController: widget.controller,
          isEnabled: widget.enabled,
          validator: widget.validator,
          ignoreBlank: true,
          textStyle: TextStyle(
            color: fieldTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          selectorTextStyle: TextStyle(
            color: fieldTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          inputDecoration: InputDecoration(
            hintText: _hintText(),
            hintStyle: TextStyle(
              color: fieldHintColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: primaryColor,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: Color(0xFFF4C7CC),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: Color(0xFFF4C7CC),
                width: 1.2,
              ),
            ),
            errorStyle: TextStyle(
              color: Color(0xFFF4A3AD),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18.w,
              vertical: 18.h,
            ),
          ),
          cursorColor: primaryColor,
          formatInput: true,
        ),
      ],
    );
  }
}
