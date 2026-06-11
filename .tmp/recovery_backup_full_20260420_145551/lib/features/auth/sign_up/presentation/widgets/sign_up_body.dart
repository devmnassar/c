import 'dart:io';

import 'package:flutter/material.dart';
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
    required this.selectedPhoneNumber,
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
  });

  final File? profilePhoto;
  final PhoneNumber? initialPhoneNumber;
  final PhoneNumber? selectedPhoneNumber;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePhotoPicker(
          imageFile: profilePhoto,
          onTap: onPickPhotoTap,
        ),
        const SizedBox(height: 40),
        const SignUpSectionTitle(title: 'Personal Information'),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Full Name',
          hintText: 'Enter your name',
          controller: nameController,
          prefixIcon: Icons.person_outline_rounded,
          enabled: !loading,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Email',
          hintText: 'Enter your email',
          controller: emailController,
          prefixIcon: Icons.email_outlined,
          enabled: !loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return 'Email is required';
            }
            if (!email.contains('@') || !email.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Password',
          hintText: 'Enter your password',
          controller: passwordController,
          prefixIcon: Icons.lock_outline,
          enabled: !loading,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onContinue(),
          validator: (value) {
            final password = value?.trim() ?? '';
            if (password.isEmpty) {
              return 'Password is required';
            }
            if (password.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          suffixIcon: IconButton(
            onPressed: loading ? null : onTogglePasswordVisibility,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
          ),
        ),
        // const SizedBox(height: 24),
        // PhoneNumberField(
        //   initialPhoneNumber: initialPhoneNumber,
        //   selectedPhoneNumber: selectedPhoneNumber,
        //   controller: phoneController,
        //   enabled: !loading,
        //   onChanged: onPhoneChanged,
        // ),
        // const SizedBox(height: 24),
        // CustomTextField(
        //   label: 'National ID (Optional)',
        //   hintText: 'Enter your ID',
        //   controller: nationalIdController,
        //   prefixIcon: Icons.badge_outlined,
        //   enabled: !loading,
        //   keyboardType: TextInputType.number,
        //   textInputAction: TextInputAction.done,
        // ),
        // const SizedBox(height: 32),
      ],
    );
  }
}
