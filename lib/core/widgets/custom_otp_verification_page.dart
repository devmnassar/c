import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/scaffold_auth.dart';
import 'package:gaseel_courier/features/auth/otp/presentation/cubit/otp_cubit.dart';
import 'package:gaseel_courier/features/auth/otp/presentation/widgets/otp_code_input_row.dart';
import 'package:gaseel_courier/features/auth/otp/presentation/widgets/otp_phone_hint_card.dart';
import 'package:gaseel_courier/features/auth/otp/presentation/widgets/otp_resend_section.dart';

typedef OtpSuccessCallback = void Function(BuildContext context, String phone);

class CustomOtpVerificationPage extends StatelessWidget {
  final String phoneNumber;
  final String title;
  final int currentStep;
  final int totalSteps;
  final String nextLabel;
  final String? nextRoute;
  final OtpSuccessCallback? onSuccess;

  const CustomOtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.title = 'Verify Phone',
    this.currentStep = 2,
    this.totalSteps = 4,
    this.nextLabel = 'Verify',
    this.nextRoute,
    this.onSuccess,
  });

  void _handleStateChanges(
    BuildContext context,
    OtpCubit cubit,
    OtpState state,
  ) {
    if (cubit.shouldNavigateToDocuments(state)) {
      if (onSuccess != null) {
        onSuccess!(context, phoneNumber);
      } else if (nextRoute != null && nextRoute!.isNotEmpty) {
        context.go(nextRoute!, extra: phoneNumber);
      }
      cubit.consumeStateMessages(state);
      return;
    }

    final feedbackMessage = cubit.feedbackMessage(state);
    if (feedbackMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(feedbackMessage)));
      cubit.consumeStateMessages(state);
    }
  }

  Widget _buildScreenBody(OtpCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We have sent a verification code to your phone number.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 12),
        OtpPhoneHintCard(phoneNumber: phoneNumber),
        const SizedBox(height: 48),
        OtpCodeInputRow(
          controllers: cubit.otpControllers,
          focusNodes: cubit.otpFocusNodes,
          onChanged: cubit.onCodeChanged,
        ),
        const SizedBox(height: 48),
        OtpResendSection(onResendTap: cubit.resendCode),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpCubit()..initializeAutoFill(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<OtpCubit>();

          return BlocConsumer<OtpCubit, OtpState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.errorMessage != current.errorMessage ||
                previous.infoMessage != current.infoMessage,
            listener: (context, state) =>
                _handleStateChanges(context, cubit, state),
            builder: (context, state) {
              return ScaffoldItem(
                title: title,
                currentStep: currentStep,
                totalSteps: totalSteps,
                onNext: cubit.verifyCurrentCode,
                nextLabel: nextLabel,
                loading: state.isLoading,
                body: _buildScreenBody(cubit),
              );
            },
          );
        },
      ),
    );
  }
}
