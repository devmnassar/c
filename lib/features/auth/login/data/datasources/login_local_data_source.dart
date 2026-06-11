import 'package:gaseel_courier/core/auth/auth_service.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/login_credentials.dart';

class LoginLocalDataSource {
  Future<AuthUser> login(LoginCredentials credentials) async {
    await AuthService.login();
    return AuthUser(
      accessToken: '',
      refreshToken: '',
      expiresInMinutes: 0,
      userId: '',
      userName: credentials.phoneNumber,
      phoneNumber: credentials.phoneNumber,
      isActive: false,
      isRejected: false,
      isPhoneVerified: false,
    );
  }
}
