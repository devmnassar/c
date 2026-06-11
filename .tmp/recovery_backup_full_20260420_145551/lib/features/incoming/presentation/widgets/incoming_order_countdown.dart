import 'package:flutter/material.dart';

/// Countdown timer for incoming order. Color phases: normal → amber (2:00) → red (1:00).
/// Progress bar fills down as time passes.
class IncomingOrderCountdown extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool compact;

  const IncomingOrderCountdown({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 180,
    this.compact = false,
  });

  /// Color for current phase: 3:00–2:01 teal, 2:00–1:01 amber, 1:00–0:01 red.
  static Color colorForSeconds(int remaining, int total) {
    if (remaining <= 60) return const Color(0xFFD32F2F); // red
    if (remaining <= 120) return const Color(0xFFF57C00); // amber
    return const Color(0xFF00897B); // teal
  }

  /// Progress 0..1 (1 = full, 0 = empty). Fills down as time passes.
  double get progress => 1.0 - (remainingSeconds / totalSeconds);

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForSeconds(remainingSeconds, totalSeconds);
    final w = compact ? 48.0 : 56.0;
    final h = compact ? 36.0 : 44.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade300,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: remainingSeconds <= 60 ? 6 : 0,
            spreadRadius: remainingSeconds <= 60 ? 1 : 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _ProgressBarPainter(
                  progress: progress,
                  color: color,
                ),
              ),
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * progress.clamp(0.0, 1.0);
    if (fillHeight > 0) {
      final fillRect =
          Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight);
      canvas.save();
      canvas.clipRect(fillRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(8)),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
