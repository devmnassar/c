import 'package:flutter/material.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_content.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_app_bar.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_title.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_step_indicator.dart';

class SignUpScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool loading;

  const SignUpScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentStep,
    this.totalSteps = 4,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final canShowBottomActions = onNext != null || onBack != null;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SignUpAppBar(onBack: onBack),
            SignUpStepIndicator(
              currentStep: currentStep,
              totalSteps: totalSteps,
            ),
            SignUpTitle(title: title),
            Expanded(
              child: SignUpScaffoldContent(
                body: body,
                canShowBottomActions: canShowBottomActions,
                onBack: onBack,
                onNext: onNext,
                loading: loading,
                nextLabel: nextLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScaffoldItem extends SignUpScaffold {
  const ScaffoldItem({
    super.key,
    required super.title,
    required super.body,
    required super.currentStep,
    super.totalSteps = 4,
    super.onBack,
    super.onNext,
    super.nextLabel,
    super.loading = false,
  });
}
