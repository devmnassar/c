import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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

    const barHeight = 6.0;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.acceptWithinLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 54,
          child: Text(
            timeStr,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
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
