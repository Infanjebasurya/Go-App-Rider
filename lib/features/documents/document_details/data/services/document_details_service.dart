import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/documents/document_details/data/models/document_model.dart';

enum DataMode { mock, live }

abstract interface class DocumentDetailsService {
  Future<DocumentModel> getAadhaar();
  Future<DocumentModel> getPan();
}

class DocumentDetailsServiceImpl implements DocumentDetailsService {
  DocumentDetailsServiceImpl({required DataMode mode, Dio? dio})
    : _mode = mode,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final DataMode _mode;
  final Dio _dio;

  static const bool _mockError = bool.fromEnvironment(
    'DOCS_MOCK_ERROR',
    defaultValue: false,
  );

  @override
  Future<DocumentModel> getAadhaar() {
    switch (_mode) {
      case DataMode.mock:
        return _mockAadhaar();
      case DataMode.live:
        return _liveGet(ApiEndpoints.documentsAadhaar);
    }
  }

  @override
  Future<DocumentModel> getPan() {
    switch (_mode) {
      case DataMode.mock:
        return _mockPan();
      case DataMode.live:
        return _liveGet(ApiEndpoints.documentsPan);
    }
  }

  Future<DocumentModel> _mockAadhaar() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_mockError) {
      throw Exception('Failed to load Aadhaar details.');
    }
    return DocumentModel.fromJson(const <String, dynamic>{
      'success': true,
      'id': '448915ba',
      'driver_id': '20000000-0000-4000-8000-000000000001',
      'document_type': 'aadhar',
      'document_url': '/api/v1/documents/file/sample.png',
      'is_active': true,
      'document_number': '123456789012',
      'verification_status': 'pending',
      'uploaded_at': '2026-03-18T09:47:34Z',
      'aadhaar_last4': '9012',
    });
  }

  Future<DocumentModel> _mockPan() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_mockError) {
      throw Exception('Failed to load PAN details.');
    }
    return DocumentModel.fromJson(const <String, dynamic>{
      'success': true,
      'id': 'b2afed7a',
      'driver_id': '20000000-0000-4000-8000-000000000001',
      'document_type': 'pan',
      'document_url': '/api/v1/documents/file/sample.png',
      'is_active': true,
      'document_number': 'ABCDE1234F',
      'verification_status': 'pending',
      'uploaded_at': '2026-03-18T09:52:31Z',
      'pan_number': 'ABCDE1234F',
    });
  }

  Future<DocumentModel> _liveGet(String path) async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final Response<dynamic> response = await _dio.get(
      path,
      options: Options(
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }

    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
