import '../../domain/entities/verify_register_otp_result.dart';

class VerifyRegisterOtpResultModel {
  const VerifyRegisterOtpResultModel({
    required this.isVerified,
    required this.message,
  });

  final bool isVerified;
  final String message;

  factory VerifyRegisterOtpResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawIsVerified = json['isVerified'] ?? json['IsVerified'];
    final dynamic rawMessage = json['message'] ?? json['Message'];

    return VerifyRegisterOtpResultModel(
      isVerified: rawIsVerified as bool? ?? false,
      message: (rawMessage as String?)?.trim() ??
          'Unable to verify OTP. Please try again.',
    );
  }

  VerifyRegisterOtpResult toEntity() {
    return VerifyRegisterOtpResult(
      isVerified: isVerified,
      message: message,
    );
  }
}
