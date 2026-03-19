import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/documents/data/models/documents_list_models.dart';

abstract interface class DocumentsListRemoteDataSource {
  Future<DocumentsListResponseModel> fetchAll();
}

class DocumentsListRemoteDataSourceImpl
    implements DocumentsListRemoteDataSource {
  DocumentsListRemoteDataSourceImpl({Dio? dio})
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

  Options _authOptions() {
    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }
    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    return Options(
      headers: <String, String>{
        'Authorization': '$tokenType $token',
        'Accept': 'application/json',
      },
    );
  }

  @override
  Future<DocumentsListResponseModel> fetchAll() async {
    _refreshBaseUrl();

    if (Env.mockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return DocumentsListResponseModel.fromJson(<String, dynamic>{
        'success': true,
        'documents': [
          {
            'id': 'dl_front_mock_001',
            'document_type': 'license_front',
            'documentUrl': '/api/v1/documents/file/mock_license_front.png',
            'document_number': 'TN012026123',
            'verification_status': 'pending',
          },
          {
            'id': 'dl_back_mock_001',
            'document_type': 'license_back',
            'documentUrl': '/api/v1/documents/file/mock_license_back.png',
            'document_number': 'TN012026123',
            'verification_status': 'pending',
          },
          {
            'id': 'rc_front_mock_001',
            'document_type': 'rc_book_front',
            'documentUrl': '/api/v1/documents/file/mock_rc_front.png',
            'rc_number': 'TN01AB1234',
            'verification_status': 'pending',
          },
          {
            'id': 'rc_back_mock_001',
            'document_type': 'rc_book_back',
            'documentUrl': '/api/v1/documents/file/mock_rc_back.png',
            'rc_number': 'TN01AB1234',
            'verification_status': 'pending',
          },
          {
            'id': 'aadhaar_front_mock_001',
            'document_type': 'aadhar_front',
            'documentUrl': '/api/v1/documents/file/mock_aadhar_front.png',
            'aadhaar_number': '123412341234',
            'verification_status': 'verified',
          },
          {
            'id': 'aadhaar_back_mock_001',
            'document_type': 'aadhar_back',
            'documentUrl': '/api/v1/documents/file/mock_aadhar_back.png',
            'aadhaar_number': '123412341234',
            'verification_status': 'verified',
          },
        ],
      });
    }

    try {
      if (kDebugMode) {
        debugPrint(
          'Documents List API called -> GET '
          '${_dio.options.baseUrl}${ApiEndpoints.documents}',
        );
      }

      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.documents,
        options: _authOptions(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid documents response.');
      }

      final model = DocumentsListResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (model.success != true) {
        final String msg = (model.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Failed to fetch documents.' : msg);
      }
      return model;
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

    return 'Failed to fetch documents.';
  }
}
