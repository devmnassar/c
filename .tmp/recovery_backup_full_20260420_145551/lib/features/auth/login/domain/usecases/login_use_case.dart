import '../entities/auth_user.dart';
import '../entities/login_credentials.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final LoginRepository _repository;

  Future<AuthUser> login(LoginCredentials credentials) {
    return _repository.login(credentials);
  }
}
