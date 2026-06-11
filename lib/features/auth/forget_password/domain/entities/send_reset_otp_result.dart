class SendResetOtpResult {
  const SendResetOtpResult({
    required this.message,
    required this.expiresInSeconds,
    this.otpCode,
  });

  final String message;
  final int expiresInSeconds;
  final String? otpCode;
}
