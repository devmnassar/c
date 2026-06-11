import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pad = compact ? 10.0 : 14.0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                fontSize: compact ? 15 : null,
              ),
            ),
            SizedBox(height: compact ? 10 : 12),
            Text(
              l10n.baseAmountLabel(baseAmount.toStringAsFixed(2)),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: compact ? 14 : null,
              ),
            ),
            if (bonusAmount != null && bonusAmount! > 0 && bonusConditionMinutes != null) ...[
              SizedBox(height: compact ? 6 : 8),
              Text(
                l10n.bonusLabel(
                  bonusAmount!.toStringAsFixed(0),
                  bonusConditionMinutes.toString(),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
