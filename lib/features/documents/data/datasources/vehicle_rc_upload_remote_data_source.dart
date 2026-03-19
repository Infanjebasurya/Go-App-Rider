import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/documents/data/models/document_upload_api_response_models.dart';

abstract interface class VehicleRcUploadRemoteDataSource {
  Future<UploadVehicleRcResponseModel> upload({
    required String filePath,
    String? fileFrontPath,
    String? fileBackPath,
    required String rcNumber,
  });
}

class VehicleRcUploadRemoteDataSourceImpl
    implements VehicleRcUploadRemoteDataSource {
  VehicleRcUploadRemoteDataSourceImpl({Dio? dio})
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
  Future<UploadVehicleRcResponseModel> upload({
    required String filePath,
    String? fileFrontPath,
    String? fileBackPath,
    required String rcNumber,
  }) async {
    final String trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      throw Exception('Please select a vehicle RC image.');
    }
    final String trimmedFrontPath = (fileFrontPath ?? '').trim();
    final String trimmedBackPath = (fileBackPath ?? '').trim();
    final String trimmedRc = rcNumber.trim();
    if (trimmedRc.isEmpty) {
      throw Exception('Vehicle RC number is required.');
    }

    _refreshBaseUrl();

    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const UploadVehicleRcResponseModel(
        success: true,
        documentType: 'rc_book',
        front: VehicleRcSideModel(
          id: 'rc_front_mock_001',
          documentUrl: '/api/v1/documents/file/mock_rc_front.png',
          verificationStatus: 'pending',
        ),
        back: VehicleRcSideModel(
          id: 'rc_back_mock_001',
          documentUrl: '/api/v1/documents/file/mock_rc_back.png',
          verificationStatus: 'pending',
        ),
        documentId: 'rc_doc_mock_001',
        fileUrl: '/api/v1/documents/file/mock_rc.png',
        status: 'pending',
        message: 'Vehicle RC uploaded successfully.',
      );
    }

    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final Map<String, dynamic> bodyMap = <String, dynamic>{
      'file': await MultipartFile.fromFile(trimmedPath),
      'rc_number': trimmedRc,
    };

    // Backward compatible:
    // - Older backend expects single `file` only.
    // - New backend supports `file_front` + `file_back` (recommended when present).
    if (trimmedFrontPath.isNotEmpty || trimmedBackPath.isNotEmpty) {
      if (trimmedFrontPath.isEmpty) {
        throw Exception('Please select the vehicle RC front image.');
      }
      if (trimmedBackPath.isEmpty) {
        throw Exception('Please select the vehicle RC back image.');
      }
      bodyMap['file_front'] = await MultipartFile.fromFile(trimmedFrontPath);
      bodyMap['file_back'] = await MultipartFile.fromFile(trimmedBackPath);
    }

    final FormData body = FormData.fromMap(bodyMap);

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
          'Vehicle RC Upload API called -> POST '
          '${_dio.options.baseUrl}${ApiEndpoints.vehicleRcUpload}',
        );
      }

      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.vehicleRcUpload,
        data: body,
        options: options,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid vehicle RC upload response.');
      }

      final UploadVehicleRcResponseModel parsed =
          UploadVehicleRcResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );

      if (parsed.success != true) {
        final String msg = (parsed.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Vehicle RC upload failed.' : msg);
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

    return 'Failed to upload vehicle RC.';
  }
}
