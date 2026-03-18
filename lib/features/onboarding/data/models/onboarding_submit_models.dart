class OnboardingSubmitRequestModel {
  const OnboardingSubmitRequestModel({
    required this.driverId,
    required this.declarationAccepted,
  });

  final String driverId;
  final bool declarationAccepted;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'driver_id': driverId,
      'declaration_accepted': declarationAccepted,
    };
  }
}

class OnboardingSubmitResponseModel {
  const OnboardingSubmitResponseModel({
    this.success,
    this.submissionId,
    this.status,
    this.message,
  });

  final bool? success;
  final String? submissionId;
  final String? status;
  final String? message;

  factory OnboardingSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    return OnboardingSubmitResponseModel(
      success: _parseBool(json['success'] ?? json['status']),
      submissionId:
          (json['submission_id'] ?? json['submissionId'] ?? json['id'])
              ?.toString(),
      status: json['status']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (success != null) 'success': success,
      if (submissionId != null) 'submission_id': submissionId,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    };
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
