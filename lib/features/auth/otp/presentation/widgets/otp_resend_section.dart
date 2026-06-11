import 'package:flutter/material.dart';

class OtpResendSection extends StatelessWidget {
  const OtpResendSection({
    super.key,
    required this.onResendTap,
  });

  final VoidCallback onResendTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onResendTap,
        child: const Text('Resend code'),
      ),
    );
  }
}
