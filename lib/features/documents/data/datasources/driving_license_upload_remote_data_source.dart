import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/documents/data/models/document_upload_api_response_models.dart';

abstract interface class DrivingLicenseUploadRemoteDataSource {
  Future<UploadDrivingLicenseResponseModel> upload({
    required String driverId,
    required String filePath,
    String? fileFrontPath,
    String? fileBackPath,
    required String dlNumber,
    String? expiryDate,
  });
}

class DrivingLicenseUploadRemoteDataSourceImpl
    implements DrivingLicenseUploadRemoteDataSource {
  DrivingLicenseUploadRemoteDataSourceImpl({Dio? dio})
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
  Future<UploadDrivingLicenseResponseModel> upload({
    required String driverId,
    required String filePath,
    String? fileFrontPath,
    String? fileBackPath,
    required String dlNumber,
    String? expiryDate,
  }) async {
    final String trimmedDriverId = driverId.trim();
    if (trimmedDriverId.isEmpty) {
      throw Exception('Driver id missing. Please try again.');
    }
    final String trimmedFilePath = filePath.trim();
    if (trimmedFilePath.isEmpty) {
      throw Exception('Please select a driving license image.');
    }
    final String trimmedFrontPath = (fileFrontPath ?? '').trim();
    final String trimmedBackPath = (fileBackPath ?? '').trim();
    final String trimmedDlNumber = dlNumber.trim();
    if (trimmedDlNumber.isEmpty) {
      throw Exception('Driving license number is required.');
    }
    final String trimmedExpiry = (expiryDate ?? '').trim();

    _refreshBaseUrl();

    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const UploadDrivingLicenseResponseModel(
        success: true,
        documentType: 'license',
        front: DrivingLicenseSideModel(
          id: 'dl_front_mock_001',
          documentUrl: '/api/v1/documents/file/mock_license_front.png',
          verificationStatus: 'pending',
        ),
        back: DrivingLicenseSideModel(
          id: 'dl_back_mock_001',
          documentUrl: '/api/v1/documents/file/mock_license_back.png',
          verificationStatus: 'pending',
        ),
        documentId: 'dl_doc_mock_001',
        fileUrl: '/api/v1/documents/file/mock_license.png',
        status: 'pending',
        message: 'Driving license uploaded successfully.',
      );
    }

    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final Map<String, dynamic> bodyMap = <String, dynamic>{
      'file': await MultipartFile.fromFile(trimmedFilePath),
      'dl_number': trimmedDlNumber,
      'driver_id': trimmedDriverId,
    };

    // Backward compatible:
    // - Older backend expects single `file` only.
    // - New backend supports `file_front` + `file_back` (recommended when present).
    if (trimmedFrontPath.isNotEmpty || trimmedBackPath.isNotEmpty) {
      if (trimmedFrontPath.isEmpty) {
        throw Exception('Please select the driving license front image.');
      }
      if (trimmedBackPath.isEmpty) {
        throw Exception('Please select the driving license back image.');
      }
      bodyMap['file_front'] = await MultipartFile.fromFile(trimmedFrontPath);
      bodyMap['file_back'] = await MultipartFile.fromFile(trimmedBackPath);
    }
    if (trimmedExpiry.isNotEmpty) {
      bodyMap['expiry_date'] = trimmedExpiry;
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
          'Driving License Upload API called -> POST '
          '${_dio.options.baseUrl}${ApiEndpoints.drivingLicenseUpload}',
        );
      }

      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.drivingLicenseUpload,
        data: body,
        options: options,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid driving license upload response.');
      }

      final UploadDrivingLicenseResponseModel parsed =
          UploadDrivingLicenseResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );

      if (parsed.success != true) {
        final String msg = (parsed.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Driving license upload failed.' : msg);
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

    return 'Failed to upload driving license.';
  }
}
