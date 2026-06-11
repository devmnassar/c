class RegisterAuthResult {
  const RegisterAuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInMinutes,
    required this.userId,
    required this.userName,
    required this.phoneNumber,
    required this.isActive,
    required this.isRejected,
    required this.isPhoneVerified,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInMinutes;
  final String userId;
  final String userName;
  final String phoneNumber;
  final bool isActive;
  final bool isRejected;
  final bool isPhoneVerified;
}
