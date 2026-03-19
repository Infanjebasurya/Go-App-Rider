import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';

enum DataMode { mock, live }

abstract interface class AadhaarUploadService {
  Future<AadhaarUploadResponse> uploadAadhaar({
    required File frontFile,
    required File backFile,
    required String aadhaarNumber,
  });
}

class AadhaarUploadServiceImpl implements AadhaarUploadService {
  AadhaarUploadServiceImpl({required DataMode mode, Dio? dio})
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
  Future<AadhaarUploadResponse> uploadAadhaar({
    required File frontFile,
    required File backFile,
    required String aadhaarNumber,
  }) {
    switch (_mode) {
      case DataMode.mock:
        return _mockUpload(
          frontFile: frontFile,
          backFile: backFile,
          aadhaarNumber: aadhaarNumber,
        );
      case DataMode.live:
        return _liveUpload(
          frontFile: frontFile,
          backFile: backFile,
          aadhaarNumber: aadhaarNumber,
        );
    }
  }

  Future<AadhaarUploadResponse> _mockUpload({
    required File frontFile,
    required File backFile,
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

    final String frontName = frontFile.uri.pathSegments.isNotEmpty
        ? frontFile.uri.pathSegments.last
        : 'aadhaar_front.png';
    final String backName = backFile.uri.pathSegments.isNotEmpty
        ? backFile.uri.pathSegments.last
        : 'aadhaar_back.png';

    return AadhaarUploadResponse(
      success: true,
      documentType: 'aadhar',
      front: AadhaarSide(
        id: '9a0d9640-6fea-4f83-807f-da8291043a17',
        documentUrl: '/api/v1/documents/file/$frontName',
        verificationStatus: 'pending',
      ),
      back: AadhaarSide(
        id: '3b4a1c30-65df-4bf6-8a7c-e889d59eea4c',
        documentUrl: '/api/v1/documents/file/$backName',
        verificationStatus: 'pending',
      ),
      requestId: '27109e02-df35-40c9-a68c-e4d098a115b2',
    );
  }

  Future<AadhaarUploadResponse> _liveUpload({
    required File frontFile,
    required File backFile,
    required String aadhaarNumber,
  }) async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final String frontName = frontFile.uri.pathSegments.isNotEmpty
        ? frontFile.uri.pathSegments.last
        : 'aadhaar_front.png';
    final String backName = backFile.uri.pathSegments.isNotEmpty
        ? backFile.uri.pathSegments.last
        : 'aadhaar_back.png';

    final formData = FormData.fromMap(<String, dynamic>{
      'aadhaar_number': aadhaarNumber,
      'file_front': await MultipartFile.fromFile(
        frontFile.path,
        filename: frontName,
      ),
      'file_back': await MultipartFile.fromFile(
        backFile.path,
        filename: backName,
      ),
    });

    final Response<dynamic> response = await _dio.post(
      ApiEndpoints.documentsAadhaar,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }

    return AadhaarUploadResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
