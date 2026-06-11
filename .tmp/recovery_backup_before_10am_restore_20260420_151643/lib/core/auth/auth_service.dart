import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import '../onboarding/onboarding_state.dart';
import '../profile/profile_service.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';

  static Future<bool> isLoggedIn() async {
    await OnboardingState.instance.ensureLoaded();
    return OnboardingState.instance.isLoggedIn;
  }

  static Future<void> login() async {
    // Keep backward compatibility with existing key and also update onboarding state.
    await SharedPrefHelper.setData(_isLoggedInKey, true);
    await OnboardingState.instance.setLoggedIn(true);
  }

  /// Full logout: clears auth flags, profile data, and onboarding state.
  /// Router (refreshListenable: OnboardingState) will re-evaluate and send user to /login.
  static Future<void> logout() async {
    await SharedPrefHelper.setData(_isLoggedInKey, false);
    await ProfileService.clearProfile();
    await OnboardingState.instance.logout();
  }
}
