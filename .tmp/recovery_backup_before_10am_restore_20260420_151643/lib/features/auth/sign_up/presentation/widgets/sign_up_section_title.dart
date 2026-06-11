import 'package:flutter/material.dart';

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
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.grey[800],
        letterSpacing: -0.5,
      ),
    );
  }
}