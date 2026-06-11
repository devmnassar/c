/// Central route path constants for [GoRouter].
///
/// Phase 1: additive only — not imported by production code yet.
/// Strings must match [AppRouter] and page `static const id` values exactly.
class RoutePaths {
  const RoutePaths._();

  // ---------------------------------------------------------------------------
  // Core / auth / onboarding
  // ---------------------------------------------------------------------------

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const signupOtp = '/signup/otp';
  static const signupDocuments = '/signup/documents';
  static const signupAwaitingReview = '/signup/awaiting-review';
  static const signupDetails = '/signup/details';
  static const signupWelcome = '/signup/welcome';

  static const forgetPassword = '/forget-password';
  static const forgetPasswordOtp = '/forget-password/otp';
  static const forgetPasswordCreatePassword =
      '/forget-password/create-password';

  static const permissions = '/permissions';
  static const locationSetup = '/location-setup';

  /// Legacy redirect target in [AppRouter] — maps to [permissions].
  static const permissionLegacy = '/permission';

  // ---------------------------------------------------------------------------
  // Document upload (KYC) — paths from page `id` constants
  // ---------------------------------------------------------------------------

  static const docIqama = '/signup/documents/iqama';
  static const docSelfie = '/signup/documents/selfie';
  static const docLicense = '/signup/documents/license';
  static const docRegistration = '/signup/documents/registration';
  static const docDriverCard = '/signup/documents/driver-card';

  // ---------------------------------------------------------------------------
  // Main app shell
  // ---------------------------------------------------------------------------

  static const home = '/home';
  static const homeOrders = '/home/orders';
  static const homeStats = '/home/stats';
  static const homeProfile = '/home/profile';
  static const homeSettings = '/home/settings';

  static const orders = '/orders';
  static const stats = '/stats';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const map = '/map';

  // ---------------------------------------------------------------------------
  // Courier operational flows
  // ---------------------------------------------------------------------------

  static const mapStatus = '/map-status';
  static const incomingOrder = '/incoming-order';
  static const incomingOrderMap = '/incoming-order/map';

  static String activeTrip(String orderId) => '/active-trip/$orderId';

  static String activeTripMap(String orderId) => '/active-trip/$orderId/map';
}
