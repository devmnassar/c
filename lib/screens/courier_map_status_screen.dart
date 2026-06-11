import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_service.dart';
import '../core/di/dependency_injection.dart';
import '../core/profile/profile_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_snack_bar.dart';
import '../features/driver_availability/presentation/cubit/courier_location_sync_cubit.dart';
import '../features/driver_availability/presentation/cubit/heartbeat_cubit.dart';
import '../features/driver_availability/presentation/cubit/go_offline_cubit.dart';
import '../features/driver_availability/presentation/cubit/go_online_cubit.dart';
import '../features/courier_profile/data/datasources/courier_profile_local_data_source.dart';
import '../features/incoming/data/mappers/mobile_order_offer_to_order_mock_mapper.dart';
import '../features/incoming/data/mappers/mobile_order_to_order_mock_mapper.dart';
import '../features/incoming/presentation/models/incoming_order_route_args.dart';
import '../features/orders/domain/models/mobile_order.dart';
import '../features/orders/domain/models/mobile_order_offer.dart';
import '../features/orders/domain/usecases/get_current_offer_use_case.dart';
import '../features/orders/domain/usecases/get_current_order_use_case.dart';
import '../l10n/app_localizations.dart';
import 'widgets/courier_map_drawer_notification_button.dart';
import 'widgets/courier_map_drawer_stats_row.dart';
import 'widgets/courier_map_drawer_tile.dart';
import 'widgets/courier_map_searching_indicator.dart';

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

/// Fallback centre (Riyadh) until real GPS is available.
const double _mapCenterLat = 24.7136;
const double _mapCenterLng = 46.6753;
const double _mapZoom = 16.0;
const Duration _kFakeOfferBannerInitialDelay = Duration(seconds: 1);
const Duration _kFakeOfferBannerInterval = Duration(seconds: 30);
const Duration _kFakeOfferBannerVisibleDuration = Duration(seconds: 10);

/// Map status screen: full-screen Google Map (same as Order Details), current location, "Go To Online" button.
/// Uses google_maps_flutter; language follows app/device locale automatically.
class CourierMapStatusScreen extends StatefulWidget {
  static const String id = '/map-status';
  final bool autoSearch;

  const CourierMapStatusScreen({super.key, this.autoSearch = false});

  @override
  State<CourierMapStatusScreen> createState() => _CourierMapStatusScreenState();
}

class _CourierMapStatusScreenState extends State<CourierMapStatusScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  final ValueNotifier<String> _profileNameNotifier = ValueNotifier<String>(
    'Courier',
  );

  /// Courier online/offline status (persisted to SharedPreferences).
  bool _courierOnline = false;
  static const String _kCourierOnlineKey = 'courier_online';

  /// Real current position (GPS). Null until we get it or if permission denied.
  Position? _currentPosition;
  bool _locationLoading = false;

  /// Courier marker icon (van), loaded once from assets.
  final ValueNotifier<BitmapDescriptor?> _courierMarkerIconNotifier =
      ValueNotifier<BitmapDescriptor?>(null);
  final ValueNotifier<bool> _courierMarkerIconLoadingNotifier =
      ValueNotifier<bool>(false);

  BitmapDescriptor? get _courierMarkerIcon => _courierMarkerIconNotifier.value;
  bool get _courierMarkerIconLoading => _courierMarkerIconLoadingNotifier.value;
  Timer? _fakeOfferBannerTimer;
  Timer? _fakeOfferBannerHideTimer;
  bool _offerLookupInFlight = false;
  bool _openingOfferFlow = false;
  bool _fakeOfferBannerVisible = false;
  int? _cachedCourierTypeId;
  final GetCurrentOrderUseCase _getCurrentOrderUseCase =
      getIt<GetCurrentOrderUseCase>();
  final GetCurrentOfferUseCase _getCurrentOfferUseCase =
      getIt<GetCurrentOfferUseCase>();
  final CourierProfileLocalDataSource _courierProfileLocalDataSource =
      getIt<CourierProfileLocalDataSource>();

  void _log(String message) {
    debugPrint('================ MAP STATUS FLOW ================');
    debugPrint('[MAP STATUS FLOW] $message');
  }

  String _describeOffer(MobileOrderOffer offer) {
    return 'offerId=${offer.offerId}, orderId=${offer.orderId}, '
        'type=${offer.orderType.name}, orderStatus=${offer.orderStatus.name}, '
        'remainingSeconds=${offer.remainingSeconds}, '
        'distanceKm=${offer.distanceKm}, etaMinutes=${offer.etaMinutes}, '
        'source="${offer.sourceAddress}", target="${offer.targetAddress}"';
  }

  String _describeCurrentOrder(MobileOrder order) {
    return 'orderId=${order.id}, type=${order.orderType.name}, '
        'status=${order.status.name}, riderStatus=${order.riderStatus?.name}, '
        'pickupRiderStatus=${order.pickupRiderStatus?.name}, '
        'distanceKm=${order.distanceKm}, etaMinutes=${order.etaMinutes}, '
        'source="${order.sourceAddress}", target="${order.targetAddress}"';
  }

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _loadCourierOnline();
    _loadCachedCourierTypeId();
    _initializeLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startFakeOfferBannerLoop();
    });
    if (widget.autoSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<GoOnlineCubit>().goOnline();
      });
    }
  }

  Future<void> _loadCourierOnline() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _courierOnline = prefs.getBool(_kCourierOnlineKey) ?? false,
      );
    }
  }

  Future<void> _loadCachedCourierTypeId() async {
    final courierTypeId = await _courierProfileLocalDataSource
        .getCachedCourierTypeId();
    _log('Loaded cached courierTypeId=$courierTypeId for map status screen');
    if (!mounted) {
      _cachedCourierTypeId = courierTypeId;
      return;
    }

    setState(() => _cachedCourierTypeId = courierTypeId);
    if (_shouldShowFreelancerOfferPolling) {
      _startFakeOfferBannerLoop();
    } else {
      _stopFakeOfferBannerLoop();
      _dismissOfferBanner();
    }
  }

  bool get _shouldShowFreelancerOfferPolling => _cachedCourierTypeId == 1;

  Future<void> _setCourierOnline(bool value) async {
    if (value == _courierOnline) {
      return;
    }

    if (value) {
      context.read<GoOnlineCubit>().goOnline();
      return;
    }

    context.read<GoOfflineCubit>().goOffline();
  }

  Future<void> _persistCourierOnline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCourierOnlineKey, value);
    if (mounted) {
      setState(() => _courierOnline = value);
    }
  }

  /// Load van marker icon once for map display (64–72 logical px, devicePixelRatio for sharpness).
  Future<void> _loadCourierMarkerIcon(BuildContext context) async {
    if (_courierMarkerIcon != null || _courierMarkerIconLoading) return;
    _courierMarkerIconLoadingNotifier.value = true;
    try {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: const Size(72, 72), devicePixelRatio: dpr),
        'assets/markers/van_3d.png',
      );
      if (!mounted) return;
      _courierMarkerIconNotifier.value = icon;
      _courierMarkerIconLoadingNotifier.value = false;
    } catch (_) {
      if (!mounted) return;
      _courierMarkerIconLoadingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _stopFakeOfferBannerLoop();
    _fakeOfferBannerHideTimer?.cancel();
    _fakeOfferBannerVisible = false;
    _mapController?.dispose();
    _courierMarkerIconNotifier.dispose();
    _courierMarkerIconLoadingNotifier.dispose();
    _profileNameNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfileName() async {
    final profile = await ProfileService.getProfile();
    if (mounted && profile != null) {
      final name = profile['fullName'] as String?;
      if (name != null && name.isNotEmpty) {
        _profileNameNotifier.value = name;
      }
    }
  }

  /// Check location service, request permission, get current position. Does not crash; shows SnackBar if denied.
  Future<void> _initializeLocation() async {
    if (!mounted) return;
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.locationUnavailable ??
                    'Location services are disabled. Enable in settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.locationPermissionDenied ??
                    'Location permission is required to show your position.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Clear loading state immediately once we have permission, so map shows at fallback
      if (mounted) {
        setState(() => _locationLoading = false);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _animateToCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  /// Fetch latest position and animate camera to it (for "My Location" button).
  Future<void> _moveToMyLocation() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          setState(() => _locationLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.locationPermissionDenied ??
                    'Location permission denied.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationLoading = false;
        });
        _animateToCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _animateToCurrentLocation() {
    final pos = _currentPosition;
    if (pos == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), _mapZoom),
    );
  }

  void _onGoToOnline() {
    _log('Go To Online button pressed');
    context.read<GoOnlineCubit>().goOnline();
  }

  Future<void> _handlePostGoOnlineNavigation() async {
    _log('Go-online succeeded. Starting post-success navigation flow');
    final courierTypeId = await _courierProfileLocalDataSource
        .getCachedCourierTypeId();
    _log('Cached courierTypeId=$courierTypeId');
    if (!mounted) return;

    if (courierTypeId == 3) {
      _log(
        'Courier is fulltime (courierTypeId=3); routing to orders screen after go-online success',
      );
      context.go('/orders');
      return;
    }

    if (courierTypeId == 1) {
      await _handleOfferFirstGoOnlineNavigation();
      return;
    }

    final result = await _getCurrentOrderUseCase();
    if (!mounted) return;

    result.fold(
      (error) {
        _log('Failed to fetch current order after go-online: ${error.message}');
        context.push('/incoming-order');
      },
      (order) {
        if (order == null) {
          _log(
            'No current order found after go-online; opening incoming order screen',
          );
          context.push('/incoming-order');
          return;
        }
        _routeUsingCurrentOrder(order);
      },
    );
  }

  Future<void> _handleOfferFirstGoOnlineNavigation() async {
    _log(
      'Courier is freelancer (courierTypeId=1); STEP 1 -> calling current offer API before current order',
    );
    final offerResult = await _getCurrentOfferUseCase();
    if (!mounted) return;

    MobileOrderOffer? currentOffer;
    offerResult.fold(
      (error) {
        _log('Failed to fetch current offer after go-online: ${error.message}');
      },
      (offer) {
        currentOffer = offer;
        if (offer == null) {
          _log('Current offer API returned data=null');
          return;
        }
        _log('Current offer API returned data: ${_describeOffer(offer)}');
      },
    );

    if (currentOffer != null) {
      _log(
        'STEP 2 -> Offer exists, navigating immediately to incoming order using offer payload',
      );
      await _openFreelancerOffer(currentOffer!);
      return;
    }

    _log('STEP 2 -> No active offer found, falling back to current order API');
    final orderResult = await _getCurrentOrderUseCase();
    if (!mounted) return;

    orderResult.fold(
      (error) {
        _log(
          'Failed to fetch current order after offer returned null: ${error.message}',
        );
        context.push(
          '/incoming-order',
          extra: const IncomingOrderRouteArgs(showEmptyState: true),
        );
      },
      (order) {
        if (order == null) {
          _log(
            'Current order API returned data=null. Offer and current order are both empty, opening no-order screen',
          );
          context.push(
            '/incoming-order',
            extra: const IncomingOrderRouteArgs(showEmptyState: true),
          );
          return;
        }
        _log(
          'Current order API returned data: ${_describeCurrentOrder(order)}',
        );
        _routeUsingCurrentOrder(order);
      },
    );
  }

  void _routeUsingCurrentOrder(MobileOrder order) {
    final mappedOrder = fromMobileOrder(order);
    final riderStatus = order.riderStatus;
    final pickupRiderStatus = order.pickupRiderStatus;
    final orderStatus = order.status;
    _log(
      'Current order found. '
      'orderId=${order.id}, riderStatus=$riderStatus, '
      'pickupRiderStatus=$pickupRiderStatus, orderStatus=$orderStatus',
    );

    if (_shouldResumeActiveTrip(order)) {
      _log('Routing to active trip to resume unfinished order');
      context.go(
        '/active-trip/${mappedOrder.id}',
        extra: {'order': mappedOrder, 'entrySource': 'map-status'},
      );
      return;
    }

    if (_shouldOpenFreelancerPendingTrip(order)) {
      _log(
        'Routing freelancer to active trip initial step because '
        'backend rider status is still null',
      );
      context.go(
        '/active-trip/${mappedOrder.id}',
        extra: {'order': mappedOrder, 'entrySource': 'map-status'},
      );
      return;
    }

    _log('Routing to incoming order because order still needs acceptance');
    context.push('/incoming-order', extra: mappedOrder);
  }

  void _startFakeOfferBannerLoop() {
    if (!_shouldShowFreelancerOfferPolling) {
      _log(
        'Skipping fake offer banner loop because courierTypeId=$_cachedCourierTypeId',
      );
      _stopFakeOfferBannerLoop();
      _dismissOfferBanner();
      return;
    }
    _fakeOfferBannerTimer?.cancel();
    _fakeOfferBannerTimer = Timer.periodic(
      _kFakeOfferBannerInterval,
      (_) => _showFakeOfferBanner(),
    );
    _fakeOfferBannerHideTimer?.cancel();
    _fakeOfferBannerHideTimer = Timer(_kFakeOfferBannerInitialDelay, () {
      if (!mounted) {
        return;
      }
      _showFakeOfferBanner();
    });
  }

  void _stopFakeOfferBannerLoop() {
    _fakeOfferBannerTimer?.cancel();
    _fakeOfferBannerTimer = null;
    _fakeOfferBannerHideTimer?.cancel();
    _fakeOfferBannerHideTimer = null;
  }

  void _showFakeOfferBanner() {
    if (!mounted ||
        _openingOfferFlow ||
        _fakeOfferBannerVisible ||
        !_shouldShowFreelancerOfferPolling) {
      return;
    }
    _log('Showing fake offer banner overlay');
    setState(() => _fakeOfferBannerVisible = true);
    _fakeOfferBannerHideTimer?.cancel();
    _fakeOfferBannerHideTimer = Timer(_kFakeOfferBannerVisibleDuration, () {
      if (!mounted || !_fakeOfferBannerVisible) {
        return;
      }
      _dismissOfferBanner();
    });
  }

  void _dismissOfferBanner() {
    if (!mounted && _fakeOfferBannerVisible == false) {
      return;
    }
    _fakeOfferBannerHideTimer?.cancel();
    _fakeOfferBannerHideTimer = null;
    if (mounted) {
      setState(() => _fakeOfferBannerVisible = false);
    } else {
      _fakeOfferBannerVisible = false;
    }
  }

  Future<void> _handleFakeOfferTap() async {
    if (_offerLookupInFlight ||
        _openingOfferFlow ||
        !mounted ||
        !_shouldShowFreelancerOfferPolling) {
      return;
    }

    setState(() => _offerLookupInFlight = true);
    final result = await _getCurrentOfferUseCase();
    if (mounted) {
      setState(() => _offerLookupInFlight = false);
    } else {
      _offerLookupInFlight = false;
    }
    if (!mounted) {
      return;
    }

    await result.fold(
      (error) async {
        _log(
          'Offer banner tap failed while loading current offer: ${error.message}',
        );
        AppSnackBar.showError(context, error.message);
      },
      (offer) async {
        if (offer == null) {
          _log(
            'Offer banner tap returned data=null -> opening no-order screen',
          );
          _dismissOfferBanner();
          await context.push(
            '/incoming-order',
            extra: const IncomingOrderRouteArgs(showEmptyState: true),
          );
          return;
        }

        _log(
          'Offer banner tap returned active offer: ${_describeOffer(offer)}',
        );
        _dismissOfferBanner();
        await _openFreelancerOffer(offer);
      },
    );
  }

  Future<void> _openFreelancerOffer(MobileOrderOffer offer) async {
    if (_openingOfferFlow || !mounted) {
      return;
    }
    _log(
      'Opening incoming order screen with offer payload: ${_describeOffer(offer)}',
    );
    _openingOfferFlow = true;
    _fakeOfferBannerVisible = false;
    _stopFakeOfferBannerLoop();
    try {
      await context.push(
        '/incoming-order',
        extra: IncomingOrderRouteArgs(
          initialOrder: fromMobileOrderOffer(offer),
          initialOffer: offer,
        ),
      );
    } finally {
      _openingOfferFlow = false;
      if (mounted) {
        _startFakeOfferBannerLoop();
      }
    }
  }

  bool _shouldResumeActiveTrip(MobileOrder order) {
    if (order.orderType == MobileOrderType.pickup) {
      final pickupRiderStatus = order.pickupRiderStatus;
      if (pickupRiderStatus == null ||
          pickupRiderStatus == MobilePickupRiderStatus.droppedOffAtLaundry ||
          pickupRiderStatus == MobilePickupRiderStatus.unknown) {
        return false;
      }

      return true;
    }

    final riderStatus = order.riderStatus;
    if (riderStatus == null || _isTerminalRiderStatus(riderStatus)) {
      return false;
    }

    return true;
  }

  bool _shouldOpenFreelancerPendingTrip(MobileOrder order) {
    if (_cachedCourierTypeId != 1) {
      return false;
    }

    if (order.orderType == MobileOrderType.pickup) {
      return order.pickupRiderStatus == null ||
          order.pickupRiderStatus == MobilePickupRiderStatus.unknown;
    }

    return order.riderStatus == null ||
        order.riderStatus == MobileRiderStatus.unknown;
  }

  bool _isTerminalRiderStatus(MobileRiderStatus status) {
    return status == MobileRiderStatus.delivered ||
        status == MobileRiderStatus.attemptedDelivery;
  }

  @override
  Widget build(BuildContext context) {
    if (_courierMarkerIcon == null && !_courierMarkerIconLoading) {
      _loadCourierMarkerIcon(context);
    }
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = _resolveL10n(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(_mapCenterLat, _mapCenterLng);

    return MultiBlocListener(
      listeners: [
        BlocListener<GoOnlineCubit, GoOnlineState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status != GoOnlineStatus.initial,
          listener: (context, state) async {
            if (state.status == GoOnlineStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<GoOnlineCubit>().resetStatus();
              return;
            }

            if (state.status == GoOnlineStatus.success &&
                state.result != null) {
              _log(
                'GoOnlineCubit success received on map screen. '
                'isOnline=${state.result!.isOnline}, '
                'sessionId=${state.result!.onlineSessionId}',
              );
              await _persistCourierOnline(state.result!.isOnline);
              if (!context.mounted) return;
              _log('Starting heartbeat after go-online success');
              await context.read<HeartbeatCubit>().startHeartbeat();
              if (!context.mounted) return;
              _log('Starting SignalR location sync every 5 seconds');
              await context.read<CourierLocationSyncCubit>().startLocationSync(
                    intervalSeconds:
                        CourierLocationSyncCubit.defaultIntervalSeconds,
                  );
              if (!context.mounted) return;
              await _handlePostGoOnlineNavigation();
              if (!context.mounted) return;
              context.read<GoOnlineCubit>().resetStatus();
            }
          },
        ),
        BlocListener<HeartbeatCubit, HeartbeatState>(
          listenWhen: (previous, current) =>
              previous.feedbackCounter != current.feedbackCounter &&
              current.status == HeartbeatStatus.serverForcedOffline,
          listener: (context, state) async {
            await _persistCourierOnline(false);
            if (!context.mounted) return;
            await context.read<CourierLocationSyncCubit>().stopLocationSync(
                  reason: 'Server forced offline.',
                );
            AppSnackBar.showError(
              context,
              state.message ?? 'Please go online first.',
            );
            context.read<HeartbeatCubit>().clearTransientMessage();
          },
        ),
      ],
      child: BlocBuilder<GoOnlineCubit, GoOnlineState>(
        builder: (context, state) {
          final searchingForOrder = state.isLoading;
          final offlineState = context.watch<GoOfflineCubit>().state;
          final availabilityBusy = searchingForOrder || offlineState.isLoading;

          return BlocListener<GoOfflineCubit, GoOfflineState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status != GoOfflineStatus.initial,
            listener: (context, state) async {
              if (state.status == GoOfflineStatus.failure &&
                  state.errorMessage != null) {
                AppSnackBar.showError(context, state.errorMessage!);
                context.read<GoOfflineCubit>().resetStatus();
                return;
              }

              if (state.status == GoOfflineStatus.success &&
                  state.result != null) {
                await context.read<CourierLocationSyncCubit>().stopLocationSync(
                      reason: 'Go offline succeeded.',
                    );
                await context.read<HeartbeatCubit>().stopHeartbeat(
                      reason: 'Go offline succeeded.',
                    );
                await _persistCourierOnline(state.result!.isOnline);
                if (!context.mounted) return;
                AppSnackBar.showSuccess(
                  context,
                  state.result!.message ?? 'Driver is offline now.',
                );
                context.read<GoOfflineCubit>().resetStatus();
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              drawer: isRtl ? null : _buildDrawer(theme, availabilityBusy),
              endDrawer: isRtl ? _buildDrawer(theme, availabilityBusy) : null,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen Google Map (courier shown as van marker; language from app locale)
                  ValueListenableBuilder<BitmapDescriptor?>(
                    valueListenable: _courierMarkerIconNotifier,
                    builder: (context, courierMarkerIcon, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _courierMarkerIconLoadingNotifier,
                        builder: (context, courierMarkerIconLoading, child) {
                          final Set<Marker> markers = {};
                          if (courierMarkerIcon != null) {
                            markers.add(
                              Marker(
                                markerId: const MarkerId('courier'),
                                position: initialTarget,
                                icon: courierMarkerIcon,
                              ),
                            );
                          }
                          return GoogleMap(
                            key: ValueKey('map_status_$localeCode'),
                            initialCameraPosition: CameraPosition(
                              target: initialTarget,
                              zoom: _mapZoom,
                            ),
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                            markers: markers,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              if (_currentPosition != null) {
                                _animateToCurrentLocation();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                  // Hamburger menu button (LTR: top-left, RTL: top-right)
                  PositionedDirectional(
                    top: 16,
                    start: 16,
                    child: SafeArea(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        child: InkWell(
                          onTap: () {
                            final rtl =
                                Directionality.of(context) == TextDirection.rtl;
                            if (rtl) {
                              _scaffoldKey.currentState?.openEndDrawer();
                            } else {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.menu, color: Color(0xFF111827)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_fakeOfferBannerVisible)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Material(
                            elevation: 10,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            shadowColor: Colors.black.withValues(alpha: 0.18),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                10,
                                12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active_outlined,
                                    color: Color(0xFF111827),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'New offer available. Tap View to check it.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _offerLookupInFlight
                                        ? null
                                        : _dismissOfferBanner,
                                    child: const Text('Dismiss'),
                                  ),
                                  const SizedBox(width: 4),
                                  FilledButton(
                                    onPressed: _offerLookupInFlight
                                        ? null
                                        : () {
                                            unawaited(_handleFakeOfferTap());
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(72, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    child: _offerLookupInFlight
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('View'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // My Location floating button (fully visible above "Go To Online"; RTL-aware)
                  PositionedDirectional(
                    end: 16,
                    bottom:
                        MediaQuery.of(context).padding.bottom +
                        54.0 +
                        (16.0 * 2) +
                        12.0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(28),
                      color: AppTheme.primaryColor,
                      child: InkWell(
                        onTap: _locationLoading ? null : _moveToMyLocation,
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _locationLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom sheet / snack-like indicator when searching
                  if (searchingForOrder)
                    PositionedDirectional(
                      start: 20,
                      end: 20,
                      bottom: MediaQuery.of(context).padding.bottom + 54 + 16,
                      child: CourierMapSearchingIndicator(
                        theme: theme,
                        message: l10n.searchingForNewOrder,
                      ),
                    ),
                  // Bottom yellow "Go To Online" button
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: searchingForOrder ? null : _onGoToOnline,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFFFC107,
                              ), // bright yellow
                              foregroundColor: const Color(0xFF111827),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.goToOnline,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDrawer(ThemeData theme, bool availabilityBusy) {
    final l10n = _resolveL10n(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: avatar, name, Offline chip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/home/profile');
                        },
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primaryColor,
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<String>(
                              valueListenable: _profileNameNotifier,
                              builder: (context, profileName, _) {
                                return Text(
                                  profileName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _courierOnline ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _courierOnline
                                ? l10n.drawerStatusOnline
                                : l10n.drawerStatusOffline,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _courierOnline,
                            onChanged: availabilityBusy
                                ? null
                                : (value) => _setCourierOnline(value),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CourierMapDrawerNotificationButton(
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      context.push('/notifications');
                    },
                  ),
                ],
              ),
            ),
            // Stats row: Income SAR 0.00 | Orders 0
            CourierMapDrawerStatsRow(
              theme: theme,
              incomeLabel: l10n.income,
              ordersLabel: l10n.orders,
            ),
            const Divider(height: 1),
            // Menu list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.profile,
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/home/profile');
                    },
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.drawerOrders,
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/orders');
                    },
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.promotion,
                    icon: Icons.campaign_outlined,
                    onTap: () => _showComingSoon(context),
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.inbox,
                    icon: Icons.inbox_outlined,
                    onTap: () => _showComingSoon(context),
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.appealCentre,
                    icon: Icons.gavel_outlined,
                    onTap: () => _showComingSoon(context),
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.tutorialCentre,
                    icon: Icons.school_outlined,
                    onTap: () => _showComingSoon(context),
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.contactCs,
                    icon: Icons.support_agent_outlined,
                    onTap: () => _showComingSoon(context),
                  ),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.menuSettings,
                    icon: Icons.settings_outlined,
                    onTap: () => _openSettings(context),
                  ),
                  const Divider(height: 24),
                  CourierMapDrawerTile(
                    theme: theme,
                    title: l10n.menuLogout,
                    icon: Icons.logout,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    Navigator.of(context).pop(); // close drawer
    final l10n = _resolveL10n(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pop();
    context.push('/home/settings');
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    final l10n = _resolveL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.drawerLogoutTitle),
        content: Text(l10n.drawerLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.drawerLogoutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.drawerLogoutYes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AuthService.logout();
      if (context.mounted) context.go('/login');
    }
  }
}
