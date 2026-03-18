import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/documents/data/models/profile_image_upload_response_model.dart';

abstract interface class ProfileImageUploadRemoteDataSource {
  Future<ProfileImageUploadResponseModel> upload({required String filePath});
}

class ProfileImageUploadRemoteDataSourceImpl
    implements ProfileImageUploadRemoteDataSource {
  ProfileImageUploadRemoteDataSourceImpl({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: const <String, String>{'Accept': 'application/json'},
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
  Future<ProfileImageUploadResponseModel> upload({
    required String filePath,
  }) async {
    final String trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      throw Exception('Please select a profile image.');
    }

    _refreshBaseUrl();

    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return const ProfileImageUploadResponseModel(
        success: true,
        requestId: 'profile_request_mock_001',
        message: 'Profile image uploaded successfully.',
      );
    }

    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final FormData body = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(trimmedPath),
    });

    final Options options = Options(
      headers: <String, String>{
        'Authorization': '$tokenType $token',
        'Accept': 'application/json',
      },
      contentType: 'multipart/form-data',
    );

    try {
      if (kDebugMode) {
        debugPrint(
          'Profile Image Upload API called -> POST '
          '${_dio.options.baseUrl}${ApiEndpoints.profileImageUpload}',
        );
      }

      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.profileImageUpload,
        data: body,
        options: options,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid profile image upload response.');
      }

      final ProfileImageUploadResponseModel parsed =
          ProfileImageUploadResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );

      if (parsed.success != true) {
        final String msg = (parsed.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Profile image upload failed.' : msg);
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

    return 'Failed to upload profile image.';
  }
}
