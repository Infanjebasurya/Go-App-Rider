class RideExpireResponseModel {
  const RideExpireResponseModel({
    required this.success,
    this.message,
    this.rideId,
    this.status,
    this.requestId,
  });

  final bool success;
  final String? message;
  final String? rideId;
  final String? status;
  final String? requestId;

  factory RideExpireResponseModel.fromJson(Map<String, dynamic> json) {
    return RideExpireResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
      rideId: (json['ride_id'] ?? json['rideId'])?.toString(),
      status: json['status']?.toString(),
      requestId: (json['requestId'] ?? json['request_id'])?.toString(),
    );
  }
}

