import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/onboarding/data/models/onboarding_progress_response_model.dart';

abstract interface class OnboardingProgressRemoteDataSource {
  Future<OnboardingProgressResponseModel> fetchProgress();
}

class OnboardingProgressRemoteDataSourceImpl
    implements OnboardingProgressRemoteDataSource {
  OnboardingProgressRemoteDataSourceImpl({Dio? dio})
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
  Future<OnboardingProgressResponseModel> fetchProgress() async {
    final String token = (AuthTokenStore.accessToken() ?? '').trim();

    // Keep onboarding UI functional during local/dev work.
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return const OnboardingProgressResponseModel(
        success: true,
        overallStatus: 'IN_PROGRESS',
        steps: [
          OnboardingProgressStepModel(
            id: 'profile',
            title: 'Personal Details',
            isCompleted: true,
          ),
          OnboardingProgressStepModel(
            id: 'documents',
            title: 'Document Upload',
            isCompleted: false,
          ),
          OnboardingProgressStepModel(
            id: 'bank',
            title: 'Bank Details',
            isCompleted: false,
          ),
        ],
        completionPercentage: 33,
      );
    }

    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    _refreshBaseUrl();

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final Options options = Options(
      headers: <String, String>{
        'Authorization': '$tokenType $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    try {
      if (kDebugMode) {
        debugPrint(
          'Onboarding Progress API called -> GET '
          '${_dio.options.baseUrl}${ApiEndpoints.onboardingProgress}',
        );
      }

      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.onboardingProgress,
        options: options,
      );

      if (kDebugMode) {
        debugPrint('Onboarding Progress API response -> ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid onboarding progress response.');
      }

      final OnboardingProgressResponseModel parsed =
          OnboardingProgressResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );
      if (!parsed.success) {
        throw Exception('Failed to fetch onboarding progress.');
      }
      return parsed;
    } on DioException catch (error) {
      throw Exception(_mapDioError(error));
    }
  }

  String _mapDioError(DioException error) {
    final DioExceptionType type = error.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return 'Network error. Please check your internet connection.';
    }
    if (type == DioExceptionType.badCertificate) {
      return 'SSL certificate error. Unable to reach the server securely.';
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
      final String? message = (data['message'] ?? data['error'])?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Failed to fetch onboarding progress.';
  }
}
