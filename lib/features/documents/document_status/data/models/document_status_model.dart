class DocumentStatusModel {
  const DocumentStatusModel({
    required this.profileImageStatus,
    required this.dlStatus,
    required this.rcStatus,
    required this.aadhaarStatus,
    required this.panStatus,
  });

  final String profileImageStatus;
  final String dlStatus;
  final String rcStatus;
  final String aadhaarStatus;
  final String panStatus;

  factory DocumentStatusModel.fromJson(Map<String, dynamic> json) {
    return DocumentStatusModel(
      profileImageStatus: (json['profile_image'] ?? '').toString(),
      dlStatus: (json['dl'] ?? '').toString(),
      rcStatus: (json['rc'] ?? '').toString(),
      aadhaarStatus: (json['aadhaar'] ?? '').toString(),
      panStatus: (json['pan'] ?? '').toString(),
    );
  }
}
