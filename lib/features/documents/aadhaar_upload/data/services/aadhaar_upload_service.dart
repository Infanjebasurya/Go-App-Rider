import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';

enum DataMode { mock, live }

abstract interface class AadhaarUploadService {
  Future<DocumentUploadResponse> uploadAadhaar({
    required File file,
    required String aadhaarNumber,
  });
}

class AadhaarUploadServiceImpl implements AadhaarUploadService {
  AadhaarUploadServiceImpl({
    required DataMode mode,
    Dio? dio,
  }) : _mode = mode,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: ApiConfig.baseUrl,
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 30),
             ),
           );

  static const String _endpointPath = '/api/v1/documents/aadhaar';

  final DataMode _mode;
  final Dio _dio;

  @override
  Future<DocumentUploadResponse> uploadAadhaar({
    required File file,
    required String aadhaarNumber,
  }) {
    switch (_mode) {
      case DataMode.mock:
        return _mockUpload(file: file, aadhaarNumber: aadhaarNumber);
      case DataMode.live:
        return _liveUpload(file: file, aadhaarNumber: aadhaarNumber);
    }
  }

  Future<DocumentUploadResponse> _mockUpload({
    required File file,
    required String aadhaarNumber,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Deterministic mock failures (easy to test).
    if (aadhaarNumber.endsWith('0000')) {
      throw Exception('Network error. Please try again.');
    }
    if (aadhaarNumber.endsWith('9999')) {
      throw Exception('Upload failed. Please retry.');
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'aadhaar.png';

    return DocumentUploadResponse(
      success: true,
      id: '448915ba-bc96-436e-b959-101b33ba2f0d',
      driverId: '20000000-0000-4000-8000-000000000001',
      documentType: 'aadhar',
      documentUrl: '/api/v1/documents/file/$fileName',
      verificationStatus: 'pending',
      requestId: 'e8cb3c41-3c8d-477c-bb59-6969373284b3',
    );
  }

  Future<DocumentUploadResponse> _liveUpload({
    required File file,
    required String aadhaarNumber,
  }) async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final formData = FormData.fromMap(<String, dynamic>{
      'aadhaar_number': aadhaarNumber,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'aadhaar.png',
      ),
    });

    final Response<dynamic> response = await _dio.post(
      _endpointPath,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }

    return DocumentUploadResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

