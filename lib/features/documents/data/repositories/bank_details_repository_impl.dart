import 'dart:io';

import '../datasources/bank_details_service.dart';
import '../models/save_bank_details_models.dart';
import 'bank_details_repository.dart';

class BankDetailsRepositoryImpl implements BankDetailsRepository {
  BankDetailsRepositoryImpl({required BankDetailsService service})
    : _service = service;

  final BankDetailsService _service;

  static final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  @override
  Future<BankDetailsModel> addBankDetails({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifscCode,
    String type = 'savings',
    required File bankBook,
  }) async {
    final holder = _requireNonEmpty(
      accountHolderName,
      message: 'Account holder name is required.',
    );
    final bank = _requireNonEmpty(bankName, message: 'Bank name is required.');
    final account = _normalizeAccount(accountNumber);
    if (account.length < 8) {
      throw FormatException('Account number must be at least 8 digits.');
    }
    final confirm = _normalizeAccount(confirmAccountNumber);
    if (confirm != account) {
      throw FormatException('Account numbers do not match.');
    }

    final ifsc = _requireNonEmpty(
      ifscCode,
      message: 'IFSC code is required.',
    ).toUpperCase();
    if (!_ifscRegex.hasMatch(ifsc)) {
      throw FormatException('Enter a valid IFSC code.');
    }

    final normalizedType = _normalizeType(type);
    if (!await bankBook.exists()) {
      throw Exception('Selected bank book image not found.');
    }

    final req = AddBankDetailsRequestModel(
      accountHolderName: holder,
      bankName: _normalizeBankName(bank),
      accountNumber: account,
      confirmAccountNumber: confirm,
      ifscCode: ifsc,
      type: normalizedType,
    );

    final BankDetailsResponseModel response = await _service.addBankDetails(
      request: req,
      bankBook: bankBook,
    );
    if (!response.success) {
      throw Exception('Failed to add bank details.');
    }

    final details = response.details;
    return BankDetailsModel(
      bankId: details.bankId,
      accountHolder: details.accountHolder.trim(),
      maskedAccountNumber: details.maskedAccountNumber.trim().isNotEmpty
          ? details.maskedAccountNumber
          : 'XXXX XXXX ${_last4(account)}',
      ifsc: details.ifsc.trim().toUpperCase(),
      bankName: _normalizeBankName(details.bankName),
      type: _normalizeType(
        details.type.isEmpty ? normalizedType : details.type,
      ),
      bankBookUrl: details.bankBookUrl,
      status: details.status.trim().isEmpty ? 'pending' : details.status.trim(),
    );
  }

  @override
  Future<BankDetailsModel> getBankDetails() async {
    final response = await _service.getBankDetails();
    if (!response.success) {
      throw Exception('Failed to fetch bank details.');
    }
    final d = response.details;
    return BankDetailsModel(
      bankId: d.bankId,
      accountHolder: d.accountHolder.trim(),
      maskedAccountNumber: d.maskedAccountNumber,
      ifsc: d.ifsc.trim().toUpperCase(),
      bankName: _normalizeBankName(d.bankName),
      type: _normalizeType(d.type),
      bankBookUrl: d.bankBookUrl,
      status: d.status.trim().isEmpty ? 'pending' : d.status.trim(),
    );
  }

  String _requireNonEmpty(String value, {required String message}) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw FormatException(message);
    return normalized;
  }

  String _normalizeAccount(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) {
      throw FormatException('Account number is required.');
    }
    return normalized;
  }

  String _normalizeType(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'savings' || normalized == 'current') return normalized;
    throw FormatException('Account type must be savings or current.');
  }

  String _normalizeBankName(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\\s+'), ' ');
    return trimmed.isEmpty ? trimmed : trimmed.toUpperCase();
  }

  String _last4(String raw) {
    if (raw.isEmpty) return '0000';
    if (raw.length <= 4) return raw;
    return raw.substring(raw.length - 4);
  }
}
