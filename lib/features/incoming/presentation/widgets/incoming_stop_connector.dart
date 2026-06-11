import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dotted vertical connector between incoming order stop cards.
class IncomingStopConnector extends StatelessWidget {
  const IncomingStopConnector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final start = compact ? 30.w : 36.w;
    final h = compact ? 20.h : 24.h;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: start),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Container(
              width: 2.w,
              height: h / 7,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
