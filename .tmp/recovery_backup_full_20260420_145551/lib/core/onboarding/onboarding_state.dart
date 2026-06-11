import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

class OnboardingState extends ChangeNotifier {
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kPermissionsGranted = 'permissionsGranted';
  static const _kLocationServiceEnabled = 'locationServiceEnabled';
  static const _kProfileCompleted = 'profileCompleted';
  static const _kDocumentsSubmitted = 'documentsSubmitted';
  static const _kReviewApproved = 'reviewApproved';

  OnboardingState._();

  static final OnboardingState instance = OnboardingState._();

  bool _loaded = false;
  Future<void>? _loadingFuture;

  bool _isLoggedIn = false;
  bool _permissionsGranted = false;
  bool _locationServiceEnabled = false;
  bool _profileCompleted = false;
  bool _documentsSubmitted = false;
  bool _reviewApproved = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get permissionsGranted => _permissionsGranted;
  bool get locationServiceEnabled => _locationServiceEnabled;
  bool get profileCompleted => _profileCompleted;
  bool get documentsSubmitted => _documentsSubmitted;
  bool get reviewApproved => _reviewApproved;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    _loadingFuture ??= _load();
    return _loadingFuture!;
  }

  Future<void> _load() async {
    _isLoggedIn = await SharedPrefHelper.getBool(_kIsLoggedIn);
    _permissionsGranted = await SharedPrefHelper.getBool(_kPermissionsGranted);
    _locationServiceEnabled = await SharedPrefHelper.getBool(
      _kLocationServiceEnabled,
    );
    _profileCompleted = await SharedPrefHelper.getBool(_kProfileCompleted);
    _documentsSubmitted = await SharedPrefHelper.getBool(_kDocumentsSubmitted);
    _reviewApproved = await SharedPrefHelper.getBool(_kReviewApproved);
    _loaded = true;
  }

  Future<void> setLoggedIn(bool value) async {
    await ensureLoaded();
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    await SharedPrefHelper.setData(_kIsLoggedIn, value);
    notifyListeners();
  }

  Future<void> setPermissionsGranted(bool value) async {
    await ensureLoaded();
    if (_permissionsGranted == value) return;
    _permissionsGranted = value;
    await SharedPrefHelper.setData(_kPermissionsGranted, value);
    notifyListeners();
  }

  Future<void> setLocationServiceEnabled(bool value) async {
    await ensureLoaded();
    if (_locationServiceEnabled == value) return;
    _locationServiceEnabled = value;
    await SharedPrefHelper.setData(_kLocationServiceEnabled, value);
    notifyListeners();
  }

  Future<void> setProfileCompleted(bool value) async {
    await ensureLoaded();
    if (_profileCompleted == value) return;
    _profileCompleted = value;
    await SharedPrefHelper.setData(_kProfileCompleted, value);
    notifyListeners();
  }

  Future<void> setDocumentsSubmitted(bool value) async {
    await ensureLoaded();
    if (_documentsSubmitted == value) return;
    _documentsSubmitted = value;
    await SharedPrefHelper.setData(_kDocumentsSubmitted, value);
    notifyListeners();
  }

  Future<void> setReviewApproved(bool value) async {
    await ensureLoaded();
    if (_reviewApproved == value) return;
    _reviewApproved = value;
    await SharedPrefHelper.setData(_kReviewApproved, value);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await ensureLoaded();
    _permissionsGranted = false;
    _locationServiceEnabled = false;
    _profileCompleted = false;
    await SharedPrefHelper.setData(_kPermissionsGranted, false);
    await SharedPrefHelper.setData(_kLocationServiceEnabled, false);
    await SharedPrefHelper.setData(_kProfileCompleted, false);
    notifyListeners();
  }

  Future<void> logout() async {
    await ensureLoaded();
    _isLoggedIn = false;
    _permissionsGranted = false;
    _locationServiceEnabled = false;
    _profileCompleted = false;
    await SharedPrefHelper.setData(_kIsLoggedIn, false);
    await SharedPrefHelper.setData(_kPermissionsGranted, false);
    await SharedPrefHelper.setData(_kLocationServiceEnabled, false);
    await SharedPrefHelper.setData(_kProfileCompleted, false);
    // Clear app locale preference (optional - user can keep language preference)
    // await prefs.remove('app_locale');
    notifyListeners();
  }
}
