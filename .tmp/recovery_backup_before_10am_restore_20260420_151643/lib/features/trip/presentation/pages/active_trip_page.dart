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
import '../../../../core/localization/app_localizations.dart';
import '../../../incoming/data/mappers/incoming_order_mapper.dart';
import '../../../incoming/domain/models/incoming_order_mock.dart'
    show StopPoint, StopPointType;
import '../../../incoming/presentation/pages/incoming_order_page.dart'
    show fitToTwoPoints;
import '../../../incoming/presentation/widgets/labeled_marker_widget.dart';
import '../../../incoming/utils/incoming_map_utils.dart'
    show kLabelBubbleHeight, kLabelBubbleWidth, kLabelGap, loadMarkerIcon;
import '../../../orders/data/mock_orders_data.dart';
import '../../../orders/domain/models/order_mock.dart';
import '../../../delivery/delivery_to_customer_page.dart';
import '../widgets/complaint_drawer_content.dart';
import '../widgets/active_order_details_sheet.dart';
import '../../../chat/customer_chat_screen.dart';

/// When true, courier marker rotates by heading (requires device heading support).
const bool enableHeadingArrow = false;

/// Generic 3-phase trip progress. Meaning depends on order type:
///   Delivery: firstStop=Laundry, secondStop=Customer
///   Pickup:   firstStop=Customer, secondStop=Laundry
enum OrderStep { atFirstStop, firstStopConfirmed, headingToSecondStop }

/// Active trip page: map top, order details below, actions.
class ActiveTripPage extends StatefulWidget {
  static const String id = '/active-trip/:orderId';

  static String path(String orderId) => '/active-trip/$orderId';
  final String orderId;

  const ActiveTripPage({super.key, required this.orderId});

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
  double _mapHeight = 0;

  static const _routeThrottleSeconds = 15;
  static const _routeThrottleMeters = 50.0;

  OrderStep _orderStep = OrderStep.atFirstStop;

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
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
        if (_order != null) _fetchRouteIfNeeded(pos);
      }
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) {
            if (mounted) {
              setState(() => _currentPosition = pos);
              _fetchRouteIfNeeded(pos);
              _updateLabelOffsets();
            }
          });
    } catch (_) {}
  }

  Future<void> _fetchRouteIfNeeded(Position current) async {
    if (_order == null) return;
    final now = DateTime.now();
    final dist = _lastRouteFetchPosition == null
        ? double.infinity
        : Geolocator.distanceBetween(
            _lastRouteFetchPosition!.latitude,
            _lastRouteFetchPosition!.longitude,
            current.latitude,
            current.longitude,
          );
    final elapsedSec = _lastRouteFetchTime == null
        ? double.infinity
        : now.difference(_lastRouteFetchTime!).inSeconds;

    if (dist < _routeThrottleMeters && elapsedSec < _routeThrottleSeconds) {
      return;
    }

    final destWrapper = _getNextStop(_order!);
    if (destWrapper == null) return;

    final dest = destWrapper.location;
    final start = LatLng(current.latitude, current.longitude);
    final points = await _directionsService.getDrivingRoutePoints(
      origin: start,
      destination: dest,
    );

    if (mounted && points.isNotEmpty) {
      setState(() {
        _routePolyline = points;
        _lastRouteFetchTime = now;
        _lastRouteFetchPosition = current;
      });
    }
  }

  StopPointWrapper? _getNextStop(OrderMock order) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;
    final incoming = fromOrderMock(order, l10n);
    final stops = incoming.buildStops();
    if (stops.isEmpty) return null;

    final StopPoint stop;
    final String addressLine1;
    final String addressLine2;

    if (order.type == OrderTypeMock.pickup) {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
        case OrderStep.firstStopConfirmed:
          stop = stops.first; // Customer
          addressLine1 = incoming.firstStopAddressLine1;
          addressLine2 = incoming.firstStopAddressLine2;
        case OrderStep.headingToSecondStop:
          stop = stops.length > 1 ? stops[1] : stops.first; // Laundry
          addressLine1 = incoming.secondStopAddressLine1;
          addressLine2 = incoming.secondStopAddressLine2;
      }
    } else {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
        case OrderStep.firstStopConfirmed:
          stop = stops.first; // Laundry
          addressLine1 = incoming.firstStopAddressLine1;
          addressLine2 = incoming.firstStopAddressLine2;
        case OrderStep.headingToSecondStop:
          stop = stops.length > 1 ? stops[1] : stops.first; // Customer
          addressLine1 = incoming.secondStopAddressLine1;
          addressLine2 = incoming.secondStopAddressLine2;
      }
    }
    return StopPointWrapper(
      stop,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
    );
  }

  Future<void> _recenterMap() async {
    if (_mapController == null || _currentPosition == null || _order == null) {
      return;
    }
    final destW = _getNextStop(_order!);
    if (destW == null) return;

    await fitToTwoPoints(
      _mapController!,
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      destW.location,
      mapHeight: _mapHeight,
    );
  }

  void _updateLabelOffsets() async {
    if (_mapController == null || _labelData.isEmpty || !mounted) return;
    final now = DateTime.now();
    if (_lastLabelUpdateTime != null &&
        now.difference(_lastLabelUpdateTime!).inMilliseconds <
            _labelUpdateThrottleMs) {
      return;
    }
    _lastLabelUpdateTime = now;

    final Map<String, Offset> newOffsets = {};
    for (final l in _labelData) {
      try {
        final screenPos = await _mapController!.getScreenCoordinate(l.position);
        newOffsets[l.id] = Offset(
          screenPos.x.toDouble() - (kLabelBubbleWidth / 2),
          screenPos.y.toDouble() - (kLabelBubbleHeight + kLabelGap),
        );
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _labelOffsets.addAll(newOffsets);
        _labelsReady = true;
      });
    }
  }

  void _onArrivedPressed() {
    final l10n = AppLocalizations.of(context)!;
    final isPickup = _order?.type == OrderTypeMock.pickup;

    switch (_orderStep) {
      case OrderStep.atFirstStop:
        setState(() => _orderStep = OrderStep.firstStopConfirmed);
        break;
      case OrderStep.firstStopConfirmed:
        if (isPickup) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DeliveryToCustomerPage(
                orderId: _order!.id,
                customerName: _order!.customerName,
                customerPhone: _order!.customerPhone,
                customerNotes: _order!.notes,
                isPickup: true,
                onComplete: () {
                  Navigator.pop(context); // Close DeliveryToCustomerPage
                  setState(() => _orderStep = OrderStep.headingToSecondStop);
                  if (_currentPosition != null) {
                    _fetchRouteIfNeeded(_currentPosition!);
                  }
                },
              ),
            ),
          );
        } else {
          // Delivery: Laundry confirmed
          _showConfirmationDialog(
            message: l10n.confirmPickupQ,
            onConfirm: () {
              setState(() => _orderStep = OrderStep.headingToSecondStop);
              if (_currentPosition != null) {
                _fetchRouteIfNeeded(_currentPosition!);
              }
            },
          );
        }
        break;
      case OrderStep.headingToSecondStop:
        if (_order == null) return;
        if (isPickup) {
          _showConfirmationDialog(
            message: l10n.confirmHandoverToLaundryQ,
            onConfirm: () => context.go('/map-status'),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DeliveryToCustomerPage(
                orderId: _order!.id,
                customerName: _order!.customerName,
                customerPhone: _order!.customerPhone,
                customerNotes: _order!.notes,
                isPickup: false,
                onComplete: () {
                  context.go('/map-status');
                },
              ),
            ),
          );
        }
        break;
    }
  }

  void _showConfirmationDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Confirm Action',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onConfirm();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.confirm,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails() {
    if (_order == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActiveOrderDetailsSheet(order: _order!),
    );
  }

  void _openHelpDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _runInitialFitOnce(LatLng courier, LatLng dest, double mapH) {
    if (_didInitialFit || _mapController == null) return;
    _didInitialFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await fitToTwoPoints(_mapController!, courier, dest, mapHeight: mapH);
      _updateLabelOffsets();
    });
  }

  String _formatEtaTimeRange(int etaMin) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final end = now.add(Duration(minutes: etaMin));
    final fmt = intl.DateFormat.jm(Localizations.localeOf(context).toString());
    return l10n.etaTimeRange(fmt.format(now), fmt.format(end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.activeTripTitle)),
        body: Center(child: Text(l10n.orderNotFound)),
      );
    }

    final order = _order!;
    final nextStopW = _getNextStop(order);
    final LatLng? destLatLng = nextStopW?.location;

    // Build label data for custom markers
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
          title: 'You',
        ),
      );
    }
    if (destLatLng != null) {
      _labelData.add(
        _MapLabelData(
          id: 'dest',
          position: destLatLng,
          type: nextStopW?.type == StopPointType.laundry
              ? LabeledMarkerType.laundry
              : LabeledMarkerType.home,
          title: nextStopW?.title ?? '',
        ),
      );
    }

    final String primaryLabel;
    final isPickup = order.type == OrderTypeMock.pickup;
    if (isPickup) {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
          primaryLabel = l10n.arrivedAtCustomer;
        case OrderStep.firstStopConfirmed:
          primaryLabel = l10n.pickedUpFromCustomerBtn;
        case OrderStep.headingToSecondStop:
          primaryLabel = l10n.deliveredToLaundryBtn;
      }
    } else {
      switch (_orderStep) {
        case OrderStep.atFirstStop:
          primaryLabel = l10n.arrivedAtLaundry;
        case OrderStep.firstStopConfirmed:
          primaryLabel = l10n.pickedUpButton;
        case OrderStep.headingToSecondStop:
          primaryLabel = l10n.arrivedAtCustomer;
      }
    }

    final mapH = mq.size.height * 0.45;
    final routePoints = _routePolyline ?? [];
    final destMarkerIcon = nextStopW?.type == StopPointType.laundry
        ? _laundryIcon ?? BitmapDescriptor.defaultMarker
        : _homeIcon ?? BitmapDescriptor.defaultMarker;

    final helpDrawer = Drawer(
      width: mq.size.width * 0.85,
      child: ComplaintDrawerContent(order: order),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isRtl ? null : helpDrawer,
      endDrawer: isRtl ? helpDrawer : null,
      body: Column(
        children: [
          // MAP SECTION
          SizedBox(
            height: mapH,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                _mapHeight = constraints.maxHeight;
                return Stack(
                  children: [
                    if (destLatLng != null) ...[
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: destLatLng,
                          zoom: 15,
                        ),
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
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
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                        },
                        polylines: routePoints.length >= 2
                            ? {
                                Polyline(
                                  polylineId: const PolylineId('r'),
                                  points: routePoints,
                                  color: AppTheme.primaryColor,
                                  width: 6,
                                  startCap: Cap.roundCap,
                                  endCap: Cap.roundCap,
                                  jointType: JointType.round,
                                ),
                              }
                            : {},
                        onMapCreated: (c) {
                          _mapController = c;
                          if (_currentPosition != null) {
                            _runInitialFitOnce(
                              LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              destLatLng,
                              mapH,
                            );
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
                                  textDirection: isRtl
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                ),
                              );
                            }),
                    ],
                    // "Next destination" pill
                    if (nextStopW != null)
                      Positioned(
                        top: mq.padding.top + 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Material(
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next destination',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    nextStopW.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (nextStopW.type ==
                                      StopPointType.laundry) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE0F2F1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF009688),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Map controls
                    PositionedDirectional(
                      bottom: 12,
                      end: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MapControlBtn(
                            icon: Icons.my_location,
                            tooltip: 'Recenter',
                            onPressed: _recenterMap,
                          ),
                          const SizedBox(height: 8),
                          _MapControlBtn(
                            icon: Icons.fullscreen,
                            tooltip: 'Expand',
                            onPressed: () =>
                                context.push('/active-trip/${order.id}/map'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // CONTENT SECTION
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & ETA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.orderNumberLabel(order.id),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatEtaTimeRange(order.etaMin),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time_filled,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Destination Detailed Info
                  if (nextStopW != null) ...[
                    Text(
                      nextStopW.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextStopW.addressLine1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      nextStopW.addressLine2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Action Buttons Row
                  LayoutBuilder(
                    builder: (ctx, consts) {
                      final btnW = (consts.maxWidth - 48) / 4;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CompactActionBtn(
                            icon: Icons.directions,
                            label: 'Directions',
                            width: btnW,
                            onTap: () {
                              if (destLatLng != null) {
                                launchUrl(
                                  Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${destLatLng.latitude},${destLatLng.longitude}&travelmode=driving',
                                  ),
                                );
                              }
                            },
                          ),
                          _CompactActionBtn(
                            icon: Icons.message_outlined,
                            label: l10n.messages,
                            width: btnW,
                            onTap: () {
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
                            },
                          ),
                          _CompactActionBtn(
                            icon: Icons.call,
                            label: l10n.call,
                            width: btnW,
                            onTap: () => launchUrl(
                              Uri.parse('tel:${order.customerPhone}'),
                            ),
                          ),
                          _CompactActionBtn(
                            icon: Icons.info_outline,
                            label: l10n.moreDetails,
                            width: btnW,
                            onTap: _showOrderDetails,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    Text(
                      l10n.customerNotes,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        order.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF444444),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // BOTTOM BUTTON
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, mq.padding.bottom + 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _onArrivedPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  onPressed: _openHelpDrawer,
                  icon: const Icon(Icons.help_outline),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
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

class StopPointWrapper {
  final StopPoint stop;
  final String addressLine1;
  final String addressLine2;

  StopPointWrapper(
    this.stop, {
    required this.addressLine1,
    required this.addressLine2,
  });

  LatLng get location => LatLng(stop.latLng.lat, stop.latLng.lng);
  String get title => stop.title;
  StopPointType get type => stop.type;
}

class _CompactActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;

  const _CompactActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
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
  _MapLabelData({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
  });
}
