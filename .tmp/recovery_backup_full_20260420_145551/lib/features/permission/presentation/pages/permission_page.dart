import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/onboarding/onboarding_state.dart';

enum PermissionStatus {
  initial,
  requesting,
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  PermissionStatus _status = PermissionStatus.initial;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    if (kIsWeb) {
      // For web, check if location services are available
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = PermissionStatus.unavailable;
        });
      } else {
        // Try to get current position to check permission
        try {
          await Geolocator.getCurrentPosition();
          setState(() {
            _status = PermissionStatus.granted;
          });
          _navigateToHome();
        } catch (e) {
          setState(() {
            _status = PermissionStatus.unavailable;
          });
        }
      }
      return;
    }

    // For mobile platforms
    final status = await Permission.location.status;
    setState(() {
      if (status.isGranted) {
        _status = PermissionStatus.granted;
        _navigateToHome();
      } else if (status.isDenied) {
        _status = PermissionStatus.denied;
      } else if (status.isPermanentlyDenied) {
        _status = PermissionStatus.permanentlyDenied;
      } else {
        _status = PermissionStatus.denied;
      }
    });
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      // For web, try to get location
      setState(() {
        _isLoading = true;
        _status = PermissionStatus.requesting;
      });

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _status = PermissionStatus.unavailable;
            _isLoading = false;
          });
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          setState(() {
            _status = PermissionStatus.granted;
            _isLoading = false;
          });
          _navigateToHome();
        } else {
          setState(() {
            _status = PermissionStatus.unavailable;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _status = PermissionStatus.unavailable;
          _isLoading = false;
        });
      }
      return;
    }

    // For mobile platforms
    setState(() {
      _isLoading = true;
      _status = PermissionStatus.requesting;
    });

    final status = await Permission.location.request();

    setState(() {
      _isLoading = false;
      if (status.isGranted) {
        _status = PermissionStatus.granted;
        _navigateToHome();
      } else if (status.isPermanentlyDenied) {
        _status = PermissionStatus.permanentlyDenied;
      } else {
        _status = PermissionStatus.denied;
      }
    });
  }

  Future<void> _openSettings() async {
    if (kIsWeb) {
      // Web doesn't have system settings, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'openSettings'.tr ??
                  'Please enable location in your browser settings',
            ),
          ),
        );
      }
      return;
    }

    await openAppSettings();
    // Recheck permission after returning from settings
    await Future.delayed(const Duration(milliseconds: 500));
    _checkPermissionStatus();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Legacy screen: treat as onboarding completion for permissions+location.
        OnboardingState.instance.setPermissionsGranted(true);
        OnboardingState.instance.setLocationServiceEnabled(true);
        context.go('/onboarding/profile');
      }
    });
  }

  void _continueDemo() {
    OnboardingState.instance.setPermissionsGranted(true);
    OnboardingState.instance.setLocationServiceEnabled(true);
    context.go('/onboarding/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('permission'.tr ?? 'Permission'),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case PermissionStatus.initial:
      case PermissionStatus.requesting:
        return _buildRequestingView();
      case PermissionStatus.granted:
        return _buildGrantedView();
      case PermissionStatus.denied:
        return _buildDeniedView(false);
      case PermissionStatus.permanentlyDenied:
        return _buildDeniedView(true);
      case PermissionStatus.unavailable:
        return _buildUnavailableView();
    }
  }

  Widget _buildRequestingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'locationPermissionRequired'.tr ?? 'Location Permission Required',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'locationPermissionDescription'.tr ??
                  'This app needs location permission to track deliveries and provide accurate delivery services.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              FilledButton(
                onPressed: _requestPermission,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('grantPermission'.tr ?? 'Grant Permission'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrantedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Permission Granted',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeniedView(bool isPermanentlyDenied) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              isPermanentlyDenied
                  ? ('permissionPermanentlyDenied'.tr ??
                      'Permission Permanently Denied')
                  : ('permissionDenied'.tr ?? 'Permission Denied'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanentlyDenied
                  ? ('permissionPermanentlyDeniedMessage'.tr ??
                      'Location permission has been permanently denied. Please enable it in your device settings to use this app.')
                  : ('permissionDeniedMessage'.tr ??
                      'Location permission is required for this app to function properly. Please grant permission in settings.'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton(
              onPressed:
                  isPermanentlyDenied ? _openSettings : _requestPermission,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                isPermanentlyDenied
                    ? ('openSettings'.tr ?? 'Open Settings')
                    : ('grantPermission'.tr ?? 'Grant Permission'),
              ),
            ),
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _openSettings,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('openSettings'.tr ?? 'Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'locationUnavailable'.tr ?? 'Location Unavailable',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'locationUnavailableMessage'.tr ??
                  'Unable to access location services. You can continue in demo mode.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: _continueDemo,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text('continueDemo'.tr ?? 'Continue (Demo)'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _requestPermission,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text('grantPermission'.tr ?? 'Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
