import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Generates labeled bubble markers (black pill + tail, badge circle + icon, text).
/// Results are cached by (label, iconPath, badgeColor, scale).
class MarkerIconFactory {
  MarkerIconFactory._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static const double _baseWidth = 220;
  static const double _baseHeight = 72;
  static const double _tailWidth = 16;
  static const double _tailHeight = 10;
  static const double _badgeRadius = 22;
  static const double _badgePadding = 10;
  static const double _textPadding = 12;
  static const double _cornerRadius = 24;

  static String _cacheKey(
      String label, String assetIconPath, Color badgeColor, double scale) {
    return '$label|$assetIconPath|${badgeColor.alpha}_${badgeColor.red}_${badgeColor.green}_${badgeColor.blue}|$scale';
  }

  static Future<BitmapDescriptor> labeledMarker({
    required String label,
    required String assetIconPath,
    required Color badgeColor,
    double scale = 1.0,
  }) async {
    final key = _cacheKey(label, assetIconPath, badgeColor, scale);
    final cached = _cache[key];
    if (cached != null) return cached;

    final width = _baseWidth * scale;
    final height = _baseHeight * scale;
    final tailW = _tailWidth * scale;
    final tailH = _tailHeight * scale;
    final badgeR = _badgeRadius * scale;
    final badgePad = _badgePadding * scale;
    final textPad = _textPadding * scale;
    final corner = _cornerRadius * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bubbleHeight = height - tailH;

    // 1) Black pill (rounded rect body)
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, bubbleHeight),
      Radius.circular(corner),
    );
    canvas.drawRRect(pillRect, Paint()..color = Colors.black);

    // 2) Tail (centered at bottom)
    final tailPath = Path()
      ..moveTo(width / 2 - tailW / 2, bubbleHeight)
      ..lineTo(width / 2, height)
      ..lineTo(width / 2 + tailW / 2, bubbleHeight)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = Colors.black);

    // 3) White circle badge (left)
    final badgeCenterX = badgePad + badgeR;
    final badgeCenterY = bubbleHeight / 2;
    canvas.drawCircle(
      Offset(badgeCenterX, badgeCenterY),
      badgeR,
      Paint()..color = Colors.white,
    );

    // 4) Icon inside badge (load from asset, scale to fit, tint with badgeColor)
    ui.Image? iconImage;
    try {
      final bytes = await rootBundle.load(assetIconPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: (badgeR * 1.6).round(),
        targetHeight: (badgeR * 1.6).round(),
      );
      final frame = await codec.getNextFrame();
      iconImage = frame.image;
    } catch (_) {
      // fallback: draw a small circle in badgeColor
      canvas.drawCircle(
        Offset(badgeCenterX, badgeCenterY),
        badgeR * 0.5,
        Paint()..color = badgeColor,
      );
    }
    if (iconImage != null) {
      final iconSize = badgeR * 1.2;
      final src = Rect.fromLTWH(
          0, 0, iconImage.width.toDouble(), iconImage.height.toDouble());
      final dst = Rect.fromCenter(
        center: Offset(badgeCenterX, badgeCenterY),
        width: iconSize,
        height: iconSize,
      );
      canvas.saveLayer(dst.inflate(2), Paint());
      canvas.drawImageRect(
        iconImage,
        src,
        dst,
        Paint()..colorFilter = ColorFilter.mode(badgeColor, BlendMode.srcIn),
      );
      canvas.restore();
    }

    // 5) Text (white bold, vertically centered right of badge)
    final textX = badgeCenterX + badgeR + textPad;
    final textY = bubbleHeight / 2;
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 18 * scale,
        fontWeight: ui.FontWeight.w700,
        fontFamily: 'Roboto',
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(label);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width - textX - textPad));
    canvas.drawParagraph(
      paragraph,
      Offset(textX, textY - paragraph.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.ceil(), height.ceil());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final descriptor = BitmapDescriptor.fromBytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }
}
