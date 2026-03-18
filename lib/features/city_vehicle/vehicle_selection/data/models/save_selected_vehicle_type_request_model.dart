class SaveSelectedVehicleTypeRequestModel {
  const SaveSelectedVehicleTypeRequestModel({
    required this.vehicleTypeId,
    this.cityId,
  });

  final String vehicleTypeId;
  final String? cityId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'vehicle_type_id': vehicleTypeId,
      if (cityId != null) 'city_id': cityId,
    };
  }
}
