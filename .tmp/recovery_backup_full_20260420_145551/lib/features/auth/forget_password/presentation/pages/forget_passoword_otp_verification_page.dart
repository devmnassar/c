import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/widgets/custom_otp_verification_page.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_cubit.dart';
import 'package:go_router/go_router.dart';

class ForgetPasswordOtpVerificationPage extends StatelessWidget {
  static const String id = '/forget-password/otp';

  const ForgetPasswordOtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.nextRoute,
  });

  final String phoneNumber;
  final String nextRoute;

  void _handleStateChanges(
    BuildContext context,
    ForgetPasswordCubit cubit,
    ForgetPasswordState state,
  ) {
    if (cubit.shouldNavigateAfterOtp(state)) {
      context.go(nextRoute, extra: phoneNumber);
      cubit.consumeOtpStateMessages(state);
      return;
    }

    final feedbackMessage = cubit.feedbackOtpMessage(state);
    if (feedbackMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(feedbackMessage)));
      cubit.consumeOtpStateMessages(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgetPasswordCubit()..initializeOtpAutoFill(),
      child: BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
        listenWhen: (previous, current) =>
            previous.otpStatus != current.otpStatus ||
            previous.otpErrorMessage != current.otpErrorMessage ||
            previous.otpInfoMessage != current.otpInfoMessage,
        listener: (context, state) => _handleStateChanges(
          context,
          context.read<ForgetPasswordCubit>(),
          state,
        ),
        builder: (context, state) {
          final cubit = context.read<ForgetPasswordCubit>();
          return CustomOtpVerificationPage(
            phoneNumber: phoneNumber,
            title: 'Verify Your Phone',
            currentStep: 2,
            totalSteps: 2,
            nextLabel: 'Verify',
            loading: state.isOtpLoading,
            controllers: cubit.otpControllers,
            focusNodes: cubit.otpFocusNodes,
            onCodeChanged: cubit.onOtpCodeChanged,
            onVerify: cubit.verifyCurrentOtpCode,
            onResendTap: cubit.resendOtpCode,
          );
        },
      ),
    );
  }
}