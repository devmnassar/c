import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
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
      create: (_) => getIt<LoginCubit>(),
      child: BlocConsumer<LoginCubit, LoginCubitState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.feedbackCounter != current.feedbackCounter,
        listener: (context, state) {
          final cubit = context.read<LoginCubit>();
          if (state.status == LoginStatus.success) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.go('/permissions');
            return;
          }

          if ((state.feedbackMessage?.isNotEmpty ?? false) &&
              state.feedbackIsError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _showErrorSnackBar(context, state.feedbackMessage!);
          }

          if (state.status == LoginStatus.failure) {
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<LoginCubit>();
          final primaryColor = Theme.of(context).colorScheme.primary;
          final isLoginEnabled = state.hasAnyInput && !state.isLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Stack(
                children: [
                  LoginBackground(),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 420.w),
                          child: Form(
                            key: cubit.formKey,
                            autovalidateMode: state.showValidationErrors
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LoginHeader(
                                  companyName:
                                      l10n?.companyName ?? 'Gaseel Express',
                                  subtitle: 'Driver Portal',
                                ),
                                SizedBox(height: 40.h),
                                PhoneNumberField(
                                  initialPhoneNumber: state.initialPhoneNumber,
                                  selectedPhoneNumber:
                                      state.selectedPhoneNumber,
                                  controller: cubit.phoneController,
                                  enabled: !state.isLoading,
                                  onChanged: cubit.onPhoneChanged,
                                  onValidated: cubit.onPhoneValidated,
                                  validator: cubit.phoneValidator,
                                ),
                                SizedBox(height: 20.h),
                                CustomTextField(
                                  label: 'Password',
                                  hintText: 'Enter your password',
                                  controller: cubit.passwordController,
                                  maxLength: 30,
                                  isSensitive: true,
                                  prefixIcon: Icons.lock_outline,
                                  textInputAction: TextInputAction.done,
                                  obscureText: state.obscurePassword,
                                  enabled: !state.isLoading,
                                  validator: cubit.passwordValidator,
                                  onChanged: cubit.onPasswordChanged,
                                  onSubmitted: (_) {
                                    if (isLoginEnabled) {
                                      cubit.login();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: primaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: state.isLoading
                                          ? null
                                          : cubit.togglePasswordVisibility,
                                      icon: Icon(
                                        state.obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20.r,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 1.2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF4C7CC),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF4C7CC),
                                        width: 1.2,
                                      ),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Color(0xFFF4A3AD),
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    contentPadding: EdgeInsets.all(20.r),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: state.isLoading
                                        ? null
                                        : () {
                                            context.push(ForgetPasswordPage.id);
                                          },
                                    child: Text(
                                      'Forget Password?',
                                      style: TextStyle(
                                        color: const Color(0xFF7BD4CB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                CustomButton(
                                  text: 'Login',
                                  isLoading: state.isLoading,
                                  fullWidth: true,
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  borderRadius: 18,
                                  elevation: 8,
                                  shadowColor:
                                      primaryColor.withValues(alpha: 0.4),
                                  onPressed: isLoginEnabled
                                      ? () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          cubit.login();
                                        }
                                      : null,
                                ),
                                SizedBox(height: 28.h),
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
            ),
          );
        },
      ),
    );
  }
}
