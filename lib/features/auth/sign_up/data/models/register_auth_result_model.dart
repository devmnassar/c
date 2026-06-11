import '../../domain/entities/register_auth_result.dart';

class RegisterAuthResultModel {
  const RegisterAuthResultModel({
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

  factory RegisterAuthResultModel.fromJson(Map<String, dynamic> json) {
    return RegisterAuthResultModel(
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
      expiresInMinutes: (json['expiresInMinutes'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as String?) ?? '',
      userName: (json['userName'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isRejected: json['isRejected'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
    );
  }

  RegisterAuthResult toEntity() {
    return RegisterAuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInMinutes: expiresInMinutes,
      userId: userId,
      userName: userName,
      phoneNumber: phoneNumber,
      isActive: isActive,
      isRejected: isRejected,
      isPhoneVerified: isPhoneVerified,
    );
  }
}
