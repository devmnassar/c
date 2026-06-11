import '../../domain/entities/auth_user.dart';

class AuthUserModel {
  const AuthUserModel({
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

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAccessToken = json['accessToken'] ?? json['AccessToken'];
    final dynamic rawRefreshToken =
        json['refreshToken'] ?? json['RefreshToken'];
    final dynamic rawExpiresInMinutes =
        json['expiresInMinutes'] ?? json['ExpiresInMinutes'];
    final dynamic rawUserId = json['userId'] ?? json['UserId'];
    final dynamic rawUserName = json['userName'] ?? json['UserName'];
    final dynamic rawPhoneNumber = json['phoneNumber'] ?? json['PhoneNumber'];
    final dynamic rawIsActive = json['isActive'] ?? json['IsActive'];
    final dynamic rawIsRejected = json['isRejected'] ?? json['IsRejected'];
    final dynamic rawIsPhoneVerified =
        json['isPhoneVerified'] ?? json['IsPhoneVerified'];

    return AuthUserModel(
      accessToken: (rawAccessToken as String?) ?? '',
      refreshToken: (rawRefreshToken as String?) ?? '',
      expiresInMinutes: (rawExpiresInMinutes as num?)?.toInt() ?? 0,
      userId: (rawUserId as String?) ?? '',
      userName: (rawUserName as String?) ?? '',
      phoneNumber: (rawPhoneNumber as String?) ?? '',
      isActive: rawIsActive as bool? ?? false,
      isRejected: rawIsRejected as bool? ?? false,
      isPhoneVerified: rawIsPhoneVerified as bool? ?? false,
    );
  }

  AuthUser toEntity() {
    return AuthUser(
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
