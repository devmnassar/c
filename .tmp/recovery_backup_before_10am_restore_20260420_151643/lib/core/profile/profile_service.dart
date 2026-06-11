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
  }
}
