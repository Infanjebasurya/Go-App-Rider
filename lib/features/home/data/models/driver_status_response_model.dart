class DriverStatusResponseModel {
  const DriverStatusResponseModel({
    required this.success,
    this.driverId,
    this.status,
    this.message,
    this.requestId,
  });

  final bool success;
  final String? driverId;
  final String? status;
  final String? message;
  final String? requestId;

  factory DriverStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return DriverStatusResponseModel(
      success: json['success'] == true,
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      requestId: (json['requestId'] ?? json['request_id'])?.toString(),
    );
  }
}

