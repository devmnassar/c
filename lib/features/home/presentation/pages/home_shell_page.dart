import 'package:flutter/material.dart';
import 'home_page.dart';

/// Final app shell after onboarding completes.
class HomeShellPage extends StatelessWidget {
  static const String id = '/home';
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
