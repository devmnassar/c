import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/profile/profile_service.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/image_source_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({String? initialPhoneNumber}) : super(const SignUpState()) {
    _setDefaultPhoneNumber(initialPhoneNumber);
  }

  static const _defaultIsoCode = 'SA';

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  //final nationalIdController = TextEditingController();

  void _setDefaultPhoneNumber(String? initialPhoneNumber) {
    if (initialPhoneNumber != null && initialPhoneNumber.isNotEmpty) {
      phoneController.text = _extractNationalNumber(initialPhoneNumber);
      emit(
        state.copyWith(
          initialPhoneNumber: PhoneNumber(
            phoneNumber: initialPhoneNumber,
            isoCode: _defaultIsoCode,
            dialCode: '+966',
          ),
          e164Number: initialPhoneNumber,
          nationalNumber: phoneController.text,
        ),
      );
      return;
    }

    emit(
      state.copyWith(initialPhoneNumber: PhoneNumber(isoCode: _defaultIsoCode)),
    );
  }

  String _extractNationalNumber(String e164Number) {
    const defaultDialCode = '+966';
    if (e164Number.startsWith(defaultDialCode)) {
      return e164Number.substring(defaultDialCode.length);
    }
    return e164Number.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );

    if (pickedFile == null) {
      return;
    }

    final photoFile = File(pickedFile.path);
    if (!await photoFile.exists()) {
      return;
    }

    emit(state.copyWith(profilePhoto: photoFile));
  }

  Future<void> showImageSourceDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ImageSourceSheet(
          onCameraTap: () {
            Navigator.pop(context);
            pickImage(ImageSource.camera);
          },
          onGalleryTap: () {
            Navigator.pop(context);
            pickImage(ImageSource.gallery);
          },
        );
      },
    );
  }

  void onPhoneChanged(PhoneNumber number) {
    emit(
      state.copyWith(
        e164Number: number.phoneNumber ?? '',
        nationalNumber: phoneController.text,
      ),
    );
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> onNext() async {
    if (!_validateForm()) {
      return;
    }

    final validationMessage = _validateBusinessRules();
    if (validationMessage != null) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: validationMessage,
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignUpStatus.loading, errorMessage: null));

    try {
      final submissionData = _buildSubmissionData();
      await ProfileService.saveProfile(
        fullName: submissionData.fullName,
        e164Number: submissionData.e164Number,
        nationalNumber: submissionData.nationalNumber,
        photoPath: submissionData.photoPath,
     //   nationalId: submissionData.nationalId,
        phoneVerified: submissionData.phoneVerified,
      );

      emit(state.copyWith(status: SignUpStatus.success, errorMessage: null));
    } catch (_) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: 'Something went wrong, please try again.',
        ),
      );
    }
  }

  void resetStatus() {
    emit(state.copyWith(status: SignUpStatus.initial, errorMessage: null));
  }

  bool _validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  String? _validateBusinessRules() {
    if (state.profilePhoto == null) {
      return 'Profile photo is required';
    }
    return null;
  }

  SignUpSubmissionData _buildSubmissionData() {
    return SignUpSubmissionData(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      e164Number: state.e164Number,
      nationalNumber: state.nationalNumber,
      photoPath: state.profilePhoto!.path,
      //nationalId: nationalIdController.text.trim(),
      phoneVerified: state.phoneVerified,
    );
  }

  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
   // nationalIdController.dispose();
    return super.close();
  }
}

class SignUpSubmissionData {
  const SignUpSubmissionData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.e164Number,
    required this.nationalNumber,
    required this.photoPath,
   // required this.nationalId,
    required this.phoneVerified,
  });

  final String fullName;
  final String email;
  final String password;
  final String e164Number;
  final String nationalNumber;
  final String photoPath;
 // final String nationalId;
  final bool phoneVerified;

  Map<String, dynamic> toApiPayload() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'e164Number': e164Number,
      'nationalNumber': nationalNumber,
      'photoPath': photoPath,
     // 'nationalId': nationalId,
      'phoneVerified': phoneVerified,
    };
  }
}
