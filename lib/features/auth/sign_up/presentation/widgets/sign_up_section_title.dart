import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignupSectionTitle extends StatelessWidget {
  const SignupSectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w900,
        color: Colors.grey[800],
        letterSpacing: -0.5,
      ),
    );
  }
}

class SignUpSectionTitle extends SignupSectionTitle {
  const SignUpSectionTitle({
    super.key,
    required super.title,
  });
}
