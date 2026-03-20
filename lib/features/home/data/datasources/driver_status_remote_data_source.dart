import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/home/data/models/driver_status_response_model.dart';

abstract interface class DriverStatusRemoteDataSource {
  Future<DriverStatusResponseModel> updateStatus({
    required String driverId,
    required String status, // "online" | "offline"
  });
}

class DriverStatusRemoteDataSourceImpl implements DriverStatusRemoteDataSource {
  DriverStatusRemoteDataSourceImpl({Dio? dio})
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
          );

  final Dio _dio;

  void _refreshBaseUrl() {
    final String latestBaseUrl = ApiConfig.baseUrl;
    if (_dio.options.baseUrl != latestBaseUrl) {
      _dio.options.baseUrl = latestBaseUrl;
    }
  }

  @override
  Future<DriverStatusResponseModel> updateStatus({
    required String driverId,
    required String status,
  }) async {
    final String trimmedDriverId = driverId.trim();
    final String normalizedStatus = status.trim().toLowerCase();
    if (trimmedDriverId.isEmpty) {
      throw Exception('Driver ID missing.');
    }
    if (normalizedStatus != 'online' && normalizedStatus != 'offline') {
      throw Exception('Invalid driver status.');
    }

    final String token = (AuthTokenStore.accessToken() ?? '').trim();

    // Keep UI functional during local/dev work.
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return DriverStatusResponseModel(
        success: true,
        driverId: trimmedDriverId,
        status: normalizedStatus,
        message: normalizedStatus == 'online'
            ? 'Driver is now online'
            : 'Driver is now offline',
        requestId: 'mock-request-id',
      );
    }

    if (token.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    _refreshBaseUrl();

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final Options options = Options(
      headers: <String, String>{'Authorization': '$tokenType $token'},
    );

    try {
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.driverStatus,
        data: <String, dynamic>{
          'driver_id': trimmedDriverId,
          'status': normalizedStatus,
        },
        options: options,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid driver status response.');
      }

      final parsed = DriverStatusResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!parsed.success) {
        throw Exception(
          (parsed.message ?? '').trim().isNotEmpty
              ? parsed.message!.trim()
              : 'Failed to update driver status.',
        );
      }
      return parsed;
    } on DioException catch (error) {
      throw Exception(_mapDioError(error));
    }
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
      return 'Session expired. Please login again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    final dynamic data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Failed to update driver status.';
  }
}
