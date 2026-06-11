import 'package:shared_preferences/shared_preferences.dart';

enum CourierWorkType {
  fullTime,
  freelancer,
}

class CourierWorkTypeService {
  CourierWorkTypeService._();

  static const String overrideKey = 'courier_work_type_override';

  static Future<CourierWorkType> resolve() async {
    final prefs = await SharedPreferences.getInstance();

    final override = prefs.getString(overrideKey);
    final fromOverride = _parseStringValue(override);
    if (fromOverride != null) {
      return fromOverride;
    }

    final fromStringCandidates = <String?>[
      prefs.getString('courierWorkType'),
      prefs.getString('courierType'),
      prefs.getString('driverType'),
      prefs.getString('employmentType'),
      prefs.getString('userType'),
    ];
    for (final candidate in fromStringCandidates) {
      final parsed = _parseStringValue(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    final isFreelancer = _firstTrue(<bool?>[
      prefs.getBool('isFreelancer'),
      prefs.getBool('isCompanyCourier'),
    ]);
    if (isFreelancer == true) {
      return CourierWorkType.freelancer;
    }

    final isFullTime = _firstTrue(<bool?>[
      prefs.getBool('isFullTimeCourier'),
      prefs.getBool('isFullTime'),
    ]);
    if (isFullTime == true) {
      return CourierWorkType.fullTime;
    }

    return CourierWorkType.fullTime;
  }

  static Future<void> setOverride(CourierWorkType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(overrideKey, type.name);
  }

  static CourierWorkType? _parseStringValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'freelancer':
      case 'company':
      case 'companycourier':
      case 'company_courier':
      case 'company-courier':
        return CourierWorkType.freelancer;
      case 'fulltime':
      case 'full_time':
      case 'full-time':
      case 'employee':
        return CourierWorkType.fullTime;
      default:
        return null;
    }
  }

  static bool? _firstTrue(List<bool?> values) {
    for (final value in values) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}
