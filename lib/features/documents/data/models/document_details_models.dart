class DrivingLicenseDetailsModel {
  const DrivingLicenseDetailsModel({
    required this.success,
    this.id,
    this.driverId,
    this.documentType,
    this.documentUrl,
    this.front,
    this.back,
    this.documentNumber,
    this.expiryDateIso,
    this.verificationStatus,
    this.uploadedAtIso,
    this.message,
  });

  final bool success;
  final String? id;
  final String? driverId;
  final String? documentType;
  final String? documentUrl;
  final DocumentSideDetailsModel? front;
  final DocumentSideDetailsModel? back;
  final String? documentNumber;
  final String? expiryDateIso;
  final String? verificationStatus;
  final String? uploadedAtIso;
  final String? message;

  factory DrivingLicenseDetailsModel.fromJson(Map<String, dynamic> json) {
    final dynamic frontRaw = json['front'];
    final dynamic backRaw = json['back'];
    final DocumentSideDetailsModel? front = frontRaw is Map<String, dynamic>
        ? DocumentSideDetailsModel.fromJson(frontRaw)
        : null;
    final DocumentSideDetailsModel? back = backRaw is Map<String, dynamic>
        ? DocumentSideDetailsModel.fromJson(backRaw)
        : null;

    final String? oldUrl =
        (json['document_url'] ??
                json['documentUrl'] ??
                json['url'] ??
                json['file_url'] ??
                json['fileUrl'])
            ?.toString();

    return DrivingLicenseDetailsModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      documentType: (json['document_type'] ?? json['documentType'])?.toString(),
      documentUrl: (oldUrl ?? front?.documentUrl ?? back?.documentUrl)
          ?.toString(),
      front: front,
      back: back,
      documentNumber:
          (json['document_number'] ?? json['dl_number'] ?? json['dlNumber'])
              ?.toString(),
      expiryDateIso: (json['expiry_date'] ?? json['expiryDate'])?.toString(),
      verificationStatus:
          (json['verification_status'] ??
                  json['verificationStatus'] ??
                  json['status'])
              ?.toString(),
      uploadedAtIso: (json['uploaded_at'] ?? json['uploadedAt'])?.toString(),
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

class VehicleRcDetailsModel {
  const VehicleRcDetailsModel({
    required this.success,
    this.id,
    this.driverId,
    this.documentType,
    this.documentUrl,
    this.front,
    this.back,
    this.rcNumber,
    this.verificationStatus,
    this.uploadedAtIso,
    this.message,
  });

  final bool success;
  final String? id;
  final String? driverId;
  final String? documentType;
  final String? documentUrl;
  final DocumentSideDetailsModel? front;
  final DocumentSideDetailsModel? back;
  final String? rcNumber;
  final String? verificationStatus;
  final String? uploadedAtIso;
  final String? message;

  factory VehicleRcDetailsModel.fromJson(Map<String, dynamic> json) {
    final dynamic frontRaw = json['front'];
    final dynamic backRaw = json['back'];
    final DocumentSideDetailsModel? front = frontRaw is Map<String, dynamic>
        ? DocumentSideDetailsModel.fromJson(frontRaw)
        : null;
    final DocumentSideDetailsModel? back = backRaw is Map<String, dynamic>
        ? DocumentSideDetailsModel.fromJson(backRaw)
        : null;

    final String? oldUrl =
        (json['document_url'] ??
                json['documentUrl'] ??
                json['url'] ??
                json['file_url'] ??
                json['fileUrl'])
            ?.toString();

    return VehicleRcDetailsModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      documentType: (json['document_type'] ?? json['documentType'])?.toString(),
      documentUrl: (oldUrl ?? front?.documentUrl ?? back?.documentUrl)
          ?.toString(),
      front: front,
      back: back,
      rcNumber:
          (json['rc_number'] ?? json['rcNumber'] ?? json['document_number'])
              ?.toString(),
      verificationStatus:
          (json['verification_status'] ??
                  json['verificationStatus'] ??
                  json['status'])
              ?.toString(),
      uploadedAtIso: (json['uploaded_at'] ?? json['uploadedAt'])?.toString(),
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

class DocumentSideDetailsModel {
  const DocumentSideDetailsModel({
    this.id,
    this.documentUrl,
    this.verificationStatus,
  });

  final String? id;
  final String? documentUrl;
  final String? verificationStatus;

  factory DocumentSideDetailsModel.fromJson(Map<String, dynamic> json) {
    return DocumentSideDetailsModel(
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      documentUrl:
          (json['document_url'] ??
                  json['documentUrl'] ??
                  json['url'] ??
                  json['file_url'] ??
                  json['fileUrl'])
              ?.toString(),
      verificationStatus:
          (json['verification_status'] ??
                  json['verificationStatus'] ??
                  json['status'])
              ?.toString(),
    );
  }
}
