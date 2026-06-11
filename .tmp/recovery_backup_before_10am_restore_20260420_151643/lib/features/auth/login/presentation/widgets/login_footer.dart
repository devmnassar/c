import 'package:flutter/material.dart';

class LoginBottom extends StatelessWidget {
  const LoginBottom({
    super.key,
    required this.onCreateAccountTap,
  });

  final VoidCallback onCreateAccountTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to Gaseel?',
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: onCreateAccountTap,
          child: Text(
            'Create Account',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
