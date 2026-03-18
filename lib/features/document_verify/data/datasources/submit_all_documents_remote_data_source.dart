import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/document_verify/data/models/submit_for_review_models.dart';

abstract interface class SubmitAllDocumentsRemoteDataSource {
  Future<SubmitForReviewResponseModel> submitAll({
    required bool declarationAccepted,
  });
}

class SubmitAllDocumentsRemoteDataSourceImpl
    implements SubmitAllDocumentsRemoteDataSource {
  SubmitAllDocumentsRemoteDataSourceImpl({Dio? dio})
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
  Future<SubmitForReviewResponseModel> submitAll({
    required bool declarationAccepted,
  }) async {
    if (!declarationAccepted) {
      throw Exception('Please accept the declaration to submit.');
    }

    _refreshBaseUrl();

    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (Env.mockApi || token.startsWith('mock-')) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return const SubmitForReviewResponseModel(
        success: true,
        submissionId: 'SUB-MOCK-DOCS-0001',
        status: 'SUBMITTED',
        message: 'All documents submitted successfully for verification.',
      );
    }

    if (token.isEmpty) {
      throw Exception('Access token missing. Please login again.');
    }

    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    final SubmitForReviewRequestModel body = SubmitForReviewRequestModel(
      declarationAccepted: declarationAccepted,
    );

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
          'Submit All Documents API called -> POST '
          '${_dio.options.baseUrl}${ApiEndpoints.submitAllDocuments}',
        );
        debugPrint('Submit All Documents request -> ${body.toJson()}');
      }

      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.submitAllDocuments,
        data: body.toJson(),
        options: options,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid submit response.');
      }

      final SubmitForReviewResponseModel parsed =
          SubmitForReviewResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );

      if (parsed.success != true) {
        final String msg = (parsed.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Submission failed.' : msg);
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

    return 'Failed to submit documents.';
  }
}
