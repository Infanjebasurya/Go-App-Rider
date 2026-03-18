class DrivingLicenseDetailsModel {
  const DrivingLicenseDetailsModel({
    required this.success,
    this.id,
    this.driverId,
    this.documentType,
    this.documentUrl,
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
  final String? documentNumber;
  final String? expiryDateIso;
  final String? verificationStatus;
  final String? uploadedAtIso;
  final String? message;

  factory DrivingLicenseDetailsModel.fromJson(Map<String, dynamic> json) {
    return DrivingLicenseDetailsModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      documentType: (json['document_type'] ?? json['documentType'])?.toString(),
      documentUrl: (json['document_url'] ??
              json['documentUrl'] ??
              json['url'] ??
              json['file_url'] ??
              json['fileUrl'])
          ?.toString(),
      documentNumber:
          (json['document_number'] ?? json['dl_number'] ?? json['dlNumber'])
              ?.toString(),
      expiryDateIso: (json['expiry_date'] ?? json['expiryDate'])?.toString(),
      verificationStatus:
          (json['verification_status'] ?? json['verificationStatus'] ?? json['status'])
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
  final String? rcNumber;
  final String? verificationStatus;
  final String? uploadedAtIso;
  final String? message;

  factory VehicleRcDetailsModel.fromJson(Map<String, dynamic> json) {
    return VehicleRcDetailsModel(
      success: _parseBool(json['success'] ?? json['status']) ?? false,
      id: (json['id'] ?? json['documentId'] ?? json['document_id'])?.toString(),
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      documentType: (json['document_type'] ?? json['documentType'])?.toString(),
      documentUrl: (json['document_url'] ??
              json['documentUrl'] ??
              json['url'] ??
              json['file_url'] ??
              json['fileUrl'])
          ?.toString(),
      rcNumber:
          (json['rc_number'] ?? json['rcNumber'] ?? json['document_number'])
              ?.toString(),
      verificationStatus:
          (json['verification_status'] ?? json['verificationStatus'] ?? json['status'])
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

