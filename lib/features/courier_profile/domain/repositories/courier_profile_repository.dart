import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/courier_profile/domain/entities/courier_profile.dart';

abstract class CourierProfileRepository {
  Future<Either<ApiException, CourierProfile>> getCourierProfile();
}
