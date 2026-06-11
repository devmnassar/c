class VerifyRegisterOtpResult {
  const VerifyRegisterOtpResult({
    required this.isVerified,
    required this.message,
  });

  final bool isVerified;
  final String message;
}
