import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/core/widgets/custom_button.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_constants.dart';

class SignUpScaffoldBottomActions extends StatelessWidget {
  const SignUpScaffoldBottomActions({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.loading,
    required this.nextLabel,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool loading;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        signUpScaffoldHorizontalPadding.w,
        16.h,
        signUpScaffoldHorizontalPadding.w,
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
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      signUpScaffoldButtonBorderRadius.r,
                    ),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          if (onBack != null && onNext != null) SizedBox(width: 16.w),
          if (onNext != null)
            Expanded(
              flex: 2,
              child: CustomButton(
                text: nextLabel ?? 'Next',
                isLoading: loading,
                fullWidth: true,
                onPressed: () async {
                  onNext!.call();
                },
              ),
            ),
        ],
      ),
    );
  }
}
