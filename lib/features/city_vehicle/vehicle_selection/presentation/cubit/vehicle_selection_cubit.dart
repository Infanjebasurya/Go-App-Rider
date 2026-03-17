import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/data/models/get_vehicle_types_response_model.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/model/vehicle_model.dart';

class VehicleSelectionCubit extends Cubit<VehicleSelectionState> {
  VehicleSelectionCubit({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: const <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ),
      super(VehicleSelectionState.initial());

  final Dio _dio;

  Future<void> loadVehicleTypes({required String city}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      if (Env.mockApi) {
        emit(state.copyWith(vehicles: kVehicles, isLoading: false));
        return;
      }

      final token = AuthTokenStore.accessToken();
      final tokenType = AuthTokenStore.tokenType() ?? 'Bearer';
      if (token == null || token.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Session expired. Please sign in again.',
          ),
        );
        return;
      }

      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.vehicleTypes,
        queryParameters: <String, dynamic>{'city': city},
        options: Options(
          headers: <String, dynamic>{'Authorization': '$tokenType $token'},
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Invalid server response.',
          ),
        );
        return;
      }

      final parsed = GetVehicleTypesResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      final List<VehicleTypeItemModel> activeTypes = parsed.vehicleTypes
          .where((e) => e.isActive)
          .toList(growable: false);

      final List<Vehicle> vehicles = activeTypes
          .map(_mapApiTypeToVehicle)
          .whereType<Vehicle>()
          .toList(growable: false);

      emit(state.copyWith(vehicles: vehicles, isLoading: false));
    } on DioException catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _mapDioError(error),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load vehicle types.',
        ),
      );
    }
  }

  void selectVehicle(Vehicle vehicle) {
    if (state.isSelected(vehicle)) {
      emit(state.copyWith(clearSelection: true));
    } else {
      emit(state.copyWith(selectedVehicle: vehicle));
    }
  }

  void reset() {
    emit(VehicleSelectionState.initial());
  }

  Vehicle? _mapApiTypeToVehicle(VehicleTypeItemModel item) {
    if (item.id.trim().isEmpty) return null;

    final VehicleType mapped = _vehicleTypeFromName(item.name);
    final Vehicle base = kVehicles.firstWhere(
      (v) => v.type == mapped,
      orElse: () => kVehicles.last,
    );

    return Vehicle(
      type: mapped,
      vehicleTypeId: item.id,
      label: item.name.trim().isEmpty ? base.label : item.name,
      tier: base.tier,
      seatsDescription: base.seatsDescription,
      icon: base.icon,
    );
  }

  VehicleType _vehicleTypeFromName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('bike') || normalized.contains('two')) {
      return VehicleType.bike;
    }
    if (normalized.contains('auto') || normalized.contains('rickshaw')) {
      return VehicleType.auto;
    }
    return VehicleType.cab;
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network failure. Please check your internet connection.';
    }

    final int? statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Unauthorized. Please sign in again.';
    }

    final dynamic data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'Failed to load vehicle types.';
  }
}
