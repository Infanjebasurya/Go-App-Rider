class ProfileImageUploadResponseModel {
  const ProfileImageUploadResponseModel({
    required this.success,
    this.requestId,
    this.message,
  });

  final bool success;
  final String? requestId;
  final String? message;

  factory ProfileImageUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileImageUploadResponseModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      requestId: (json['requestId'] ?? json['request_id'])?.toString(),
      message: (json['message'] ?? json['error'])?.toString(),
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
