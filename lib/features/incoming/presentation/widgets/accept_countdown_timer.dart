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

/// Compact horizontal countdown: [Accept within] [00:23] [progress bar].
/// Uses Expanded for progress bar to avoid overflow on small screens.
class AcceptCountdownTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool compact;

  const AcceptCountdownTimer({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 60,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
    final remainingFraction = remainingSeconds / totalSeconds;
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final color = remainingSeconds <= 15
        ? const Color(0xFFD32F2F)
        : remainingSeconds <= 30
            ? const Color(0xFFF57C00)
            : AppTheme.primaryColor;

    final barHeight = 6.h;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.acceptWithinLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: compact ? 10.sp : 11.sp,
                ),
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: 54.w,
          child: Text(
            timeStr,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: compact ? 13.sp : 15.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: LinearProgressIndicator(
              value: remainingFraction,
              minHeight: barHeight,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
