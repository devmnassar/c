import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_constants.dart';

class SignUpStepIndicator extends StatelessWidget {
  const SignUpStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final active = currentStep.clamp(0, totalSteps);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        signUpScaffoldHorizontalPadding.w,
        8.h,
        signUpScaffoldHorizontalPadding.w,
        8.h,
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index < active;
          return Expanded(
            child: Container(
              margin: EdgeInsetsDirectional.only(
                  end: index == totalSteps - 1 ? 0 : 6.w),
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}
