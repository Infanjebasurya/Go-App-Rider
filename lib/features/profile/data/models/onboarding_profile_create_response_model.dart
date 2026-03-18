class OnboardingProfileCreateResponseModel {
  const OnboardingProfileCreateResponseModel({
    required this.success,
    required this.message,
    this.driverId,
    this.requestId,
  });

  final bool success;
  final String message;
  final String? driverId;
  final String? requestId;

  factory OnboardingProfileCreateResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OnboardingProfileCreateResponseModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      message: (json['message'] ?? json['error'] ?? '').toString(),
      driverId: json['driverId']?.toString() ?? json['driver_id']?.toString(),
      requestId:
          json['requestId']?.toString() ?? json['request_id']?.toString(),
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
