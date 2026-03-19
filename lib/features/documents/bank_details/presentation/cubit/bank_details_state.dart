import 'package:equatable/equatable.dart';

import '../../../data/models/save_bank_details_models.dart';

enum BankDetailsStatus { empty, loading, success, error }

class BankDetailsState extends Equatable {
  const BankDetailsState({
    required this.status,
    required this.details,
    required this.errorMessage,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.confirmAccountNumber,
    required this.ifscCode,
    required this.type,
    required this.bankBookPath,
  });

  final BankDetailsStatus status;
  final BankDetailsModel? details;
  final String? errorMessage;

  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifscCode;
  final String type; // savings/current
  final String? bankBookPath;

  factory BankDetailsState.initial() => const BankDetailsState(
    status: BankDetailsStatus.empty,
    details: null,
    errorMessage: null,
    accountHolderName: '',
    bankName: '',
    accountNumber: '',
    confirmAccountNumber: '',
    ifscCode: '',
    type: 'savings',
    bankBookPath: null,
  );

  bool get isLoading => status == BankDetailsStatus.loading;

  bool get hasBankBook =>
      bankBookPath != null && bankBookPath!.trim().isNotEmpty;

  bool get canSubmit {
    if (isLoading) return false;
    if (accountHolderName.trim().isEmpty) return false;
    if (bankName.trim().isEmpty) return false;
    if (accountNumber.trim().length < 8) return false;
    if (confirmAccountNumber.trim() != accountNumber.trim()) return false;
    if (!RegExp(
      r'^[A-Z]{4}0[A-Z0-9]{6}$',
    ).hasMatch(ifscCode.trim().toUpperCase())) {
      return false;
    }
    final t = type.trim().toLowerCase();
    if (t != 'savings' && t != 'current') return false;
    if (!hasBankBook) return false;
    return true;
  }

  BankDetailsState copyWith({
    BankDetailsStatus? status,
    BankDetailsModel? details,
    String? errorMessage,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? type,
    String? bankBookPath,
    bool clearError = false,
    bool clearDetails = false,
  }) {
    return BankDetailsState(
      status: status ?? this.status,
      details: clearDetails ? null : (details ?? this.details),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      confirmAccountNumber: confirmAccountNumber ?? this.confirmAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      type: type ?? this.type,
      bankBookPath: bankBookPath ?? this.bankBookPath,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    details,
    errorMessage,
    accountHolderName,
    bankName,
    accountNumber,
    confirmAccountNumber,
    ifscCode,
    type,
    bankBookPath,
  ];
}
