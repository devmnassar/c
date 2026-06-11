import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/incoming_order_mock.dart';

AppLocalizations _resolveL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (l10n != null) return l10n;

  final locale = Localizations.maybeLocaleOf(context);
  if (locale != null) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (supported) return lookupAppLocalizations(locale);
  }

  return lookupAppLocalizations(const Locale('en'));
}

/// Header: Row A (title + chip) + Row B (timer). Two rows to avoid overflow.
class OrderHeaderLabelRow extends StatelessWidget {
  final IncomingOrderType orderType;
  final ThemeData theme;
  final bool compact;
  final Widget? countdown;

  const OrderHeaderLabelRow({
    super.key,
    required this.orderType,
    required this.theme,
    this.compact = false,
    this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
    final isPickup = orderType == IncomingOrderType.pickup;
    final chipLabel = isPickup ? l10n.pickup : l10n.delivery;
    final color = isPickup ? Colors.amber.shade700 : AppTheme.primaryColor;
    final bgColor = isPickup
        ? Colors.amber.shade50
        : color.withValues(alpha: 0.1);
    final icon = isPickup
        ? Icons.shopping_basket_outlined
        : Icons.local_shipping_outlined;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12.w : 16.w,
        compact ? 8.h : 12.h,
        compact ? 12.w : 16.w,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.incomingOrderTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isPickup ? 'New Pickup Request' : 'New Delivery Request',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: compact ? 18.sp : 22.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12.w : 16.w,
                  vertical: compact ? 6.h : 8.h,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: compact ? 16.sp : 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      chipLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 13.sp : 14.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (countdown != null) ...[SizedBox(height: 12.h), countdown!],
        ],
      ),
    );
  }
}
