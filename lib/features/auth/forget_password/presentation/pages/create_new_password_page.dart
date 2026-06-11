import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/core/widgets/custom_text_form_field.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/reset_password_cubit.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_password_page.dart';
import 'package:gaseel_courier/features/auth/login/presentation/pages/login_page.dart';

class CreateNewPasswordPage extends StatelessWidget {
  static const String id = '/forget-password/create-password';

  const CreateNewPasswordPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return BlocProvider(
      create: (_) => getIt<ResetPasswordCubit>()..setPhoneNumber(phoneNumber),
      child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            (previous.feedbackCounter != current.feedbackCounter &&
                current.feedbackIsError),
        listener: (context, state) {
          final cubit = context.read<ResetPasswordCubit>();

          if ((state.feedbackMessage?.isNotEmpty ?? false) &&
              state.feedbackIsError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }

          if (state.status == ResetPasswordStatus.success) {
            context.go(LoginPage.id);
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<ResetPasswordCubit>();

          return Scaffold(
            backgroundColor: primaryColor,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20.r,
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              context.pop();
                              return;
                            }
                            context.go(ForgetPasswordPage.id);
                          },
                        ),
                        const Spacer(),
                        Text(
                          'Gaseel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 40.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _buildStepIndicator(currentStep: 3),
                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create New Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                20.w,
                                20.h,
                                20.w,
                                24.h,
                              ),
                              child: Form(
                                key: cubit.formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Information',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    SizedBox(height: 22.h),
                                    Text(
                                      'Create a new password and confirm it to continue.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: 18.h),
                                    CustomTextField(
                                      label: 'Password',
                                      hintText: 'Enter your password',
                                      controller: cubit.passwordController,
                                      maxLength: 30,
                                      isSensitive: true,
                                      obscureText: state.obscurePassword,
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        onPressed:
                                            cubit.togglePasswordVisibility,
                                        icon: Icon(
                                          state.obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      validator: cubit.passwordValidator,
                                    ),
                                    SizedBox(height: 22.h),
                                    CustomTextField(
                                      label: 'Confirm Password',
                                      hintText: 'Confirm your password',
                                      controller:
                                          cubit.confirmPasswordController,
                                      maxLength: 30,
                                      isSensitive: true,
                                      obscureText: state.obscureConfirmPassword,
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        onPressed: cubit
                                            .toggleConfirmPasswordVisibility,
                                        icon: Icon(
                                          state.obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      validator: cubit.confirmPasswordValidator,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              20.w,
                              16.h,
                              20.w,
                              32.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10.r,
                                  offset: Offset(0, -5.h),
                                ),
                              ],
                            ),
                            child: CustomButton(
                              text: 'Continue',
                              isLoading: state.loading,
                              fullWidth: true,
                              onPressed: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                await cubit.submit();
                              },
                            ),
                          ),
                        ],
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

  static Widget _buildStepIndicator({required int currentStep}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = currentStep == index + 1;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 30.w : 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        );
      }),
    );
  }
}
