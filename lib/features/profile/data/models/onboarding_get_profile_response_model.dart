class OnboardingGetProfileResponseModel {
  const OnboardingGetProfileResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final OnboardingDriverProfileModel? data;

  factory OnboardingGetProfileResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dataRaw = json['data'];
    return OnboardingGetProfileResponseModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      message: (json['message'] ?? json['error'])?.toString(),
      data: dataRaw is Map<String, dynamic>
          ? OnboardingDriverProfileModel.fromJson(dataRaw)
          : null,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'success') return true;
      if (normalized == 'false' || normalized == 'failed') return false;
    }
    return null;
  }
}

class OnboardingDriverProfileModel {
  const OnboardingDriverProfileModel({
    required this.driverId,
    required this.fullName,
    required this.email,
    required this.dob,
    required this.gender,
  });

  final String driverId;
  final String fullName;
  final String email;
  final String dob;
  final String gender;

  factory OnboardingDriverProfileModel.fromJson(Map<String, dynamic> json) {
    return OnboardingDriverProfileModel(
      driverId: (json['driverId'] ?? json['driver_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      dob: (json['dob'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
    );
  }
}
