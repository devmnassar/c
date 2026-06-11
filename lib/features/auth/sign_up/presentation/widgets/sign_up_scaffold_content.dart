import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gaseel_courier/features/auth/sign_up/presentation/widgets/sign_up_scaffold_bottom_actions.dart';

class SignUpScaffoldContent extends StatelessWidget {
  const SignUpScaffoldContent({
    super.key,
    required this.body,
    required this.canShowBottomActions,
    required this.onBack,
    required this.onNext,
    required this.loading,
    required this.nextLabel,
  });

  final Widget body;
  final bool canShowBottomActions;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool loading;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              child: body,
            ),
          ),
          if (canShowBottomActions)
            SignUpScaffoldBottomActions(
              onBack: onBack,
              onNext: onNext,
              loading: loading,
              nextLabel: nextLabel,
            ),
        ],
      ),
    );
  }
}
