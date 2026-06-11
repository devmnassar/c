import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'orders_ui_constants.dart';

class OrdersSummaryBar extends StatelessWidget {
  const OrdersSummaryBar({
    super.key,
    required this.todayCount,
    required this.activeCount,
    required this.doneCount,
  });

  final int todayCount;
  final int activeCount;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryItem(
            label: 'Today',
            value: todayCount.toString(),
            color: kOrdersPrimaryColor,
          ),
          Container(width: 1.w, height: 24.h, color: Colors.grey[200]),
          _SummaryItem(
            label: 'Active',
            value: activeCount.toString(),
            color: const Color(0xFF3B82F6),
          ),
          Container(width: 1.w, height: 24.h, color: Colors.grey[200]),
          _SummaryItem(
            label: 'Done',
            value: doneCount.toString(),
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
