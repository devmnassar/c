import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/di/dependency_injection.dart';
import 'package:gaseel_courier/core/firebase/fcm_token_service.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/courier_location_sync_cubit.dart';
import 'package:gaseel_courier/features/driver_availability/presentation/cubit/heartbeat_cubit.dart';
import '../onboarding/onboarding_state.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';

  static Future<bool> isLoggedIn() async {
    await OnboardingState.instance.ensureLoaded();
    return OnboardingState.instance.isLoggedIn;
  }

  static Future<void> login() async {
    // Keep backward compatibility with existing key and also update onboarding state.
    await SharedPrefHelper.setData(_isLoggedInKey, true);
    await OnboardingState.instance.setPermissionsGranted(false);
    await OnboardingState.instance.setLoggedIn(true);
  }

  /// Full logout: clears auth flags, profile data, and onboarding state.
  /// Router (refreshListenable: OnboardingState) will re-evaluate and send user to /login.
  static Future<void> logout() async {
    debugPrint('================ LOGOUT START ================');

    if (getIt.isRegistered<HeartbeatCubit>()) {
      await getIt<HeartbeatCubit>().stopHeartbeat(reason: 'Logout');
    }

    if (getIt.isRegistered<CourierLocationSyncCubit>()) {
      await getIt<CourierLocationSyncCubit>().stopLocationSync(reason: 'Logout');
    }

    // SharedPreferences auth/session keys
    const sharedPrefKeysToRemove = <String>[
      SharedPrefKeys.userToken,
      SharedPrefKeys.refreshToken,
      SharedPrefKeys.authUserId,
      SharedPrefKeys.authUserName,
      SharedPrefKeys.authPhoneNumber,
      SharedPrefKeys.authIsActive,
      SharedPrefKeys.authIsRejected,
      SharedPrefKeys.authIsPhoneVerified,
      SharedPrefKeys.authExpiresInMinutes,
      HeartbeatCubit.courierOnlineKey,
      'courierWorkType',
      'courierType',
      'driverType',
      'employmentType',
      'userType',
      'courier_work_type_override',
      'isFreelancer',
      'isCompanyCourier',
      'isFullTimeCourier',
      'isFullTime',
    ];

    for (final key in sharedPrefKeysToRemove) {
      await SharedPrefHelper.removeData(key);
      debugPrint('[LOGOUT] Removed SharedPreferences key: $key');
    }

    // Secure storage token keys
    const securedKeysToRemove = <String>[
      SharedPrefKeys.userToken,
      SharedPrefKeys.refreshToken,
    ];

    for (final key in securedKeysToRemove) {
      await SharedPrefHelper.removeSecuredData(key);
      debugPrint('[LOGOUT] Removed SecureStorage key: $key');
    }

    await SharedPrefHelper.setData(_isLoggedInKey, false);
    debugPrint('[LOGOUT] Updated auth flag: $_isLoggedInKey = false');

    await FcmTokenService.clearCachedToken();
    debugPrint('[LOGOUT] Cleared cached Firebase FCM token');

    await OnboardingState.instance.logout();
    debugPrint('[LOGOUT] Cleared onboarding/session state');
    debugPrint('================ LOGOUT DONE ================');
  }
}
