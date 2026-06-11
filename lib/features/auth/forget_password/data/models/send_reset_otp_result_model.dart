import '../../domain/entities/send_reset_otp_result.dart';

class SendResetOtpResultModel {
  const SendResetOtpResultModel({
    required this.message,
    required this.expiresInSeconds,
    this.otpCode,
  });

  final String message;
  final int expiresInSeconds;
  final String? otpCode;

  factory SendResetOtpResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMessage = json['message'] ?? json['Message'];
    final dynamic rawExpiry =
        json['expiresInSeconds'] ?? json['ExpiresInSeconds'];
    final dynamic rawOtpCode = json['otpCode'] ?? json['OtpCode'];

    return SendResetOtpResultModel(
      message: (rawMessage as String?)?.trim() ?? 'OTP sent successfully.',
      expiresInSeconds: _parseExpiryInSeconds(rawExpiry) ?? 120,
      otpCode: _parseOtpCode(rawOtpCode),
    );
  }

  static int? _parseExpiryInSeconds(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static String? _parseOtpCode(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (raw is num) {
      return raw.toInt().toString();
    }
    return null;
  }

  SendResetOtpResult toEntity() {
    return SendResetOtpResult(
      message: message,
      expiresInSeconds: expiresInSeconds,
      otpCode: otpCode,
    );
  }
}
