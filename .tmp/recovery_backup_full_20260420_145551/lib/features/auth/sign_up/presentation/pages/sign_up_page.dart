import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/cubit/sign_up_cubit.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_body.dart';
import 'package:gaseel_courier/core/widgets/scaffold_auth.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  static const String id = '/signup/details';

  const SignUpPage({
    super.key,
    this.phoneNumber,
  });

  final String? phoneNumber;

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpCubit(initialPhoneNumber: phoneNumber),
      child: BlocConsumer<SignUpCubit, SignUpState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<SignUpCubit>();

          if (state.status == SignUpStatus.failure &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            _showSnackBar(context, state.errorMessage!);
            cubit.resetStatus();
            return;
          }

          if (state.status == SignUpStatus.success) {
            context.push('/signup/otp', extra: state.e164Number);
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<SignUpCubit>();

          return ScaffoldItem(
            title: 'Create Account',
            currentStep: 1,
            totalSteps: 4,
            onNext: cubit.onNext,
            loading: state.loading,
            body: Form(
              key: cubit.formKey,
              child: SignUpBody(
                profilePhoto: state.profilePhoto,
                initialPhoneNumber: state.initialPhoneNumber,
                nameController: cubit.nameController,
                emailController: cubit.emailController,
                passwordController: cubit.passwordController,
                phoneController: cubit.phoneController,
              //  nationalIdController: cubit.nationalIdController,
                loading: state.loading,
                onPickPhotoTap: () => cubit.showImageSourceDialog(context),
                onPhoneChanged: cubit.onPhoneChanged,
                obscurePassword: state.obscurePassword,
                onTogglePasswordVisibility: cubit.togglePasswordVisibility,
                onContinue: cubit.onNext,
              ),
            ),
          );
        },
      ),
    );
  }
}
