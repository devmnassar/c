import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../l10n/app_localizations.dart';
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
import '../pages/incoming_order_page.dart'
    show
        buildSmoothCurvePoints,
        computeBoundsForTwoPoints,
        fitToTwoPoints,
        resetToInitialBounds;
import '../widgets/incoming_map_controls.dart';
import '../widgets/labeled_marker_widget.dart';

/// Fullscreen map for incoming order. Same markers, polyline, labels, camera fit.
class IncomingOrderFullMapPage extends StatefulWidget {
  static const String id = '/incoming-order/map';

  final OrderMock order;
  const IncomingOrderFullMapPage({super.key, required this.order});
  @override
  State<IncomingOrderFullMapPage> createState() =>
      _IncomingOrderFullMapPageState();
}

class _IncomingOrderFullMapPageState extends State<IncomingOrderFullMapPage> {
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

  BitmapDescriptor? _laundryIcon;
  BitmapDescriptor? _homeIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void dispose() {
    _cameraMoveDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    _laundryIcon = await loadMarkerIcon('assets/markers/ic_laundry.png');
    _homeIcon = await loadMarkerIcon('assets/markers/ic_home.png');
    if (mounted) setState(() {});
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
      if (mounted)
        setState(() {
          _labelOffsets.clear();
          _labelsReady = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    _mapWidth = mq.size.width;
    _mapHeight = mq.size.height;
    final l10n = AppLocalizations.of(context)!;
    final incoming = fromOrderMock(widget.order);
    final stops = incoming.buildStops();
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final mapPoints =
        stops.map((s) => LatLng(s.latLng.lat, s.latLng.lng)).toList();

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

    final screenH = MediaQuery.of(context).size.height;
    final mapH = screenH;

    final markers = <Marker>{};
    for (var i = 0; i < mapPoints.length; i++) {
      final icon = stops[i].type == StopPointType.laundry
          ? (_laundryIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
          : (_homeIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ));
      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: mapPoints[i],
          icon: icon,
        ),
      );
    }

    final routePoints = mapPoints.length >= 2
        ? buildSmoothCurvePoints(mapPoints[0], mapPoints[1])
        : <LatLng>[];
    final shadowPoints =
        routePoints.isNotEmpty ? offsetPolylineSouth(routePoints) : <LatLng>[];

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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapPoints.first,
              zoom: 15,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (c) {
              _mapController = c;
              _runInitialFitOnce(mapPoints, mapH);
            },
            onCameraMove: (_) {
              _cameraMoveDebounce?.cancel();
              _cameraMoveDebounce = Timer(
                const Duration(milliseconds: _labelUpdateThrottleMs),
                () {
                  if (mounted) _updateLabelOffsets();
                },
              );
            },
            onCameraMoveStarted: () {
              if (!_isProgrammaticFit && mounted)
                setState(() => _userMovedMap = true);
            },
            onCameraIdle: () {
              if (mounted) _isProgrammaticFit = false;
            },
          ),
          if (_labelsReady)
            ..._labelData.where((l) => _labelOffsets[l.id] != null).map((l) {
              final off = _labelOffsets[l.id]!;
              return Positioned(
                left: off.dx,
                top: off.dy,
                child: LabeledMarkerWidget(
                  type: l.type,
                  title: l.title,
                  logoUrl: l.logoUrl,
                  textDirection:
                      isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              );
            }),
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 12,
            start: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.go('/map-status'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.menu, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          IncomingFullMapControls(
            showReset: _userMovedMap,
            onClose: () => context.pop(),
            onReset: _userMovedMap ? () => _resetCamera(mapH) : null,
            isRtl: isRtl,
          ),
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
