import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/auth_user.dart';
import '../entities/login_credentials.dart';

abstract class LoginRepository {
  Future<Either<ApiException, AuthUser>> login(LoginCredentials credentials);
}
