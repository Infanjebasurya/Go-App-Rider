import 'package:goapp/features/documents/data/models/document_upload_response_model.dart';

class DrivingLicenseSideModel {
  const DrivingLicenseSideModel({
    this.id,
    this.documentUrl,
    this.verificationStatus,
  });

  final String? id;
  final String? documentUrl;
  final String? verificationStatus;

  factory DrivingLicenseSideModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);
    return DrivingLicenseSideModel(
      id: base.documentId,
      documentUrl: base.fileUrl,
      verificationStatus: base.status,
    );
  }
}

class VehicleRcSideModel {
  const VehicleRcSideModel({
    this.id,
    this.documentUrl,
    this.verificationStatus,
  });

  final String? id;
  final String? documentUrl;
  final String? verificationStatus;

  factory VehicleRcSideModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);
    return VehicleRcSideModel(
      id: base.documentId,
      documentUrl: base.fileUrl,
      verificationStatus: base.status,
    );
  }
}

class UploadProfileImageResponseModel extends DocumentUploadResponseModel {
  const UploadProfileImageResponseModel({
    super.documentId,
    super.fileUrl,
    super.status,
    super.message,
    super.success,
  });

  factory UploadProfileImageResponseModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);
    return UploadProfileImageResponseModel(
      documentId: base.documentId,
      fileUrl: base.fileUrl,
      status: base.status,
      message: base.message,
      success: base.success,
    );
  }
}

class UploadDrivingLicenseResponseModel extends DocumentUploadResponseModel {
  const UploadDrivingLicenseResponseModel({
    this.documentType,
    this.front,
    this.back,
    super.documentId,
    super.fileUrl,
    super.status,
    super.message,
    super.success,
  });

  final String? documentType;
  final DrivingLicenseSideModel? front;
  final DrivingLicenseSideModel? back;

  factory UploadDrivingLicenseResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final base = DocumentUploadResponseModel.fromJson(json);

    final dynamic frontRaw = json['front'];
    final dynamic backRaw = json['back'];
    final DrivingLicenseSideModel? front = frontRaw is Map<String, dynamic>
        ? DrivingLicenseSideModel.fromJson(frontRaw)
        : null;
    final DrivingLicenseSideModel? back = backRaw is Map<String, dynamic>
        ? DrivingLicenseSideModel.fromJson(backRaw)
        : null;

    final String? derivedId = (base.documentId ?? front?.id ?? back?.id)
        ?.toString();
    final String? derivedUrl =
        (base.fileUrl ?? front?.documentUrl ?? back?.documentUrl)?.toString();
    final String? derivedStatus =
        (base.status ?? front?.verificationStatus ?? back?.verificationStatus)
            ?.toString();

    return UploadDrivingLicenseResponseModel(
      documentType: json['documentType']?.toString(),
      front: front,
      back: back,
      documentId: derivedId,
      fileUrl: derivedUrl,
      status: derivedStatus,
      message: base.message ?? json['message']?.toString(),
      success: base.success,
    );
  }
}

class UploadVehicleRcResponseModel extends DocumentUploadResponseModel {
  const UploadVehicleRcResponseModel({
    this.documentType,
    this.front,
    this.back,
    super.documentId,
    super.fileUrl,
    super.status,
    super.message,
    super.success,
  });

  final String? documentType;
  final VehicleRcSideModel? front;
  final VehicleRcSideModel? back;

  factory UploadVehicleRcResponseModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);

    final dynamic frontRaw = json['front'];
    final dynamic backRaw = json['back'];
    final VehicleRcSideModel? front = frontRaw is Map<String, dynamic>
        ? VehicleRcSideModel.fromJson(frontRaw)
        : null;
    final VehicleRcSideModel? back = backRaw is Map<String, dynamic>
        ? VehicleRcSideModel.fromJson(backRaw)
        : null;

    final String? derivedId = (base.documentId ?? front?.id ?? back?.id)
        ?.toString();
    final String? derivedUrl =
        (base.fileUrl ?? front?.documentUrl ?? back?.documentUrl)?.toString();
    final String? derivedStatus =
        (base.status ?? front?.verificationStatus ?? back?.verificationStatus)
            ?.toString();

    return UploadVehicleRcResponseModel(
      documentType: json['documentType']?.toString(),
      front: front,
      back: back,
      documentId: derivedId,
      fileUrl: derivedUrl,
      status: derivedStatus,
      message: base.message ?? json['message']?.toString(),
      success: base.success,
    );
  }
}

class UploadAadhaarResponseModel extends DocumentUploadResponseModel {
  const UploadAadhaarResponseModel({
    super.documentId,
    super.fileUrl,
    super.status,
    super.message,
    super.success,
  });

  factory UploadAadhaarResponseModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);
    return UploadAadhaarResponseModel(
      documentId: base.documentId,
      fileUrl: base.fileUrl,
      status: base.status,
      message: base.message,
      success: base.success,
    );
  }
}

class UploadPanResponseModel extends DocumentUploadResponseModel {
  const UploadPanResponseModel({
    super.documentId,
    super.fileUrl,
    super.status,
    super.message,
    super.success,
  });

  factory UploadPanResponseModel.fromJson(Map<String, dynamic> json) {
    final base = DocumentUploadResponseModel.fromJson(json);
    return UploadPanResponseModel(
      documentId: base.documentId,
      fileUrl: base.fileUrl,
      status: base.status,
      message: base.message,
      success: base.success,
    );
  }
}
