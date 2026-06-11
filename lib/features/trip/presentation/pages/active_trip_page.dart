import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/maps/directions_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../incoming/data/mappers/mobile_order_to_order_mock_mapper.dart';
import '../../../incoming/domain/models/incoming_order_mock.dart'
    show LatLngMock, StopPoint, StopPointType;
import '../../../incoming/presentation/widgets/labeled_marker_widget.dart';
import '../../../incoming/utils/incoming_map_utils.dart'
    show
        kLabelBubbleHeight,
        kLabelBubbleWidth,
        kLabelGap,
        kMarkerIconSize,
        loadMarkerIcon;
import '../../../orders/data/order_session_store.dart';
import '../../../orders/domain/models/mobile_order.dart';
import '../../../orders/domain/models/proof_photo_upload_result.dart';
import '../../../orders/domain/models/order_mock.dart';
import '../../../orders/domain/usecases/get_current_order_use_case.dart';
import '../../../orders/domain/usecases/update_rider_status_use_case.dart';
import '../../../delivery/delivery_to_customer_page.dart';
import '../../../courier_profile/data/datasources/courier_profile_local_data_source.dart';
import '../cubit/pickup_status_cubit.dart';
import '../widgets/active_order_details_sheet.dart';
import '../widgets/active_trip_compact_action_button.dart';
import '../widgets/active_trip_map_control_button.dart';
import '../widgets/complaint_drawer_content.dart';
import '../../../chat/customer_chat_screen.dart';

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

/// When true, courier marker rotates by heading (requires device heading support).
const bool enableHeadingArrow = false;

/// Active trip page: map top, order details below, actions.
class ActiveTripPage extends StatefulWidget {
  final String orderId;
  final OrderMock? initialOrder;
  final String entrySource;

  const ActiveTripPage({
    super.key,
    required this.orderId,
    this.initialOrder,
    this.entrySource = 'map-status',
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  static const int _fullTimeCourierTypeId = 3;
  static const int _deliveryStatusPendingStart = 0;
  static const int _riderStatusEnRouteToLaundry = 1;
  static const int _riderStatusArrivedAtLaundry = 2;
  static const int _riderStatusPickedUp = 3;
  static const int _riderStatusEnRouteToCustomer = 4;
  static const int _riderStatusArrivedAtCustomer = 5;
  static const int _pickupStatusPendingStart = 0;
  static const int _pickupStatusEnRouteToCustomer = 1;
  static const int _pickupStatusArrivedAtCustomer = 2;
  static const int _pickupStatusPickedUp = 3;
  static const int _pickupStatusEnRouteToLaundry = 4;
  static const int _pickupStatusArrivedAtLaundry = 5;
  static const int _pickupStatusDroppedOffAtLaundry = 6;

  OrderMock? _order;
  bool _loading = true;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final ValueNotifier<BitmapDescriptor?> _laundryIconNotifier =
      ValueNotifier<BitmapDescriptor?>(null);
  final ValueNotifier<BitmapDescriptor?> _homeIconNotifier =
      ValueNotifier<BitmapDescriptor?>(null);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final DirectionsService _directionsService = DirectionsService();
  List<LatLng>? _routePolyline;
  StreamSubscription<Position>? _positionSubscription;

  final Map<String, Offset> _labelOffsets = {};
  bool _labelsReady = false;
  bool _initialMapReady = false;
  DateTime? _lastLabelUpdateTime;
  static const int _labelUpdateThrottleMs = 150;
  List<_MapLabelData> _labelData = [];
  bool _didInitialFit = false;
  double _mapWidth = 0;
  double _mapHeight = 0;

  int? _deliveryRiderStatus;
  int? _pickupRiderStatus;
  int? _cachedCourierTypeId;
  bool _useFullTimeInitialDeliveryStep = false;
  bool _useFullTimeInitialPickupStep = false;
  bool _isUpdatingRiderStatus = false;
  bool _openedDeliveryConfirmationPage = false;
  bool _openedPickupConfirmationPage = false;
  bool _isTransitioningToPickupConfirmation = false;
  bool _isCurrentActiveOrder = false;
  late final PickupStatusCubit _pickupStatusCubit;
  final GetCurrentOrderUseCase _getCurrentOrderUseCase =
      getIt<GetCurrentOrderUseCase>();
  final UpdateRiderStatusUseCase _updateRiderStatusUseCase =
      getIt<UpdateRiderStatusUseCase>();
  final CourierProfileLocalDataSource _courierProfileLocalDataSource =
      getIt<CourierProfileLocalDataSource>();

  void _log(String message) {
    debugPrint('================ ACTIVE TRIP FLOW ================');
    debugPrint('[ACTIVE TRIP FLOW] $message');
  }

  @override
  void initState() {
    super.initState();
    _pickupStatusCubit = getIt<PickupStatusCubit>();
    _log('initState orderId=${widget.orderId}');
    _loadOrder();
    _loadIcons();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    _laundryIconNotifier.dispose();
    _homeIconNotifier.dispose();
    _pickupStatusCubit.close();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    await _loadCachedCourierTypeId();
    final order = widget.initialOrder;
    _log(
      '_loadOrder started. initialOrderFromRoute=${widget.initialOrder != null}, '
      'sessionOrderFound=${order != null}',
    );
    if (order != null && mounted) {
      setState(() {
        _order = order;
        _loading = false;
        _isCurrentActiveOrder = _shouldUseOrdersListFlow;
        _applyStepStateFromOrder(order);
      });
      _maybePrepareInitialMap();
      if (_shouldUseOrdersListFlow) {
        _log(
          'Using selected order item from orders list as source of truth '
          'for fulltime courier. Skipping current order sync.',
        );
        _log('_loadOrder finished');
        return;
      }
    }
    await _syncCurrentOrder();
    _log('_loadOrder finished');
  }

  Future<void> _loadCachedCourierTypeId() async {
    final courierTypeId = await _courierProfileLocalDataSource
        .getCachedCourierTypeId();
    _cachedCourierTypeId = courierTypeId;
    _log('Loaded cached courierTypeId=$courierTypeId in active trip');
  }

  bool get _isFullTimeCourier => _cachedCourierTypeId == _fullTimeCourierTypeId;

  bool get _shouldUseOrdersListFlow =>
      _isFullTimeCourier &&
      widget.entrySource == 'orders' &&
      widget.initialOrder != null;

  int get _effectiveDeliveryRiderStatus {
    if (_useFullTimeInitialDeliveryStep) {
      return _deliveryStatusPendingStart;
    }
    return _deliveryRiderStatus ?? _riderStatusEnRouteToLaundry;
  }

  int get _effectivePickupRiderStatus {
    if (_useFullTimeInitialPickupStep) {
      return _pickupStatusPendingStart;
    }
    return _pickupRiderStatus ?? _pickupStatusEnRouteToCustomer;
  }

  void _applyStepStateFromOrder(OrderMock order) {
    if (order.type == OrderTypeMock.delivery) {
      _deliveryRiderStatus = _mapRiderStatusValue(order.riderStatus);
      _pickupRiderStatus = null;
      _useFullTimeInitialDeliveryStep = order.riderStatus == null;
      _useFullTimeInitialPickupStep = false;
      return;
    }

    _pickupRiderStatus = _mapPickupRiderStatusValue(order.pickupRiderStatus);
    _deliveryRiderStatus = null;
    _useFullTimeInitialPickupStep = order.pickupRiderStatus == null;
    _useFullTimeInitialDeliveryStep = false;
  }

  Future<void> _loadIcons() async {
    final laundry = await loadMarkerIcon('assets/markers/ic_laundry.png');
    final home = await loadMarkerIcon('assets/markers/ic_home.png');
    if (!mounted) return;
    _laundryIconNotifier.value = laundry;
    _homeIconNotifier.value = home;
  }

  Future<void> _initLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        _maybePrepareInitialMap();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final hadNoLocation = _currentPosition == null;
      if (mounted) {
        setState(() => _currentPosition = pos);
      }
      if (hadNoLocation && _mapController != null && _order != null) {
        await _recenterMap();
      }
      unawaited(_fetchOrderRoute(markMapReady: true));
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) {
            if (mounted) {
              setState(() {
                _currentPosition = pos;
              });
              _updateLabelOffsets();
            }
            unawaited(_fetchOrderRoute(markMapReady: true));
          });
    } catch (_) {}
  }

  Future<void> _fetchOrderRoute({bool markMapReady = false}) async {
    final order = _order;
    if (order == null) return;
    final polylineEndpoints = _getPolylineEndpoints(order);
    if (polylineEndpoints == null) return;

    final points = await _directionsService.getDrivingRoutePoints(
      origin: polylineEndpoints.origin,
      destination: polylineEndpoints.destination,
    );

    if (!mounted) return;
    setState(() {
      _routePolyline = points.isNotEmpty
          ? points
          : DirectionsService.straightPolyline(
              polylineEndpoints.origin,
              polylineEndpoints.destination,
            );
      if (markMapReady) {
        _initialMapReady = true;
      }
    });
  }

  void _maybePrepareInitialMap() {
    if (_initialMapReady || _order == null || _currentPosition == null) {
      return;
    }
    unawaited(_fetchOrderRoute(markMapReady: true));
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
      final riderStatus = _effectiveDeliveryRiderStatus;
      if (riderStatus >= _riderStatusPickedUp) {
        return endpoints.target;
      }
      return endpoints.source;
    }

    final pickupStatus = _effectivePickupRiderStatus;
    if (pickupStatus >= _pickupStatusPickedUp) {
      return endpoints.target;
    }
    return endpoints.source;
  }

  StopPointWrapper? _getDisplayedDetailsStop(OrderMock order) {
    final endpoints = _getRouteEndpoints(order);
    if (endpoints == null) return null;

    if (order.type == OrderTypeMock.pickup) {
      final pickupStatus = _effectivePickupRiderStatus;
      if (pickupStatus >= _pickupStatusPickedUp) {
        return endpoints.target;
      }
      return endpoints.source;
    }

    final riderStatus = _effectiveDeliveryRiderStatus;
    if (riderStatus >= _riderStatusPickedUp) {
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
    StopPointWrapper? sourceStop,
    StopPointWrapper? targetStop,
  }) {
    final points = <LatLng>[];
    if (sourceStop != null) points.add(sourceStop.location);
    if (targetStop != null) points.add(targetStop.location);
    final courierLatLng = _getCourierLatLng();
    if (courierLatLng != null) points.add(courierLatLng);
    return points;
  }

  List<LatLng> _buildRouteFocusPoints(OrderMock order) {
    final polylineEndpoints = _getPolylineEndpoints(order);
    if (polylineEndpoints == null) return const <LatLng>[];
    return <LatLng>[polylineEndpoints.origin, polylineEndpoints.destination];
  }

  Future<void> _syncCurrentOrder({bool showError = false}) async {
    if (_shouldUseOrdersListFlow) {
      _log(
        '_syncCurrentOrder skipped because fulltime courier is using '
        'orders-list item flow',
      );
      return;
    }
    _log('_syncCurrentOrder started. showError=$showError');
    final result = await _getCurrentOrderUseCase();
    if (!mounted) return;

    result.fold(
      (error) {
        _log('_syncCurrentOrder failed: ${error.message}');
        if (!showError) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (order) {
        if (order == null || order.id.toString() != widget.orderId) {
          if (mounted) {
            setState(() {
              _loading = false;
              _isCurrentActiveOrder = false;
            });
          }
          _log(
            '_syncCurrentOrder ignored result. '
            'returnedOrderId=${order?.id}, expectedOrderId=${widget.orderId}',
          );
          return;
        }

        final liveOrder = fromMobileOrder(order);
        final existingOrder = _order;
        final mappedOrder = existingOrder != null
            ? mergeOrderWithLiveProgress(
                displayOrder: existingOrder,
                liveOrder: liveOrder,
              )
            : liveOrder;
        OrderSessionStore.upsert(mappedOrder);

        setState(() {
          _order = mappedOrder;
          _loading = false;
          _isCurrentActiveOrder = true;
          _useFullTimeInitialDeliveryStep =
              mappedOrder.type == OrderTypeMock.delivery &&
              order.riderStatus == null;
          _useFullTimeInitialPickupStep =
              mappedOrder.type == OrderTypeMock.pickup &&
              order.pickupRiderStatus == null;
          if (mappedOrder.type == OrderTypeMock.delivery) {
            _deliveryRiderStatus = _mapRiderStatusValue(order.riderStatus);
          } else {
            _pickupRiderStatus =
                _mapPickupRiderStatusValue(order.pickupRiderStatus) ??
                _pickupRiderStatus;
          }
        });
        _log(
          '_syncCurrentOrder success. orderId=${order.id}, '
          'backendRiderStatus=${order.riderStatus}, '
          'backendPickupRiderStatus=${order.pickupRiderStatus}, '
          'mappedDeliveryRiderStatus=$_deliveryRiderStatus, '
          'mappedPickupRiderStatus=$_pickupRiderStatus, '
          'useFullTimeInitialDeliveryStep=$_useFullTimeInitialDeliveryStep, '
          'useFullTimeInitialPickupStep=$_useFullTimeInitialPickupStep, '
          'orderType=${mappedOrder.type}',
        );

        _maybePrepareInitialMap();

        _handleDeliveryScreenNavigation();
        _handlePickupScreenNavigation();
      },
    );
  }

  int? _mapRiderStatusValue(MobileRiderStatus? status) {
    switch (status) {
      case MobileRiderStatus.enRouteToLaundry:
        return _riderStatusEnRouteToLaundry;
      case MobileRiderStatus.arrivedAtLaundry:
        return _riderStatusArrivedAtLaundry;
      case MobileRiderStatus.pickedUp:
        return _riderStatusPickedUp;
      case MobileRiderStatus.enRouteToCustomer:
        return _riderStatusEnRouteToCustomer;
      case MobileRiderStatus.arrivedAtCustomer:
        return _riderStatusArrivedAtCustomer;
      case MobileRiderStatus.delivered:
        return 6;
      case MobileRiderStatus.attemptedDelivery:
        return 7;
      case MobileRiderStatus.unknown:
      case null:
        return null;
    }
  }

  int? _mapPickupRiderStatusValue(MobilePickupRiderStatus? status) {
    switch (status) {
      case MobilePickupRiderStatus.enRouteToCustomer:
        return _pickupStatusEnRouteToCustomer;
      case MobilePickupRiderStatus.arrivedAtCustomer:
        return _pickupStatusArrivedAtCustomer;
      case MobilePickupRiderStatus.pickedUp:
        return _pickupStatusPickedUp;
      case MobilePickupRiderStatus.enRouteToLaundry:
        return _pickupStatusEnRouteToLaundry;
      case MobilePickupRiderStatus.arrivedAtLaundry:
        return _pickupStatusArrivedAtLaundry;
      case MobilePickupRiderStatus.droppedOffAtLaundry:
        return _pickupStatusDroppedOffAtLaundry;
      case MobilePickupRiderStatus.unknown:
      case null:
        return null;
    }
  }

  void _handleDeliveryScreenNavigation() {
    if (!mounted || _order == null || _order!.type != OrderTypeMock.delivery) {
      return;
    }

    final riderStatus = _effectiveDeliveryRiderStatus;
    _log('_handleDeliveryScreenNavigation riderStatus=$riderStatus');
    if (riderStatus == _riderStatusArrivedAtCustomer) {
      _openDeliveryConfirmationPage();
      return;
    }

    if (riderStatus == 6 || riderStatus == 7) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/map-status');
        }
      });
    }
  }

  void _handlePickupScreenNavigation() {
    if (!mounted || _order == null || _order!.type != OrderTypeMock.pickup) {
      return;
    }

    final pickupStatus = _effectivePickupRiderStatus;
    _log('_handlePickupScreenNavigation pickupStatus=$pickupStatus');
    if (pickupStatus == _pickupStatusArrivedAtCustomer) {
      _openPickupConfirmationPage();
    }
  }

  Future<void> _advanceDeliveryRiderStatus(
    int nextStatus, {
    VoidCallback? onSuccess,
  }) async {
    if (_order == null || _isUpdatingRiderStatus) return;

    _log(
      '_advanceDeliveryRiderStatus started. '
      'orderId=${_order!.id}, current=$_deliveryRiderStatus, next=$nextStatus',
    );
    setState(() => _isUpdatingRiderStatus = true);
    final result = await _updateRiderStatusUseCase(
      orderId: _order!.id,
      status: nextStatus,
    );

    if (!mounted) return;

    final succeeded = result.fold(
      (error) {
        _log(
          '_advanceDeliveryRiderStatus failed. '
          'orderId=${_order!.id}, next=$nextStatus, error=${error.message}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      },
      (_) {
        _log(
          '_advanceDeliveryRiderStatus success. '
          'orderId=${_order!.id}, next=$nextStatus',
        );
        setState(() {
          _deliveryRiderStatus = nextStatus;
          _useFullTimeInitialDeliveryStep = false;
        });
        return true;
      },
    );

    if (!mounted) return;
    setState(() => _isUpdatingRiderStatus = false);

    if (!succeeded) {
      if (!_shouldUseOrdersListFlow) {
        await _syncCurrentOrder();
      }
      return;
    }

    if (nextStatus >= _riderStatusPickedUp) {
      _fetchOrderRoute();
    }

    if (!_shouldUseOrdersListFlow) {
      await _syncCurrentOrder();
    }
    if (!mounted) return;
    _log(
      '_advanceDeliveryRiderStatus completed. '
      'latestLocalRiderStatus=$_deliveryRiderStatus',
    );
    onSuccess?.call();
  }

  void _openDeliveryConfirmationPage() {
    if (_openedDeliveryConfirmationPage || _order == null || !mounted) {
      return;
    }

    _log(
      '_openDeliveryConfirmationPage orderId=${_order!.id} '
      'customer=${_order!.customerName}',
    );
    _openedDeliveryConfirmationPage = true;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DeliveryToCustomerPage(
          orderId: _order!.id,
          customerName: _order!.customerName,
          customerPhone: _order!.customerPhone,
          buildingNo: _order!.buildingNumber?.toString(),
          floorNo: null,
          apartmentNo: _order!.roomNumber?.toString(),
          customerNotes: _order!.notes,
          customerHasHanger: _order!.customerHasHanger,
          isPickup: false,
          onComplete: () {
            context.go('/map-status');
          },
        ),
      ),
    ).then((_) {
      _log('DeliveryToCustomerPage closed for orderId=${_order!.id}');
      _openedDeliveryConfirmationPage = false;
    });
  }

  Future<void> _recenterMap() async {
    if (_mapController == null || _order == null) {
      return;
    }
    final focusPoints = _buildRouteFocusPoints(_order!);
    if (focusPoints.length < 2) return;

    await _fitRouteOverview(
      _mapController!,
      focusPoints,
      mapWidth: _mapWidth,
      mapHeight: _mapHeight,
    );
  }

  void _updateLabelOffsets() async {
    if (_mapController == null || _labelData.isEmpty || !mounted) return;
    if (_mapWidth <= 0 || _mapHeight <= 0) return;
    final now = DateTime.now();
    if (_lastLabelUpdateTime != null &&
        now.difference(_lastLabelUpdateTime!).inMilliseconds <
            _labelUpdateThrottleMs) {
      return;
    }
    _lastLabelUpdateTime = now;

    final dpr = MediaQuery.of(context).devicePixelRatio;
    const edgePad = 8.0;
    final minX = edgePad;
    final maxX = _mapWidth - kLabelBubbleWidth - edgePad;
    final maxTop = _mapHeight - kLabelBubbleHeight - edgePad;
    final Map<String, Offset> newOffsets = {};
    for (final l in _labelData) {
      try {
        final screenPos = await _mapController!.getScreenCoordinate(l.position);
        final dx = screenPos.x.toDouble() / dpr;
        final dy = screenPos.y.toDouble() / dpr;

        var x = (dx - (kLabelBubbleWidth / 2)).clamp(minX, maxX).toDouble();

        var preferredTop = dy - kMarkerIconSize - kLabelGap;
        double top;
        if (preferredTop < edgePad) {
          top = dy + kLabelGap;
        } else {
          top = preferredTop;
        }
        top = top.clamp(edgePad, maxTop).toDouble();

        newOffsets[l.id] = Offset(x, top);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _labelOffsets
          ..clear()
          ..addAll(newOffsets);
        _labelsReady = true;
      });
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (!mounted) return false;
    final targetRoute = widget.entrySource == 'orders'
        ? '/orders'
        : '/map-status';
    _log(
      'Back navigation intercepted -> routing to $targetRoute '
      '(entrySource=${widget.entrySource})',
    );
    context.go(targetRoute);
    return false;
  }

  void _onArrivedPressed() {
    if (!_isCurrentActiveOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This order is not your active order'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final l10n = _resolveL10n(context);
    final isPickup = _order?.type == OrderTypeMock.pickup;
    _log(
      '_onArrivedPressed. isPickup=$isPickup, '
      'currentDeliveryRiderStatus=$_deliveryRiderStatus, '
      'pickupRiderStatus=$_pickupRiderStatus',
    );

    if (!isPickup) {
      final riderStatus = _effectiveDeliveryRiderStatus;
      switch (riderStatus) {
        case _deliveryStatusPendingStart:
          _log('Button action -> send step 1 EnRouteToLaundry');
          _showConfirmationDialog(
            message: '',
            onConfirm: () =>
                _advanceDeliveryRiderStatus(_riderStatusEnRouteToLaundry),
          );
          return;
        case _riderStatusEnRouteToLaundry:
          _log('Button action -> send step 2 ArrivedAtLaundry');
          _showConfirmationDialog(
            message: l10n.confirmArrivalLaundryQ,
            onConfirm: () =>
                _advanceDeliveryRiderStatus(_riderStatusArrivedAtLaundry),
          );
          return;
        case _riderStatusArrivedAtLaundry:
          _log('Button action -> send step 3 PickedUp');
          _showConfirmationDialog(
            message: l10n.confirmPickupQ,
            onConfirm: () => _advanceDeliveryRiderStatus(_riderStatusPickedUp),
          );
          return;
        case _riderStatusPickedUp:
          _log('Button action -> send step 4 EnRouteToCustomer');
          _showConfirmationDialog(
            message: '',
            onConfirm: () =>
                _advanceDeliveryRiderStatus(_riderStatusEnRouteToCustomer),
          );
          return;
        case _riderStatusEnRouteToCustomer:
          _log('Button action -> send step 5 ArrivedAtCustomer');
          _showConfirmationDialog(
            message: l10n.confirmArrivalCustomerQ,
            onConfirm: () => _advanceDeliveryRiderStatus(
              _riderStatusArrivedAtCustomer,
              onSuccess: _openDeliveryConfirmationPage,
            ),
          );
          return;
        default:
          _handleDeliveryScreenNavigation();
          return;
      }
    }

    final pickupStatus = _effectivePickupRiderStatus;
    switch (pickupStatus) {
      case _pickupStatusPendingStart:
        _showConfirmationDialog(
          message: _buildStartTripConfirmationMessage(isPickup: true),
          onConfirm: () => _submitPickupStatus(_pickupStatusEnRouteToCustomer),
        );
        break;
      case _pickupStatusEnRouteToCustomer:
        _showConfirmationDialog(
          message: l10n.confirmArrivalCustomerQ,
          onConfirm: () async {
            await _submitPickupStatus(
              _pickupStatusArrivedAtCustomer,
              onSuccessBeforeSync: () async {
                _openPickupConfirmationPage();
              },
            );
          },
        );
        break;
      case _pickupStatusArrivedAtCustomer:
        _openPickupConfirmationPage();
        break;
      case _pickupStatusPickedUp:
        _showConfirmationDialog(
          message: l10n.confirmPickupQ,
          onConfirm: () => _submitPickupStatus(_pickupStatusEnRouteToLaundry),
        );
        break;
      case _pickupStatusEnRouteToLaundry:
        _showConfirmationDialog(
          message: l10n.confirmArrivalLaundryQ,
          onConfirm: () => _submitPickupStatus(_pickupStatusArrivedAtLaundry),
        );
        break;
      case _pickupStatusArrivedAtLaundry:
        _showConfirmationDialog(
          message: _buildDeliveredToLaundryConfirmationMessage(),
          onConfirm: () async {
            final success = await _submitPickupStatus(
              _pickupStatusDroppedOffAtLaundry,
            );
            if (success && mounted) {
              context.go('/map-status');
            }
          },
        );
        break;
      default:
        context.go('/map-status');
        break;
    }
  }

  Future<bool> _submitPickupStatus(
    int nextStatus, {
    String? proofPhotoPath,
    ProofPhotoType? proofPhotoType,
    Future<void> Function()? onSuccessBeforeSync,
  }) async {
    if (_order == null) return false;

    final success = await _pickupStatusCubit.submitStatus(
      orderId: _order!.id,
      status: nextStatus,
      proofPhotoPath: proofPhotoPath,
      proofPhotoType: proofPhotoType,
    );

    if (!success || !mounted) {
      return false;
    }

    if (onSuccessBeforeSync != null) {
      await onSuccessBeforeSync();
      if (!mounted) return false;
    }

    setState(() {
      _useFullTimeInitialPickupStep = false;
      _pickupRiderStatus = nextStatus;
    });
    if (!_shouldUseOrdersListFlow) {
      await _syncCurrentOrder();
    }
    if (!mounted) return false;

    if (nextStatus >= _pickupStatusPickedUp) {
      _fetchOrderRoute();
    }

    return true;
  }

  void _openPickupConfirmationPage() {
    if (_openedPickupConfirmationPage || _order == null || !mounted) return;

    final l10n = _resolveL10n(context);
    _openedPickupConfirmationPage = true;
    setState(() => _isTransitioningToPickupConfirmation = true);
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => DeliveryToCustomerPage(
          orderId: _order!.id,
          customerName: _order!.customerName,
          customerPhone: _order!.customerPhone,
          buildingNo: _order!.buildingNumber?.toString(),
          floorNo: null,
          apartmentNo: _order!.roomNumber?.toString(),
          customerNotes: _order!.notes,
          customerHasHanger: _order!.customerHasHanger,
          isPickup: true,
          requireProofPhoto: true,
          pickupConfirmButtonText: l10n.confirmPickup,
          onPickupConfirm: (proofPhotoPath) async {
            final success = await _submitPickupStatus(
              _pickupStatusPickedUp,
              proofPhotoPath: proofPhotoPath,
              proofPhotoType: proofPhotoPath != null
                  ? ProofPhotoType.pickupProof
                  : null,
            );
            if (success && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      _openedPickupConfirmationPage = false;
      if (mounted) {
        setState(() => _isTransitioningToPickupConfirmation = false);
      } else {
        _isTransitioningToPickupConfirmation = false;
      }
    });
  }

  String _buildStartTripConfirmationMessage({required bool isPickup}) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return isPickup
          ? 'تأكيد التوجه إلى العميل؟'
          : 'تأكيد التوجه إلى المغسلة؟';
    }

    return isPickup
        ? 'Confirm heading to the customer?'
        : 'Confirm heading to the laundry?';
  }

  String _buildEnRouteButtonLabel({required bool toLaundry}) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return toLaundry ? 'في الطريق إلى المغسلة' : 'في الطريق إلى العميل';
    }

    return toLaundry ? 'Enroute to laundry' : 'Enroute to customer';
  }

  String _buildDeliveredToLaundryConfirmationMessage() {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ar') {
      return 'تأكيد تسليم الطلب إلى المغسلة؟';
    }

    return 'Confirm delivered to the laundry?';
  }

  void _showConfirmationDialog({
    required String message,
    required FutureOr<void> Function() onConfirm,
  }) {
    final l10n = _resolveL10n(context);
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryColor,
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'Confirm Action',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
              if (message.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
              ],
              SizedBox(height: 32.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
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
                  SizedBox(width: 16.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        unawaited(Future<void>.value(onConfirm()));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
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

  Future<void> _handleTripCallTap(OrderMock order) async {
    final displayedStop = _getDisplayedDetailsStop(order);
    final isPickupLaundryLeg =
        order.type == OrderTypeMock.pickup &&
        _effectivePickupRiderStatus >= _pickupStatusPickedUp;
    final isLaundryStep =
        isPickupLaundryLeg || displayedStop?.type == StopPointType.laundry;
    final phone = isLaundryStep
        ? order.laundryPhone?.trim()
        : order.customerPhone.trim();

    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await launchUrl(Uri.parse('tel:$phone'));
  }

  void _openHelpDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _runInitialFitOnce(List<LatLng> points, double mapH) {
    if (_didInitialFit || _mapController == null || points.length < 2) return;
    _didInitialFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _fitRouteOverview(
        _mapController!,
        points,
        mapWidth: _mapWidth,
        mapHeight: mapH,
      );
      _updateLabelOffsets();
    });
  }

  String _formatApiTimeRange(OrderMock order) {
    final l10n = _resolveL10n(context);
    final fmt = intl.DateFormat.jm(Localizations.localeOf(context).toString());
    final start = order.pickupTime ?? order.createdOn ?? order.scheduledAt;
    final end = order.deliveryTime ?? order.pickupTime ?? order.scheduledAt;

    if (start.isAtSameMomentAs(end)) {
      return fmt.format(start);
    }

    return l10n.etaTimeRange(fmt.format(start), fmt.format(end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _resolveL10n(context);
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
    final endpoints = _getRouteEndpoints(order);
    final sourceStop = endpoints?.source;
    final targetStop = endpoints?.target;
    final currentMapStop = nextStopW;
    final displayedStop =
        _getDisplayedDetailsStop(order) ?? nextStopW ?? sourceStop;
    final bool isPickupLaundryLeg =
        order.type == OrderTypeMock.pickup &&
        _effectivePickupRiderStatus >= _pickupStatusPickedUp;
    final bool showCustomerNotesUnderDestination =
        order.type == OrderTypeMock.delivery &&
        _effectiveDeliveryRiderStatus >= _riderStatusPickedUp &&
        order.notes != null &&
        order.notes!.trim().isNotEmpty;
    final LatLng? destLatLng = nextStopW?.location;
    final courierLatLng = _getCourierLatLng();
    final routePoints = _initialMapReady
        ? (_routePolyline ?? const <LatLng>[])
        : const <LatLng>[];
    final overviewPoints = _buildMapOverviewPoints(
      sourceStop: currentMapStop,
      targetStop: null,
    );
    final focusPoints = _buildRouteFocusPoints(order);

    // Build label data for custom markers
    _labelData = [];
    if (currentMapStop != null) {
      _labelData.add(
        _MapLabelData(
          id: 'dest',
          position: currentMapStop.location,
          type: currentMapStop.type == StopPointType.laundry
              ? LabeledMarkerType.laundry
              : LabeledMarkerType.home,
          title: currentMapStop.mapLabelTitle,
        ),
      );
    }
    if (courierLatLng != null) {
      _labelData.add(
        _MapLabelData(
          id: 'courier',
          position: courierLatLng,
          type: LabeledMarkerType.courier,
          title: 'Courier',
        ),
      );
    }
    final String primaryLabel;
    final isPickup = order.type == OrderTypeMock.pickup;
    if (isPickup) {
      switch (_effectivePickupRiderStatus) {
        case _pickupStatusPendingStart:
          primaryLabel = _buildEnRouteButtonLabel(toLaundry: false);
          break;
        case _pickupStatusEnRouteToCustomer:
          primaryLabel = l10n.arrivedAtCustomer;
          break;
        case _pickupStatusArrivedAtCustomer:
          primaryLabel = l10n.pickedUpFromCustomerBtn;
          break;
        case _pickupStatusPickedUp:
          primaryLabel = _buildEnRouteButtonLabel(toLaundry: true);
          break;
        case _pickupStatusEnRouteToLaundry:
          primaryLabel = l10n.arrivedAtLaundry;
          break;
        case _pickupStatusArrivedAtLaundry:
          primaryLabel = l10n.deliveredToLaundryBtn;
          break;
        default:
          primaryLabel = l10n.deliveredToLaundryBtn;
          break;
      }
    } else {
      switch (_effectiveDeliveryRiderStatus) {
        case _deliveryStatusPendingStart:
          primaryLabel = _buildEnRouteButtonLabel(toLaundry: true);
          break;
        case _riderStatusEnRouteToLaundry:
          primaryLabel = l10n.arrivedAtLaundry;
          break;
        case _riderStatusArrivedAtLaundry:
          primaryLabel = l10n.pickedUpButton;
          break;
        case _riderStatusPickedUp:
          primaryLabel = _buildEnRouteButtonLabel(toLaundry: false);
          break;
        case _riderStatusEnRouteToCustomer:
          primaryLabel = l10n.arrivedAtCustomer;
          break;
        default:
          primaryLabel = l10n.deliveredBtn;
          break;
      }
    }

    final hideMessagesAction = !isPickup
        ? (_effectiveDeliveryRiderStatus == _deliveryStatusPendingStart ||
              _effectiveDeliveryRiderStatus == _riderStatusEnRouteToLaundry ||
              _effectiveDeliveryRiderStatus == _riderStatusArrivedAtLaundry)
        : (_effectivePickupRiderStatus == _pickupStatusPickedUp ||
              _effectivePickupRiderStatus == _pickupStatusEnRouteToLaundry ||
              _effectivePickupRiderStatus == _pickupStatusArrivedAtLaundry ||
              _effectivePickupRiderStatus == _pickupStatusDroppedOffAtLaundry);

    final actionButtons = <ActiveTripCompactActionButton>[
      ActiveTripCompactActionButton(
        icon: Icons.directions,
        label: 'Directions',
        width: 0,
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
      if (!hideMessagesAction)
        ActiveTripCompactActionButton(
          icon: Icons.message_outlined,
          label: l10n.messages,
          width: 0,
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
      ActiveTripCompactActionButton(
        icon: Icons.call,
        label: l10n.call,
        width: 0,
        onTap: () => _handleTripCallTap(order),
      ),
      ActiveTripCompactActionButton(
        icon: Icons.info_outline,
        label: l10n.moreDetails,
        width: 0,
        onTap: _showOrderDetails,
      ),
    ];

    final mapH = mq.size.height * 0.45;
    final mapPadding = EdgeInsets.fromLTRB(104.w, 88.h, 104.w, 28.h);

    final helpDrawer = Drawer(
      width: mq.size.width * 0.85,
      child: ComplaintDrawerContent(order: order),
    );

    return BlocListener<PickupStatusCubit, PickupStatusState>(
      bloc: _pickupStatusCubit,
      listener: (context, pickupState) {
        if (pickupState.status == PickupStatusSubmissionStatus.failure &&
            pickupState.errorMessage != null &&
            pickupState.errorMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pickupState.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<PickupStatusCubit, PickupStatusState>(
        bloc: _pickupStatusCubit,
        builder: (context, pickupState) {
          final isActionBusy =
              _isUpdatingRiderStatus || pickupState.isSubmitting;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              unawaited(_handleBackNavigation());
            },
            child: Scaffold(
              key: _scaffoldKey,
              drawer: isRtl ? null : helpDrawer,
              endDrawer: isRtl ? helpDrawer : null,
              body: Stack(
                children: [
                  Column(
                    children: [
                      // MAP SECTION
                      SizedBox(
                        height: mapH,
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            _mapWidth = constraints.maxWidth;
                            _mapHeight = constraints.maxHeight;
                            return Stack(
                              children: [
                                if (currentMapStop != null) ...[
                                  if (_initialMapReady && courierLatLng != null)
                                    ValueListenableBuilder<BitmapDescriptor?>(
                                      valueListenable: _laundryIconNotifier,
                                      builder: (context, laundryIcon, _) {
                                        return ValueListenableBuilder<
                                          BitmapDescriptor?
                                        >(
                                          valueListenable: _homeIconNotifier,
                                          builder: (context, homeIcon, child) {
                                            final currentMarkerIcon =
                                                currentMapStop.type ==
                                                    StopPointType.laundry
                                                ? laundryIcon ??
                                                      BitmapDescriptor
                                                          .defaultMarker
                                                : homeIcon ??
                                                      BitmapDescriptor
                                                          .defaultMarker;
                                            return GoogleMap(
                                              initialCameraPosition:
                                                  CameraPosition(
                                                    target:
                                                        currentMapStop.location,
                                                    zoom: 15,
                                                  ),
                                              padding: mapPadding,
                                              myLocationEnabled: false,
                                              zoomControlsEnabled: false,
                                              markers: {
                                                Marker(
                                                  markerId: const MarkerId(
                                                    'dest',
                                                  ),
                                                  position:
                                                      currentMapStop.location,
                                                  icon: currentMarkerIcon,
                                                ),
                                                Marker(
                                                  markerId: const MarkerId(
                                                    'courier',
                                                  ),
                                                  position: courierLatLng,
                                                ),
                                              },
                                              polylines: routePoints.length >= 2
                                                  ? {
                                                      Polyline(
                                                        polylineId:
                                                            const PolylineId(
                                                              'r',
                                                            ),
                                                        points: routePoints,
                                                        color: const Color(
                                                          0xFF111111,
                                                        ),
                                                        width: 6,
                                                        startCap: Cap.roundCap,
                                                        endCap: Cap.roundCap,
                                                        jointType:
                                                            JointType.round,
                                                      ),
                                                    }
                                                  : {},
                                              onMapCreated: (c) {
                                                _mapController = c;
                                                _runInitialFitOnce(
                                                  focusPoints.isNotEmpty
                                                      ? focusPoints
                                                      : overviewPoints,
                                                  mapH,
                                                );
                                              },
                                              onCameraMove: (_) =>
                                                  _updateLabelOffsets(),
                                            );
                                          },
                                        );
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
                                    ..._labelData
                                        .where(
                                          (l) => _labelOffsets[l.id] != null,
                                        )
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
                                if (currentMapStop != null)
                                  Positioned(
                                    top: mq.padding.top + 16.h,
                                    left: 16.w,
                                    right: 16.w,
                                    child: Center(
                                      child: Material(
                                        elevation: 8,
                                        shadowColor: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          30.r,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              30.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Next destination',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                displayedStop?.addressLine1 ??
                                                    '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.sp,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                              if (currentMapStop.type ==
                                                  StopPointType.laundry) ...[
                                                SizedBox(width: 8.w),
                                                Container(
                                                  padding: EdgeInsets.all(4.w),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFE0F2F1,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Text(
                                                    '1',
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                  bottom: 12.h,
                                  end: 12.w,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ActiveTripMapControlButton(
                                        icon: Icons.my_location,
                                        tooltip: 'Recenter',
                                        onPressed: _recenterMap,
                                      ),
                                      SizedBox(height: 8.h),
                                      ActiveTripMapControlButton(
                                        icon: Icons.fullscreen,
                                        tooltip: 'Expand',
                                        onPressed: () => context.push(
                                          '/active-trip/${order.id}/map',
                                          extra: {
                                            'order': order,
                                            'deliveryRiderStatus':
                                                _effectiveDeliveryRiderStatus,
                                            'pickupRiderStatus':
                                                _effectivePickupRiderStatus,
                                          },
                                        ),
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
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status & ETA
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              l10n.orderNumberLabel(
                                                order.orderNumber ?? order.id,
                                              ),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.sp,
                                                    color: const Color(
                                                      0xFF1A1A1A,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  order.type ==
                                                      OrderTypeMock.pickup
                                                  ? Colors.amber.shade100
                                                  : AppTheme.primaryColor
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(999.r),
                                            ),
                                            child: Text(
                                              order.type == OrderTypeMock.pickup
                                                  ? 'Pickup'
                                                  : 'Delivery',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        order.type ==
                                                            OrderTypeMock.pickup
                                                        ? Colors.amber.shade900
                                                        : AppTheme.primaryColor,
                                                    fontSize: 11.sp,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_outlined,
                                            size: 16.sp,
                                            color: AppTheme.primaryColor,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            _formatApiTimeRange(order),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14.sp,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(14.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time_filled,
                                      color: AppTheme.primaryColor,
                                      size: 24.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),

                              // Destination Detailed Info
                              if (displayedStop != null) ...[
                                Text(
                                  displayedStop.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  displayedStop.addressLine1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                if (displayedStop.addressLine2
                                    .trim()
                                    .isNotEmpty)
                                  Text(
                                    displayedStop.addressLine2,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                              ],
                              SizedBox(height: 32.h),

                              // Action Buttons Row
                              LayoutBuilder(
                                builder: (ctx, consts) {
                                  final buttonCount = actionButtons.length;
                                  final spacing = 16.w;
                                  final totalSpacing =
                                      spacing * (buttonCount - 1);
                                  final btnW =
                                      (consts.maxWidth - totalSpacing) /
                                      buttonCount;
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: actionButtons
                                        .map(
                                          (button) => SizedBox(
                                            width: btnW,
                                            child:
                                                ActiveTripCompactActionButton(
                                                  icon: button.icon,
                                                  label: button.label,
                                                  width: btnW,
                                                  onTap: button.onTap,
                                                ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              SizedBox(height: 32.h),

                              if (showCustomerNotesUnderDestination) ...[
                                Text(
                                  l10n.customerNotes,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18.w,
                                    vertical: 16.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(
                                      color: const Color(0xFFE8EDF2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    order.notes!.trim(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF5F6C7B),
                                      fontSize: 14.sp,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32.h),
                              ],

                              if (order.type == OrderTypeMock.pickup &&
                                  !isPickupLaundryLeg &&
                                  order.notes != null &&
                                  order.notes!.isNotEmpty) ...[
                                Text(
                                  l10n.customerNotes,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(18.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Text(
                                    order.notes!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF444444),
                                      height: 1.4,
                                      fontSize: 14.sp,
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
                        padding: EdgeInsets.fromLTRB(
                          24.w,
                          0,
                          24.w,
                          mq.padding.bottom + 24.h,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: isActionBusy
                                    ? null
                                    : _onArrivedPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(vertical: 18.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                child: isActionBusy
                                    ? SizedBox(
                                        width: 22.w,
                                        height: 22.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        primaryLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            IconButton.outlined(
                              onPressed: _openHelpDrawer,
                              icon: Icon(Icons.help_outline, size: 22.sp),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.all(18.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isTransitioningToPickupConfirmation)
                    Positioned.fill(
                      child: ColoredBox(
                        color: theme.scaffoldBackgroundColor,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
  final latPad = latSpan * 0.22;
  final lngPad = lngSpan * 0.22;

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
  return (dimension * 0.34).clamp(120.0, 220.0);
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

  RouteEndpoints({required this.source, required this.target});
}

class PolylineEndpoints {
  final LatLng origin;
  final LatLng destination;

  PolylineEndpoints({required this.origin, required this.destination});
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
  return parts.first;
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
  _MapLabelData({
    required this.id,
    required this.position,
    required this.type,
    required this.title,
  });
}
