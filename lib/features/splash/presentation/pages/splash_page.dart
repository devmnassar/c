import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/core/onboarding/onboarding_state.dart';

class SplashPage extends StatefulWidget {
  static const String id = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await OnboardingState.instance.ensureLoaded();
    await _handleFirstLaunchLocationPermission();
    await SharedPrefHelper.setData(SharedPrefKeys.splashCompleted, true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _handleFirstLaunchLocationPermission() async {
    final alreadyHandled = await SharedPrefHelper.getBool(
      SharedPrefKeys.locationPermissionPromptHandled,
    );
    if (alreadyHandled) {
      return;
    }

    await SharedPrefHelper.setData(
      SharedPrefKeys.locationPermissionPromptHandled,
      true,
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      await OnboardingState.instance.setLocationServiceEnabled(serviceEnabled);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final isGranted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!isGranted || !serviceEnabled) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final isoCode = placemarks.isNotEmpty
          ? placemarks.first.isoCountryCode?.toUpperCase()
          : null;

      if (isoCode != null && RegExp(r'^[A-Z]{2}$').hasMatch(isoCode)) {
        await SharedPrefHelper.setData(
          SharedPrefKeys.cachedDetectedPhoneIsoCode,
          isoCode,
        );
      }
    } catch (_) {
      // Continue to login even if location bootstrap is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Gaseel Courier',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
