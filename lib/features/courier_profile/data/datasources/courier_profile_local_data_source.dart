import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

class CourierProfileLocalDataSource {
  const CourierProfileLocalDataSource();

  Future<void> cacheCourierTypeId(int courierTypeId) {
    return SharedPrefHelper.setData(
        SharedPrefKeys.courierTypeId, courierTypeId);
  }

  Future<int?> getCachedCourierTypeId() {
    return SharedPrefHelper.getNullableInt(SharedPrefKeys.courierTypeId);
  }
}
