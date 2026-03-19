import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';

import '../models/save_bank_details_models.dart';

enum DataMode { mock, live }

abstract interface class BankDetailsService {
  Future<BankDetailsResponseModel> addBankDetails({
    required AddBankDetailsRequestModel request,
    required File bankBook,
  });

  Future<BankDetailsResponseModel> getBankDetails();
}

class BankDetailsServiceImpl implements BankDetailsService {
  BankDetailsServiceImpl({required DataMode mode, Dio? dio})
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
  Future<BankDetailsResponseModel> addBankDetails({
    required AddBankDetailsRequestModel request,
    required File bankBook,
  }) {
    switch (_mode) {
      case DataMode.mock:
        return _mockAdd(request: request, bankBook: bankBook);
      case DataMode.live:
        return _liveAdd(request: request, bankBook: bankBook);
    }
  }

  @override
  Future<BankDetailsResponseModel> getBankDetails() {
    switch (_mode) {
      case DataMode.mock:
        return _mockGet();
      case DataMode.live:
        return _liveGet();
    }
  }

  Future<BankDetailsResponseModel> _mockAdd({
    required AddBankDetailsRequestModel request,
    required File bankBook,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final account = request.accountNumber.trim();
    if (account.endsWith('0000')) {
      throw Exception('Network error. Please try again.');
    }
    if (account.endsWith('9999')) {
      throw Exception('Upload failed. Please retry.');
    }

    final last4 = account.length <= 4
        ? account
        : account.substring(account.length - 4);
    return BankDetailsResponseModel.fromJson(<String, dynamic>{
      'success': true,
      'bank_id': '1a579fec-da76-4d82-809c-0f3386226b7b',
      'account_holder': request.accountHolderName,
      'masked_account_number': 'XXXX XXXX $last4',
      'ifsc': request.ifscCode,
      'bank_name': request.bankName,
      'type': request.type,
      'bank_book_url': '/api/v1/documents/file/${_fileName(bankBook)}',
      'status': 'pending',
      'message': 'Bank details saved successfully.',
      'requestId': '5057d9f2-1281-4af7-8b95-0ee816237693',
    });
  }

  Future<BankDetailsResponseModel> _mockGet() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return BankDetailsResponseModel.fromJson(const <String, dynamic>{
      'success': true,
      'bank_id': '1a579fec-da76-4d82-809c-0f3386226b7b',
      'account_holder': 'Kesavan Kumar',
      'masked_account_number': 'XXXX XXXX 7890',
      'ifsc': 'SBIN0001234',
      'bank_name': 'State Bank of India',
      'type': 'savings',
      'status': 'pending',
    });
  }

  Future<BankDetailsResponseModel> _liveAdd({
    required AddBankDetailsRequestModel request,
    required File bankBook,
  }) async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final formData = FormData.fromMap(<String, dynamic>{
      ...request.toJson(),
      'bank_book': await MultipartFile.fromFile(
        bankBook.path,
        filename: _fileName(bankBook),
      ),
    });

    final Response<dynamic> response = await _dio.post(
      ApiEndpoints.bankDetails,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }
    return BankDetailsResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<BankDetailsResponseModel> _liveGet() async {
    final token = AuthTokenStore.accessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }

    final Response<dynamic> response = await _dio.get(
      ApiEndpoints.bankDetails,
      options: Options(
        headers: <String, dynamic>{'Authorization': 'Bearer $token'},
      ),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }
    return BankDetailsResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  String _fileName(File file) {
    final segments = file.uri.pathSegments;
    if (segments.isNotEmpty) return segments.last;
    return 'bank_book.png';
  }
}
