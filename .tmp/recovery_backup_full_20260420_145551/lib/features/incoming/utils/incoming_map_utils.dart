import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const int kMarkerIconSize = 56;
const double kLabelGap = 6;
const double kLabelBubbleWidth = 130;
const double kLabelBubbleHeight = 44.0;
const double kRouteShadowOffsetLat = 0.0002;

/// Loads a marker icon from assets.
Future<BitmapDescriptor> loadMarkerIcon(String assetPath) async {
  try {
    final bytes = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: kMarkerIconSize,
      targetHeight: kMarkerIconSize,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  } catch (_) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }
}

/// Creates shadow points (offset south) for depth effect.
List<LatLng> offsetPolylineSouth(List<LatLng> points) {
  return points
      .map((p) => LatLng(p.latitude - kRouteShadowOffsetLat, p.longitude))
      .toList();
}
