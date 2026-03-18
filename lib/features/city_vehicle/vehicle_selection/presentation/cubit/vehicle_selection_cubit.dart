import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/data/models/get_vehicle_types_response_model.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/data/models/save_selected_vehicle_type_request_model.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/data/models/save_selected_vehicle_type_response_model.dart';
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

  void _log(String message) {
    developer.log(message, name: 'VehicleSelection');
  }

  Future<void> loadVehicleTypes({required String city}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      if (Env.mockApi) {
        _log('Vehicle types -> MOCK_API enabled; using local fallback.');
        emit(state.copyWith(vehicles: kVehicles, isLoading: false));
        return;
      }

      final token = AuthTokenStore.accessToken();
      final tokenType = AuthTokenStore.tokenType() ?? 'Bearer';
      if (token == null || token.isEmpty) {
        _log('Vehicle types -> missing auth token.');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Session expired. Please sign in again.',
          ),
        );
        return;
      }

      _log(
        'Vehicle types -> GET ${_dio.options.baseUrl}${ApiEndpoints.vehicleTypes}?city=$city',
      );
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.vehicleTypes,
        queryParameters: <String, dynamic>{'city': city},
        options: Options(
          headers: <String, dynamic>{'Authorization': '$tokenType $token'},
        ),
      );
      _log(
        'Vehicle types response <- [${response.statusCode}] ${response.data}',
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
      emit(state.copyWith(isLoading: false, errorMessage: _mapDioError(error)));
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

  Future<String?> submitSelectedVehicleType({
    required String vehicleTypeId,
  }) async {
    if (vehicleTypeId.trim().isEmpty) {
      return 'Please select a vehicle type.';
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      if (Env.mockApi) {
        _log('Vehicle select -> MOCK_API enabled; skipping backend call.');
        emit(state.copyWith(isLoading: false));
        return 'Vehicle type saved.';
      }

      final token = AuthTokenStore.accessToken();
      final tokenType = AuthTokenStore.tokenType() ?? 'Bearer';
      if (token == null || token.isEmpty) {
        _log('Vehicle select -> missing auth token.');
        final message = 'Session expired. Please sign in again.';
        emit(state.copyWith(isLoading: false, errorMessage: message));
        return message;
      }

      final body = SaveSelectedVehicleTypeRequestModel(
        vehicleTypeId: vehicleTypeId,
      ).toJson();

      _log(
        'Vehicle select -> POST ${_dio.options.baseUrl}${ApiEndpoints.vehicleSelect}',
      );
      _log('Vehicle select request body -> $body');

      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.vehicleSelect,
        data: body,
        options: Options(
          headers: <String, dynamic>{'Authorization': '$tokenType $token'},
        ),
      );

      _log(
        'Vehicle select response <- [${response.statusCode}] ${response.data}',
      );

      if (response.data is Map<String, dynamic>) {
        final parsed = SaveSelectedVehicleTypeResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (parsed.success == true) {
          emit(state.copyWith(isLoading: false));
          final message = parsed.message?.trim().isNotEmpty == true
              ? parsed.message!.trim()
              : 'Vehicle type saved.';
          return message;
        }
        final message = parsed.message?.trim().isNotEmpty == true
            ? parsed.message!.trim()
            : 'Failed to save vehicle selection.';
        emit(state.copyWith(isLoading: false, errorMessage: message));
        return message;
      }

      // Some backends return empty body on success.
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(isLoading: false));
        return 'Vehicle type saved.';
      }

      final message = 'Failed to save vehicle selection.';
      emit(state.copyWith(isLoading: false, errorMessage: message));
      return message;
    } on DioException catch (error) {
      _log(
        'Vehicle select error <- [${error.response?.statusCode}] ${error.response?.data}',
      );
      final message = _mapDioError(error);
      emit(state.copyWith(isLoading: false, errorMessage: message));
      return message;
    } catch (_) {
      final message = 'Failed to save vehicle selection.';
      emit(state.copyWith(isLoading: false, errorMessage: message));
      return message;
    }
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
