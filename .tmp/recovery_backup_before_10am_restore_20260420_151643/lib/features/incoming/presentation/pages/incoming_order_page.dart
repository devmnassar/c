import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/audio/alert_sound_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/mock_orders_data.dart';
import '../../../orders/domain/models/order_mock.dart';
import '../../data/mappers/incoming_order_mapper.dart';
import '../../domain/models/incoming_order_mock.dart';
import '../../utils/incoming_map_utils.dart'
    show
        kLabelBubbleHeight,
        kLabelBubbleWidth,
        kLabelGap,
        kMarkerIconSize,
        loadMarkerIcon,
        offsetPolylineSouth;
import '../widgets/accept_countdown_timer.dart';
import '../widgets/earnings_card.dart';
import '../widgets/incoming_map_controls.dart';
import '../widgets/labeled_marker_widget.dart';

/// Max curvature factor: offset = lineLength * (factor). Keeps curve subtle.
const double kMaxCurvatureFactor = 0.12;

/// Builds a smooth curved polyline between two points using quadratic Bezier.
/// 12–24 intermediate points, subtle curve (controlled by curvature factor).
/// Curve direction based on bearing; professional look, not cartoon.
List<LatLng> buildSmoothCurvePoints(
  LatLng start,
  LatLng end, {
  double curvatureFactor = 0.06,
}) {
  const numPoints = 18;
  final dlat = end.latitude - start.latitude;
  final dlng = end.longitude - start.longitude;
  final lineLen = math.sqrt(dlat * dlat + dlng * dlng);
  if (lineLen < 1e-8) return [start, end];

  final midLat = (start.latitude + end.latitude) / 2;
  final midLng = (start.longitude + end.longitude) / 2;

  // Perpendicular unit vector: (dlng, -dlat) normalized
  final perpLat = dlng / lineLen;
  final perpLng = -dlat / lineLen;

  // Offset proportional to line length; clamp to max 0.12
  final factor = curvatureFactor.clamp(0.03, kMaxCurvatureFactor);
  final offset = lineLen * factor;

  final ctrlLat = midLat + offset * perpLat;
  final ctrlLng = midLng + offset * perpLng;
  final control = LatLng(ctrlLat, ctrlLng);

  final points = <LatLng>[];
  for (var i = 0; i <= numPoints; i++) {
    final t = i / numPoints;
    final mt = 1 - t;
    final mt2 = mt * mt;
    final tt = t * t;
    points.add(
      LatLng(
        mt2 * start.latitude +
            2 * mt * t * control.latitude +
            tt * end.latitude,
        mt2 * start.longitude +
            2 * mt * t * control.longitude +
            tt * end.longitude,
      ),
    );
  }
  return points;
}

/// Tiny degree padding (avoids zoom-out from large degree padding).
const double _kBoundsPaddingDeg = 0.0002;

/// Minimum zoom after fit (never zoom out past this).
const double _kMinZoom = 15.0;

/// Max zoom after zoom-in step (avoids over-zooming).
const double _kMaxZoom = 18.0;

/// Small zoom bump after bounds fit (+0.8 to +1.5 range).
const double _kZoomInStep = 1.2;

/// Default zoom if getZoomLevel() fails.
const double _kDefaultTargetZoom = 15.0;

/// Computes bounds for two points (used by fit and reset).
/// Minimal degree padding; rely on screen padding in newLatLngBounds.
LatLngBounds computeBoundsForTwoPoints(LatLng p1, LatLng p2) {
  final minLat = math.min(p1.latitude, p2.latitude) - _kBoundsPaddingDeg;
  final maxLat = math.max(p1.latitude, p2.latitude) + _kBoundsPaddingDeg;
  final minLng = math.min(p1.longitude, p2.longitude) - _kBoundsPaddingDeg;
  final maxLng = math.max(p1.longitude, p2.longitude) + _kBoundsPaddingDeg;
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// Tight padding for fit bounds (10–14). Points fill the map area.
double _computeFitPadding(double mapHeight) =>
    (mapHeight * 0.04).clamp(10.0, 14.0);

/// Fits map to two points with TIGHT padding, then zooms IN.
/// A) Fit bounds -> B) Delay 300ms -> C) targetZoom = max(current,15) + 1.2 -> D) scrollBy 5%.
Future<void> fitToTwoPoints(
  GoogleMapController controller,
  LatLng p1,
  LatLng p2, {
  required double mapHeight,
}) async {
  try {
    final bounds = computeBoundsForTwoPoints(p1, p2);
    final padding = _computeFitPadding(mapHeight);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    double currentZoom;
    try {
      currentZoom = await controller.getZoomLevel();
    } catch (_) {
      currentZoom = _kDefaultTargetZoom - _kZoomInStep;
    }
    if (kDebugMode) {
      debugPrint('[IncomingMap] bounds-fit zoom=$currentZoom');
    }
    var targetZoom = math.max(currentZoom, _kMinZoom);
    targetZoom = (targetZoom + _kZoomInStep).clamp(_kMinZoom, _kMaxZoom);
    if (kDebugMode) {
      debugPrint(
        '[IncomingMap] final targetZoom=$targetZoom (>=15: ${targetZoom >= 15})',
      );
    }
    await controller.animateCamera(CameraUpdate.zoomTo(targetZoom));

    final scrollDy = mapHeight * 0.05;
    await controller.animateCamera(CameraUpdate.scrollBy(0, scrollDy));
  } catch (e) {
    if (kDebugMode) debugPrint('[IncomingMap] fitToTwoPoints error: $e');
  }
}

/// Resets camera to initial fit state (same tight fit + zoom in logic).
Future<void> resetToInitialBounds(
  GoogleMapController controller,
  LatLngBounds bounds,
  double mapHeight,
) async {
  try {
    final padding = _computeFitPadding(mapHeight);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    double currentZoom;
    try {
      currentZoom = await controller.getZoomLevel();
    } catch (_) {
      currentZoom = _kDefaultTargetZoom - _kZoomInStep;
    }
    if (kDebugMode) {
      debugPrint('[IncomingMap] reset bounds-fit zoom=$currentZoom');
    }
    var targetZoom = math.max(currentZoom, _kMinZoom);
    targetZoom = (targetZoom + _kZoomInStep).clamp(_kMinZoom, _kMaxZoom);
    if (kDebugMode) {
      debugPrint('[IncomingMap] reset final targetZoom=$targetZoom');
    }
    await controller.animateCamera(CameraUpdate.zoomTo(targetZoom));

    final scrollDy = mapHeight * 0.05;
    await controller.animateCamera(CameraUpdate.scrollBy(0, scrollDy));
  } catch (e) {
    if (kDebugMode) debugPrint('[IncomingMap] resetToInitialBounds error: $e');
  }
}

/// Screen shown when a new order is found (after "Go To Online" search).
/// Map, two-stop cards, ETA, Accept/Reject actions.
class IncomingOrderPage extends StatefulWidget {
  static const String id = '/incoming-order';
  final OrderMock order;

  const IncomingOrderPage({super.key, required this.order});

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  GoogleMapController? _mapController;
  final Map<String, Offset> _labelOffsets = {};
  bool _labelsReady = false;
  DateTime? _lastLabelUpdateTime;
  static const int _labelUpdateThrottleMs = 150;
  Timer? _cameraMoveDebounce;

  List<_MapLabelData> _labelData = [];
  LatLngBounds? _initialBounds;
  bool _userMovedMap = false;
  bool _isProgrammaticFit = false;
  bool _didInitialFit = false;
  double _mapWidth = 0;
  double _mapHeight = 0;

  static const int _kCountdownTotalSeconds = 60;
  int _remainingSeconds = _kCountdownTotalSeconds;
  Timer? _countdownTimer;
  bool _expiredNavigated = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
        _handleExpired();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _handleExpired() async {
    if (_expiredNavigated) return;
    _expiredNavigated = true;
    _stopCountdown();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.orderExpiredTitle),
        content: Text(l10n.orderExpiredBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go('/map-status', extra: {'autoSearch': true});
  }

  @override
  void dispose() {
    AlertSoundService.stopOrderAlertSound();
    _countdownTimer?.cancel();
    _cameraMoveDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _runInitialFitOnce(List<LatLng> points, double mapHeight) {
    if (points.length < 2 || _mapController == null || _didInitialFit) return;
    _didInitialFit = true;
    _isProgrammaticFit = true;
    _initialBounds = computeBoundsForTwoPoints(points[0], points[1]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted || _mapController == null) return;
      await fitToTwoPoints(
        _mapController!,
        points[0],
        points[1],
        mapHeight: mapHeight,
      );
      if (mounted) _updateLabelOffsets();
    });
  }

  Future<void> _resetCamera(double mapHeight) async {
    if (_mapController == null || _initialBounds == null) return;
    _isProgrammaticFit = true;
    await resetToInitialBounds(_mapController!, _initialBounds!, mapHeight);
    if (mounted) {
      setState(() => _userMovedMap = false);
      _updateLabelOffsets();
    }
  }

  Future<void> _updateLabelOffsets() async {
    if (_mapController == null || !mounted || _labelData.isEmpty) return;
    if (_mapWidth <= 0 || _mapHeight <= 0) return;
    final now = DateTime.now();
    if (_lastLabelUpdateTime != null &&
        now.difference(_lastLabelUpdateTime!).inMilliseconds <
            _labelUpdateThrottleMs) {
      return;
    }
    _lastLabelUpdateTime = now;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final newOffsets = <String, Offset>{};
    const edgePad = 8.0;
    final minX = edgePad;
    final maxX = _mapWidth - kLabelBubbleWidth - edgePad;
    final maxTop = _mapHeight - kLabelBubbleHeight - edgePad;
    try {
      for (final label in _labelData) {
        final sc = await _mapController!.getScreenCoordinate(label.position);
        final dx = sc.x.toDouble() / dpr;
        final dy = sc.y.toDouble() / dpr;

        var x = dx - kLabelBubbleWidth / 2;
        x = x.clamp(minX, maxX);

        var preferredTop = dy - kMarkerIconSize - kLabelGap;
        double top;
        if (preferredTop < edgePad) {
          top = dy + kLabelGap;
        } else {
          top = preferredTop;
        }
        top = top.clamp(edgePad, maxTop);

        newOffsets[label.id] = Offset(x, top);
      }
      if (!mounted) return;
      setState(() {
        _labelOffsets.clear();
        _labelOffsets.addAll(newOffsets);
        _labelsReady = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _labelOffsets.clear();
          _labelsReady = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final incoming = fromOrderMock(widget.order, l10n);
    final stops = incoming.buildStops();
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    final mapPoints = stops
        .map((s) => LatLng(s.latLng.lat, s.latLng.lng))
        .toList();

    _labelData = [
      _MapLabelData(
        id: 'stop_0',
        position: mapPoints[0],
        type: stops[0].type == StopPointType.laundry
            ? LabeledMarkerType.laundry
            : LabeledMarkerType.home,
        title: stops[0].type == StopPointType.laundry
            ? (incoming.laundryName.isNotEmpty
                  ? incoming.laundryName
                  : l10n.labelLaundry)
            : l10n.labelHome,
        logoUrl: stops[0].type == StopPointType.laundry
            ? incoming.laundryLogoUrl
            : null,
      ),
      _MapLabelData(
        id: 'stop_1',
        position: mapPoints[1],
        type: stops[1].type == StopPointType.laundry
            ? LabeledMarkerType.laundry
            : LabeledMarkerType.home,
        title: stops[1].type == StopPointType.laundry
            ? (incoming.laundryName.isNotEmpty
                  ? incoming.laundryName
                  : l10n.labelLaundry)
            : l10n.labelHome,
        logoUrl: stops[1].type == StopPointType.laundry
            ? incoming.laundryLogoUrl
            : null,
      ),
    ];

    final mq = MediaQuery.of(context);
    final screenH = mq.size.height - mq.padding.top - mq.padding.bottom;
    final compact = screenH < 650;

    // Map height: 42% when compact for more map, 38% otherwise
    final mapH = (screenH * (compact ? 0.42 : 0.40)).clamp(140.0, 280.0);

    // Tight padding in compact mode
    final padH = compact ? 10.0 : 14.0;
    final padV = compact ? 6.0 : 10.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Map: full-width, edge-to-edge
        SizedBox(
          height: mapH,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _mapWidth = constraints.maxWidth;
              _mapHeight = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  _IncomingOrderMap(
                    mapPoints: mapPoints,
                    stops: stops,
                    labelData: _labelData,
                    labelOffsets: _labelOffsets,
                    labelsReady: _labelsReady,
                    isRtl: isRtl,
                    onMapCreated: (c) {
                      _mapController = c;
                      _runInitialFitOnce(mapPoints, mapH);
                    },
                    onCameraMove: () {
                      _cameraMoveDebounce?.cancel();
                      _cameraMoveDebounce = Timer(
                        const Duration(milliseconds: _labelUpdateThrottleMs),
                        () {
                          if (mounted) _updateLabelOffsets();
                        },
                      );
                    },
                    onCameraMoveStarted: () {
                      if (!_isProgrammaticFit && mounted) {
                        setState(() => _userMovedMap = true);
                      }
                    },
                    onCameraIdle: () {
                      if (mounted) _isProgrammaticFit = false;
                    },
                  ),
                  IncomingMapControls(
                    showReset: _userMovedMap,
                    onExpand: () => context.push(
                      '/incoming-order/map',
                      extra: widget.order,
                    ),
                    onReset: _userMovedMap ? () => _resetCamera(mapH) : null,
                    isRtl: isRtl,
                  ),
                  PositionedDirectional(
                    top: mq.padding.top + 12,
                    start: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      child: InkWell(
                        onTap: () => context.go('/map-status'),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // Label row: New Order | [Countdown] [Pickup/Delivery chip]
        OrderHeaderLabelRow(
          orderType: incoming.orderType,
          theme: theme,
          compact: compact,
          countdown: AcceptCountdownTimer(
            remainingSeconds: _remainingSeconds,
            totalSeconds: _kCountdownTotalSeconds,
            compact: compact,
          ),
        ),
        // Content: compact cards + ETA + earnings (single scroll, no nested scroll)
        Padding(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StopCard(
                stop: stops[0],
                distanceKm: incoming.distanceToFirstKm,
                theme: theme,
                compact: compact,
              ),
              _StopConnector(compact: compact),
              _StopCard(
                stop: stops[1],
                distanceKm: incoming.distanceFirstToSecondKm,
                theme: theme,
                compact: compact,
              ),
              SizedBox(height: compact ? 8 : 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.estimatedArrival,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${incoming.etaFrom} – ${incoming.etaTo}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: compact ? 16 : 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildServiceChips(
                    context,
                    order: widget.order,
                    compact: compact,
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              EarningsCard(
                baseAmount: 15.00,
                bonusAmount: 5,
                bonusConditionMinutes: 1,
                compact: compact,
              ),
            ],
          ),
        ),
      ],
    );

    final buttons = Padding(
      padding: EdgeInsets.fromLTRB(padH, 0, padH, mq.padding.bottom + 12),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  _stopCountdown();
                  _showRejectModal(context, l10n);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: Text(l10n.reject),
              ),
            ),
          ),
          SizedBox(width: padH),
          Expanded(
            flex: 13,
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: () {
                  _stopCountdown();
                  MockOrdersData.addMockOrder(widget.order);
                  context.go('/active-trip/${widget.order.id}');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  textStyle: TextStyle(fontSize: compact ? 14 : 15),
                ),
                child: Text(l10n.accept),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(child: SingleChildScrollView(child: content)),
              buttons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceChips(
    BuildContext context, {
    required OrderMock order,
    required bool compact,
  }) {
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    // TODO: replace with real order.services list from API
    final services = <String>[
      if (isRtl)
        order.laundryTypeNameAr ?? order.laundryTypeName ?? 'غسيل سجاد'
      else
        order.laundryTypeName ?? order.laundryTypeNameAr ?? 'Carpet Washing',
    ];

    if (services.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const int maxVisible = 2;
    final visible = services.take(maxVisible).toList();
    final overflow = services.length - maxVisible;

    Widget chip(String label) {
      return Container(
        constraints: BoxConstraints(maxWidth: compact ? 90 : 110),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(50),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
            height: 1.2,
          ),
        ),
      );
    }

    return Tooltip(
      message: isRtl ? 'نوع الطلب' : 'Services',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        children: [
          for (final s in visible) chip(s),
          if (overflow > 0) chip('+$overflow'),
        ],
      ),
    );
  }

  Future<void> _showRejectModal(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rejectRatingWarning),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => const Icon(Icons.star, color: Colors.amber, size: 32),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.confirmReject),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/map-status');
    } else if (context.mounted) {
      _startCountdown();
    }
  }
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
    final l10n = AppLocalizations.of(context)!;
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
        compact ? 12 : 16,
        compact ? 8 : 12,
        compact ? 12 : 16,
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
                    const SizedBox(height: 2),
                    Text(
                      isPickup ? 'New Pickup Request' : 'New Delivery Request',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: compact ? 18 : 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: compact ? 16 : 18),
                    const SizedBox(width: 8),
                    Text(
                      chipLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 13 : 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (countdown != null) ...[const SizedBox(height: 12), countdown!],
        ],
      ),
    );
  }
}

class _MapLabelData {
  final String id;
  final LatLng position;
  final LabeledMarkerType type;
  final String title;
  final String? logoUrl;

  _MapLabelData({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
    this.logoUrl,
  });
}

class _IncomingOrderMap extends StatefulWidget {
  final List<LatLng> mapPoints;
  final List<StopPoint> stops;
  final List<_MapLabelData> labelData;
  final Map<String, Offset> labelOffsets;
  final bool labelsReady;
  final bool isRtl;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onCameraMove;
  final VoidCallback? onCameraMoveStarted;
  final VoidCallback? onCameraIdle;

  const _IncomingOrderMap({
    required this.mapPoints,
    required this.stops,
    required this.labelData,
    required this.labelOffsets,
    required this.labelsReady,
    required this.isRtl,
    required this.onMapCreated,
    required this.onCameraMove,
    this.onCameraMoveStarted,
    this.onCameraIdle,
  });

  @override
  State<_IncomingOrderMap> createState() => _IncomingOrderMapState();
}

class _IncomingOrderMapState extends State<_IncomingOrderMap> {
  BitmapDescriptor? _laundryIcon;
  BitmapDescriptor? _homeIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    _laundryIcon = await loadMarkerIcon('assets/markers/ic_laundry.png');
    _homeIcon = await loadMarkerIcon('assets/markers/ic_home.png');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    for (var i = 0; i < widget.mapPoints.length; i++) {
      final icon = widget.stops[i].type == StopPointType.laundry
          ? (_laundryIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
          : (_homeIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ));
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: widget.mapPoints[i],
          icon: icon,
        ),
      );
    }

    final routePoints = widget.mapPoints.length >= 2
        ? buildSmoothCurvePoints(widget.mapPoints[0], widget.mapPoints[1])
        : <LatLng>[];
    final shadowPoints = routePoints.isNotEmpty
        ? offsetPolylineSouth(routePoints)
        : <LatLng>[];

    final polylines = <Polyline>{};
    if (shadowPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_shadow'),
          points: shadowPoints,
          color: Colors.black.withValues(alpha: 0.25),
          width: 10,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          geodesic: true,
        ),
      );
    }
    if (routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_main'),
          points: routePoints,
          color: const Color(0xFF1A1A1A),
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          geodesic: true,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.mapPoints.first,
            zoom: 15,
          ),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          onMapCreated: widget.onMapCreated,
          onCameraMove: (_) => widget.onCameraMove(),
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onCameraIdle: widget.onCameraIdle,
        ),
        if (widget.labelsReady)
          ...widget.labelData
              .where((l) => widget.labelOffsets[l.id] != null)
              .map((l) {
                final off = widget.labelOffsets[l.id]!;
                return Positioned(
                  left: off.dx,
                  top: off.dy,
                  child: LabeledMarkerWidget(
                    type: l.type,
                    title: l.title,
                    logoUrl: l.logoUrl,
                    textDirection: widget.isRtl
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr,
                  ),
                );
              }),
      ],
    );
  }
}

class _StopCard extends StatefulWidget {
  final StopPoint stop;
  final double distanceKm;
  final ThemeData theme;
  final bool compact;

  const _StopCard({
    required this.stop,
    required this.distanceKm,
    required this.theme,
    this.compact = false,
  });

  @override
  State<_StopCard> createState() => _StopCardState();
}

class _StopCardState extends State<_StopCard> {
  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final theme = widget.theme;
    final compact = widget.compact;
    final icon = stop.type == StopPointType.laundry
        ? Icons.local_laundry_service
        : Icons.home;
    final iconColor = stop.type == StopPointType.laundry
        ? AppTheme.primaryColor
        : Colors.deepOrange;
    final iconBgColor = iconColor.withValues(alpha: 0.1);
    final pad = compact ? 12.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: compact ? 20 : 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stop.addressLine1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stop.addressLine2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.distanceKm.toStringAsFixed(1)} km',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12 : 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Dist.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: compact ? 9 : 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopConnector extends StatelessWidget {
  final bool compact;

  const _StopConnector({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final start = compact ? 30.0 : 36.0;
    final h = compact ? 20.0 : 24.0;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: start),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Container(
              width: 2,
              height: h / 7,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
