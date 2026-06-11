import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/audio/alert_sound_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/profile/profile_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/models/mobile_order_offer.dart';
import '../../../orders/domain/models/order_mock.dart';
import '../../../orders/presentation/widgets/orders_drawer.dart';
import '../cubit/incoming_order_cubit.dart';
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
import '../widgets/incoming_info_field.dart';
import '../widgets/incoming_map_controls.dart';
import '../widgets/incoming_order_header_label_row.dart';
import '../widgets/incoming_stop_connector.dart';
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

AppLocalizations _resolveL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (l10n != null) return l10n;

  final locale = Localizations.maybeLocaleOf(context);
  if (locale != null) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (supported) {
      return lookupAppLocalizations(locale);
    }
  }

  return lookupAppLocalizations(const Locale('en'));
}

String buildIncomingMapMarkerTitle(
  OrderTypeMock orderType,
  int stopIndex,
  AppLocalizations l10n,
  String? laundryName,
) {
  final isDelivery = orderType == OrderTypeMock.delivery;
  final isSourceStop = stopIndex == 0;

  final shouldShowLaundryName = isDelivery ? isSourceStop : !isSourceStop;
  return shouldShowLaundryName
      ? _resolveLaundryMarkerTitle(laundryName, l10n)
      : l10n.labelHome;
}

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

/// Balanced padding for fit bounds so the whole route stays visible.
double _computeFitPadding(double mapHeight) =>
    (mapHeight * 0.14).clamp(28.0, 64.0);

/// Fits map to two points with comfortable padding, matching other trip screens.
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
  } catch (e) {
    if (kDebugMode) debugPrint('[IncomingMap] fitToTwoPoints error: $e');
  }
}

/// Resets camera to the initial fit state with the same comfortable padding.
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
  } catch (e) {
    if (kDebugMode) debugPrint('[IncomingMap] resetToInitialBounds error: $e');
  }
}

/// Screen shown when a new order is found (after "Go To Online" search).
/// Map, two-stop cards, ETA, Accept/Reject actions.
class IncomingOrderPage extends StatefulWidget {
  static const String id = '/incoming-order';
  final OrderMock? initialOrder;
  final MobileOrderOffer? initialOffer;
  final bool loadCurrentOfferOnOpen;
  final bool showEmptyState;

  const IncomingOrderPage({
    super.key,
    this.initialOrder,
    this.initialOffer,
    this.loadCurrentOfferOnOpen = false,
    this.showEmptyState = false,
  });

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  static const String _kCourierOnlineKey = 'courier_online';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  final ValueNotifier<File?> _profilePhotoNotifier = ValueNotifier<File?>(null);
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
  late int _remainingSeconds;
  Timer? _countdownTimer;
  final ValueNotifier<bool> _courierOnlineNotifier = ValueNotifier<bool>(false);
  bool get _courierOnline => _courierOnlineNotifier.value;
  bool _expiredNavigated = false;
  bool _didStartEntryAlert = false;
  final ValueNotifier<bool> _isRejectSubmittingNotifier = ValueNotifier<bool>(
    false,
  );

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('================ INCOMING ORDER PAGE ================');
    debugPrint('[INCOMING ORDER PAGE] $message');
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialOffer != null
        ? widget.initialOffer!.remainingSeconds.clamp(0, 3600).toInt()
        : 0;
    _loadProfilePhoto();
    _loadCourierOnline();
    if (widget.initialOffer != null) {
      _playEntryAlertOnce();
    }
    _log(
      'Page opened. hasInitialOrder=${widget.initialOrder != null}, '
      'hasInitialOffer=${widget.initialOffer != null}, '
      'loadCurrentOfferOnOpen=${widget.loadCurrentOfferOnOpen}, '
      'showEmptyState=${widget.showEmptyState}, '
      'initialRemainingSeconds=$_remainingSeconds',
    );
    if (_shouldUseOfferCountdown) {
      _startCountdown();
    }
    context.read<IncomingOrderCubit>().loadCurrentOrder(
      initialOrder: widget.initialOrder,
      initialOffer: widget.initialOffer,
      loadCurrentOfferOnOpen: widget.loadCurrentOfferOnOpen,
      showEmptyState: widget.showEmptyState,
    );
  }

  bool get _shouldUseOfferCountdown =>
      widget.initialOffer != null || widget.loadCurrentOfferOnOpen;

  void _playEntryAlertOnce() {
    if (_didStartEntryAlert) {
      return;
    }
    _didStartEntryAlert = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AlertSoundService.playOrderAlertSound());
    });
  }

  Future<void> _loadCourierOnline() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _courierOnlineNotifier.value = prefs.getBool(_kCourierOnlineKey) ?? false;
  }

  Future<void> _loadProfilePhoto() async {
    final profile = await ProfileService.getProfile();
    if (profile == null) return;

    final photoPath = profile['photoPath'];
    if (photoPath == null) return;

    final photoFile = File(photoPath);
    if (await photoFile.exists() && mounted) {
      _profilePhotoNotifier.value = photoFile;
    }
  }

  void _showComingSoon() {
    Navigator.of(context).pop();
    final l10n = _resolveL10n(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  void _openSettings() {
    Navigator.of(context).pop();
    context.push('/home/settings');
  }

  Future<void> _logout() async {
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

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) context.go('/login');
    }
  }

  void _handleDrawerAvailabilityChange(bool value) {
    Navigator.of(context).pop();
    if (value == _courierOnline) {
      return;
    }
    context.go('/map-status', extra: {'autoSearch': value});
  }

  Widget _buildOrdersDrawer({
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return ValueListenableBuilder<File?>(
      valueListenable: _profilePhotoNotifier,
      builder: (context, profilePhoto, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _courierOnlineNotifier,
          builder: (context, courierOnline, _) {
            return OrdersDrawer(
              theme: theme,
              l10n: l10n,
              profilePhoto: profilePhoto,
              courierOnline: courierOnline,
              onCourierOnlineChanged: _handleDrawerAvailabilityChange,
              availabilityBusy: false,
              onProfileTap: () {
                Navigator.of(context).pop();
                context.push('/home/profile');
              },
              onNotificationsTap: () {
                Navigator.of(context).pop();
                context.push('/notifications');
              },
              onOrdersTap: () {
                Navigator.of(context).pop();
                context.go('/orders');
              },
              onSettingsTap: _openSettings,
              onComingSoonTap: _showComingSoon,
              onLogoutTap: _logout,
            );
          },
        );
      },
    );
  }

  void _startCountdown() {
    if (!_shouldUseOfferCountdown || _remainingSeconds <= 0) {
      _log(
        'Countdown not started. shouldUseOfferCountdown=$_shouldUseOfferCountdown, '
        'remainingSeconds=$_remainingSeconds',
      );
      return;
    }
    _log('Starting offer countdown from $_remainingSeconds seconds');
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
    _log('Stopping offer countdown at remainingSeconds=$_remainingSeconds');
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<bool> _handleBackToMapStatus() async {
    if (!mounted) return false;
    _stopCountdown();
    context.go('/map-status');
    return false;
  }

  Future<void> _handleAcceptPressed(OrderMock order) async {
    _log(
      'Accept button pressed. orderId=${order.id}, type=${order.type.name}, '
      'currentCubitOrderId=${context.read<IncomingOrderCubit>().state.currentOrderId}, '
      'isFreelancerOfferFlow=${context.read<IncomingOrderCubit>().state.isFreelancerOfferFlow}',
    );
    _stopCountdown();

    final accepted = order.type == OrderTypeMock.delivery
        ? await context.read<IncomingOrderCubit>().acceptDeliveryOrder()
        : await context.read<IncomingOrderCubit>().acceptPickupOrder();
    if (!mounted) return;
    if (!accepted) {
      _resumeOfferCountdownIfNeeded();
      return;
    }

    if (!mounted) return;
    final resolvedOrderId =
        context.read<IncomingOrderCubit>().state.currentOrderId?.toString() ??
        order.id;
    final resolvedOrder = context.read<IncomingOrderCubit>().state.order;
    _log(
      'Accept flow succeeded. Navigating to active trip for orderId=$resolvedOrderId',
    );
    context.go(
      '/active-trip/$resolvedOrderId',
      extra: {'order': resolvedOrder, 'entrySource': 'incoming-order'},
    );
  }

  Future<void> _handleExpired() async {
    if (!context.read<IncomingOrderCubit>().state.isFreelancerOfferFlow) {
      _log(
        'Ignoring expiry handler because current flow is not freelancer offer',
      );
      return;
    }
    if (_expiredNavigated) return;
    _expiredNavigated = true;
    _log('Offer countdown expired. Showing order expired dialog');
    _stopCountdown();
    if (!mounted) return;
    final l10n = _resolveL10n(context);
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
    final isFreelancerOfferFlow = context
        .read<IncomingOrderCubit>()
        .state
        .isFreelancerOfferFlow;
    if (isFreelancerOfferFlow) {
      _log('Expiry dialog closed. Navigating back to map-status');
      context.go('/map-status');
      return;
    }
    context.go('/map-status', extra: {'autoSearch': true});
  }

  void _resumeOfferCountdownIfNeeded() {
    if (_shouldUseOfferCountdown && _remainingSeconds > 0) {
      _log('Resuming offer countdown with remainingSeconds=$_remainingSeconds');
      _startCountdown();
    }
  }

  @override
  void dispose() {
    AlertSoundService.stopOrderAlertSound();
    _countdownTimer?.cancel();
    _cameraMoveDebounce?.cancel();
    _mapController?.dispose();
    _profilePhotoNotifier.dispose();
    _courierOnlineNotifier.dispose();
    _isRejectSubmittingNotifier.dispose();
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
    return BlocConsumer<IncomingOrderCubit, IncomingOrderState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.actionStatus != current.actionStatus ||
          previous.offer?.offerId != current.offer?.offerId,
      listener: (context, state) {
        _log(
          'Bloc listener fired. status=${state.status.name}, '
          'actionStatus=${state.actionStatus.name}, '
          'flowType=${state.flowType.name}, '
          'currentOrderId=${state.currentOrderId}, '
          'offerId=${state.offer?.offerId}',
        );
        if (state.isFreelancerOfferFlow && state.offer != null) {
          _playEntryAlertOnce();
        }
        final offer = state.offer;
        if (state.isFreelancerOfferFlow && offer != null) {
          final offerRemainingSeconds = offer.remainingSeconds.clamp(0, 3600);
          if (_remainingSeconds != offerRemainingSeconds) {
            _log(
              'Syncing countdown from cubit offer payload. '
              'old=$_remainingSeconds new=$offerRemainingSeconds',
            );
            setState(() => _remainingSeconds = offerRemainingSeconds);
          }
          if (_countdownTimer == null && offerRemainingSeconds > 0) {
            _startCountdown();
          }
        }

        if (state.actionStatus == IncomingOrderActionStatus.failure &&
            state.actionErrorMessage != null &&
            state.actionErrorMessage!.trim().isNotEmpty) {
          _log('Showing action failure snackbar: ${state.actionErrorMessage}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionErrorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.isLoading || state.status == IncomingOrderStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == IncomingOrderStatus.failure ||
            state.status == IncomingOrderStatus.empty) {
          _log(
            'Rendering fallback state screen. '
            'status=${state.status.name}, message=${state.errorMessage}',
          );
          final l10n = _resolveL10n(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        state.errorMessage ?? l10n.orderNotFound,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 20.h),
                      FilledButton(
                        onPressed: () => context.go('/map-status'),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final order = state.order;
        if (order == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final l10n = _resolveL10n(context);
        final theme = Theme.of(context);
        final incoming = state.isFreelancerOfferFlow && state.offer != null
            ? fromOfferToIncomingOrderMock(state.offer!, l10n)
            : fromOrderMock(order, l10n);
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
            title: buildIncomingMapMarkerTitle(
              order.type,
              0,
              l10n,
              order.laundryName,
            ),
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
            title: buildIncomingMapMarkerTitle(
              order.type,
              1,
              l10n,
              order.laundryName,
            ),
            logoUrl: stops[1].type == StopPointType.laundry
                ? incoming.laundryLogoUrl
                : null,
          ),
        ];

        final mq = MediaQuery.of(context);
        final screenH = mq.size.height - mq.padding.top - mq.padding.bottom;
        final compact = screenH < 650;

        final mapH = (screenH * (compact ? 0.42 : 0.40)).clamp(140.0, 280.0);
        final padH = compact ? 10.w : 14.w;
        final padV = compact ? 6.h : 10.h;

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
                            const Duration(
                              milliseconds: _labelUpdateThrottleMs,
                            ),
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
                        onExpand: () =>
                            context.push('/incoming-order/map', extra: order),
                        onReset: _userMovedMap
                            ? () => _resetCamera(mapH)
                            : null,
                        isRtl: isRtl,
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
              countdown: state.isFreelancerOfferFlow && _remainingSeconds > 0
                  ? AcceptCountdownTimer(
                      remainingSeconds: _remainingSeconds,
                      totalSeconds:
                          state.offer?.remainingSeconds.clamp(1, 3600) ??
                          _kCountdownTotalSeconds,
                      compact: compact,
                    )
                  : null,
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
                  IncomingStopConnector(compact: compact),
                  _StopCard(
                    stop: stops[1],
                    distanceKm: incoming.distanceFirstToSecondKm,
                    theme: theme,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8.h : 10.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.estimatedArrival,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: compact ? 11.sp : 12.sp,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            if ((incoming.etaLabel ?? '').trim().isNotEmpty)
                              Text(
                                incoming.etaLabel!,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: compact ? 16.sp : 18.sp,
                                ),
                              )
                            else
                              SizedBox(height: compact ? 24.h : 28.h),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IncomingInfoField(
                        label: 'Service Name',
                        value: incoming.serviceName,
                        compact: compact,
                        textAlign: TextAlign.end,
                        theme: theme,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10.h : 12.h),
                  EarningsCard(
                    baseAmount: state.isFreelancerOfferFlow
                        ? (state.offer?.effectiveTotalPrice ??
                              state.offer?.totalPrice ??
                              0)
                        : order.totalPrice,
                    bonusAmount: state.isFreelancerOfferFlow
                        ? state.offer?.bonusAmount
                        : null,
                    bonusConditionMinutes: state.isFreelancerOfferFlow
                        ? null
                        : 1,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ],
        );

        final buttons = Padding(
          padding: EdgeInsets.fromLTRB(padH, 0, padH, mq.padding.bottom + 12.h),
          child: ValueListenableBuilder<bool>(
            valueListenable: _isRejectSubmittingNotifier,
            builder: (context, isRejectSubmitting, _) {
              return Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: SizedBox(
                      height: 44.h,
                      child: OutlinedButton(
                        onPressed: state.isSubmitting || isRejectSubmitting
                            ? null
                            : () {
                                _stopCountdown();
                                _showRejectModal(context, l10n);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        child: isRejectSubmitting
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.error,
                                  ),
                                ),
                              )
                            : Text(l10n.reject),
                      ),
                    ),
                  ),
                  SizedBox(width: padH),
                  Expanded(
                    flex: 13,
                    child: SizedBox(
                      height: 44.h,
                      child: FilledButton(
                        onPressed: state.isSubmitting || isRejectSubmitting
                            ? null
                            : () => _handleAcceptPressed(order),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          textStyle: TextStyle(
                            fontSize: compact ? 14.sp : 15.sp,
                          ),
                        ),
                        child: state.isSubmitting && !isRejectSubmitting
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(l10n.accept),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            unawaited(_handleBackToMapStatus());
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: isRtl ? null : _buildOrdersDrawer(theme: theme, l10n: l10n),
            endDrawer: isRtl
                ? _buildOrdersDrawer(theme: theme, l10n: l10n)
                : null,
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
          ),
        );
      },
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
        constraints: BoxConstraints(maxWidth: compact ? 90.w : 110.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(50),
            width: 0.5.w,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 10.sp : 11.sp,
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
        spacing: 4.w,
        runSpacing: 4.h,
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
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => Icon(Icons.star, color: Colors.amber, size: 32.sp),
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
      final cubit = context.read<IncomingOrderCubit>();
      if (cubit.state.isFreelancerOfferFlow) {
        _log(
          'Reject confirmed for freelancer offer. '
          'offerId=${cubit.state.offer?.offerId}',
        );
        if (mounted) {
          _isRejectSubmittingNotifier.value = true;
        }
        final rejected = await cubit.rejectCurrentOffer();
        if (mounted) {
          _isRejectSubmittingNotifier.value = false;
        }
        if (!context.mounted) {
          return;
        }
        if (rejected) {
          _log('Reject flow succeeded. Navigating back to map-status');
          context.go('/map-status');
        } else {
          _log('Reject flow failed. Resuming countdown if needed');
          _resumeOfferCountdownIfNeeded();
        }
        return;
      }

      _log(
        'Reject confirmed for non-offer flow. Navigating back to map-status',
      );
      context.go('/map-status');
    } else if (context.mounted) {
      _log('Reject dialog cancelled. Resuming countdown if needed');
      _resumeOfferCountdownIfNeeded();
    }
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
  final double? distanceKm;
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
    final stopName = stop.type == StopPointType.laundry
        ? _resolveLaundryNameFromStopTitle(stop.title)
        : 'Home';
    final stopAddress = [
      stop.addressLine1.trim(),
      stop.addressLine2.trim(),
    ].where((line) => line.isNotEmpty).join(', ');
    final icon = stop.type == StopPointType.laundry
        ? Icons.local_laundry_service
        : Icons.home;
    final iconColor = stop.type == StopPointType.laundry
        ? AppTheme.primaryColor
        : Colors.deepOrange;
    final iconBgColor = iconColor.withValues(alpha: 0.1);
    final pad = compact ? 12.w : 16.w;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
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
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: compact ? 20.sp : 24.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stopName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14.sp : 16.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  if (stopAddress.isNotEmpty)
                    Text(
                      stopAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: compact ? 11.sp : 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.distanceKm == null
                      ? 'km'
                      : '${widget.distanceKm!.toStringAsFixed(1)} km',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12.sp : 14.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Dist.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: compact ? 9.sp : 10.sp,
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

String _resolveLaundryDisplayName(String? laundryName) {
  final trimmed = laundryName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return '';
}

String _resolveLaundryMarkerTitle(String? laundryName, AppLocalizations l10n) {
  final displayName = _resolveLaundryDisplayName(laundryName);
  if (displayName.isEmpty) {
    return '${l10n.labelLaundry}:';
  }
  return displayName;
}

String _resolveLaundryNameFromStopTitle(String title) {
  const prefix = 'Laundry:';
  final trimmed = title.trim();
  if (trimmed.startsWith(prefix)) {
    final value = trimmed.substring(prefix.length).trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  if (trimmed == prefix) {
    return prefix;
  }
  return _resolveLaundryDisplayName(trimmed);
}
