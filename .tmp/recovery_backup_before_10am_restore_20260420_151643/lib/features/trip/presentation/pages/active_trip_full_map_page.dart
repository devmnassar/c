import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/directions_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../incoming/data/mappers/incoming_order_mapper.dart';
import '../../../incoming/domain/models/incoming_order_mock.dart'
    show StopPoint, StopPointType;
import '../../../incoming/presentation/pages/incoming_order_page.dart'
    show computeBoundsForTwoPoints, fitToTwoPoints, resetToInitialBounds;
import '../../../incoming/presentation/widgets/incoming_map_controls.dart';
import '../../../incoming/presentation/widgets/labeled_marker_widget.dart';
import '../../../incoming/utils/incoming_map_utils.dart'
    show
        kLabelBubbleHeight,
        kLabelBubbleWidth,
        kLabelGap,
        kMarkerIconSize,
        loadMarkerIcon;
import '../../../orders/data/mock_orders_data.dart';
import '../../../orders/domain/models/order_mock.dart';

/// Full-screen map for active trip. Same markers (courier + destination), route, labels, recenter.
class ActiveTripFullMapPage extends StatefulWidget {
  static const String id = '/active-trip/:orderId/map';

  static String path(String orderId) => '/active-trip/$orderId/map';
  final String orderId;
  const ActiveTripFullMapPage({super.key, required this.orderId});
  @override
  State<ActiveTripFullMapPage> createState() => _ActiveTripFullMapPageState();
}

class _ActiveTripFullMapPageState extends State<ActiveTripFullMapPage> {
  OrderMock? _order;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  final Map<String, Offset> _labelOffsets = {};
  bool _labelsReady = false;
  DateTime? _lastLabelUpdateTime;
  static const int _labelUpdateThrottleMs = 150;

  List<_MapLabelData> _labelData = [];
  LatLngBounds? _initialBounds;
  bool _userMovedMap = false;
  bool _isProgrammaticFit = false;
  bool _didInitialFit = false;
  double _mapWidth = 0;
  double _mapHeight = 0;

  BitmapDescriptor? _laundryIcon;
  BitmapDescriptor? _homeIcon;
  final DirectionsService _directionsService = DirectionsService();
  List<LatLng>? _routePolyline;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadIcons();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    final order = MockOrdersData.getOrderById(widget.orderId);
    if (mounted) {
      setState(() => _order = order);
      if (order != null && _currentPosition != null) {
        _fetchRoute();
      }
    }
  }

  Future<void> _loadIcons() async {
    final laundry = await loadMarkerIcon('assets/markers/ic_laundry.png');
    final home = await loadMarkerIcon('assets/markers/ic_home.png');
    if (mounted) {
      setState(() {
        _laundryIcon = laundry;
        _homeIcon = home;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
        _fetchRoute();
      }
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            if (!mounted) return;
            setState(() => _currentPosition = pos);
          });
    } catch (_) {}
  }

  Future<void> _fetchRoute() async {
    if (_order == null || _currentPosition == null) return;
    final nextStop = _getNextStop(_order!);
    if (nextStop == null) return;
    final origin = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final dest = LatLng(nextStop.latLng.lat, nextStop.latLng.lng);
    final points = await _directionsService.getRoutePolyline(
      origin: origin,
      destination: dest,
    );
    if (!mounted) return;
    setState(() {
      _routePolyline =
          points ?? DirectionsService.straightPolyline(origin, dest);
    });
  }

  StopPoint? _getNextStop(OrderMock order) {
    final l10n = AppLocalizations.of(context)!;
    final incoming = fromOrderMock(order, l10n);
    final stops = incoming.buildStops();
    return stops.isNotEmpty ? stops.first : null;
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
    final mq = MediaQuery.of(context);
    _mapWidth = mq.size.width;
    _mapHeight = mq.size.height;
    final l10n = AppLocalizations.of(context)!;
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.activeTripTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;
    final nextStop = _getNextStop(order);
    final destLatLng = nextStop != null
        ? LatLng(nextStop.latLng.lat, nextStop.latLng.lng)
        : null;

    final mapPoints = <LatLng>[];
    if (_currentPosition != null) {
      mapPoints.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }
    if (destLatLng != null) {
      mapPoints.add(destLatLng);
    }

    _labelData = [];
    if (_currentPosition != null) {
      _labelData.add(
        _MapLabelData(
          id: 'courier',
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          type: LabeledMarkerType.courier,
          title: l10n.stepCourier,
          logoUrl: null,
        ),
      );
    }
    if (destLatLng != null) {
      _labelData.add(
        _MapLabelData(
          id: 'dest',
          position: destLatLng,
          type: nextStop != null && nextStop.type == StopPointType.laundry
              ? LabeledMarkerType.laundry
              : LabeledMarkerType.home,
          title:
              nextStop?.title ??
              (nextStop != null && nextStop.type == StopPointType.laundry
                  ? l10n.labelLaundry
                  : l10n.labelHome),
          logoUrl: null,
        ),
      );
    }

    final destMarkerIcon =
        nextStop != null && nextStop.type == StopPointType.laundry
        ? (_laundryIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_homeIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ));

    final routePoints =
        _routePolyline ??
        (mapPoints.length >= 2
            ? DirectionsService.straightPolyline(mapPoints[0], mapPoints[1])
            : <LatLng>[]);

    final markers = <Marker>{};
    if (destLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dest'),
          position: destLatLng,
          icon: destMarkerIcon,
        ),
      );
    }
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('courier'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    final polylines = routePoints.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: const Color(0xFF1A1A1A),
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              geodesic: true,
            ),
          }
        : <Polyline>{};

    final initialTarget =
        destLatLng ??
        (mapPoints.isNotEmpty ? mapPoints.first : const LatLng(0, 0));

    if (mapPoints.length >= 2 && _mapController != null && !_didInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runInitialFitOnce(mapPoints, _mapHeight);
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (c) {
              _mapController = c;
              if (mapPoints.length >= 2) {
                _runInitialFitOnce(mapPoints, _mapHeight);
              }
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
                  textDirection: isRtl
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                ),
              );
            }),
          if (nextStop != null)
            Positioned(
              top: mq.padding.top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      '${l10n.nextDestination} • ${nextStop.title}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            top: mq.padding.top + 12,
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
            onReset: _userMovedMap ? () => _resetCamera(_mapHeight) : null,
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
