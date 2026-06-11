import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_passoword_otp_verification_page.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/widgets/scaffold_auth.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_cubit.dart';
import 'package:gaseel_courier/features/auth/login/presentation/pages/login_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_phone_body.dart';

class ForgetPasswordPage extends StatelessWidget {
  static const String id = '/forget-password';

  const ForgetPasswordPage({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgetPasswordCubit(),
      child: BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<ForgetPasswordCubit>();

          if (state.status == ForgetPasswordStatus.failure &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            _showSnackBar(context, state.errorMessage!);
            cubit.resetStatus();
            return;
          }

          if (state.status == ForgetPasswordStatus.success) {
            context.push(
              ForgetPasswordOtpVerificationPage.id,
              extra: {
                'phoneNumber': state.e164Number,
                'nextRoute': LoginPage.id,
              },
            );
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<ForgetPasswordCubit>();

          return ScaffoldItem(
            title: 'Forget Password Account',
            currentStep: 1,
            totalSteps: 4,
            onNext: cubit.onNext,
            loading: state.loading,
            nextLabel: 'Continue',
            body: SignUpPhoneBody(
              initialPhoneNumber: state.initialPhoneNumber,
              selectedPhoneNumber: state.selectedPhoneNumber,
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
