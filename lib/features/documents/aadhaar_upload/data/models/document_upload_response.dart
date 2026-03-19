class AadhaarSide {
  const AadhaarSide({
    required this.id,
    required this.documentUrl,
    required this.verificationStatus,
  });

  final String id;
  final String documentUrl;
  final String verificationStatus;

  factory AadhaarSide.fromJson(Map<String, dynamic> json) {
    return AadhaarSide(
      id: (json['id'] ?? '').toString(),
      documentUrl: (json['documentUrl'] ?? json['document_url'] ?? '')
          .toString(),
      verificationStatus:
          (json['verificationStatus'] ?? json['verification_status'] ?? '')
              .toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'documentUrl': documentUrl,
    'verificationStatus': verificationStatus,
  };
}

class AadhaarUploadResponse {
  const AadhaarUploadResponse({
    required this.success,
    required this.documentType,
    required this.front,
    required this.back,
    required this.requestId,
  });

  final bool success;
  final String documentType;
  final AadhaarSide front;
  final AadhaarSide back;
  final String requestId;

  factory AadhaarUploadResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> frontJson = _asMap(json['front']);
    final Map<String, dynamic> backJson = _asMap(json['back']);
    return AadhaarUploadResponse(
      success: json['success'] == true,
      documentType: (json['documentType'] ?? json['document_type'] ?? '')
          .toString(),
      front: AadhaarSide.fromJson(frontJson),
      back: AadhaarSide.fromJson(backJson),
      requestId: (json['requestId'] ?? json['request_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'success': success,
    'documentType': documentType,
    'front': front.toJson(),
    'back': back.toJson(),
    'requestId': requestId,
  };

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }
}
