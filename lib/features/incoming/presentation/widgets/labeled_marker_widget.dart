import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/incoming_map_utils.dart'
    show kLabelBubbleHeight, kLabelBubbleWidth;

/// Marker type: laundry, home, or courier.
enum LabeledMarkerType {
  laundry,
  home,
  courier,
}

/// Reusable labeled marker overlay for map. Shows icon (or logo for laundry) + title.
/// Compact design; positioned above the marker pin.
class LabeledMarkerWidget extends StatelessWidget {
  final LabeledMarkerType type;
  final String title;
  final String? logoUrl;
  final ui.TextDirection textDirection;

  const LabeledMarkerWidget({
    super.key,
    required this.type,
    required this.title,
    this.logoUrl,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final icon = type == LabeledMarkerType.laundry
        ? Icons.local_laundry_service
        : type == LabeledMarkerType.home
            ? Icons.home
            : Icons.person;

    return Directionality(
      textDirection: textDirection,
      child: SizedBox(
        width: kLabelBubbleWidth,
        height: kLabelBubbleHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: kLabelBubbleWidth,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLeading(context, icon),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: _BubbleTailPainter(
                color: const Color(0xFF111111).withValues(alpha: 0.92),
              ),
              size: const Size(12, 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, IconData fallbackIcon) {
    if (type == LabeledMarkerType.laundry &&
        logoUrl != null &&
        logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Image.network(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _IconLeading(icon: fallbackIcon),
          ),
        ),
      );
    }
    return _IconLeading(icon: fallbackIcon);
  }
}

class _IconLeading extends StatelessWidget {
  final IconData icon;

  const _IconLeading({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
