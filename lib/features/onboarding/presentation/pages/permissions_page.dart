import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/onboarding/onboarding_state.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../courier_profile/presentation/cubit/courier_profile_cubit.dart';
import '../../../../l10n/app_localizations.dart';

enum PermissionType { location, camera, contacts, notifications }

enum PermissionStatus { granted, denied, permanentlyDenied, notRequested }

class PermissionInfo {
  final PermissionType type;
  final IconData icon;
  final String nameKey;
  final String descKey;
  PermissionStatus status;
  bool isPermanentlyDenied;

  PermissionInfo({
    required this.type,
    required this.icon,
    required this.nameKey,
    required this.descKey,
    this.status = PermissionStatus.notRequested,
    this.isPermanentlyDenied = false,
  });
}

class PermissionsPage extends StatefulWidget {
  static const String id = '/permissions';

  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _loading = false;
  bool _hasPermanentlyDenied = false;

  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      type: PermissionType.location,
      icon: Icons.location_on,
      nameKey: 'locationPermissionName',
      descKey: 'locationPermissionDesc',
    ),
    PermissionInfo(
      type: PermissionType.camera,
      icon: Icons.camera_alt,
      nameKey: 'cameraPermissionName',
      descKey: 'cameraPermissionDesc',
    ),
    PermissionInfo(
      type: PermissionType.contacts,
      icon: Icons.contacts,
      nameKey: 'contactsPermissionName',
      descKey: 'contactsPermissionDesc',
    ),
    PermissionInfo(
      type: PermissionType.notifications,
      icon: Icons.notifications,
      nameKey: 'notificationsPermissionName',
      descKey: 'notificationsPermissionDesc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var hasPermanentlyDenied = false;

    if (kIsWeb) {
      // Web: check location only
      final perm = await Geolocator.checkPermission();
      final isGranted = perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      await OnboardingState.instance.setLocationServiceEnabled(serviceEnabled);
      setState(() {
        _permissions[0].status = isGranted
            ? PermissionStatus.granted
            : PermissionStatus.notRequested;
        _hasPermanentlyDenied = false;
      });
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    await OnboardingState.instance.setLocationServiceEnabled(serviceEnabled);

    // Check all permissions
    for (var permInfo in _permissions) {
      PermissionStatus status;
      bool isPermanentlyDenied = false;

      if (permInfo.type == PermissionType.location) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          status = PermissionStatus.granted;
        } else if (perm == LocationPermission.denied) {
          status = PermissionStatus.notRequested;
        } else {
          status = PermissionStatus.denied;
          isPermanentlyDenied = perm == LocationPermission.deniedForever;
        }
      } else {
        Permission permission;
        switch (permInfo.type) {
          case PermissionType.camera:
            permission = Permission.camera;
            break;
          case PermissionType.contacts:
            permission = Permission.contacts;
            break;
          case PermissionType.notifications:
            permission = Permission.notification;
            break;
          default:
            continue;
        }

        final statusValue = await permission.status;
        if (statusValue.isGranted) {
          status = PermissionStatus.granted;
        } else if (statusValue.isDenied) {
          status = PermissionStatus.notRequested;
        } else if (statusValue.isPermanentlyDenied) {
          status = PermissionStatus.denied;
          isPermanentlyDenied = true;
        } else {
          status = PermissionStatus.denied;
        }
      }

      setState(() {
        permInfo.status = status;
        permInfo.isPermanentlyDenied = isPermanentlyDenied;
        if (isPermanentlyDenied) hasPermanentlyDenied = true;
      });
    }

    if (!mounted) return;
    setState(() {
      _hasPermanentlyDenied = hasPermanentlyDenied;
    });
  }

  Future<void> _requestAllPermissions() async {
    final courierProfileCubit = context.read<CourierProfileCubit>();
    if (_loading || courierProfileCubit.state.isLoading) {
      return;
    }

    setState(() {
      _loading = true;
      _hasPermanentlyDenied = false;
    });

    try {
      if (kIsWeb) {
        // Web: request location only
        final perm = await Geolocator.requestPermission();
        final isGranted = perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always;
        setState(() {
          _permissions[0].status =
              isGranted ? PermissionStatus.granted : PermissionStatus.denied;
        });
        await _checkAllGrantedAndFetchProfile();
        return;
      }

      // Request all permissions
      for (var permInfo in _permissions) {
        if (permInfo.status == PermissionStatus.granted) continue;

        PermissionStatus newStatus;
        bool isPermanentlyDenied = false;

        if (permInfo.type == PermissionType.location) {
          final perm = await Geolocator.requestPermission();
          if (perm == LocationPermission.whileInUse ||
              perm == LocationPermission.always) {
            newStatus = PermissionStatus.granted;
          } else if (perm == LocationPermission.deniedForever) {
            newStatus = PermissionStatus.denied;
            isPermanentlyDenied = true;
          } else {
            newStatus = PermissionStatus.denied;
          }
        } else {
          Permission permission;
          switch (permInfo.type) {
            case PermissionType.camera:
              permission = Permission.camera;
              break;
            case PermissionType.contacts:
              permission = Permission.contacts;
              break;
            case PermissionType.notifications:
              permission = Permission.notification;
              break;
            default:
              continue;
          }

          final statusValue = await permission.request();
          if (statusValue.isGranted) {
            newStatus = PermissionStatus.granted;
          } else if (statusValue.isPermanentlyDenied) {
            newStatus = PermissionStatus.denied;
            isPermanentlyDenied = true;
          } else {
            newStatus = PermissionStatus.denied;
          }
        }

        setState(() {
          permInfo.status = newStatus;
          permInfo.isPermanentlyDenied = isPermanentlyDenied;
          if (isPermanentlyDenied) {
            _hasPermanentlyDenied = true;
          }
        });
      }

      await _checkAllGrantedAndFetchProfile();
    } catch (e) {
      // Handle error
      if (mounted) {
        await _checkPermissions();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkAllGrantedAndFetchProfile() async {
    final allGranted = _permissions.every(
      (p) => p.status == PermissionStatus.granted,
    );

    if (allGranted) {
      await context.read<CourierProfileCubit>().getCourierProfile();
    } else {
      // Re-check permissions in case user granted them from system dialog
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkPermissions();
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'Please grant all permissions first, then we will continue automatically.',
        );
      }
    }
  }

  String _getStatusText(AppLocalizations? l10n, PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'permissionGranted'.tr ?? 'Granted';
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return 'permissionDenied'.tr ?? 'Denied';
      case PermissionStatus.notRequested:
        return 'permissionNotRequested'.tr ?? 'Not requested';
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.notRequested:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allGranted = _permissions.every(
      (p) => p.status == PermissionStatus.granted,
    );
    final cubitLoading = context.select(
      (CourierProfileCubit cubit) => cubit.state.isLoading,
    );

    return BlocListener<CourierProfileCubit, CourierProfileState>(
      listener: (context, state) async {
        if (state.status == CourierProfileStatus.success) {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          await OnboardingState.instance.setLocationServiceEnabled(
            serviceEnabled,
          );
          await OnboardingState.instance.setPermissionsGranted(true);
          if (!context.mounted) return;
          context.go('/map-status');
        }

        if (state.status == CourierProfileStatus.failure && context.mounted) {
          AppSnackBar.showError(
            context,
            state.errorMessage ?? 'Failed to load courier profile.',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('permissionsTitle'.tr ?? 'App Permissions')),
        body: SafeArea(
          child: Column(
            children: [
              // Stepper header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'permissionsTitle'.tr ?? 'App Permissions',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'permissionsDescription'.tr ??
                          'We need these permissions to provide you with the best delivery experience.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Permission cards list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final perm = _permissions[index];
                    final name = _getLocalizedString(l10n, perm.nameKey);
                    final desc = _getLocalizedString(l10n, perm.descKey);
                    final statusText = _getStatusText(l10n, perm.status);
                    final statusColor = _getStatusColor(perm.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                perm.icon,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasPermanentlyDenied && !allGranted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'somePermissionsDenied'.tr ??
                              'Some permissions were denied. Please enable them in settings.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: (_loading || cubitLoading)
                            ? null
                            : _requestAllPermissions,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: (_loading || cubitLoading)
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                'allowAndContinue'.tr ?? 'Allow & Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (_hasPermanentlyDenied && !allGranted) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: (_loading || cubitLoading)
                              ? null
                              : openAppSettings,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'openSettings'.tr ?? 'Open Settings',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedString(AppLocalizations? l10n, String key) {
    switch (key) {
      case 'locationPermissionName':
        return 'locationPermissionName'.tr ?? 'Location';
      case 'locationPermissionDesc':
        return 'locationPermissionDesc'.tr ??
            'Track your location for accurate delivery tracking';
      case 'cameraPermissionName':
        return 'cameraPermissionName'.tr ?? 'Camera';
      case 'cameraPermissionDesc':
        return 'cameraPermissionDesc'.tr ??
            'Take photos of deliveries and documents';
      case 'contactsPermissionName':
        return 'contactsPermissionName'.tr ?? 'Contacts';
      case 'contactsPermissionDesc':
        return 'contactsPermissionDesc'.tr ?? 'Quick contact with customers';
      case 'notificationsPermissionName':
        return 'notificationsPermissionName'.tr ?? 'Notifications';
      case 'notificationsPermissionDesc':
        return 'notificationsPermissionDesc'.tr ??
            'Receive order updates and important alerts';
      default:
        return '';
    }
  }
}
