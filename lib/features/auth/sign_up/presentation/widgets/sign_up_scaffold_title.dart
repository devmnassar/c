import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_constants.dart';

class SignUpTitle extends StatelessWidget {
  const SignUpTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        signUpScaffoldHorizontalPadding.w,
        8.h,
        signUpScaffoldHorizontalPadding.w,
        24.h,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
