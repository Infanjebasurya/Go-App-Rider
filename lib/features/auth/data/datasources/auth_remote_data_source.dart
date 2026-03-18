import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/auth/data/models/user_model.dart';
import 'package:goapp/features/auth/data/models/verify_otp_response_model.dart';

class AuthResponse {
  const AuthResponse({required this.user});

  final UserModel user;
}

abstract interface class AuthRemoteDataSource {
  Future<String> requestOtp({required String phone});

  Future<AuthResponse> login({
    required String phone,
    required String otp,
    required String otpId,
  });

  Future<String> resendOtp({required String phone});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({Dio? dio})
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

  static const String _staticOtpType = 'login';

  final Dio _dio;

  void _refreshBaseUrl() {
    final String latestBaseUrl = ApiConfig.baseUrl;
    if (_dio.options.baseUrl != latestBaseUrl) {
      _dio.options.baseUrl = latestBaseUrl;
    }
  }

  @override
  Future<AuthResponse> login({
    required String phone,
    required String otp,
    required String otpId,
  }) async {
    _refreshBaseUrl();

    // Temporary/mock flow (enabled by default via Env.mockApi=true).
    // Allows UI to proceed even if the backend OTP verification contract differs.
    if (Env.mockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (otp.trim() != '5656') {
        throw Exception('Invalid OTP');
      }
      await AuthTokenStore.save(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        tokenType: 'Bearer',
      );
      return AuthResponse(
        user: UserModel(id: 'captain-001', phone: phone.trim()),
      );
    }
    // Backend contract (as provided):
    // POST /api/v1/auth/otp/verify
    // { phoneNumber, otpCode, otpType }
    final Map<String, dynamic> body = <String, dynamic>{
      'phoneNumber': phone.trim(),
      'otpCode': otp.trim(),
      'otpType': _staticOtpType,
    };

    final List<String> endpoints = <String>[
      ApiEndpoints.authVerifyOtp,
      ApiEndpoints.authLogin, // legacy fallback
    ];

    debugPrint(
      'Verify OTP request -> POST ${_dio.options.baseUrl}${endpoints.first}',
    );
    debugPrint('Verify OTP request body -> $body');

    try {
      Response<dynamic> response;
      String usedEndpoint = endpoints.first;

      try {
        response = await _dio.post(usedEndpoint, data: body);
      } on DioException catch (error) {
        if (error.response?.statusCode == 404 && endpoints.length > 1) {
          usedEndpoint = endpoints[1];
          debugPrint(
            'Verify OTP endpoint not found (404). Retrying legacy endpoint -> '
            '$usedEndpoint',
          );
          response = await _dio.post(usedEndpoint, data: body);
        } else {
          rethrow;
        }
      }

      debugPrint(
        'Verify OTP response <- [$usedEndpoint] [${response.statusCode}] ${response.data}',
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid verify OTP response.');
      }

      final Map<String, dynamic> json = response.data as Map<String, dynamic>;

      // Primary parsing via existing model (supports access_token/token).
      final VerifyOtpResponseModel parsed = VerifyOtpResponseModel.fromJson(
        json,
      );

      // Backend contract (as provided) returns `sessionToken`, not `accessToken`.
      final String? sessionToken = json['sessionToken']?.toString();
      final String? refreshToken = json['refreshToken']?.toString();

      final String accessToken = (parsed.accessToken?.isNotEmpty ?? false)
          ? parsed.accessToken!
          : (sessionToken ?? '');

      if (accessToken.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await AuthTokenStore.save(
        accessToken: accessToken,
        refreshToken: (parsed.refreshToken?.isNotEmpty ?? false)
            ? parsed.refreshToken
            : refreshToken,
        tokenType: (parsed.tokenType?.isNotEmpty ?? false)
            ? parsed.tokenType
            : 'Bearer',
      );

      final UserModel user =
          parsed.user ??
          _extractUserFromVerifyJson(json) ??
          UserModel(id: 'captain-001', phone: phone.trim());

      return AuthResponse(user: user);
    } on DioException catch (error) {
      debugPrint(
        'Verify OTP error <- [${error.response?.statusCode}] ${error.response?.data}',
      );
      debugPrint(
        'Verify OTP dio details <- type=${error.type}, message=${error.message}, error=${error.error}',
      );
      throw Exception(_mapVerifyOtpError(error));
    } catch (error) {
      debugPrint('Verify OTP unexpected error <- $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<String> requestOtp({required String phone}) async {
    _refreshBaseUrl();

    // Temporary/mock flow (enabled by default via Env.mockApi=true).
    // Returns a stable request id that the OTP page can pass back.
    if (Env.mockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return 'mock-otp-request-id';
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'phoneNumber': phone.trim(),
      'otpType': _staticOtpType,
    };

    // Backend contract (as provided):
    // POST /api/v1/auth/otp/request
    // { phoneNumber, otpType }
    final List<String> endpoints = <String>[
      ApiEndpoints.authOtpRequest,
      ApiEndpoints.authSendOtp,
      '/api/v1/auth/request-otp', // common alternative on some backends
      ApiEndpoints.authRequestOtp, // legacy fallback
    ];

    debugPrint('OTP request -> POST ${_dio.options.baseUrl}${endpoints.first}');
    debugPrint('OTP request body -> $body');

    try {
      Response<dynamic>? response;
      String? usedEndpoint;

      DioException? lastNotFound;
      for (final String endpoint in endpoints) {
        try {
          response = await _dio.post(endpoint, data: body);
          usedEndpoint = endpoint;
          break;
        } on DioException catch (error) {
          if (error.response?.statusCode == 404) {
            lastNotFound = error;
            debugPrint('OTP endpoint not found (404) -> $endpoint');
            continue;
          }
          rethrow;
        }
      }

      if (response == null || usedEndpoint == null) {
        // None of the known endpoints exist on this backend.
        throw Exception(
          _mapDioError(
            lastNotFound ??
                DioException(
                  requestOptions: RequestOptions(path: endpoints.first),
                  response: Response(
                    requestOptions: RequestOptions(path: endpoints.first),
                    statusCode: 404,
                    data: const <String, dynamic>{
                      'message': 'OTP endpoint not found',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
          ),
        );
      }

      debugPrint(
        'OTP response <- [$usedEndpoint] [${response.statusCode}] ${response.data}',
      );

      if (_isOtpRequestSuccessful(response)) {
        final String? extracted = _extractOtpId(response.data);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
        // Some backends don't return any id and also don't require it for verify.
        // We still have to provide something to the OTP UI route parameter.
        return 'no-otp-id';
      }

      throw Exception(_extractErrorMessage(response.data));
    } on DioException catch (error) {
      debugPrint(
        'OTP error <- [${error.response?.statusCode}] ${error.response?.data}',
      );
      debugPrint(
        'OTP dio details <- type=${error.type}, message=${error.message}, error=${error.error}',
      );
      throw Exception(_mapDioError(error));
    } catch (error) {
      debugPrint('OTP unexpected error <- $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<String> resendOtp({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'OTP resent';
  }

  bool _isOtpRequestSuccessful(Response<dynamic> response) {
    final int? statusCode = response.statusCode;
    final dynamic data = response.data;

    if (statusCode != 200 && statusCode != 201) {
      return false;
    }

    if (data is Map<String, dynamic>) {
      final dynamic success = data['success'] ?? data['status'];
      if (success is bool) return success;
      if (success is String) {
        final String normalized = success.toLowerCase();
        if (normalized == 'success' || normalized == 'ok') {
          return true;
        }
        if (normalized == 'failed' ||
            normalized == 'failure' ||
            normalized == 'error' ||
            normalized == 'false') {
          return false;
        }
      }
      final dynamic error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return false;
      }
      if (data.containsKey('otpId') ||
          data.containsKey('otp_id') ||
          data.containsKey('requestId') ||
          data.containsKey('request_id') ||
          data.containsKey('message')) {
        return true;
      }
    }

    return false;
  }

  String? _extractOtpId(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final dynamic otpId =
        data['otpId'] ??
        data['otp_id'] ??
        data['requestId'] ??
        data['request_id'] ??
        data['id'] ??
        data['data']?['otpId'] ??
        data['data']?['otp_id'] ??
        data['data']?['requestId'] ??
        data['data']?['request_id'] ??
        data['data']?['id'];
    if (otpId is String && otpId.isNotEmpty) {
      return otpId;
    }
    return null;
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic message =
          data['message'] ?? data['error'] ?? data['errors'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Failed to send OTP.';
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network failure. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.badCertificate) {
      return 'SSL certificate error. Unable to reach the server securely.';
    }

    final int? statusCode = error.response?.statusCode;
    if (statusCode == 404) {
      return 'OTP service not available on this server. Please update the app or contact support.';
    }
    if (statusCode == 400 || statusCode == 422) {
      return 'Invalid phone number.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return _extractErrorMessage(error.response?.data);
  }

  UserModel? _extractUserFromVerifyJson(Map<String, dynamic> json) {
    final dynamic userRaw = json['user'];
    if (userRaw is Map<String, dynamic>) {
      final String id =
          (userRaw['userId'] ?? userRaw['id'] ?? userRaw['user_id'] ?? '')
              .toString();
      final String phone =
          (userRaw['phoneNumber'] ??
                  userRaw['phone'] ??
                  userRaw['mobile'] ??
                  '')
              .toString();
      if (id.isEmpty && phone.isEmpty) return null;
      return UserModel(id: id, phone: phone);
    }
    return null;
  }

  String _mapVerifyOtpError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network failure. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.badCertificate) {
      return 'SSL certificate error. Unable to reach the server securely.';
    }

    final int? statusCode = error.response?.statusCode;
    final String message = _extractErrorMessage(error.response?.data);
    if (statusCode == 400 || statusCode == 401) {
      final String normalized = message.toLowerCase();
      if (normalized.contains('expired')) {
        return 'OTP expired. Please request a new OTP.';
      }
      if (normalized.contains('invalid otp') || normalized.contains('wrong')) {
        return 'Invalid OTP';
      }
      if (message.isNotEmpty) return message;
      return 'Invalid OTP';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return message;
  }

  // (removed unused _shouldUseStaticFallback)
}
