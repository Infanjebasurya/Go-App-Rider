class BankDetailsModel {
  const BankDetailsModel({
    required this.bankId,
    required this.accountHolder,
    required this.maskedAccountNumber,
    required this.ifsc,
    required this.bankName,
    required this.type,
    required this.status,
    this.bankBookUrl,
  });

  final String bankId;
  final String accountHolder;
  final String maskedAccountNumber;
  final String ifsc;
  final String bankName;
  final String type; // savings | current
  final String status; // pending | approved | rejected
  final String? bankBookUrl;

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) {
    return BankDetailsModel(
      bankId: (json['bank_id'] ?? json['bankId'] ?? json['id'] ?? '')
          .toString(),
      accountHolder: (json['account_holder'] ?? json['accountHolder'] ?? '')
          .toString(),
      maskedAccountNumber:
          (json['masked_account_number'] ?? json['maskedAccountNumber'] ?? '')
              .toString(),
      ifsc: (json['ifsc'] ?? json['ifsc_code'] ?? json['ifscCode'] ?? '')
          .toString(),
      bankName: (json['bank_name'] ?? json['bankName'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      bankBookUrl: (json['bank_book_url'] ?? json['bankBookUrl'])?.toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'bank_id': bankId,
    'account_holder': accountHolder,
    'masked_account_number': maskedAccountNumber,
    'ifsc': ifsc,
    'bank_name': bankName,
    'type': type,
    if (bankBookUrl != null) 'bank_book_url': bankBookUrl,
    'status': status,
  };
}

class BankDetailsResponseModel {
  const BankDetailsResponseModel({
    required this.success,
    required this.details,
    this.message,
    this.requestId,
  });

  final bool success;
  final BankDetailsModel details;
  final String? message;
  final String? requestId;

  factory BankDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return BankDetailsResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
      requestId: (json['requestId'] ?? json['request_id'])?.toString(),
      details: BankDetailsModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'success': success,
    if (message != null) 'message': message,
    if (requestId != null) 'requestId': requestId,
    ...details.toJson(),
  };
}

class AddBankDetailsRequestModel {
  const AddBankDetailsRequestModel({
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.confirmAccountNumber,
    required this.ifscCode,
    required this.type,
  });

  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifscCode;
  final String type; // savings | current

  Map<String, dynamic> toJson() => <String, dynamic>{
    'account_holder_name': accountHolderName,
    'bank_name': bankName,
    'account_number': accountNumber,
    'confirm_account_number': confirmAccountNumber,
    'ifsc_code': ifscCode,
    'type': type,
  };
}
