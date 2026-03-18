class VehicleTypeItemModel {
  const VehicleTypeItemModel({
    required this.id,
    required this.name,
    required this.city,
    required this.isActive,
  });

  final String id;
  final String name;
  final String city;
  final bool isActive;

  factory VehicleTypeItemModel.fromJson(Map<String, dynamic> json) {
    final dynamic activeRaw =
        json['is_active'] ?? json['isActive'] ?? json['active'];
    return VehicleTypeItemModel(
      id:
          (json['vehicle_type_id'] ??
                  json['vehicleTypeId'] ??
                  json['id'] ??
                  json['code'] ??
                  json['type'] ??
                  '')
              .toString(),
      name: (json['name'] ?? json['label'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      isActive:
          activeRaw == true ||
          (activeRaw is String && activeRaw.toLowerCase() == 'true') ||
          (activeRaw is num && activeRaw != 0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicle_type_id': id,
      'name': name,
      'city': city,
      'is_active': isActive,
    };
  }
}

class GetVehicleTypesResponseModel {
  const GetVehicleTypesResponseModel({
    required this.vehicleTypes,
    this.message,
    this.success,
  });

  final List<VehicleTypeItemModel> vehicleTypes;
  final String? message;
  final bool? success;

  factory GetVehicleTypesResponseModel.fromJson(Map<String, dynamic> json) {
    final dynamic listRaw =
        json['data'] ??
        json['vehicle_types'] ??
        json['vehicleTypes'] ??
        json['types'];
    final List<VehicleTypeItemModel> parsedTypes =
        (listRaw is List<dynamic> ? listRaw : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeItemModel.fromJson)
            .toList(growable: false);

    return GetVehicleTypesResponseModel(
      vehicleTypes: parsedTypes,
      message: json['message']?.toString(),
      success: _parseBool(json['success'] ?? json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': vehicleTypes.map((e) => e.toJson()).toList(growable: false),
      if (message != null) 'message': message,
      if (success != null) 'success': success,
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
