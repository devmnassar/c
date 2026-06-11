import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.labelStyle,
    this.decoration,
    this.fieldSpacing = 10,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextStyle? labelStyle;
  final InputDecoration? decoration;
  final double fieldSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;
    const fieldTextColor = Color(0xFF111827);
    const fieldHintColor = Color(0xFF9CA3AF);
    const fieldLabelColor = Color(0xFF374151);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: (theme.textTheme.titleSmall ?? const TextStyle())
              .merge(labelStyle)
              .copyWith(
                fontSize: labelStyle?.fontSize ?? 14.sp,
                fontWeight: labelStyle?.fontWeight ?? FontWeight.bold,
                color: labelStyle?.color ?? fieldLabelColor,
              ),
        ),
        SizedBox(height: fieldSpacing.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: fieldTextColor,
          ),
          cursorColor: primaryColor,
          decoration: decoration ??
              InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: fieldHintColor,
                ),
                prefixIcon: prefixIcon == null
                    ? null
                    : Icon(prefixIcon, color: primaryColor),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                errorStyle: theme.textTheme.bodySmall?.copyWith(
                  color: errorColor,
                ),
                contentPadding: EdgeInsets.all(20.r),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: primaryColor, width: 1.2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: errorColor),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: errorColor,
                    width: 1.2,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
