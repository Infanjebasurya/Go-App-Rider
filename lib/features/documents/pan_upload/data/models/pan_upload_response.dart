class PanUploadResponse {
  const PanUploadResponse({
    required this.success,
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.documentUrl,
    required this.verificationStatus,
    required this.requestId,
  });

  final bool success;
  final String id;
  final String driverId;
  final String documentType;
  final String documentUrl;
  final String verificationStatus;
  final String requestId;

  factory PanUploadResponse.fromJson(Map<String, dynamic> json) {
    return PanUploadResponse(
      success: json['success'] == true,
      id: (json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? json['driver_id'] ?? '').toString(),
      documentType: (json['documentType'] ?? json['document_type'] ?? '')
          .toString(),
      documentUrl: (json['documentUrl'] ?? json['document_url'] ?? '')
          .toString(),
      verificationStatus:
          (json['verificationStatus'] ?? json['verification_status'] ?? '')
              .toString(),
      requestId: (json['requestId'] ?? json['request_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'id': id,
      'driverId': driverId,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'verificationStatus': verificationStatus,
      'requestId': requestId,
    };
  }
}
