import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.initialPhoneNumber,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final PhoneNumber? initialPhoneNumber;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<PhoneNumber> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: InternationalPhoneNumberInput(
            onInputChanged: onChanged,
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.DROPDOWN,
              showFlags: true,
              setSelectorButtonAsPrefixIcon: true,
              leadingPadding: 16,
            ),
            initialValue: initialPhoneNumber,
            textFieldController: controller,
            isEnabled: enabled,
            inputDecoration: InputDecoration(
              hintText: '5xxxxxxxx',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            formatInput: true,
          ),
        ),
      ],
    );
  }
}