import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/directions_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../incoming/domain/models/incoming_order_mock.dart'
    show LatLngMock, StopPoint, StopPointType;
import '../../../incoming/presentation/widgets/incoming_map_controls.dart';
import '../../../incoming/presentation/widgets/labeled_marker_widget.dart';
import '../../../incoming/utils/incoming_map_utils.dart'
    show
        kLabelBubbleHeight,
        kLabelBubbleWidth,
        kLabelGap,
        kMarkerIconSize,
        loadMarkerIcon;
import '../../../orders/data/order_session_store.dart';
import '../../../orders/domain/models/order_mock.dart';

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

class ActiveTripFullMapPage extends StatefulWidget {
  final String orderId;
  final OrderMock? initialOrder;
  final int? deliveryRiderStatus;
  final int? pickupRiderStatus;

  const ActiveTripFullMapPage({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.deliveryRiderStatus,
    this.pickupRiderStatus,
  });

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
  bool _initialMapReady = false;
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
    final order =
        widget.initialOrder ?? OrderSessionStore.getById(widget.orderId);
    if (!mounted) return;
    setState(() => _order = order);
    _maybePrepareInitialMap();
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
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        _maybePrepareInitialMap();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final hadNoLocation = _currentPosition == null;
      if (mounted) {
        setState(() => _currentPosition = pos);
      }
      if (hadNoLocation && _mapController != null && _order != null) {
        final endpoints = _getRouteEndpoints(_order!);
        if (endpoints != null) {
          final overviewPoints = _buildMapOverviewPoints(
            sourceStop: endpoints.source,
            targetStop: endpoints.target,
          );
          if (overviewPoints.length >= 2) {
            await _fitRouteOverview(
              _mapController!,
              overviewPoints,
              mapWidth: _mapWidth,
              mapHeight: _mapHeight,
            );
          }
        }
      }
      await _fetchRoute(markMapReady: true);
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
        });
        _updateLabelOffsets();
        unawaited(_fetchRoute(markMapReady: true));
      });
    } catch (_) {}
  }

  Future<void> _fetchRoute({bool markMapReady = false}) async {
    final order = _order;
    if (order == null) return;
    final polylineEndpoints = _getPolylineEndpoints(order);
    if (polylineEndpoints == null) return;
    final focusPoints = _buildRouteFocusPoints(order);

    final points = await _directionsService.getRoutePolyline(
      origin: polylineEndpoints.origin,
      destination: polylineEndpoints.destination,
    );
    if (!mounted) return;
    setState(() {
      _routePolyline = points != null && points.isNotEmpty
          ? points
          : DirectionsService.straightPolyline(
              polylineEndpoints.origin,
              polylineEndpoints.destination,
            );
      if (markMapReady) {
        _initialMapReady = true;
      }
    });
    if (!mounted || _mapController == null) return;
    if (_userMovedMap) return;
    if (focusPoints.length < 2) return;
    await _fitRouteOverview(
      _mapController!,
      focusPoints,
      mapWidth: _mapWidth,
      mapHeight: _mapHeight,
    );
    if (mounted) {
      _updateLabelOffsets();
    }
  }

  void _maybePrepareInitialMap() {
    if (_initialMapReady || _order == null || _currentPosition == null) {
      return;
    }
    unawaited(_fetchRoute(markMapReady: true));
  }

  RouteEndpoints? _getRouteEndpoints(OrderMock order) {
    final sourceLocation = _latLngOrNull(order.sourceLat, order.sourceLng);
    final targetLocation = _latLngOrNull(order.targetLat, order.targetLng);
    if (sourceLocation == null || targetLocation == null) return null;

    final sourceType = order.type == OrderTypeMock.delivery
        ? StopPointType.laundry
        : StopPointType.home;
    final targetType = order.type == OrderTypeMock.delivery
        ? StopPointType.home
        : StopPointType.laundry;

    return RouteEndpoints(
      source: StopPointWrapper(
        StopPoint(
          type: sourceType,
          title: _buildStopTitle(
            type: sourceType,
            customerName: order.customerName,
            laundryName: order.laundryName,
            address: order.sourceAddress,
          ),
          addressLine1: _addressLine1(order.sourceAddress),
          addressLine2: _addressLine2(order.sourceAddress),
          latLng: LatLngMock(sourceLocation.latitude, sourceLocation.longitude),
        ),
        addressLine1: _addressLine1(order.sourceAddress),
        addressLine2: _addressLine2(order.sourceAddress),
      ),
      target: StopPointWrapper(
        StopPoint(
          type: targetType,
          title: _buildStopTitle(
            type: targetType,
            customerName: order.customerName,
            laundryName: order.laundryName,
            address: order.targetAddress,
          ),
          addressLine1: _addressLine1(order.targetAddress),
          addressLine2: _addressLine2(order.targetAddress),
          latLng: LatLngMock(targetLocation.latitude, targetLocation.longitude),
        ),
        addressLine1: _addressLine1(order.targetAddress),
        addressLine2: _addressLine2(order.targetAddress),
        destinationLabelOverride: order.targetAddress,
      ),
    );
  }

  StopPointWrapper? _getNextStop(OrderMock order) {
    final endpoints = _getRouteEndpoints(order);
    if (endpoints == null) return null;

    if (order.type == OrderTypeMock.delivery) {
      final riderStatus = widget.deliveryRiderStatus ?? 1;
      if (riderStatus >= 3) {
        return endpoints.target;
      }
      return endpoints.source;
    }

    final pickupStatus = widget.pickupRiderStatus ?? 1;
    if (pickupStatus >= 4) {
      return endpoints.target;
    }
    return endpoints.source;
  }

  LatLng? _getCourierLatLng() {
    final position = _currentPosition;
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }

  PolylineEndpoints? _getPolylineEndpoints(OrderMock order) {
    final destinationStop = _getNextStop(order);
    if (destinationStop == null) return null;

    final courierLatLng = _getCourierLatLng();
    if (courierLatLng != null) {
      return PolylineEndpoints(
        origin: courierLatLng,
        destination: destinationStop.location,
      );
    }

    final endpoints = _getRouteEndpoints(order);
    if (endpoints == null) return null;
    return PolylineEndpoints(
      origin: endpoints.source.location,
      destination: endpoints.target.location,
    );
  }

  List<LatLng> _buildMapOverviewPoints({
    required StopPointWrapper sourceStop,
    required StopPointWrapper targetStop,
  }) {
    final points = <LatLng>[
      sourceStop.location,
      targetStop.location,
    ];
    final courierLatLng = _getCourierLatLng();
    if (courierLatLng != null) {
      points.add(courierLatLng);
    }
    return points;
  }

  List<LatLng> _buildRouteFocusPoints(OrderMock order) {
    final polylineEndpoints = _getPolylineEndpoints(order);
    if (polylineEndpoints == null) return const <LatLng>[];
    return <LatLng>[
      polylineEndpoints.origin,
      polylineEndpoints.destination,
    ];
  }

  void _runInitialFitOnce(List<LatLng> points, double mapHeight) {
    if (points.length < 2 || _mapController == null || _didInitialFit) return;
    _didInitialFit = true;
    _isProgrammaticFit = true;
    _initialBounds = _computeTripBounds(points);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted || _mapController == null) return;
      await _fitRouteOverview(
        _mapController!,
        points,
        mapWidth: _mapWidth,
        mapHeight: mapHeight,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) _updateLabelOffsets();
    });
  }

  Future<void> _resetCamera(double mapHeight) async {
    if (_mapController == null || _initialBounds == null) return;
    _isProgrammaticFit = true;
    await _resetRouteOverview(
      _mapController!,
      _initialBounds!,
      mapWidth: _mapWidth,
      mapHeight: mapHeight,
    );
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
    final l10n = _resolveL10n(context);
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.activeTripTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;
    final endpoints = _getRouteEndpoints(order);
    if (endpoints == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.activeTripTitle)),
        body: Center(child: Text(l10n.orderNotFound)),
      );
    }

    final sourceStop = endpoints.source;
    final targetStop = endpoints.target;
    final nextStop = _getNextStop(order) ?? targetStop;
    final courierLatLng = _getCourierLatLng();
    final mapPoints = _buildMapOverviewPoints(
      sourceStop: sourceStop,
      targetStop: targetStop,
    );
    final focusPoints = _buildRouteFocusPoints(order);
    final mapPadding = EdgeInsets.fromLTRB(
      112.w,
      mq.padding.top + 88.h,
      112.w,
      40.h,
    );

    _labelData = [
      _MapLabelData(
        id: 'source',
        position: sourceStop.location,
        type: sourceStop.type == StopPointType.laundry
            ? LabeledMarkerType.laundry
            : LabeledMarkerType.home,
        title: sourceStop.mapLabelTitle,
        logoUrl: null,
      ),
      _MapLabelData(
        id: 'dest',
        position: targetStop.location,
        type: targetStop.type == StopPointType.laundry
            ? LabeledMarkerType.laundry
            : LabeledMarkerType.home,
        title: targetStop.mapLabelTitle,
        logoUrl: null,
      ),
      if (courierLatLng != null)
        _MapLabelData(
          id: 'courier',
          position: courierLatLng,
          type: LabeledMarkerType.courier,
          title: 'Courier',
          logoUrl: null,
        ),
    ];
    final sourceMarkerIcon = sourceStop.type == StopPointType.laundry
        ? (_laundryIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_homeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));
    final destMarkerIcon = targetStop.type == StopPointType.laundry
        ? (_laundryIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_homeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    final routePoints = _initialMapReady
        ? (_routePolyline ?? const <LatLng>[])
        : const <LatLng>[];

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('source'),
        position: sourceStop.location,
        icon: sourceMarkerIcon,
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: targetStop.location,
        icon: destMarkerIcon,
      ),
      if (courierLatLng != null)
        Marker(
          markerId: const MarkerId('courier'),
          position: courierLatLng,
        ),
    };

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

    if (_mapController != null && !_didInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runInitialFitOnce(
          focusPoints.isNotEmpty ? focusPoints : mapPoints,
          _mapHeight,
        );
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (_initialMapReady && courierLatLng != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: sourceStop.location,
                zoom: 15,
              ),
              padding: mapPadding,
              markers: markers,
              polylines: polylines,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              onMapCreated: (c) {
                _mapController = c;
                _runInitialFitOnce(
                  focusPoints.isNotEmpty ? focusPoints : mapPoints,
                  _mapHeight,
                );
              },
              onCameraMoveStarted: () {
                if (!_isProgrammaticFit && mounted) {
                  setState(() => _userMovedMap = true);
                }
              },
              onCameraMove: (_) => _updateLabelOffsets(),
              onCameraIdle: () {
                if (!mounted) return;
                _isProgrammaticFit = false;
                _updateLabelOffsets();
              },
            )
          else
            const ColoredBox(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_initialMapReady && _labelsReady)
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
          Positioned(
            top: mq.padding.top + 56.h,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999.r),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    '${l10n.nextDestination} • ${nextStop.addressLine1}',
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
            top: mq.padding.top + 12.h,
            start: 12.w,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                onTap: () => context.go('/map-status'),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Icon(Icons.menu, color: Colors.white, size: 24.sp),
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

LatLngBounds _computeTripBounds(List<LatLng> points) {
  final first = points.first;
  var minLat = first.latitude;
  var maxLat = first.latitude;
  var minLng = first.longitude;
  var maxLng = first.longitude;

  for (final point in points.skip(1)) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
  }

  final latSpan = math.max(maxLat - minLat, 0.0001);
  final lngSpan = math.max(maxLng - minLng, 0.0001);
  final latPad = latSpan * 0.24;
  final lngPad = lngSpan * 0.24;

  return LatLngBounds(
    southwest: LatLng(minLat - latPad, minLng - lngPad),
    northeast: LatLng(maxLat + latPad, maxLng + lngPad),
  );
}

double _computeTripOverviewPadding({
  required double mapWidth,
  required double mapHeight,
}) {
  final dimension = math.min(mapWidth, mapHeight);
  return (dimension * 0.36).clamp(130.0, 240.0);
}

Future<void> _fitRouteOverview(
  GoogleMapController controller,
  List<LatLng> points, {
  required double mapWidth,
  required double mapHeight,
}) async {
  try {
    final bounds = _computeTripBounds(points);
    final padding = _computeTripOverviewPadding(
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  } catch (_) {}
}

Future<void> _resetRouteOverview(
  GoogleMapController controller,
  LatLngBounds bounds, {
  required double mapWidth,
  required double mapHeight,
}) async {
  try {
    final padding = _computeTripOverviewPadding(
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  } catch (_) {}
}

class StopPointWrapper {
  final StopPoint stop;
  final String addressLine1;
  final String addressLine2;
  final String? destinationLabelOverride;

  StopPointWrapper(
    this.stop, {
    required this.addressLine1,
    required this.addressLine2,
    this.destinationLabelOverride,
  });

  LatLng get location => LatLng(stop.latLng.lat, stop.latLng.lng);
  String get title => stop.title;
  String get mapLabelTitle {
    switch (type) {
      case StopPointType.laundry:
        final raw = title.trim();
        final prefix = 'Laundry:';
        if (raw.startsWith(prefix)) {
          final trimmed = raw.substring(prefix.length).trim();
          if (trimmed.isNotEmpty) return trimmed;
        }
        return raw.isNotEmpty ? raw : 'Laundry';
      case StopPointType.home:
        return 'Home';
    }
  }

  String get destinationLabel {
    final override = destinationLabelOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final secondLine = addressLine2.trim();
    if (secondLine.isEmpty || secondLine == addressLine1) {
      return addressLine1;
    }
    return '$addressLine1, $secondLine';
  }

  StopPointType get type => stop.type;
}

class RouteEndpoints {
  final StopPointWrapper source;
  final StopPointWrapper target;

  RouteEndpoints({
    required this.source,
    required this.target,
  });
}

class PolylineEndpoints {
  final LatLng origin;
  final LatLng destination;

  PolylineEndpoints({
    required this.origin,
    required this.destination,
  });
}

LatLng? _latLngOrNull(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;
  return LatLng(lat, lng);
}

String _buildStopTitle({
  required StopPointType type,
  required String customerName,
  required String? laundryName,
  required String? address,
}) {
  switch (type) {
    case StopPointType.laundry:
      final laundryDisplayName = _resolveLaundryDisplayName(laundryName);
      return laundryDisplayName.isEmpty
          ? 'Laundry:'
          : 'Laundry: $laundryDisplayName';
    case StopPointType.home:
      return 'Home: $customerName';
  }
}

String _resolveLaundryDisplayName(String? laundryName) {
  final trimmed = laundryName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return '';
}

String _addressLine1(String? address) {
  final parts = _normalizedAddressParts(address);
  if (parts.isEmpty) return '';
  if (parts.length >= 2) {
    return '${parts[0]}, ${parts[1]}';
  }
  return parts.isNotEmpty ? parts.first : '';
}

String _addressLine2(String? address) {
  final parts = _normalizedAddressParts(address);
  if (parts.length <= 2) return '';
  if (parts.length > 2) {
    return parts.sublist(2).join(', ');
  }
  return '';
}

List<String> _normalizedAddressParts(String? address) {
  final value = address?.trim() ?? '';
  if (value.isEmpty) return const <String>[];

  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2 &&
      parts.last.toLowerCase() == parts[parts.length - 2].toLowerCase()) {
    parts.removeLast();
  }

  return parts;
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
