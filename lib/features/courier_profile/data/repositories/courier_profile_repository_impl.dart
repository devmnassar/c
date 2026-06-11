import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/courier_profile/data/datasources/courier_profile_local_data_source.dart';
import 'package:gaseel_courier/features/courier_profile/data/datasources/courier_profile_remote_data_source.dart';
import 'package:gaseel_courier/features/courier_profile/domain/entities/courier_profile.dart';
import 'package:gaseel_courier/features/courier_profile/domain/repositories/courier_profile_repository.dart';

class CourierProfileRepositoryImpl implements CourierProfileRepository {
  const CourierProfileRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  final CourierProfileRemoteDataSource _remoteDataSource;
  final CourierProfileLocalDataSource _localDataSource;

  @override
  Future<Either<ApiException, CourierProfile>> getCourierProfile() async {
    try {
      final model = await _remoteDataSource.getCourierProfile();
      final entity = model.toEntity();
      await _localDataSource.cacheCourierTypeId(entity.user.courierTypeId);
      return right(entity);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
