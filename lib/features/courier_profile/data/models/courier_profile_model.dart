import 'package:gaseel_courier/features/courier_profile/domain/entities/courier_profile.dart';

class CourierProfileModel {
  const CourierProfileModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final CourierProfileDataModel data;

  factory CourierProfileModel.fromJson(Map<String, dynamic> json) {
    return CourierProfileModel(
      success: json['success'] == true,
      message: (json['message'] as String?)?.trim() ?? '',
      data: CourierProfileDataModel.fromJson(
        json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  CourierProfile toEntity() {
    return CourierProfile(
      success: success,
      message: message,
      user: data.user.toEntity(),
      state: data.state.toEntity(),
      documents: data.documents.map((document) => document.toEntity()).toList(),
      zone: data.zone,
    );
  }
}

class CourierProfileDataModel {
  const CourierProfileDataModel({
    required this.user,
    required this.state,
    required this.documents,
    required this.zone,
  });

  final CourierProfileUserModel user;
  final CourierProfileStateModel state;
  final List<CourierProfileDocumentModel> documents;
  final Map<String, dynamic>? zone;

  factory CourierProfileDataModel.fromJson(Map<String, dynamic> json) {
    return CourierProfileDataModel(
      user: CourierProfileUserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      state: CourierProfileStateModel.fromJson(
        json['state'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      documents: (json['documents'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CourierProfileDocumentModel.fromJson)
          .toList(),
      zone: json['zone'] is Map<String, dynamic>
          ? json['zone'] as Map<String, dynamic>
          : null,
    );
  }
}

class CourierProfileUserModel {
  const CourierProfileUserModel({
    required this.authUserId,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.profileImageUrl,
    required this.address,
    required this.languages,
    required this.qualification,
    required this.yearsOfExperience,
    required this.country,
    required this.countryId,
    required this.courierType,
    required this.courierTypeId,
    required this.workPermissionStatus,
  });

  final String authUserId;
  final String name;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String? profileImageUrl;
  final String address;
  final String languages;
  final String qualification;
  final int yearsOfExperience;
  final String country;
  final int countryId;
  final String courierType;
  final int courierTypeId;
  final String workPermissionStatus;

  factory CourierProfileUserModel.fromJson(Map<String, dynamic> json) {
    return CourierProfileUserModel(
      authUserId: (json['authUserId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      dateOfBirth: (json['dateOfBirth'] as String?)?.trim() ?? '',
      profileImageUrl: (json['profileImageUrl'] as String?)?.trim(),
      address: (json['address'] as String?)?.trim() ?? '',
      languages: (json['languages'] as String?)?.trim() ?? '',
      qualification: (json['qualification'] as String?)?.trim() ?? '',
      yearsOfExperience: _asInt(json['yearsOfExperience']),
      country: (json['country'] as String?)?.trim() ?? '',
      countryId: _asInt(json['countryId']),
      courierType: (json['courierType'] as String?)?.trim() ?? '',
      courierTypeId: _asInt(json['courierTypeId']),
      workPermissionStatus:
          (json['workPermissionStatus'] as String?)?.trim() ?? '',
    );
  }

  CourierProfileUser toEntity() {
    return CourierProfileUser(
      authUserId: authUserId,
      name: name,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      profileImageUrl: profileImageUrl,
      address: address,
      languages: languages,
      qualification: qualification,
      yearsOfExperience: yearsOfExperience,
      country: country,
      countryId: countryId,
      courierType: courierType,
      courierTypeId: courierTypeId,
      workPermissionStatus: workPermissionStatus,
    );
  }
}

class CourierProfileStateModel {
  const CourierProfileStateModel({
    required this.basicInfoStatus,
    required this.documentsStatus,
    required this.currentStep,
    required this.basicInfoReviewNotes,
    required this.documentsReviewNotes,
    required this.lastUpdatedAt,
  });

  final String basicInfoStatus;
  final String documentsStatus;
  final String currentStep;
  final String? basicInfoReviewNotes;
  final String? documentsReviewNotes;
  final String lastUpdatedAt;

  factory CourierProfileStateModel.fromJson(Map<String, dynamic> json) {
    return CourierProfileStateModel(
      basicInfoStatus: (json['basicInfoStatus'] as String?)?.trim() ?? '',
      documentsStatus: (json['documentsStatus'] as String?)?.trim() ?? '',
      currentStep: (json['currentStep'] as String?)?.trim() ?? '',
      basicInfoReviewNotes: (json['basicInfoReviewNotes'] as String?)?.trim(),
      documentsReviewNotes: (json['documentsReviewNotes'] as String?)?.trim(),
      lastUpdatedAt: (json['lastUpdatedAt'] as String?)?.trim() ?? '',
    );
  }

  CourierProfileState toEntity() {
    return CourierProfileState(
      basicInfoStatus: basicInfoStatus,
      documentsStatus: documentsStatus,
      currentStep: currentStep,
      basicInfoReviewNotes: basicInfoReviewNotes,
      documentsReviewNotes: documentsReviewNotes,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

class CourierProfileDocumentModel {
  const CourierProfileDocumentModel({
    required this.documentType,
    required this.status,
    required this.reviewNotes,
    required this.isSubmitted,
    required this.submittedAt,
    required this.lastUpdatedAt,
  });

  final String documentType;
  final String status;
  final String? reviewNotes;
  final bool isSubmitted;
  final String? submittedAt;
  final String? lastUpdatedAt;

  factory CourierProfileDocumentModel.fromJson(Map<String, dynamic> json) {
    return CourierProfileDocumentModel(
      documentType: (json['documentType'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      reviewNotes: (json['reviewNotes'] as String?)?.trim(),
      isSubmitted: json['isSubmitted'] == true,
      submittedAt: (json['submittedAt'] as String?)?.trim(),
      lastUpdatedAt: (json['lastUpdatedAt'] as String?)?.trim(),
    );
  }

  CourierProfileDocument toEntity() {
    return CourierProfileDocument(
      documentType: documentType,
      status: status,
      reviewNotes: reviewNotes,
      isSubmitted: isSubmitted,
      submittedAt: submittedAt,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
