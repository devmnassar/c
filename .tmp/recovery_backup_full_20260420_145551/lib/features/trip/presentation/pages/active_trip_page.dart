import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/maps/directions_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../incoming/data/mappers/incoming_order_mapper.dart';
import '../../../incoming/domain/models/incoming_order_mock.dart'
    show StopPoint, StopPointType;
import '../../../incoming/presentation/pages/incoming_order_page.dart'
    show fitToTwoPoints;
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
import '../../../chat/customer_chat_screen.dart';
import '../../../delivery/delivery_to_customer_page.dart';
import '../widgets/complaint_drawer_content.dart';

/// When true, courier marker rotates by heading (requires device heading support).
const bool enableHeadingArrow = false;

/// Generic 3-phase trip progress. Meaning depends on order type:
///   Delivery: firstStop=Laundry, secondStop=Customer
///   Pickup:   firstStop=Customer, secondStop=Laundry
enum OrderStep {
  atFirstStop,
  firstStopConfirmed,
  headingToSecondStop,
}

/// Active trip page: map top, order details below, actions.
class ActiveTripPage extends StatefulWidget {
  static const String id = '/active-trip/:orderId';

  final String orderId;

  const ActiveTripPage({
    super.key,
    required this.orderId,
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  OrderMock? _order;
  bool _loading = true;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  BitmapDescriptor? _laundryIcon;
  BitmapDescriptor? _homeIcon;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final DirectionsService _directionsService = DirectionsService();
  List<LatLng>? _routePolyline;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastRouteFetchTime;
  Position? _lastRouteFetchPosition;

  final Map<String, Offset> _labelOffsets = {};
  bool _labelsReady = false;
  DateTime? _lastLabelUpdateTime;
  static const int _labelUpdateThrottleMs = 150;
  List<_MapLabelData> _labelData = [];
  bool _didInitialFit = false;
  double _mapWidth = 0;
  double _mapHeight = 0;

  static const _routeThrottleSeconds = 15;
  static const _routeThrottleMeters = 50.0;

  OrderStep _orderStep = OrderStep.atFirstStop;

  /// Mocked unread messages count. TODO: wire to API.
  int _unreadCustomerMessagesCount = 1;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  String _formatEtaTimeRange(int etaMin) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final end = now.add(Duration(minutes: etaMin));
    final formatter = intl.DateFormat.jm(locale.toString());
    final startStr = formatter.format(now);
    final endStr = formatter.format(end);
    return l10n.etaTimeRange(startStr, endStr);
  }

  /// Next stop based on order type and current trip step.
  ///   Delivery: stops = [laundry, customer]
  ///   Pickup:   stops = [customer, laundry]
  /// At first-stop phases => stops[0]; after confirming first stop => stops[1].
  StopPoint? _getNextStop(OrderMock order) {
    final l10n = AppLocalizations.of(context)!;
    final incoming = fromOrderMock(order);
    final stops = incoming.buildStops();
    if (stops.isEmpty) return null;
    if (_orderStep == OrderStep.headingToSecondStop && stops.length >= 2) {
      return stops[1];
    }
    return stops.first;
  }

  /// Whether the order is a pickup-from-customer flow.
  bool get _isPickup => _order?.type == OrderTypeMock.pickup;

  /// Whether the current destination is the customer (for messages/notes).
  /// Delivery: customer is second stop; Pickup: customer is first stop.
  bool get _isCurrentDestCustomer {
    if (_isPickup) {
      return _orderStep != OrderStep.headingToSecondStop;
    }
    return _orderStep == OrderStep.headingToSecondStop;
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadIcons();
    _initLocation();
  }

  Future<void> _loadOrder() async {
    final order = MockOrdersData.getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
      if (order != null && _currentPosition != null) {
        _fetchRouteIfNeeded(_currentPosition!);
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
        _fetchRouteIfNeeded(pos);
      }
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _currentPosition = pos);
        _fetchRouteIfNeeded(pos);
      });
    } catch (_) {}
  }

  void _fetchRouteIfNeeded(Position pos) {
    if (_order == null) return;
    final nextStop = _getNextStop(_order!);
    if (nextStop == null) return;
    final dest = LatLng(nextStop.latLng.lat, nextStop.latLng.lng);
    final origin = LatLng(pos.latitude, pos.longitude);

    final now = DateTime.now();
    final shouldFetch = _lastRouteFetchTime == null ||
        now.difference(_lastRouteFetchTime!).inSeconds >=
            _routeThrottleSeconds ||
        (_lastRouteFetchPosition != null &&
            Geolocator.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  _lastRouteFetchPosition!.latitude,
                  _lastRouteFetchPosition!.longitude,
                ) >
                _routeThrottleMeters);

    if (!shouldFetch) return;
    _lastRouteFetchTime = now;
    _lastRouteFetchPosition = pos;
    _fetchRoute(origin, dest);
  }

  Future<void> _fetchRoute(LatLng origin, LatLng dest) async {
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

  void _runInitialFitOnce(LatLng courierPos, LatLng destPos, double mapHeight) {
    if (_mapController == null || _didInitialFit || mapHeight <= 0) return;
    _didInitialFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted || _mapController == null) return;
      await fitToTwoPoints(_mapController!, courierPos, destPos,
          mapHeight: mapHeight);
      if (mounted) _updateLabelOffsets();
    });
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

  Future<void> _recenterMap() async {
    if (_mapController == null || _order == null || _mapHeight <= 0) return;
    final nextStop = _getNextStop(_order!);
    if (nextStop == null) return;
    final destLatLng = LatLng(nextStop.latLng.lat, nextStop.latLng.lng);
    if (_currentPosition != null) {
      final courierLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      await fitToTwoPoints(_mapController!, courierLatLng, destLatLng,
          mapHeight: _mapHeight);
      if (mounted) _updateLabelOffsets();
    } else {
      _mapController!.animateCamera(CameraUpdate.newLatLng(destLatLng));
    }
  }

  Future<void> _openDirections() async {
    final nextStop = _order != null ? _getNextStop(_order!) : null;
    if (nextStop == null) return;
    final lat = nextStop.latLng.lat;
    final lng = nextStop.latLng.lng;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openCall() async {
    final nextStop = _order != null ? _getNextStop(_order!) : null;
    final phone = nextStop != null && nextStop.type == StopPointType.laundry
        ? (_order!.laundryPhone ?? _order!.customerPhone)
        : (_order?.customerPhone ?? '');
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showMoreDetailsModal() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final order = _order;
    if (order == null) return;
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final nextStop = _getNextStop(order);
    final fullAddress = nextStop != null
        ? '${nextStop.addressLine1}\n${nextStop.addressLine2}'
        : '${order.district}, ${order.area}';
    final notes = order.notes ?? '';

    final sectionTitleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    // Order type display (locale-aware)
    final orderTypeName = isRtl
        ? (order.laundryTypeNameAr ?? order.laundryTypeName)
        : (order.laundryTypeName ?? order.laundryTypeNameAr);

    final items = order.orderItems ?? [];
    final images = order.orderImages ?? [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.moreDetails,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.buildingPhotos, style: sectionTitleStyle),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, i) => Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.apartment,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.fullAddress, style: sectionTitleStyle),
                const SizedBox(height: 4),
                Text(fullAddress, style: theme.textTheme.bodyMedium),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.notes, style: sectionTitleStyle),
                  const SizedBox(height: 4),
                  Text(notes, style: theme.textTheme.bodyMedium),
                ],

                // ── Order Type ──────────────────────────────
                const SizedBox(height: 16),
                Text(l10n.orderType, style: sectionTitleStyle),
                const SizedBox(height: 4),
                Text(
                  orderTypeName ?? '-',
                  style: theme.textTheme.bodyMedium,
                ),

                // ── Order Items ─────────────────────────────
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.orderDetails, style: sectionTitleStyle),
                  const SizedBox(height: 4),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              isRtl ? item.nameAr : item.nameEn,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // ── Order Images ────────────────────────────
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (imgCtx, i) => GestureDetector(
                        onTap: () => _showFullScreenImage(imgCtx, images[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            images[i],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelpDrawer() {
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    if (isRtl) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _onArrivedPressed() {
    if (_order == null) return;
    final isDelivery = _order!.type == OrderTypeMock.delivery;

    if (!isDelivery) {
      MockOrdersData.updateOrderStatus(
          _order!.id, OrderStatusMock.arrivedAtCustomer);
      setState(() {
        _order = _order!.copyWith(status: OrderStatusMock.arrivedAtCustomer);
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.arrivedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final isPickup = _isPickup;

    switch (_orderStep) {
      case OrderStep.atFirstStop:
        _showConfirmationDialog(
          message: isPickup
              ? l10n.confirmArrivalCustomerQ
              : l10n.confirmArrivalLaundryQ,
          onConfirm: () {
            setState(() => _orderStep = OrderStep.firstStopConfirmed);
          },
        );
      case OrderStep.firstStopConfirmed:
        _showConfirmationDialog(
          message: isPickup ? l10n.confirmPickupQ : l10n.confirmPickupQ,
          onConfirm: () {
            setState(() {
              _orderStep = OrderStep.headingToSecondStop;
              _routePolyline = null;
              _lastRouteFetchTime = null;
              _lastRouteFetchPosition = null;
              _didInitialFit = false;
            });
            if (_currentPosition != null) {
              _fetchRouteIfNeeded(_currentPosition!);
            }
          },
        );
      case OrderStep.headingToSecondStop:
        if (_order == null) return;
        if (isPickup) {
          // Pickup: second stop is laundry — confirm handover
          _showConfirmationDialog(
            message: l10n.confirmHandoverToLaundryQ,
            onConfirm: () {
              // TODO: send delivery-to-laundry confirmation to API
              context.go('/map-status');
            },
          );
        } else {
          // Delivery: second stop is customer — open delivery page
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DeliveryToCustomerPage(
                orderId: _order!.id,
                customerName: _order!.customerName,
                customerPhone: _order!.customerPhone,
                customerNotes: _order!.notes,
                // TODO: wire buildingNo, floorNo, apartmentNo from backend
              ),
            ),
          );
        }
    }
  }

  void _showConfirmationDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _openMessages() {
    final order = _order;
    if (order == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerChatScreen(
          orderId: order.id,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height - mq.padding.top - mq.padding.bottom;
    final isRtl =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.activeTripTitle)),
        body: Center(
          child: Text(
            l10n.orderNotFound,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final order = _order!;
    final nextStop = _getNextStop(order);
    final destLatLng = nextStop != null
        ? LatLng(nextStop.latLng.lat, nextStop.latLng.lng)
        : null;
    final hasLocation = destLatLng != null;

    final mapH = (screenH * 0.55).clamp(200.0, 400.0);

    _mapWidth = mq.size.width;
    _mapHeight = mapH;

    _labelData = [];
    if (_currentPosition != null) {
      _labelData.add(_MapLabelData(
        id: 'courier',
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        type: LabeledMarkerType.courier,
        title: l10n.stepCourier,
      ));
    }
    if (destLatLng != null) {
      _labelData.add(_MapLabelData(
        id: 'dest',
        position: destLatLng,
        type: nextStop != null && nextStop.type == StopPointType.laundry
            ? LabeledMarkerType.laundry
            : LabeledMarkerType.home,
        title: nextStop?.title ??
            (nextStop != null && nextStop.type == StopPointType.laundry
                ? l10n.labelLaundry
                : l10n.labelHome),
        logoUrl: null,
      ));
    }

    final nextStopTitle = nextStop?.title ?? '${order.district}, ${order.area}';
    final nextStopAddress = nextStop != null
        ? '${nextStop.addressLine1}\n${nextStop.addressLine2}'
        : '${order.district}, ${order.area}';
    final isDelivery = order.type == OrderTypeMock.delivery;

    final String primaryLabel;
    if (isDelivery) {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
          primaryLabel = l10n.arrivedAtLaundry;
        case OrderStep.firstStopConfirmed:
          primaryLabel = l10n.pickedUpButton;
        case OrderStep.headingToSecondStop:
          primaryLabel = l10n.arrivedAtCustomer;
      }
    } else {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
          primaryLabel = l10n.arrivedAtCustomer;
        case OrderStep.firstStopConfirmed:
          primaryLabel = l10n.pickedUpFromCustomerBtn;
        case OrderStep.headingToSecondStop:
          primaryLabel = l10n.deliveredToLaundryBtn;
      }
    }

    final destMarkerIcon = nextStop != null &&
            nextStop.type == StopPointType.laundry
        ? (_laundryIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue))
        : (_homeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

    final routePoints = _routePolyline ??
        (_currentPosition != null && destLatLng != null
            ? DirectionsService.straightPolyline(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                destLatLng,
              )
            : <LatLng>[]);

    final helpDrawer = Drawer(
      child: const ComplaintDrawerContent(),
    );

    if (_mapController != null &&
        _currentPosition != null &&
        destLatLng != null &&
        !_didInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final courierLatLng =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        _runInitialFitOnce(courierLatLng, destLatLng, mapH);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isRtl ? null : helpDrawer,
      endDrawer: isRtl ? helpDrawer : null,
      body: Column(
        children: [
          // Map
          SizedBox(
            height: mapH,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (destLatLng != null) ...[
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: destLatLng,
                      zoom: 15,
                    ),
                    mapType: MapType.normal,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('dest'),
                        position: destLatLng,
                        icon: destMarkerIcon,
                      ),
                      if (_currentPosition != null)
                        Marker(
                          markerId: const MarkerId('courier'),
                          position: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          rotation: enableHeadingArrow
                              ? _currentPosition!.heading
                              : 0.0,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                    },
                    polylines: routePoints.length >= 2
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
                        : {},
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (c) {
                      _mapController = c;
                      if (_currentPosition != null) {
                        final courierLatLng = LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude);
                        _runInitialFitOnce(courierLatLng, destLatLng, mapH);
                      }
                    },
                    onCameraMove: (_) => _updateLabelOffsets(),
                  ),
                  if (_labelsReady)
                    ..._labelData
                        .where((l) => _labelOffsets[l.id] != null)
                        .map((l) {
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
                ] else
                  Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Text(
                        l10n.noCoordinatesAvailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                // Destination label pill (below menu, centered)
                if (nextStop != null)
                  PositionedDirectional(
                    top: mq.padding.top + 56,
                    start: 0,
                    end: 0,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.nextDestination,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  nextStop.title,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '1',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Menu icon top-left
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
                        child: Icon(Icons.menu, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
                // Map controls: expand/collapse, recenter
                PositionedDirectional(
                  bottom: 12,
                  end: isRtl ? null : 12,
                  start: isRtl ? 12 : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasLocation)
                        _MapControlBtn(
                          icon: Icons.my_location,
                          tooltip: l10n.resetMap,
                          onPressed: _recenterMap,
                        ),
                      const SizedBox(width: 8),
                      _MapControlBtn(
                        icon: Icons.fullscreen,
                        tooltip: l10n.expandMap,
                        onPressed: () =>
                            context.push('/active-trip/${order.id}/map'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content below map
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.orderNumberLabel(order.id),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatEtaTimeRange(order.etaMin),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextStopTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextStopAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Action row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.directions,
                          label: l10n.directions,
                          onTap: _openDirections,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.phone,
                          label: l10n.call,
                          onTap: _openCall,
                        ),
                      ),
                      if (_isCurrentDestCustomer) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.message_outlined,
                            label: l10n.messages,
                            onTap: _openMessages,
                            badgeCount: _unreadCustomerMessagesCount,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.info_outline,
                          label: l10n.moreDetails,
                          onTap: _showMoreDetailsModal,
                        ),
                      ),
                    ],
                  ),
                  if (_isCurrentDestCustomer &&
                      order.notes != null &&
                      order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.customerNotes,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bottom buttons
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, mq.padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _onArrivedPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  child: Tooltip(
                    message: l10n.help,
                    child: OutlinedButton(
                      onPressed: _openHelpDrawer,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Icon(Icons.help_outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 22, color: AppTheme.primaryColor);
    if (badgeCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
