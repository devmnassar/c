import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/onboarding/onboarding_state.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/cubit/sign_up_phone_number_cubit.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_phone_body.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/pages/welcome_page.dart';

class SignUpPhonePage extends StatelessWidget {
  static const String id = '/signup';

  const SignUpPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignUpPhoneNumberCubit>(),
      child: BlocConsumer<SignUpPhoneNumberCubit, SignUpPhoneNumberState>(
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.errorMessage != current.errorMessage ||
              previous.debugOtpCode != current.debugOtpCode ||
              previous.feedbackCounter != current.feedbackCounter ||
              previous.phoneVerified != current.phoneVerified ||
              previous.showOtpCard != current.showOtpCard ||
              previous.otpSecondsRemaining != current.otpSecondsRemaining ||
              previous.resendCooldownRemaining !=
                  current.resendCooldownRemaining ||
              previous.obscurePassword != current.obscurePassword ||
              previous.obscureConfirmPassword !=
                  current.obscureConfirmPassword ||
              previous.selectedPhoneNumber?.isoCode !=
                  current.selectedPhoneNumber?.isoCode ||
              previous.initialPhoneNumber?.isoCode !=
                  current.initialPhoneNumber?.isoCode;
        },
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.feedbackCounter != current.feedbackCounter,
        listener: (context, state) {
          final cubit = context.read<SignUpPhoneNumberCubit>();

          if (state.status == SignUpStartStatus.success) {
            OnboardingState.instance.setWelcomeEntered(true);
            context.go(WelcomePage.id);
            cubit.resetStatus();
          }

          if ((state.feedbackMessage?.isNotEmpty ?? false)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor:
                    state.feedbackIsError ? Colors.red.shade700 : null,
              ),
            );
            cubit.clearFeedback();
          }
        },
        builder: (context, state) {
          final cubit = context.read<SignUpPhoneNumberCubit>();
          final theme = Theme.of(context);
          final primaryColor = theme.colorScheme.primary;

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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Text(
                          'Gaseel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: 40.w),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create Account',
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
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
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
                                    child: SignUpPhoneBody(
                                      initialPhoneNumber:
                                          state.initialPhoneNumber,
                                      selectedPhoneNumber:
                                          state.selectedPhoneNumber,
                                      phoneController: cubit.phoneController,
                                      passwordController:
                                          cubit.passwordController,
                                      confirmPasswordController:
                                          cubit.confirmPasswordController,
                                      loading: state.loading,
                                      phoneVerified: state.phoneVerified,
                                      onPhoneChanged: cubit.onPhoneChanged,
                                      onPhoneValidated: cubit.onPhoneValidated,
                                      obscurePassword: state.obscurePassword,
                                      obscureConfirmPassword:
                                          state.obscureConfirmPassword,
                                      onTogglePasswordVisibility:
                                          cubit.togglePasswordVisibility,
                                      onToggleConfirmPasswordVisibility:
                                          cubit.toggleConfirmPasswordVisibility,
                                      phoneValidator: cubit.phoneValidator,
                                      passwordValidator:
                                          cubit.passwordValidator,
                                      confirmPasswordValidator:
                                          cubit.confirmPasswordValidator,
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
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10.r,
                                      offset: Offset(0, -5.h),
                                    ),
                                  ],
                                ),
                                child: CustomButton(
                                  text: state.phoneVerified
                                      ? 'Sign Up'
                                      : 'Verify Number',
                                  isLoading: state.loading,
                                  fullWidth: true,
                                  onPressed: () async {
                                    if (state.showOtpCard) return;
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    if (state.phoneVerified) {
                                      await cubit.submitSignUp();
                                    } else {
                                      await cubit.onNext();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (state.showOtpCard) ...[
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20.w,
                              right: 20.w,
                              top: 74.h,
                              child: _InlineOtpCard(
                                phoneNumber: state.e164Number,
                                secondsRemaining: state.otpSecondsRemaining,
                                resendCooldownRemaining:
                                    state.resendCooldownRemaining,
                                canResend: state.canResend,
                                isExpired: state.isOtpExpired,
                                loading: state.otpActionLoading,
                                errorMessage: state.errorMessage,
                                debugOtpCode: state.debugOtpCode,
                                controllers: cubit.otpControllers,
                                focusNodes: cubit.otpFocusNodes,
                                onChanged: cubit.onOtpCodeChanged,
                                onActionTap: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (state.isOtpExpired) {
                                    await cubit.resendOtp();
                                  } else {
                                    await cubit.verifyOtp();
                                  }
                                },
                              ),
                            ),
                          ],
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
}

class _InlineOtpCard extends StatelessWidget {
  const _InlineOtpCard({
    required this.phoneNumber,
    required this.secondsRemaining,
    required this.resendCooldownRemaining,
    required this.canResend,
    required this.isExpired,
    required this.loading,
    this.errorMessage,
    this.debugOtpCode,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onActionTap,
  });

  final String phoneNumber;
  final int secondsRemaining;
  final int resendCooldownRemaining;
  final bool canResend;
  final bool isExpired;
  final bool loading;
  final String? errorMessage;
  final String? debugOtpCode;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final Future<void> Function() onActionTap;

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A2C),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify your number',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E1F5A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter the 6-digit OTP sent to $phoneNumber',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsetsDirectional.only(end: index == 5 ? 0 : 6.w),
                  height: 54.h,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    enabled: !loading,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF7ED3C8),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => onChanged(index, value),
                  ),
                ),
              );
            }),
          ),
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (kDebugMode &&
              debugOtpCode != null &&
              debugOtpCode!.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF132A2D),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF7ED3C8).withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tester OTP (Dev Only)',
                    style: TextStyle(
                      color: const Color(0xFF7ED3C8),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  SelectableText(
                    debugOtpCode!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Text(
            isExpired
                ? 'OTP expired'
                : 'Time remaining: ${_formatDuration(secondsRemaining)}',
            style: TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          if (isExpired && !canResend)
            Text(
              'Resend available in ${_formatDuration(resendCooldownRemaining)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          SizedBox(height: 14.h),
          Opacity(
            opacity: (isExpired && !canResend) ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: isExpired && !canResend,
              child: CustomButton(
                text: isExpired ? 'Resend' : 'Verify',
                isLoading: loading,
                fullWidth: true,
                onPressed: onActionTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
