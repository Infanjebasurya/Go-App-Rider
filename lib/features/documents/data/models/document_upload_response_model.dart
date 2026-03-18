class DocumentUploadResponseModel {
  const DocumentUploadResponseModel({
    this.documentId,
    this.fileUrl,
    this.status,
    this.message,
    this.success,
  });

  final String? documentId;
  final String? fileUrl;
  final String? status;
  final String? message;
  final bool? success;

  factory DocumentUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResponseModel(
      documentId: (json['document_id'] ?? json['documentId'] ?? json['id'])
          ?.toString(),
      fileUrl:
          (json['file_url'] ??
                  json['fileUrl'] ??
                  json['url'] ??
                  json['documentUrl'] ??
                  json['document_url'])
              ?.toString(),
      status: (json['status'] ?? json['verificationStatus'] ?? json['state'])
          ?.toString(),
      message: json['message']?.toString(),
      success: _parseBool(json['success'] ?? json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (documentId != null) 'document_id': documentId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (success != null) 'success': success,
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
