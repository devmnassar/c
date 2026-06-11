import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/widgets/custom_otp_verification_page.dart';

class SignUpOtpVerificationPage extends StatelessWidget {
  static const String id = '/signup/otp';

  const SignUpOtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.nextRoute,
  });

  final String phoneNumber;
  final String nextRoute;

  @override
  Widget build(BuildContext context) {
    return CustomOtpVerificationPage(
      phoneNumber: phoneNumber,
      nextRoute: nextRoute,
      title: 'Verify Phone',
      currentStep: 2,
      totalSteps: 4,
      nextLabel: 'Verify',
    );
  }
}

class ForgetPasswordOtpVerificationPage extends StatelessWidget {
  static const String id = '/forget-password/otp';

  const ForgetPasswordOtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.nextRoute,
  });

  final String phoneNumber;
  final String nextRoute;

  @override
  Widget build(BuildContext context) {
    return CustomOtpVerificationPage(
      phoneNumber: phoneNumber,
      nextRoute: nextRoute,
      title: 'Verify Your Phone',
      currentStep: 2,
      totalSteps: 2,
      nextLabel: 'Verify',
    );
  }
}
