import 'dart:io';

import '../models/save_bank_details_models.dart';

abstract interface class BankDetailsRepository {
  Future<BankDetailsModel> addBankDetails({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifscCode,
    String type = 'savings',
    required File bankBook,
  });

  Future<BankDetailsModel> getBankDetails();
}
