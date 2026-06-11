import '../../domain/entities/verify_reset_otp_result.dart';

class VerifyResetOtpResultModel {
  const VerifyResetOtpResultModel({
    required this.isVerified,
    required this.message,
  });

  final bool isVerified;
  final String message;

  factory VerifyResetOtpResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawIsVerified = json['isVerified'] ?? json['IsVerified'];
    final dynamic rawMessage = json['message'] ?? json['Message'];

    return VerifyResetOtpResultModel(
      isVerified: rawIsVerified as bool? ?? false,
      message: (rawMessage as String?)?.trim() ??
          'Unable to verify OTP. Please try again.',
    );
  }

  VerifyResetOtpResult toEntity() {
    return VerifyResetOtpResult(
      isVerified: isVerified,
      message: message,
    );
  }
}
