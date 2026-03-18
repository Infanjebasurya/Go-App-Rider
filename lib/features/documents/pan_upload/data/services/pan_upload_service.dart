import 'dart:io';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/documents/pan_upload/data/models/pan_upload_response.dart';

enum DataMode { mock, live }

abstract interface class PanUploadService {
  Future<PanUploadResponse> uploadPan({
    required File file,
    required String panNumber,
  });
}

class PanUploadServiceImpl implements PanUploadService {
  PanUploadServiceImpl({required DataMode mode, Dio? dio})
    : _mode = mode,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final DataMode _mode;
  final Dio _dio;

  @override
  Future<PanUploadResponse> uploadPan({
    required File file,
    required String panNumber,
  }) {
    switch (_mode) {
      case DataMode.mock:
        return _mockUpload(file: file, panNumber: panNumber);
      case DataMode.live:
        return _liveUpload(file: file, panNumber: panNumber);
    }
  }

  Future<PanUploadResponse> _mockUpload({
    required File file,
    required String panNumber,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Deterministic mock failures (valid PANs):
    // - Network error: BBBBB0000B
    // - Upload error:  AAAAA9999A
    if (panNumber == 'BBBBB0000B') {
      throw Exception('Network error. Please try again.');
    }
    if (panNumber == 'AAAAA9999A') {
      throw Exception('Upload failed. Please retry.');
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'pan.png';

    return PanUploadResponse(
      success: true,
      id: 'b2afed7a-763c-4532-b67e-cdfa4e8349a8',
      driverId: '20000000-0000-4000-8000-000000000001',
      documentType: 'pan',
      documentUrl: '/api/v1/documents/file/$fileName',
      verificationStatus: 'pending',
      requestId: 'ade51760-2a69-45a1-b23a-a226a8ec8b97',
    );
  }

  Future<PanUploadResponse> _liveUpload({
    required File file,
    required String panNumber,
  }) async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final formData = FormData.fromMap(<String, dynamic>{
      'pan_number': panNumber,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'pan.png',
      ),
    });

    final Response<dynamic> response = await _dio.post(
      ApiEndpoints.documentsPan,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }

    return PanUploadResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
