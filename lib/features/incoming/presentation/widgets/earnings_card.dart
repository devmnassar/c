import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

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

/// Earnings card for incoming order. Base amount + optional bonus.
class EarningsCard extends StatelessWidget {
  final double baseAmount;
  final double? bonusAmount;
  final int? bonusConditionMinutes;
  final bool compact;

  const EarningsCard({
    super.key,
    required this.baseAmount,
    this.bonusAmount,
    this.bonusConditionMinutes,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
    final theme = Theme.of(context);
    final pad = compact ? 10.w : 14.w;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.r),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.yourEarningsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 15.sp : null,
              ),
            ),
            SizedBox(height: compact ? 10.h : 12.h),
            Text(
              l10n.baseAmountLabel(baseAmount.toStringAsFixed(2)),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: compact ? 14.sp : null,
              ),
            ),
            if (bonusAmount != null && bonusAmount! > 0) ...[
              SizedBox(height: compact ? 6.h : 8.h),
              Text(
                bonusConditionMinutes != null
                    ? l10n.bonusLabel(
                        bonusAmount!.toStringAsFixed(0),
                        bonusConditionMinutes.toString(),
                      )
                    : '+${bonusAmount!.toStringAsFixed(0)} SAR bonus',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12.sp : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
