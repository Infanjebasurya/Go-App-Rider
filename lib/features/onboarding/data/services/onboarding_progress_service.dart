import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/onboarding/data/models/onboarding_progress_response_model.dart';

class OnboardingProgressService {
  OnboardingProgressService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  Future<OnboardingProgressResponseModel> fetchProgress() async {
    final token = (AuthTokenStore.accessToken() ?? '').trim();
    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    _dio.options.baseUrl = ApiConfig.baseUrl;

    final options = Options(
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    try {
      if (kDebugMode) {
        debugPrint(
          'Onboarding Progress API called -> GET '
          '${_dio.options.baseUrl}/api/v1/onboarding/progress',
        );
      }
      final response = await _dio.get(
        '/api/v1/onboarding/progress',
        options: options,
      );

      if (kDebugMode) {
        debugPrint('Onboarding Progress API response -> ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid onboarding progress response.');
      }
      final parsed = OnboardingProgressResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (!parsed.success) {
        throw Exception('Failed to fetch onboarding progress.');
      }
      return parsed;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  static Dio _buildDio() {
    return Dio(
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
  }

  String _mapDioError(DioException error) {
    final type = error.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return 'Network error. Please check your internet connection.';
    }
    if (type == DioExceptionType.badCertificate) {
      return 'SSL certificate error. Unable to reach the server securely.';
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = (data['message'] ?? data['error'])?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Failed to fetch onboarding progress.';
  }
}
