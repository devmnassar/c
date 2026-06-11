import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_data_source.dart';

class LoginRepositoryImpl implements LoginRepository {
  const LoginRepositoryImpl(this._remoteDataSource);

  final LoginRemoteDataSource _remoteDataSource;

  @override
  Future<Either<ApiException, AuthUser>> login(
    LoginCredentials credentials,
  ) async {
    try {
      final model = await _remoteDataSource.login(credentials);
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
