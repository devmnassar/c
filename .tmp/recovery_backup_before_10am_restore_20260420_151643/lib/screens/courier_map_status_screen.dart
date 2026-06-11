
 import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio/alert_sound_service.dart';
import '../core/auth/auth_service.dart';
import '../core/orders/mock_order_matcher.dart';
import '../core/profile/profile_service.dart';
import '../core/theme/app_theme.dart';

/// Fallback centre (Riyadh) until real GPS is available.
const double _mapCenterLat = 24.7136;
const double _mapCenterLng = 46.6753;
const double _mapZoom = 16.0;

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
  String _profileName = 'Courier';

  /// Courier online/offline status (persisted to SharedPreferences).
  bool _courierOnline = false;
  static const String _kCourierOnlineKey = 'courier_online';

  /// Real current position (GPS). Null until we get it or if permission denied.
  Position? _currentPosition;
  bool _locationLoading = false;

  /// Courier marker icon (van), loaded once from assets.
  BitmapDescriptor? _courierMarkerIcon;
  bool _courierMarkerIconLoading = false;

  /// True while searching for new order (disables button, shows status).
  bool _searchingForOrder = false;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _loadCourierOnline();
    _initializeLocation();
    if (widget.autoSearch) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startSearchForOrder(),
      );
    }
  }

  Future<void> _startSearchForOrder() async {
    if (!mounted) return;
    setState(() => _searchingForOrder = true);
    await _setCourierOnline(true);
    final order = await MockOrderMatcher.findNewOrder();
    await AlertSoundService.playOrderAlertSound();
    if (!mounted) return;
    context.go('/incoming-order', extra: order);
  }

  Future<void> _loadCourierOnline() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _courierOnline = prefs.getBool(_kCourierOnlineKey) ?? false,
      );
    }
  }

  Future<void> _setCourierOnline(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCourierOnlineKey, value);
    if (mounted) setState(() => _courierOnline = value);
  }
/// Load van marker icon once for map display (64–72 logical px, devicePixelRatio for sharpness).
  Future<void> _loadCourierMarkerIcon(BuildContext context) async {
    if (_courierMarkerIcon != null  _courierMarkerIconLoading) return;
    _courierMarkerIconLoading = true;
    try {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: const Size(72, 72), devicePixelRatio: dpr),
        'assets/markers/van_3d.png',
      );
      if (mounted) setState(() => _courierMarkerIcon = icon);
    } catch (_) {
      if (mounted) setState(() => _courierMarkerIconLoading = false);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfileName() async {
    final profile = await ProfileService.getProfile();
    if (mounted && profile != null) {
      final name = profile['fullName'] as String?;
      if (name != null && name.isNotEmpty) {
        setState(() => _profileName = name);
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
                'locationUnavailable'.tr,
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
      if (permission == LocationPermission.deniedForever 
          permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'locationPermissionDenied'.tr,
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
                'locationPermissionDenied'.tr,
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

  Future<void> _onGoToOnline() async {
    if (_searchingForOrder) return;
    setState(() => _searchingForOrder = true);
    await _setCourierOnline(true);

    final order = await MockOrderMatcher.findNewOrder();
    await AlertSoundService.playOrderAlertSound();

    if (!mounted) return;
    context.go('/incoming-order', extra: order);
  }

  @override
  Widget build(BuildContext context) {
    if (_courierMarkerIcon == null && !_courierMarkerIconLoading) {
      _loadCourierMarkerIcon(context);
    }
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final localeCode = Localizations.localeOf(context).languageCode;

    final initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(_mapCenterLat, _mapCenterLng);

    final Set<Marker> markers = {};
    if (_currentPosition != null && _courierMarkerIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('courier'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: _courierMarkerIcon!,
        ),
      );
    }
 return Scaffold(
      key: _scaffoldKey,
      drawer: isRtl ? null : _buildDrawer(theme),
      endDrawer: isRtl ? _buildDrawer(theme) : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen Google Map (courier shown as van marker; language from app locale)
          GoogleMap(
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
                    final rtl = Directionality.of(context) == TextDirection.rtl;
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
          // My Location floating button (fully visible above "Go To Online"; RTL-aware)
          PositionedDirectional(
            end: 16,
            bottom: MediaQuery.of(context).padding.bottom +
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
          if (_searchingForOrder)
            PositionedDirectional(
              start: 20,
              end: 20,
              bottom: MediaQuery.of(context).padding.bottom + 54 + 16,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          'searchingForNewOrder'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    onPressed: _searchingForOrder ? null : _onGoToOnline,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107), // bright yellow
                      foregroundColor: const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'goToOnline'.tr,
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
    );
  }
 Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: avatar, name, Offline chip
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profileName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
                            ? 'drawerStatusOnline'.tr
                            : 'drawerStatusOffline'.tr,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _courierOnline,
                        onChanged: (value) => _setCourierOnline(value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stats row: Income SAR 0.00 | Orders 0
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'SAR 0.00',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('income'.tr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '0',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('orders'.tr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Menu list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerTile(
                    theme,
                    'drawerOrders'.tr,
                    Icons.receipt_long_outlined,
                    () {
                      Navigator.of(context).pop();
                      context.go('/orders');
                    },
                  ),
                  _drawerTile(
                    theme,
                    'promotion'.tr,
                    Icons.campaign_outlined,
                    () => _showComingSoon(context),
                  ),
                  _drawerTile(
                    theme,
                    'inbox'.tr,
 Icons.inbox_outlined,
                    () => _showComingSoon(context),
                  ),
                  _drawerTile(
                    theme,
                    'appealCentre'.tr,
                    Icons.gavel_outlined,
                    () => _showComingSoon(context),
                  ),
                  _drawerTile(
                    theme,
                    'tutorialCentre'.tr,
                    Icons.school_outlined,
                    () => _showComingSoon(context),
                  ),
                  _drawerTile(
                    theme,
                    'contactCs'.tr,
                    Icons.support_agent_outlined,
                    () => _showComingSoon(context),
                  ),
                  _drawerTile(
                    theme,
                    'menuSettings'.tr,
                    Icons.settings_outlined,
                    () => _openSettings(context),
                  ),
                  const Divider(height: 24),
                  _drawerTile(
                    theme,
                    'menuLogout'.tr,
                    Icons.logout,
                    () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerTile(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    Navigator.of(context).pop(); // close drawer
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('comingSoon'.tr)));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pop();
    context.push('/home/settings');
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('drawerLogoutTitle'.tr),
        content: Text('drawerLogoutMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('drawerLogoutCancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('drawerLogoutYes'.tr),
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
