class CourierProfile {
  const CourierProfile({
    required this.success,
    required this.message,
    required this.user,
    required this.state,
    required this.documents,
    this.zone,
  });

  final bool success;
  final String message;
  final CourierProfileUser user;
  final CourierProfileState state;
  final List<CourierProfileDocument> documents;
  final Map<String, dynamic>? zone;
}

class CourierProfileUser {
  const CourierProfileUser({
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
}

class CourierProfileState {
  const CourierProfileState({
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
}

class CourierProfileDocument {
  const CourierProfileDocument({
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
}
