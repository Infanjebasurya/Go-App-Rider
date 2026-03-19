import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/documents/data/models/document_details_models.dart';

abstract interface class DocumentDetailsRemoteDataSource {
  Future<DrivingLicenseDetailsModel?> getDrivingLicense();
  Future<VehicleRcDetailsModel?> getVehicleRc();
}

class DocumentDetailsRemoteDataSourceImpl
    implements DocumentDetailsRemoteDataSource {
  DocumentDetailsRemoteDataSourceImpl({Dio? dio})
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
  Future<DrivingLicenseDetailsModel?> getDrivingLicense() async {
    _refreshBaseUrl();

    if (Env.mockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return const DrivingLicenseDetailsModel(
        success: true,
        id: 'dl_mock_001',
        driverId: 'DRV-MOCK-001',
        documentType: 'license',
        documentUrl: '/api/v1/documents/file/mock_license_front.png',
        front: DocumentSideDetailsModel(
          id: 'dl_front_mock_001',
          documentUrl: '/api/v1/documents/file/mock_license_front.png',
          verificationStatus: 'pending',
        ),
        back: DocumentSideDetailsModel(
          id: 'dl_back_mock_001',
          documentUrl: '/api/v1/documents/file/mock_license_back.png',
          verificationStatus: 'pending',
        ),
        documentNumber: 'TN012026123',
        expiryDateIso: '2035-12-31T00:00:00.000Z',
        verificationStatus: 'pending',
        uploadedAtIso: '2026-03-18T09:13:58.516Z',
      );
    }

    try {
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.drivingLicenseUpload,
        options: _authOptions(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid driving license response.');
      }

      final model = DrivingLicenseDetailsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (model.success != true) {
        final String msg = (model.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Failed to fetch driving license.' : msg);
      }
      return model;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw Exception(_mapDioError(error));
    }
  }

  @override
  Future<VehicleRcDetailsModel?> getVehicleRc() async {
    _refreshBaseUrl();

    if (Env.mockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return const VehicleRcDetailsModel(
        success: true,
        id: 'rc_mock_001',
        driverId: 'DRV-MOCK-001',
        documentType: 'rc_book',
        documentUrl: '/api/v1/documents/file/mock_rc_front.png',
        front: DocumentSideDetailsModel(
          id: 'rc_front_mock_001',
          documentUrl: '/api/v1/documents/file/mock_rc_front.png',
          verificationStatus: 'pending',
        ),
        back: DocumentSideDetailsModel(
          id: 'rc_back_mock_001',
          documentUrl: '/api/v1/documents/file/mock_rc_back.png',
          verificationStatus: 'pending',
        ),
        rcNumber: 'TN01AB1234',
        verificationStatus: 'pending',
        uploadedAtIso: '2026-03-18T09:43:01.210Z',
      );
    }

    try {
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.vehicleRcUpload,
        options: _authOptions(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid vehicle RC response.');
      }

      final model = VehicleRcDetailsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (model.success != true) {
        final String msg = (model.message ?? '').trim();
        throw Exception(msg.isEmpty ? 'Failed to fetch vehicle RC.' : msg);
      }
      return model;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
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
    return 'Failed to fetch document details.';
  }
}
