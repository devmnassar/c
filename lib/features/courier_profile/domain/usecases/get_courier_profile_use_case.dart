import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/courier_profile/domain/entities/courier_profile.dart';
import 'package:gaseel_courier/features/courier_profile/domain/repositories/courier_profile_repository.dart';

class GetCourierProfileUseCase {
  const GetCourierProfileUseCase(this._repository);

  final CourierProfileRepository _repository;

  Future<Either<ApiException, CourierProfile>> call() {
    return _repository.getCourierProfile();
  }
}
