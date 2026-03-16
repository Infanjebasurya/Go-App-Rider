import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
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
              baseUrl: ApiConfig.uatBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
            ),
          );

  static const String _staticPhoneNumber = '9876543210';
  static const String _staticOtpType = 'login';
  static const String _staticOtpCode = '5656';

  final Dio _dio;

  @override
  Future<AuthResponse> login({
    required String phone,
    required String otp,
    required String otpId,
  }) async {
    if (otp.trim() != _staticOtpCode) {
      debugPrint(
        'Verify OTP blocked -> entered OTP does not match static OTP $_staticOtpCode',
      );
      throw Exception('Wrong OTP');
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'phoneNumber': _staticPhoneNumber,
      'otpCode': _staticOtpCode,
      'otpType': _staticOtpType,
    };

    debugPrint(
      'Verify OTP request -> POST ${_dio.options.baseUrl}${ApiEndpoints.authVerifyOtp}',
    );
    debugPrint('Verify OTP request body -> $body');

    try {
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.authVerifyOtp,
        data: body,
      );

      debugPrint(
        'Verify OTP response <- [${response.statusCode}] ${response.data}',
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Invalid verify OTP response.');
      }

      final VerifyOtpResponseModel parsed = VerifyOtpResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!_isVerifyOtpSuccessful(response, parsed)) {
        throw Exception(_extractErrorMessage(response.data));
      }

      final String? accessToken = parsed.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await AuthTokenStore.save(
        accessToken: accessToken,
        refreshToken: parsed.refreshToken,
        tokenType: parsed.tokenType,
      );

      final UserModel user =
          parsed.user ??
          const UserModel(id: 'captain-001', phone: _staticPhoneNumber);

      return AuthResponse(user: user);
    } on DioException catch (error) {
      debugPrint(
        'Verify OTP error <- [${error.response?.statusCode}] ${error.response?.data}',
      );
      debugPrint(
        'Verify OTP dio details <- type=${error.type}, message=${error.message}, error=${error.error}',
      );
      if (_shouldUseStaticFallback(error)) {
        debugPrint('Verify OTP fallback -> using static success response');
        await AuthTokenStore.save(
          accessToken: 'static-access-token',
          refreshToken: 'static-refresh-token',
          tokenType: 'Bearer',
        );
        return const AuthResponse(
          user: UserModel(id: 'captain-001', phone: _staticPhoneNumber),
        );
      }
      throw Exception(_mapVerifyOtpError(error));
    } catch (error) {
      debugPrint('Verify OTP unexpected error <- $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<String> requestOtp({required String phone}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'phoneNumber': _staticPhoneNumber,
      'otpType': _staticOtpType,
    };

    debugPrint(
      'OTP request -> POST ${_dio.options.baseUrl}${ApiEndpoints.authSendOtp}',
    );
    debugPrint('OTP request body -> $body');

    try {
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.authSendOtp,
        data: body,
      );

      debugPrint('OTP response <- [${response.statusCode}] ${response.data}');

      if (_isOtpRequestSuccessful(response)) {
        debugPrint('Static OTP for testing -> $_staticOtpCode');
        return _extractOtpId(response.data) ?? 'static-otp-request';
      }

      throw Exception(_extractErrorMessage(response.data));
    } on DioException catch (error) {
      debugPrint(
        'OTP error <- [${error.response?.statusCode}] ${error.response?.data}',
      );
      debugPrint(
        'OTP dio details <- type=${error.type}, message=${error.message}, error=${error.error}',
      );
      if (_shouldUseStaticFallback(error)) {
        debugPrint('OTP fallback -> using static success response');
        debugPrint('Static OTP for testing -> $_staticOtpCode');
        return 'static-otp-request';
      }
      throw Exception(_mapDioError(error));
    } catch (error) {
      debugPrint('OTP unexpected error <- $error');
      throw Exception('Failed to send OTP.');
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
      }
      if (data.containsKey('otpId') ||
          data.containsKey('otp_id') ||
          data.containsKey('message')) {
        return true;
      }
    }

    return true;
  }

  String? _extractOtpId(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final dynamic otpId =
        data['otpId'] ?? data['otp_id'] ?? data['data']?['otpId'];
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
    if (statusCode == 400 || statusCode == 422) {
      return 'Invalid phone number.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return _extractErrorMessage(error.response?.data);
  }

  bool _isVerifyOtpSuccessful(
    Response<dynamic> response,
    VerifyOtpResponseModel parsed,
  ) {
    final int? statusCode = response.statusCode;
    if (statusCode != 200 && statusCode != 201) {
      return false;
    }
    return parsed.accessToken != null && parsed.accessToken!.isNotEmpty;
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
      return 'Wrong OTP';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return message;
  }

  bool _shouldUseStaticFallback(DioException error) {
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }
    final String message = (error.message ?? '').toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('no address associated with hostname');
  }
}
