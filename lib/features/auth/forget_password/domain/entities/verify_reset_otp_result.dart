class VerifyResetOtpResult {
  const VerifyResetOtpResult({
    required this.isVerified,
    required this.message,
  });

  final bool isVerified;
  final String message;
}
