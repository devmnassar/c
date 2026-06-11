import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/pages/forget_password_page.dart';
import 'package:gaseel_courier/features/auth/forget_password/presentation/cubit/forget_password_otp_cubit.dart';

class ForgetPasswordOtpVerificationPage extends StatelessWidget {
  static const String id = '/forget-password/otp';

  const ForgetPasswordOtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.nextRoute,
    this.expiresInSeconds,
    this.debugOtpCode,
  });

  final String phoneNumber;
  final String nextRoute;
  final int? expiresInSeconds;
  final String? debugOtpCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return BlocProvider(
      create: (_) => getIt<ForgetPasswordOtpCubit>()
        ..initialize(
          phoneNumber: phoneNumber,
          expiresInSeconds: expiresInSeconds,
          debugOtpCode: debugOtpCode,
        ),
      child: BlocConsumer<ForgetPasswordOtpCubit, ForgetPasswordOtpState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<ForgetPasswordOtpCubit>();

          if (state.status == ForgetPasswordOtpStatus.success) {
            context.push(
              nextRoute,
              extra: {'phoneNumber': phoneNumber},
            );
            cubit.resetStatus();
          }
        },
        builder: (context, state) {
          final cubit = context.read<ForgetPasswordOtpCubit>();

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
                  _buildStepIndicator(currentStep: 2),
                  Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Verify Your Phone',
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'We have sent a verification code to your phone number.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 14.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 10.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F6F5),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          phoneNumber,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 42.h),
                                      Row(
                                        children: List.generate(
                                          ForgetPasswordOtpCubit.otpLength,
                                          (index) => Expanded(
                                            child: Container(
                                              margin:
                                                  EdgeInsetsDirectional.only(
                                                end: index == 5 ? 0 : 6.w,
                                              ),
                                              height: 54.h,
                                              child: TextField(
                                                controller:
                                                    cubit.otpControllers[index],
                                                focusNode:
                                                    cubit.otpFocusNodes[index],
                                                autofocus: index == 0,
                                                enabled: !state.loading,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 20.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                textInputAction: index == 5
                                                    ? TextInputAction.done
                                                    : TextInputAction.next,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    1,
                                                  ),
                                                ],
                                                decoration: InputDecoration(
                                                  counterText: '',
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  filled: true,
                                                  fillColor: const Color(
                                                    0xFFF3F4F6,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14.r,
                                                    ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14.r,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: primaryColor,
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (value) =>
                                                    cubit.onCodeChanged(
                                                        index, value),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (state.errorMessage != null &&
                                          state.errorMessage!.isNotEmpty) ...[
                                        SizedBox(height: 10.h),
                                        Text(
                                          state.errorMessage!,
                                          style: TextStyle(
                                            color: Color(0xFFF4A3AD),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (kDebugMode &&
                                          state.debugOtpCode != null &&
                                          state.debugOtpCode!
                                              .trim()
                                              .isNotEmpty) ...[
                                        SizedBox(height: 10.h),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7FCFA),
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: primaryColor.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tester OTP (Dev Only)',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              SelectableText(
                                                state.debugOtpCode!,
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF0F172A),
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
                                        state.isOtpExpired && !state.canResend
                                            ? 'Resend available in ${_formatDuration(state.resendCooldownRemaining)}'
                                            : state.canResend
                                                ? 'You can request a new code now'
                                                : 'Time remaining: ${_formatDuration(state.otpSecondsRemaining)}',
                                        style: TextStyle(
                                          color: Color(0xFFE67E22),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
                                child: Opacity(
                                  opacity:
                                      (state.isOtpExpired && !state.canResend)
                                          ? 0.5
                                          : 1,
                                  child: IgnorePointer(
                                    ignoring:
                                        state.isOtpExpired && !state.canResend,
                                    child: CustomButton(
                                      text: state.isOtpExpired
                                          ? 'Resend'
                                          : 'Verify',
                                      isLoading: state.loading,
                                      fullWidth: true,
                                      onPressed: () async {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        if (state.isOtpExpired) {
                                          await cubit.resendOtp();
                                        } else {
                                          await cubit.verifyOtp();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  static String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
