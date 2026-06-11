import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaseel_courier/core/profile/profile_service.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/core/widgets/custom_text_form_field.dart';
import 'package:gaseel_courier/features/auth/login/presentation/cubit/login_cubit.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_password_page.dart';
import 'package:gaseel_courier/features/auth/login/presentation/widgets/login_background.dart';
import 'package:gaseel_courier/features/auth/login/presentation/widgets/login_footer.dart';
import 'package:gaseel_courier/features/auth/login/presentation/widgets/login_header.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/phone_number_field.dart';
import 'package:gaseel_courier/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  static const String id = '/login';
  const LoginPage({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginCubitState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<LoginCubit>();
          if (state.status == LoginStatus.success) {
            context.go('/permissions');
          } else if (state.status == LoginStatus.failure) {
            _showErrorSnackBar(
              context,
              'Login failed, please try again.',
            );
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<LoginCubit>();
          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                LoginBackground(),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: cubit.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LoginHeader(
                                companyName:
                                    l10n?.companyName ?? 'Gaseel Express',
                                subtitle: 'Driver Portal',
                              ),
                              const SizedBox(height: 40),
                              PhoneNumberField(
                                initialPhoneNumber: state.initialPhoneNumber,
                                selectedPhoneNumber: state.selectedPhoneNumber,
                                controller: cubit.phoneController,
                                enabled: !state.isLoading,
                                onChanged: cubit.onPhoneChanged,
                                validator: cubit.phoneValidator,
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                label: 'Password',
                                hintText: 'Enter your password',
                                controller: cubit.passwordController,
                                prefixIcon: Icons.lock_outline,
                                textInputAction: TextInputAction.done,
                                obscureText: state.obscurePassword,
                                enabled: !state.isLoading,
                                validator: cubit.passwordValidator,
                                onSubmitted: (_) => cubit.login(),
                                suffixIcon: IconButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : cubit.togglePasswordVisibility,
                                  icon: Icon(
                                    state.obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : () {
                                          context.push(ForgetPasswordPage.id);
                                        },
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                text: 'Login',
                                isLoading: state.isLoading,
                                onPressed: cubit.login,
                              ),
                              const SizedBox(height: 28),
                              LoginBottom(
                                onCreateAccountTap: () async {
                                  await ProfileService.clearProfile();
                                  if (context.mounted) {
                                    context.push('/signup');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
