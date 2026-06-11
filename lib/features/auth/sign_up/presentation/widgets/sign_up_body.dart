import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/core/widgets/custom_text_form_field.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/phone_number_field.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/profile_photo_picker.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_section_title.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class SignUpBody extends StatelessWidget {
  const SignUpBody({
    super.key,
    required this.profilePhoto,
    required this.initialPhoneNumber,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    // required this.nationalIdController,
    required this.loading,
    required this.onPickPhotoTap,
    required this.onPhoneChanged,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onContinue,
    required this.nameValidator,
    required this.emailValidator,
    required this.passwordValidator,
    required this.phoneValidator,
  });

  final File? profilePhoto;
  final PhoneNumber? initialPhoneNumber;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
//  final TextEditingController nationalIdController;
  final bool loading;
  final VoidCallback onPickPhotoTap;
  final ValueChanged<PhoneNumber> onPhoneChanged;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onContinue;
  final String? Function(String?) nameValidator;
  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;
  final String? Function(String?) phoneValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePhotoPicker(
          imageFile: profilePhoto,
          onTap: onPickPhotoTap,
        ),
        SizedBox(height: 40.h),
        const SignUpSectionTitle(title: 'Personal Information'),
        SizedBox(height: 24.h),
        CustomTextField(
          label: 'Full Name',
          hintText: 'Enter your name',
          controller: nameController,
          prefixIcon: Icons.person_outline_rounded,
          enabled: !loading,
          textInputAction: TextInputAction.next,
          validator: nameValidator,
        ),
        SizedBox(height: 24.h),
        CustomTextField(
          label: 'Email',
          hintText: 'Enter your email',
          controller: emailController,
          prefixIcon: Icons.email_outlined,
          enabled: !loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: emailValidator,
        ),
        SizedBox(height: 24.h),
        CustomTextField(
          label: 'Password',
          hintText: 'Enter your password',
          controller: passwordController,
          maxLength: 30,
          isSensitive: true,
          prefixIcon: Icons.lock_outline,
          enabled: !loading,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onContinue(),
          validator: passwordValidator,
          suffixIcon: IconButton(
            onPressed: loading ? null : onTogglePasswordVisibility,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20.r,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        PhoneNumberField(
          initialPhoneNumber: initialPhoneNumber,
          controller: phoneController,
          enabled: !loading,
          onChanged: onPhoneChanged,
          validator: phoneValidator,
        ),
        SizedBox(height: 24.h),
        // CustomTextField(
        //   label: 'National ID (Optional)',
        //   hintText: 'Enter your ID',
        //   controller: nationalIdController,
        //   prefixIcon: Icons.badge_outlined,
        //   enabled: !loading,
        //   keyboardType: TextInputType.number,
        //   textInputAction: TextInputAction.done,
        // ),
        SizedBox(height: 32.h),
      ],
    );
  }
}
