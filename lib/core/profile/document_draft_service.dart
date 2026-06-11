import 'package:shared_preferences/shared_preferences.dart';

class DocumentDraftService {
  static const String _kIqamaGivenName = 'draft_iqama_given_name';
  static const String _kIqamaSurname = 'draft_iqama_surname';
  static const String _kIqamaDob = 'draft_iqama_dob';
  static const String _kIqamaGender = 'draft_iqama_gender';
  static const String _kIqamaNumber = 'draft_iqama_number';
  static const String _kIqamaExpiry = 'draft_iqama_expiry';
  static const String _kIqamaPhoto = 'draft_iqama_photo';

  static const String _kLicenseNumber = 'draft_license_number';
  static const String _kLicenseExpiry = 'draft_license_expiry';
  static const String _kLicenseFront = 'draft_license_front';
  static const String _kLicenseBack = 'draft_license_back';

  static const String _kVehiclePlate = 'draft_vehicle_plate';
  static const String _kVehicleSequence = 'draft_vehicle_sequence';
  static const String _kVehicleOwnerId = 'draft_vehicle_owner_id';
  static const String _kVehicleUserId = 'draft_vehicle_user_id';
  static const String _kVehicleBrand = 'draft_vehicle_brand';
  static const String _kVehiclePhoto = 'draft_vehicle_photo';

  static const String _kSelfiePhoto = 'draft_selfie_photo';
  static const String _kDriverCardPhoto = 'draft_driver_card_photo';

  static Future<void> saveIqamaDraft({
    required String givenName,
    required String surname,
    required String dob,
    required String gender,
    required String number,
    required String expiryDate,
    String? photoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIqamaGivenName, givenName);
    await prefs.setString(_kIqamaSurname, surname);
    await prefs.setString(_kIqamaDob, dob);
    await prefs.setString(_kIqamaGender, gender);
    await prefs.setString(_kIqamaNumber, number);
    await prefs.setString(_kIqamaExpiry, expiryDate);
    if (photoPath != null && photoPath.isNotEmpty) {
      await prefs.setString(_kIqamaPhoto, photoPath);
    }
  }

  static Future<Map<String, String>> getIqamaDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'givenName': prefs.getString(_kIqamaGivenName) ?? '',
      'surname': prefs.getString(_kIqamaSurname) ?? '',
      'dob': prefs.getString(_kIqamaDob) ?? '',
      'gender': prefs.getString(_kIqamaGender) ?? '',
      'number': prefs.getString(_kIqamaNumber) ?? '',
      'expiryDate': prefs.getString(_kIqamaExpiry) ?? '',
      'photoPath': prefs.getString(_kIqamaPhoto) ?? '',
    };
  }

  static Future<void> clearIqamaDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIqamaGivenName);
    await prefs.remove(_kIqamaSurname);
    await prefs.remove(_kIqamaDob);
    await prefs.remove(_kIqamaGender);
    await prefs.remove(_kIqamaNumber);
    await prefs.remove(_kIqamaExpiry);
    await prefs.remove(_kIqamaPhoto);
  }

  static Future<void> saveLicenseDraft({
    required String number,
    required String expiryDate,
    String? frontPath,
    String? backPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLicenseNumber, number);
    await prefs.setString(_kLicenseExpiry, expiryDate);
    if (frontPath != null && frontPath.isNotEmpty) {
      await prefs.setString(_kLicenseFront, frontPath);
    }
    if (backPath != null && backPath.isNotEmpty) {
      await prefs.setString(_kLicenseBack, backPath);
    }
  }

  static Future<Map<String, String>> getLicenseDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'number': prefs.getString(_kLicenseNumber) ?? '',
      'expiryDate': prefs.getString(_kLicenseExpiry) ?? '',
      'frontPath': prefs.getString(_kLicenseFront) ?? '',
      'backPath': prefs.getString(_kLicenseBack) ?? '',
    };
  }

  static Future<void> clearLicenseDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLicenseNumber);
    await prefs.remove(_kLicenseExpiry);
    await prefs.remove(_kLicenseFront);
    await prefs.remove(_kLicenseBack);
  }

  static Future<void> saveVehicleRegistrationDraft({
    required String plateNumber,
    required String sequenceNumber,
    required String ownerId,
    required String userId,
    required String brandName,
    String? photoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehiclePlate, plateNumber);
    await prefs.setString(_kVehicleSequence, sequenceNumber);
    await prefs.setString(_kVehicleOwnerId, ownerId);
    await prefs.setString(_kVehicleUserId, userId);
    await prefs.setString(_kVehicleBrand, brandName);
    if (photoPath != null && photoPath.isNotEmpty) {
      await prefs.setString(_kVehiclePhoto, photoPath);
    }
  }

  static Future<Map<String, String>> getVehicleRegistrationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'plateNumber': prefs.getString(_kVehiclePlate) ?? '',
      'sequenceNumber': prefs.getString(_kVehicleSequence) ?? '',
      'ownerId': prefs.getString(_kVehicleOwnerId) ?? '',
      'userId': prefs.getString(_kVehicleUserId) ?? '',
      'brandName': prefs.getString(_kVehicleBrand) ?? '',
      'photoPath': prefs.getString(_kVehiclePhoto) ?? '',
    };
  }

  static Future<void> clearVehicleRegistrationDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVehiclePlate);
    await prefs.remove(_kVehicleSequence);
    await prefs.remove(_kVehicleOwnerId);
    await prefs.remove(_kVehicleUserId);
    await prefs.remove(_kVehicleBrand);
    await prefs.remove(_kVehiclePhoto);
  }

  static Future<void> saveSelfieDraft(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString(_kSelfiePhoto, path);
    }
  }

  static Future<String> getSelfieDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelfiePhoto) ?? '';
  }

  static Future<void> clearSelfieDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSelfiePhoto);
  }

  static Future<void> saveDriverCardDraft(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString(_kDriverCardPhoto, path);
    }
  }

  static Future<String> getDriverCardDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDriverCardPhoto) ?? '';
  }

  static Future<void> clearDriverCardDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDriverCardPhoto);
  }
}
