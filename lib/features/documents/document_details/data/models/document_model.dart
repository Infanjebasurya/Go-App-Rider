class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.documentType,
    required this.documentUrl,
    required this.documentNumber,
    required this.verificationStatus,
    required this.uploadedAt,
    required this.isActive,
    this.aadhaarLast4,
    this.panNumber,
  });

  final String id;
  final String documentType;
  final String documentUrl;
  final String documentNumber;
  final String verificationStatus;
  final DateTime uploadedAt;
  final bool isActive;

  final String? aadhaarLast4;
  final String? panNumber;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final uploadedRaw = json['uploaded_at'] ?? json['uploadedAt'];
    DateTime uploadedAt;
    try {
      uploadedAt = DateTime.parse((uploadedRaw ?? '').toString()).toUtc();
    } catch (_) {
      uploadedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return DocumentModel(
      id: (json['id'] ?? '').toString(),
      documentType: (json['document_type'] ?? json['documentType'] ?? '')
          .toString(),
      documentUrl: (json['document_url'] ?? json['documentUrl'] ?? '')
          .toString(),
      documentNumber: (json['document_number'] ?? json['documentNumber'] ?? '')
          .toString(),
      verificationStatus:
          (json['verification_status'] ?? json['verificationStatus'] ?? '')
              .toString(),
      uploadedAt: uploadedAt,
      isActive: json['is_active'] == true || json['isActive'] == true,
      aadhaarLast4: (json['aadhaar_last4'] ?? json['aadhaarLast4'])?.toString(),
      panNumber: (json['pan_number'] ?? json['panNumber'])?.toString(),
    );
  }
}
