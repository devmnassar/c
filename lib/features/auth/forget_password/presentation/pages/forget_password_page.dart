import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_cubit.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/create_new_password_page.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_passoword_otp_verification_page.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/phone_number_field.dart';

class ForgetPasswordPage extends StatelessWidget {
  static const String id = '/forget-password';

  const ForgetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return BlocProvider(
      create: (_) => getIt<ForgetPasswordCubit>(),
      child: BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.feedbackCounter != current.feedbackCounter,
        listener: (context, state) {
          final cubit = context.read<ForgetPasswordCubit>();

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

          if (state.status == ForgetPasswordStatus.success) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!context.mounted) return;
              FocusManager.instance.primaryFocus?.unfocus();
              await SystemChannels.textInput
                  .invokeMethod<void>('TextInput.hide');
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              await context.push(
                ForgetPasswordOtpVerificationPage.id,
                extra: {
                  'phoneNumber': state.e164Number,
                  'nextRoute': CreateNewPasswordPage.id,
                  'expiresInSeconds': state.otpExpiresInSeconds,
                  'debugOtpCode': state.debugOtpCode,
                },
              );
              if (context.mounted) {
                cubit.resetStatus();
              }
            });
          }
        },
        builder: (context, state) {
          final cubit = context.read<ForgetPasswordCubit>();
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
                          onPressed: () => context.pop(),
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
                  _buildStepIndicator(currentStep: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Forget Password Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
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
                                      'Enter your phone number to verify your account.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: 18.h),
                                    PhoneNumberField(
                                      initialPhoneNumber:
                                          state.initialPhoneNumber,
                                      selectedPhoneNumber:
                                          state.selectedPhoneNumber,
                                      controller: cubit.phoneController,
                                      enabled: !state.loading,
                                      onChanged: cubit.onPhoneChanged,
                                      onValidated: cubit.onPhoneValidated,
                                      validator: cubit.phoneValidator,
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
                                await cubit.onNext();
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
