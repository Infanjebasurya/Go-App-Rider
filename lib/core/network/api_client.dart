import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../utils/env.dart';
import 'api_endpoints.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final Dio dio;
  final TokenProvider? tokenProvider;
  final bool enableLogging;

  ApiClient({required this.dio, this.tokenProvider, bool? enableLogging})
    : enableLogging = enableLogging ?? kDebugMode {
    dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (tokenProvider != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await tokenProvider!();
            if (token != null &&
                token.isNotEmpty &&
                !options.headers.containsKey('Authorization')) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }

    if (this.enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    if (Env.mockApi) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final mockError =
                options.headers['X-Mock-Error'] == true ||
                options.headers['X-Mock-Error'] == 'true';

            if (options.path == ApiEndpoints.authLogin &&
                options.method == 'POST') {
              await Future<void>.delayed(const Duration(milliseconds: 400));
              if (mockError) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 401,
                      data: {'message': 'Invalid OTP'},
                    ),
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'user_001',
                    'name': 'Demo User',
                    'token': 'demo-token-123',
                  },
                ),
              );
              return;
            }

            if (options.path == ApiEndpoints.authRequestOtp &&
                options.method == 'POST') {
              await Future<void>.delayed(const Duration(milliseconds: 400));
              if (mockError) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 400,
                      data: {'message': 'Failed to send OTP'},
                    ),
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'OTP sent', 'otp_id': 'otp_123'},
                ),
              );
              return;
            }

            if (options.path == ApiEndpoints.authResendOtp &&
                options.method == 'POST') {
              await Future<void>.delayed(const Duration(milliseconds: 400));
              if (mockError) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 429,
                      data: {'message': 'Too many requests'},
                    ),
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'OTP resent'},
                ),
              );
              return;
            }

            if (options.path == ApiEndpoints.profileCreate &&
                options.method == 'POST') {
              await Future<void>.delayed(const Duration(milliseconds: 400));
              if (mockError) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 400,
                      data: {'message': 'Profile validation failed'},
                    ),
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'profile_001',
                    'name': options.data['name'],
                    'gender': options.data['gender'],
                    'email': options.data['email'],
                    'emergency_contact': options.data['emergency_contact'],
                  },
                ),
              );
              return;
            }

            handler.next(options);
          },
        ),
      );
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<dynamic>> put(String path, {dynamic data, Options? options}) {
    return dio.put(path, data: data, options: options);
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return dio.delete(path, data: data, options: options);
  }
}
