class ApiConstants {
  // 🔗 Base URL
  static const String apiBaseUrl = "https://auth.gaseelexpress.sa";
  static const String courierApiBaseUrl = "https://courierbe.gaseelexpress.sa";

  // =========================
  // 🔐 OTP - Registration
  // =========================
  static const String sendRegisterOtp = "$apiBaseUrl/api/otp/register/send";
  static const String verifyRegisterOtp = "$apiBaseUrl/api/otp/register/verify";

  // =========================
  // 👤 Authentication
  // =========================
  static const String login = "$apiBaseUrl/api/auth/login";
  static const String register = "$apiBaseUrl/api/auth/register";

  // =========================
  // 🔄 Reset Password
  // =========================
  static const String sendResetPasswordOtp =
      "$apiBaseUrl/api/otp/reset-password/send";

  static const String verifyResetPasswordOtp =
      "$apiBaseUrl/api/otp/reset-password/verify";

  static const String resetPassword = "$apiBaseUrl/api/auth/reset-password";

  // =========================
  // 🔁 Tokens
  // =========================
  static const String refreshToken = "$apiBaseUrl/api/auth/refresh-token";

  // =========================
  // ⚙️ User
  // =========================
  static const String updateUserStatus = "$apiBaseUrl/api/users/status";

  static const String getOrders = "$courierApiBaseUrl/api/v1/mobile/orders";

  static const String getCurrentOrder =
      "$courierApiBaseUrl/api/v1/mobile/orders/current";

  static const String getCurrentOrderOffer =
      "$courierApiBaseUrl/api/v1/mobile/orders/offers/current";

  static String acceptOrderOffer(int offerId) =>
      "$courierApiBaseUrl/api/v1/mobile/orders/offers/$offerId/accept";

  static String rejectOrderOffer(int offerId) =>
      "$courierApiBaseUrl/api/v1/mobile/orders/offers/$offerId/reject";

  static String updateRiderStatus(String orderId) =>
      "$courierApiBaseUrl/api/v1/mobile/orders/$orderId/delivery-status";

  static String updatePickupStatus(String orderId) =>
      "$courierApiBaseUrl/api/v1/mobile/orders/$orderId/pickup-status";

  static String uploadProofPhoto(String orderId) =>
      "$courierApiBaseUrl/api/v1/mobile/orders/$orderId/proof-photo";

  static String getOrderChecklist(String orderId) =>
      "$courierApiBaseUrl/api/mobile/orders/$orderId/checklist";

  static String submitOrderChecklist(String orderId) =>
      "$courierApiBaseUrl/api/mobile/orders/$orderId/checklist";

  static const String goOnline =
      "$courierApiBaseUrl/api/driver-availability/go-online";

  static const String goOffline =
      "$courierApiBaseUrl/api/driver-availability/go-offline";

  static const String heartbeat =
      "$courierApiBaseUrl/api/driver-availability/heartbeat";

  /// SignalR hub for live courier location (`UpdateLocation`) and order events.
  static const String operationsHubUrl =
      "$courierApiBaseUrl/hubs/operations";

  static const String getCourierProfile = "$courierApiBaseUrl/api/courier/me";
}
