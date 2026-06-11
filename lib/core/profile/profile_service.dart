import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _kFullName = 'profile_fullName';
  static const String _kMobileNumber = 'profile_mobileNumber';
  static const String _kE164Number = 'profile_e164Number';
  static const String _kNationalNumber = 'profile_nationalNumber';
  static const String _kNationalId = 'profile_nationalId';
  static const String _kPhotoPath = 'profile_photoPath';
  static const String _kPhoneVerified = 'profile_phoneVerified';
  static const String _kLicensePath = 'profile_licensePath';
  static const String _kNationalIdPath = 'profile_nationalIdPath';
  static const String _kVehicleType = 'profile_vehicleType';
  static const String _kPlateNumber = 'profile_plateNumber';
  static const String _kInsuranceNumber = 'profile_insuranceNumber';
  static const String _kReviewApproved = 'profile_reviewApproved';
  static const String _kDriverCardPath = 'profile_driverCardPath';
  static const String _kIqamaPath = 'profile_iqamaPath';
  static const String _kIqamaGivenName = 'profile_iqamaGivenName';
  static const String _kIqamaSurname = 'profile_iqamaSurname';
  static const String _kIqamaDob = 'profile_iqamaDob';
  static const String _kIqamaGender = 'profile_iqamaGender';
  static const String _kIqamaNumber = 'profile_iqamaNumber';
  static const String _kIqamaExpiryDate = 'profile_iqamaExpiryDate';
  static const String _kLicenseFrontPath = 'profile_licenseFrontPath';
  static const String _kLicenseBackPath = 'profile_licenseBackPath';
  static const String _kLicenseNumber = 'profile_licenseNumber';
  static const String _kLicenseExpiryDate = 'profile_licenseExpiryDate';
  static const String _kSelfiePath = 'profile_selfiePath';
  static const String _kVehicleRegistrationPath =
      'profile_vehicleRegistrationPath';
  static const String _kVehicleSequenceNumber = 'profile_vehicleSequenceNumber';
  static const String _kVehicleOwnerId = 'profile_vehicleOwnerId';
  static const String _kVehicleUserId = 'profile_vehicleUserId';
  static const String _kVehicleBrandName = 'profile_vehicleBrandName';

  static Future<void> saveProfile({
    required String fullName,
    required String e164Number,
    required String nationalNumber,
    required String photoPath,
    String? nationalId,
    bool phoneVerified = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFullName, fullName);
    await prefs.setString(_kE164Number, e164Number);
    await prefs.setString(_kNationalNumber, nationalNumber);
    // Keep mobileNumber for backward compatibility
    await prefs.setString(_kMobileNumber, e164Number);
    await prefs.setString(_kPhotoPath, photoPath);
    if (nationalId != null && nationalId.isNotEmpty) {
      await prefs.setString(_kNationalId, nationalId);
    }
    await prefs.setBool(_kPhoneVerified, phoneVerified);
  }

  static Future<void> saveDocuments({
    required String licensePath,
    required String nationalIdPath,
    required String vehicleType,
    required String plateNumber,
    required String insuranceNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLicensePath, licensePath);
    await prefs.setString(_kNationalIdPath, nationalIdPath);
    await prefs.setString(_kVehicleType, vehicleType);
    await prefs.setString(_kPlateNumber, plateNumber);
    await prefs.setString(_kInsuranceNumber, insuranceNumber);
  }

  static Future<void> saveDriverCard(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDriverCardPath, path);
  }

  static Future<void> saveIqama({
    required String path,
    required String givenName,
    required String surname,
    required String dob,
    required String gender,
    required String number,
    required String expiryDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIqamaPath, path);
    await prefs.setString(_kIqamaGivenName, givenName);
    await prefs.setString(_kIqamaSurname, surname);
    await prefs.setString(_kIqamaDob, dob);
    await prefs.setString(_kIqamaGender, gender);
    await prefs.setString(_kIqamaNumber, number);
    await prefs.setString(_kIqamaExpiryDate, expiryDate);
  }

  static Future<void> saveLicense({
    required String frontPath,
    required String backPath,
    required String number,
    required String expiryDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLicenseFrontPath, frontPath);
    await prefs.setString(_kLicenseBackPath, backPath);
    await prefs.setString(_kLicenseNumber, number);
    await prefs.setString(_kLicenseExpiryDate, expiryDate);
  }

  static Future<void> saveSelfie(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelfiePath, path);
  }

  static Future<void> saveVehicleRegistration({
    required String path,
    required String plateNumber,
    required String sequenceNumber,
    required String ownerId,
    required String userId,
    required String brandName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleRegistrationPath, path);
    await prefs.setString(_kPlateNumber, plateNumber);
    await prefs.setString(_kVehicleSequenceNumber, sequenceNumber);
    await prefs.setString(_kVehicleOwnerId, ownerId);
    await prefs.setString(_kVehicleUserId, userId);
    await prefs.setString(_kVehicleBrandName, brandName);
  }

  static Future<void> setReviewApproved(bool approved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReviewApproved, approved);
  }

  static Future<bool> isReviewApproved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReviewApproved) ?? false;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_kFullName);
    final e164Number =
        prefs.getString(_kE164Number) ?? prefs.getString(_kMobileNumber);
    final nationalNumber = prefs.getString(_kNationalNumber);
    final photoPath = prefs.getString(_kPhotoPath);

    if (fullName == null || e164Number == null || photoPath == null) {
      return null;
    }

    return {
      'fullName': fullName,
      'mobileNumber': e164Number,
      'e164Number': e164Number,
      'nationalNumber': nationalNumber,
      'photoPath': photoPath,
      'nationalId': prefs.getString(_kNationalId),
      'phoneVerified': prefs.getBool(_kPhoneVerified) ?? false,
      'licensePath': prefs.getString(_kLicensePath),
      'nationalIdPath': prefs.getString(_kNationalIdPath),
      'vehicleType': prefs.getString(_kVehicleType),
      'plateNumber': prefs.getString(_kPlateNumber),
      'insuranceNumber': prefs.getString(_kInsuranceNumber),
      'reviewApproved': prefs.getBool(_kReviewApproved) ?? false,
      'driverCardPath': prefs.getString(_kDriverCardPath),
      'iqamaPath': prefs.getString(_kIqamaPath),
      'iqamaGivenName': prefs.getString(_kIqamaGivenName),
      'iqamaSurname': prefs.getString(_kIqamaSurname),
      'iqamaDob': prefs.getString(_kIqamaDob),
      'iqamaGender': prefs.getString(_kIqamaGender),
      'iqamaNumber': prefs.getString(_kIqamaNumber),
      'iqamaExpiryDate': prefs.getString(_kIqamaExpiryDate),
      'licenseFrontPath': prefs.getString(_kLicenseFrontPath),
      'licenseBackPath': prefs.getString(_kLicenseBackPath),
      'licenseNumber': prefs.getString(_kLicenseNumber),
      'licenseExpiryDate': prefs.getString(_kLicenseExpiryDate),
      'selfiePath': prefs.getString(_kSelfiePath),
      'vehicleRegistrationPath': prefs.getString(_kVehicleRegistrationPath),
      'vehicleSequenceNumber': prefs.getString(_kVehicleSequenceNumber),
      'vehicleOwnerId': prefs.getString(_kVehicleOwnerId),
      'vehicleUserId': prefs.getString(_kVehicleUserId),
      'vehicleBrandName': prefs.getString(_kVehicleBrandName),
    };
  }

  static Future<void> setPhoneVerified(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPhoneVerified, verified);
  }

  static Future<bool> isPhoneVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPhoneVerified) ?? false;
  }

  /// Clears all stored profile data (used on full logout).
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFullName);
    await prefs.remove(_kMobileNumber);
    await prefs.remove(_kE164Number);
    await prefs.remove(_kNationalNumber);
    await prefs.remove(_kNationalId);
    await prefs.remove(_kPhotoPath);
    await prefs.remove(_kPhoneVerified);
    await prefs.remove(_kLicensePath);
    await prefs.remove(_kNationalIdPath);
    await prefs.remove(_kVehicleType);
    await prefs.remove(_kPlateNumber);
    await prefs.remove(_kInsuranceNumber);
    await prefs.remove(_kReviewApproved);
    await prefs.remove(_kDriverCardPath);
    await prefs.remove(_kIqamaPath);
    await prefs.remove(_kIqamaGivenName);
    await prefs.remove(_kIqamaSurname);
    await prefs.remove(_kIqamaDob);
    await prefs.remove(_kIqamaGender);
    await prefs.remove(_kIqamaNumber);
    await prefs.remove(_kIqamaExpiryDate);
    await prefs.remove(_kLicenseFrontPath);
    await prefs.remove(_kLicenseBackPath);
    await prefs.remove(_kLicenseNumber);
    await prefs.remove(_kLicenseExpiryDate);
    await prefs.remove(_kSelfiePath);
    await prefs.remove(_kVehicleRegistrationPath);
    await prefs.remove(_kVehicleSequenceNumber);
    await prefs.remove(_kVehicleOwnerId);
    await prefs.remove(_kVehicleUserId);
    await prefs.remove(_kVehicleBrandName);
  }
}
