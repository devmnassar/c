import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/localization/app_localizations.dart';

// Fallback location: Riyadh, Saudi Arabia
const double _fallbackLatitude = 24.7136;
const double _fallbackLongitude = 46.6753;
const double _defaultZoom = 15.0;

class MapPage extends StatefulWidget {
  static const String id = '/map';
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _locationServiceEnabled = false;
  String? _errorMessage;

  // Use fallback location initially
  double _latitude = _fallbackLatitude;
  double _longitude = _fallbackLongitude;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!_locationServiceEnabled) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _errorMessage = 'Location services are disabled';
        });
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _errorMessage = 'Location permission permanently denied';
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _errorMessage = 'Location permission denied';
        });
        return;
      }

      // Permission granted, get current position
      _hasPermission = true;
      setState(() {
        _isLoading = false; // Show map at fallback location immediately
      });
      _getCurrentLocation(); // Attempt to get real location in background
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Keep _hasPermission if it was granted before the error
        _errorMessage = 'Error initializing location: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        // Animate camera to current location
        _animateToLocation(_latitude, _longitude);
      }
    } catch (e) {
      debugPrint('Unable to get current location: $e');
      if (mounted) {
        setState(() {
          // Keep using fallback location, don't show error overlay if we have permission
          // _errorMessage = 'Unable to get current location';
        });
      }
    }
  }

  void _animateToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), _defaultZoom),
    );
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  Future<void> _retry() async {
    await _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF23C1B2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n?.map ?? 'Map'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasPermission && _currentPosition != null
          ? Stack(
              children: [
                GoogleMap(
                  key: ValueKey(
                    'map_${Localizations.localeOf(context).languageCode}',
                  ),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_latitude, _longitude),
                    zoom: _defaultZoom,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: LatLng(_latitude, _longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  },
                ),
                // Center FAB
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  bottom: 24,
                  end: 24,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_currentPosition != null) {
                        _animateToLocation(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        );
                      } else {
                        _animateToLocation(_latitude, _longitude);
                      }
                    },
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            )
          : _buildErrorView(l10n, theme, primaryColor),
    );
  }

  Widget _buildErrorView(
    AppLocalizations? l10n,
    ThemeData theme,
    Color primaryColor,
  ) {
    return Stack(
      children: [
        // Show map with fallback location even if permission denied
        GoogleMap(
          key: ValueKey('map_${Localizations.localeOf(context).languageCode}'),
          initialCameraPosition: CameraPosition(
            target: LatLng(_latitude, _longitude),
            zoom: _defaultZoom,
          ),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: {
            Marker(
              markerId: const MarkerId('fallback_location'),
              position: LatLng(_latitude, _longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          },
        ),
        // Error overlay
        Container(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _locationServiceEnabled
                        ? Icons.location_off
                        : Icons.location_disabled,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _locationServiceEnabled
                        ? (l10n?.locationPermissionDenied ??
                              'Location Permission Denied')
                        : (l10n?.locationUnavailable ?? 'Location Unavailable'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationServiceEnabled
                        ? (l10n?.locationPermissionDeniedMessage ??
                              'Location permission is required to show your current location. Please grant permission in settings.')
                        : (l10n?.locationUnavailableMessage ??
                              'Unable to access location services. You can continue in demo mode.'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings),
                        label: Text(l10n?.openSettings ?? 'Open Settings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n?.retry ?? 'Retry'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.mapShowingFallback ?? 'Showing Riyadh, Saudi Arabia',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Center FAB (still available even with error)
        Positioned.directional(
          textDirection: Directionality.of(context),
          bottom: 24,
          end: 24,
          child: FloatingActionButton(
            onPressed: () {
              _animateToLocation(_latitude, _longitude);
            },
            backgroundColor: primaryColor,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
