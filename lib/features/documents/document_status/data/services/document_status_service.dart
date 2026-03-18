import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/features/documents/document_status/data/models/document_status_model.dart';

enum DataMode { mock, live }

abstract interface class DocumentStatusService {
  Future<DocumentStatusModel> getDocumentStatus();
}

class DocumentStatusServiceImpl implements DocumentStatusService {
  DocumentStatusServiceImpl({required DataMode mode, Dio? dio})
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
    'DOC_STATUS_MOCK_ERROR',
    defaultValue: false,
  );

  @override
  Future<DocumentStatusModel> getDocumentStatus() {
    switch (_mode) {
      case DataMode.mock:
        return _mock();
      case DataMode.live:
        return _live();
    }
  }

  Future<DocumentStatusModel> _mock() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_mockError) {
      throw Exception('Failed to load document status.');
    }

    return DocumentStatusModel.fromJson(const <String, dynamic>{
      'success': true,
      'profile_image': 'verified',
      'dl': 'pending',
      'rc': 'pending',
      'aadhaar': 'pending',
      'pan': 'pending',
    });
  }

  Future<DocumentStatusModel> _live() async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final Response<dynamic> response = await _dio.get(
      ApiEndpoints.documentsStatus,
      options: Options(
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }

    return DocumentStatusModel.fromJson(response.data as Map<String, dynamic>);
  }
}
