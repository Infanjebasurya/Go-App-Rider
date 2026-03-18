class SaveSelectedVehicleTypeResponseModel {
  const SaveSelectedVehicleTypeResponseModel({
    this.message,
    this.success,
    this.selectionId,
    this.vehicleTypeId,
    this.vehicleTypeCode,
  });

  final String? message;
  final bool? success;
  final String? selectionId;
  final String? vehicleTypeId;
  final String? vehicleTypeCode;

  factory SaveSelectedVehicleTypeResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SaveSelectedVehicleTypeResponseModel(
      message: json['message']?.toString(),
      success: _parseBool(json['success'] ?? json['status']),
      selectionId: (json['selection_id'] ?? json['selectionId'] ?? json['id'])
          ?.toString(),
      vehicleTypeId: (json['vehicle_type_id'] ?? json['vehicleTypeId'])
          ?.toString(),
      vehicleTypeCode: (json['vehicle_type'] ?? json['vehicleType'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (message != null) 'message': message,
      if (success != null) 'success': success,
      if (selectionId != null) 'selection_id': selectionId,
      if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
      if (vehicleTypeCode != null) 'vehicle_type': vehicleTypeCode,
    };
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
