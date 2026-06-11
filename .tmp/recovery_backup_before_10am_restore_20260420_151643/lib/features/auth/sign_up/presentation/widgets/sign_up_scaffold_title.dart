import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(
        signUpScaffoldHorizontalPadding,
        8,
        signUpScaffoldHorizontalPadding,
        24,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
