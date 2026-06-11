import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/maps_config.dart';

/// Fetches road-following driving route from Google Directions API.
/// Uses in-memory cache. Returns empty list on error (caller may fallback to straight line with warning).
class DirectionsService {
  /// If [apiKey] is provided it is used directly (useful for tests).
  /// Otherwise the key is resolved asynchronously from [MapsConfig].
  DirectionsService({String? apiKey}) : _explicitApiKey = apiKey;

  final String? _explicitApiKey;
  String? _resolvedApiKey;

  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const _timeout = Duration(seconds: 15);

  /// In-memory cache: key = "o|w1|w2|d" (rounded to 5 decimals).
  static final Map<String, List<LatLng>> _cache = {};

  // ── Key resolution ──────────────────────────────────────────────────

  /// Resolves the API key once and caches it for the lifetime of this instance.
  Future<String> _getApiKey() async {
    // Explicit key from constructor (e.g. tests)
    final explicit = _explicitApiKey;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    // Lazy-resolve via MapsConfig (dart-define → native manifest → empty)
    final resolved = _resolvedApiKey ?? await MapsConfig.getEffectiveApiKey();
    _resolvedApiKey = resolved;
    return resolved;
  }

  // ── Cache key ───────────────────────────────────────────────────────

  static String _cacheKey(
      LatLng origin, LatLng destination, List<LatLng> waypoints) {
    final o =
        '${origin.latitude.toStringAsFixed(5)},${origin.longitude.toStringAsFixed(5)}';
    final d =
        '${destination.latitude.toStringAsFixed(5)},${destination.longitude.toStringAsFixed(5)}';
    final w = waypoints
        .map((p) =>
            '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
        .join('|');
    return w.isEmpty ? '$o|$d' : '$o|$w|$d';
  }

  // ── Main API ────────────────────────────────────────────────────────

  /// Fetches driving route polyline from origin to destination, optionally via waypoints.
  /// Returns real road-following points. Empty list on error.
  /// [language] e.g. 'en' or 'ar' for response language.
  Future<List<LatLng>> getDrivingRoutePoints({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
    String language = 'en',
  }) async {
    if (kDebugMode) {
      debugPrint('[Directions] origin=${origin.latitude},${origin.longitude} '
          'destination=${destination.latitude},${destination.longitude} '
          'waypoints=${waypoints.length}');
    }

    // ── Resolve key ──────────────────────────────────────────────────
    final apiKey = await _getApiKey();

    if (kDebugMode) {
      final keyTail =
          apiKey.length >= 4 ? apiKey.substring(apiKey.length - 4) : '????';
      debugPrint('[Directions] keySource=${MapsConfig.keySource} '
          'keyLoaded=${apiKey.isNotEmpty} keyTail=$keyTail');
    }

    if (apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Directions] ERROR: API key is empty after all fallbacks.\n'
            '  → Gradle injection: ensure local.properties has gms.debugApiKey=YOUR_KEY\n'
            '  → Manual override : flutter run --dart-define=MAPS_API_KEY=YOUR_KEY\n'
            '  → Native fallback : ensure AndroidManifest/Info.plist key is configured');
      }
      return [];
    }

    // ── Cache check ──────────────────────────────────────────────────
    final key = _cacheKey(origin, destination, waypoints);
    final cached = _cache[key];
    if (cached != null) {
      if (kDebugMode)
        debugPrint('[Directions] cache hit, points=${cached.length}');
      return cached;
    }

    // ── Build request ────────────────────────────────────────────────
    try {
      final queryParams = <String, String>{
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'alternatives': 'false',
        'units': 'metric',
        'language': language,
        'region': 'sa',
        'key': apiKey,
      };
      if (waypoints.isNotEmpty) {
        final wpStr =
            waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
        queryParams['waypoints'] = 'optimize:true|$wpStr';
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      if (kDebugMode) {
        final maskedUrl = uri.toString().replaceAll(apiKey, '***KEY***');
        debugPrint('[Directions] request: $maskedUrl');
      }

      // ── Execute ──────────────────────────────────────────────────
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[Directions] ERROR: HTTP ${response.statusCode}');
        }
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      final errorMessage = json['error_message'] as String?;

      if (kDebugMode) {
        debugPrint('[Directions] response status=$status '
            'error_message=$errorMessage');
      }

      // ── Handle error statuses ────────────────────────────────────
      if (status == 'ZERO_RESULTS') {
        if (kDebugMode) {
          debugPrint(
              '[Directions] ZERO_RESULTS: No route found between the given coordinates.');
        }
        return [];
      }

      if (status == 'REQUEST_DENIED') {
        _logRequestDeniedChecklist(errorMessage);
        return [];
      }

      if (status == 'OVER_QUERY_LIMIT') {
        if (kDebugMode) {
          debugPrint(
              '[Directions] OVER_QUERY_LIMIT: Quota exceeded or billing not enabled.');
        }
        return [];
      }

      if (status != 'OK') {
        if (kDebugMode) {
          debugPrint(
              '[Directions] ERROR: status=$status error_message=$errorMessage');
        }
        return [];
      }

      // ── Parse polyline ───────────────────────────────────────────
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        if (kDebugMode) debugPrint('[Directions] ERROR: routes empty');
        return [];
      }

      final route = routes.first as Map<String, dynamic>;
      final overview = route['overview_polyline'] as Map<String, dynamic>?;
      final encoded = overview?['points'] as String?;
      if (encoded == null || encoded.isEmpty) {
        if (kDebugMode)
          debugPrint('[Directions] ERROR: overview_polyline.points empty');
        return [];
      }

      final points = _decodePolyline(encoded);
      if (kDebugMode) {
        debugPrint('[Directions] decoded polyline points=${points.length}');
      }

      if (points.isEmpty) {
        if (kDebugMode) debugPrint('[Directions] ERROR: decoded 0 points');
        return [];
      }

      _cache[key] = points;
      return points;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Directions] ERROR: $e');
        debugPrint('[Directions] stack: $st');
      }
      return [];
    }
  }

  /// Legacy: fetches route polyline (origin → destination only).
  /// Returns null on error. Prefer getDrivingRoutePoints.
  Future<List<LatLng>?> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final points = await getDrivingRoutePoints(
      origin: origin,
      destination: destination,
    );
    return points.isEmpty ? null : points;
  }

  // ── Polyline decoder ──────────────────────────────────────────────

  /// Decodes Google encoded polyline to LatLng list.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ── Helpers ───────────────────────────────────────────────────────

  /// Straight polyline fallback ONLY when API fails. Log warning.
  static List<LatLng> straightPolyline(LatLng origin, LatLng destination) {
    if (kDebugMode) {
      debugPrint(
          '[Directions] WARNING: Using straight line fallback (API failed or returned empty)');
    }
    return [origin, destination];
  }

  /// Computes LatLngBounds from a list of points (for camera fit).
  static LatLngBounds boundsFromLatLngList(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(0, 0),
        northeast: LatLng(0, 0),
      );
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    const pad = 0.005;
    return LatLngBounds(
      southwest: LatLng(minLat - pad, minLng - pad),
      northeast: LatLng(maxLat + pad, maxLng + pad),
    );
  }

  // ── REQUEST_DENIED diagnostics ────────────────────────────────────

  static void _logRequestDeniedChecklist(String? errorMessage) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint(
        '╔══════════════════════════════════════════════════════════════╗');
    debugPrint(
        '║  DIRECTIONS API: REQUEST_DENIED                            ║');
    debugPrint(
        '╚══════════════════════════════════════════════════════════════╝');
    debugPrint('  error_message: $errorMessage');
    debugPrint('');
    debugPrint('  CHECKLIST — fix each item then retry:');
    debugPrint('');
    debugPrint('  (a) Google Cloud Console → APIs & Services → Library');
    debugPrint('      Ensure "Directions API" is ENABLED for your project.');
    debugPrint('');
    debugPrint('  (b) APIs & Services → Credentials → your API key');
    debugPrint('      Under "API restrictions", ensure "Directions API"');
    debugPrint('      is in the list of allowed APIs.');
    debugPrint('');
    debugPrint('  (c) Under "Application restrictions":');
    debugPrint('      • If "Android apps": Package name MUST be EXACTLY:');
    debugPrint('          sa.gaseelexpress.courier.test');
    debugPrint('        AND the SHA-1 must match the signing certificate.');
    debugPrint('        Run:  cd android && ./gradlew signingReport');
    debugPrint('        to get the current SHA-1. Add it in Cloud Console.');
    debugPrint('');
    debugPrint('      • If "HTTP referrers" or "IP addresses": these will');
    debugPrint('        FAIL for mobile apps. Remove them or switch to');
    debugPrint('        "Android apps" restriction.');
    debugPrint('');
    debugPrint('  (d) QUICK TEST: Temporarily set Application restrictions');
    debugPrint('      to "None" and API restrictions to "Don\'t restrict".');
    debugPrint('      If it works → the issue is restriction config.');
    debugPrint('');
    debugPrint('  (e) Ensure Billing is enabled on the Google Cloud project.');
    debugPrint('');
    debugPrint('  keySource=${MapsConfig.keySource}');
    debugPrint('  keyLoaded=${MapsConfig.keyLoaded}');
    debugPrint('');
  }
}
