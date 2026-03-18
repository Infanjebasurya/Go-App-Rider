import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum VehicleType { bike, auto, cab }

class Vehicle extends Equatable {
  final VehicleType type;
  final String vehicleTypeId;
  final String label;
  final String tier;
  final String seatsDescription;
  final IconData icon;

  const Vehicle({
    required this.type,
    required this.vehicleTypeId,
    required this.label,
    required this.tier,
    required this.seatsDescription,
    required this.icon,
  });

  String get subtitle => '$tier â€¢ $seatsDescription';

  @override
  List<Object?> get props => <Object?>[
    type,
    vehicleTypeId,
    label,
    tier,
    seatsDescription,
  ];
}

const List<Vehicle> kVehicles = <Vehicle>[
  Vehicle(
    type: VehicleType.bike,
    vehicleTypeId: 'mock-bike',
    label: 'Bike',
    tier: 'ELITE TIER',
    seatsDescription: '1 SEATS',
    icon: Icons.two_wheeler_rounded,
  ),
  Vehicle(
    type: VehicleType.auto,
    vehicleTypeId: 'mock-auto',
    label: 'Auto',
    tier: 'ELITE TIER',
    seatsDescription: '3 SEATS',
    icon: Icons.electric_rickshaw_rounded,
  ),
  Vehicle(
    type: VehicleType.cab,
    vehicleTypeId: 'mock-cab',
    label: 'Cab',
    tier: 'ELITE TIER',
    seatsDescription: '4 TO 8 SEATS',
    icon: Icons.local_taxi_rounded,
  ),
];

class VehicleSelectionState extends Equatable {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final bool isLoading;
  final String? errorMessage;

  const VehicleSelectionState({
    required this.vehicles,
    this.selectedVehicle,
    this.isLoading = false,
    this.errorMessage,
  });

  factory VehicleSelectionState.initial() =>
      const VehicleSelectionState(vehicles: <Vehicle>[], selectedVehicle: null);

  bool get hasSelection => selectedVehicle != null;

  bool isSelected(Vehicle v) =>
      selectedVehicle?.vehicleTypeId == v.vehicleTypeId;

  VehicleSelectionState copyWith({
    List<Vehicle>? vehicles,
    Vehicle? selectedVehicle,
    bool? isLoading,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return VehicleSelectionState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: clearSelection
          ? null
          : (selectedVehicle ?? this.selectedVehicle),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    vehicles,
    selectedVehicle,
    isLoading,
    errorMessage,
  ];
}
