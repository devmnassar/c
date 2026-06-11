import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/scaffold_auth.dart';
import 'package:gaseel_courier/features/auth/otp/presentation/page/otp_verification_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/cubit/sign_up_phone_number_cubit.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/pages/sign_up_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_phone_body.dart';

class SignUpPhonePage extends StatelessWidget {
  static const String id = '/signup';

  const SignUpPhonePage({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpStartCubit(),
      child: BlocConsumer<SignUpStartCubit, SignUpStartState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<SignUpStartCubit>();

          if (state.status == SignUpStartStatus.failure &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            _showSnackBar(context, state.errorMessage!);
            cubit.resetStatus();
            return;
          }

          if (state.status == SignUpStartStatus.success) {
            context.push(
              OtpVerificationPage.id,
              extra: {
                'phoneNumber': state.e164Number,
                'nextRoute': SignUpPage.id,
              },
            );
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<SignUpStartCubit>();

          return ScaffoldItem(
            title: 'Create Account',
            currentStep: 1,
            totalSteps: 4,
            onNext: cubit.onNext,
            loading: state.loading,
            nextLabel: 'Continue',
            body: SignUpPhoneBody(
              initialPhoneNumber: state.initialPhoneNumber,
              phoneController: cubit.phoneController,
              loading: state.loading,
              onPhoneChanged: cubit.onPhoneChanged,
            ),
          );
        },
      ),
    );
  }
}
