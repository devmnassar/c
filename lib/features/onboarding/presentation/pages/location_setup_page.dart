import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding/onboarding_state.dart';
import '../../../../l10n/app_localizations.dart';

class LocationSetupPage extends StatefulWidget {
  static const String id = '/location-setup';

  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  bool _loading = false;
  bool _enabled = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      await OnboardingState.instance.setLocationServiceEnabled(true);
      if (mounted) context.go('/map-status');
    }
  }

  Future<void> _tryEnable() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      if (!kIsWeb) {
        // Opens device location settings (Android); on iOS this may noop.
        await Geolocator.openLocationSettings();
      } else {
        // On web we can't open OS settings. User needs to enable in browser.
        _message = AppLocalizations.of(context)?.enableLocationDesc ??
            'Please enable location services to continue';
      }
      await Future.delayed(const Duration(milliseconds: 600));
      await _check();
    } catch (_) {
      setState(() {
        _message = AppLocalizations.of(context)?.enableLocationDesc ??
            'Please enable location services to continue';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _continueDemo() async {
    // For web demo mode, allow continuing even if location cannot be enabled.
    await OnboardingState.instance.setLocationServiceEnabled(true);
    if (mounted) context.go('/map-status');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Big map/location illustration
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'enableLocationTitle'.tr ?? 'Enable Location',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'enableLocationDesc'.tr ??
                          'Please enable location services to continue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // Bottom buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _tryEnable,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('enableLocation'.tr ?? 'Enable Location'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _check,
                      child: Text('retry'.tr ?? 'Retry'),
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _continueDemo,
                        child: Text('continueDemo'.tr ?? 'Continue (Demo)'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
