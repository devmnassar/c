import 'package:flutter/material.dart';

enum CustomSnackBar { info, success, error }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    CustomSnackBar type = CustomSnackBar.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _backgroundColor(type, scheme),
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackBar.error);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackBar.success);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: CustomSnackBar.info);
  }

  static Color _backgroundColor(CustomSnackBar type, ColorScheme scheme) {
    switch (type) {
      case CustomSnackBar.success:
        return Colors.green.shade700;
      case CustomSnackBar.error:
        return scheme.error;
      case CustomSnackBar.info:
        return const Color(0xFF1F2937);
    }
  }
}
