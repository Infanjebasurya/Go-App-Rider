import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/home/data/models/ride_expire_response_model.dart';

abstract interface class RideExpireRemoteDataSource {
  Future<RideExpireResponseModel> expireRide({required String rideId});
}

class RideExpireRemoteDataSourceImpl implements RideExpireRemoteDataSource {
  RideExpireRemoteDataSourceImpl({
    Dio? dio,
    String? adminBearerToken,
  }) : _dio =
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
       _adminBearerToken = (adminBearerToken ?? Env.adminBearerToken).trim();

  final Dio _dio;
  final String _adminBearerToken;

  void _refreshBaseUrl() {
    final String latestBaseUrl = ApiConfig.baseUrl;
    if (_dio.options.baseUrl != latestBaseUrl) {
      _dio.options.baseUrl = latestBaseUrl;
    }
  }

  @override
  Future<RideExpireResponseModel> expireRide({required String rideId}) async {
    final String trimmedRideId = rideId.trim();
    if (trimmedRideId.isEmpty) {
      throw Exception('Ride ID missing.');
    }

    // Keep UI functional during local/dev work.
    if (Env.mockApi || _adminBearerToken.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return RideExpireResponseModel(
        success: true,
        message: 'Ride expired',
        rideId: trimmedRideId,
        status: 'no_drivers',
        requestId: 'mock-request-id',
      );
    }

    _refreshBaseUrl();

    try {
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.expireRide,
        data: <String, dynamic>{'ride_id': trimmedRideId},
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $_adminBearerToken',
          },
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid expire-ride response.');
      }

      final parsed = RideExpireResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!parsed.success) {
        throw Exception(
          (parsed.message ?? '').trim().isNotEmpty
              ? parsed.message!.trim()
              : 'Failed to expire ride.',
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
    if (statusCode == 401 || statusCode == 403) {
      return 'Unauthorized. Admin token is invalid or missing.';
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

    return 'Failed to expire ride.';
  }
}
