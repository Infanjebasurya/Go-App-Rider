class DocumentsListResponseModel {
  const DocumentsListResponseModel({
    required this.success,
    required this.documents,
    this.message,
  });

  final bool success;
  final List<DocumentListItemModel> documents;
  final String? message;

  factory DocumentsListResponseModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawDocs = json['documents'] ?? json['data'] ?? json['result'];
    final List<DocumentListItemModel> docs = rawDocs is List
        ? rawDocs
              .whereType<Map>()
              .map(
                (e) => DocumentListItemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <DocumentListItemModel>[];

    return DocumentsListResponseModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      documents: docs,
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

class DocumentListItemModel {
  const DocumentListItemModel({
    this.id,
    this.documentType,
    this.documentUrl,
    this.documentNumber,
    this.verificationStatus,
    this.rejectionReason,
  });

  final String? id;
  final String? documentType;
  final String? documentUrl;
  final String? documentNumber;
  final String? verificationStatus;
  final String? rejectionReason;

  factory DocumentListItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentListItemModel(
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      documentType: (json['document_type'] ?? json['documentType'])?.toString(),
      documentUrl:
          (json['document_url'] ??
                  json['documentUrl'] ??
                  json['url'] ??
                  json['file_url'] ??
                  json['fileUrl'])
              ?.toString(),
      documentNumber:
          (json['document_number'] ??
                  json['documentNumber'] ??
                  json['dl_number'] ??
                  json['rc_number'] ??
                  json['aadhaar_number'] ??
                  json['aadhar_number'] ??
                  json['pan_number'])
              ?.toString(),
      verificationStatus:
          (json['verification_status'] ??
                  json['verificationStatus'] ??
                  json['status'])
              ?.toString(),
      rejectionReason:
          (json['rejection_reason'] ??
                  json['rejectionReason'] ??
                  json['reason'])
              ?.toString(),
    );
  }
}
