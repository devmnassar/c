import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Label + value column used on the incoming order screen.
class IncomingInfoField extends StatelessWidget {
  const IncomingInfoField({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
    required this.textAlign,
    required this.theme,
  });

  final String label;
  final String? value;
  final bool compact;
  final TextAlign textAlign;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value?.trim() ?? '';
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 90.w : 120.w,
        maxWidth: compact ? 120.w : 150.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            textAlign: textAlign,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: compact ? 11.sp : 12.sp,
            ),
          ),
          SizedBox(height: 2.h),
          if (normalizedValue.isNotEmpty)
            Text(
              normalizedValue,
              textAlign: textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 14.sp : 16.sp,
              ),
            )
          else
            SizedBox(height: compact ? 24.h : 28.h),
        ],
      ),
    );
  }
}
