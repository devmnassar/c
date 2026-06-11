import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/core/widgets/custom_text_form_field.dart';
import 'package:gaseel_courier/core/utils/validator_utils.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/phone_number_field.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class SignUpPhoneBody extends StatelessWidget {
  const SignUpPhoneBody({
    super.key,
    required this.initialPhoneNumber,
    this.selectedPhoneNumber,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.loading,
    required this.phoneVerified,
    required this.onPhoneChanged,
    required this.onPhoneValidated,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    this.phoneValidator,
    this.passwordValidator,
    this.confirmPasswordValidator,
  });

  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final bool phoneVerified;
  final ValueChanged<PhoneNumber> onPhoneChanged;
  final ValueChanged<bool> onPhoneValidated;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final String? Function(String?)? phoneValidator;
  final String? Function(String?)? passwordValidator;
  final String? Function(String?)? confirmPasswordValidator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          phoneVerified
              ? 'Phone number verified successfully. Set your password to continue.'
              : 'Enter your phone number to verify your account.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        SizedBox(height: 20.h),
        PhoneNumberField(
          initialPhoneNumber: selectedPhoneNumber ?? initialPhoneNumber,
          controller: phoneController,
          enabled: !loading && !phoneVerified,
          onChanged: onPhoneChanged,
          onValidated: onPhoneValidated,
          validator: phoneValidator,
        ),
        if (phoneVerified) ...[
          SizedBox(height: 24.h),
          CustomTextField(
            label: 'Password',
            hintText: 'Enter your password',
            controller: passwordController,
            maxLength: 30,
            isSensitive: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            obscureText: obscurePassword,
            enabled: !loading,
            validator: passwordValidator ?? Validators.passwordValidator,
            suffixIcon: IconButton(
              onPressed: loading ? null : onTogglePasswordVisibility,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20.r,
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Confirm Password',
            hintText: 'Confirm your password',
            controller: confirmPasswordController,
            maxLength: 30,
            isSensitive: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            obscureText: obscureConfirmPassword,
            enabled: !loading,
            validator: confirmPasswordValidator,
            suffixIcon: IconButton(
              onPressed: loading ? null : onToggleConfirmPasswordVisibility,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20.r,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
