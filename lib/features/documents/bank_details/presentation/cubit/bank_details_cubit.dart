import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/file_picker_service.dart';

import '../../../data/repositories/bank_details_repository.dart';
import 'bank_details_state.dart';

class BankDetailsCubit extends Cubit<BankDetailsState> {
  BankDetailsCubit({
    required BankDetailsRepository repository,
    required FilePickerService filePickerService,
  }) : _repository = repository,
       _filePickerService = filePickerService,
       super(BankDetailsState.initial());

  final BankDetailsRepository _repository;
  final FilePickerService _filePickerService;

  void _log(String message) {
    developer.log(message, name: 'Documents.BankDetails');
  }

  void updateAccountHolderName(String value) {
    emit(state.copyWith(accountHolderName: value, clearError: true));
  }

  void updateBankName(String value) {
    emit(state.copyWith(bankName: value, clearError: true));
  }

  void updateAccountNumber(String value) {
    emit(state.copyWith(accountNumber: value, clearError: true));
  }

  void updateConfirmAccountNumber(String value) {
    emit(state.copyWith(confirmAccountNumber: value, clearError: true));
  }

  void updateIfscCode(String value) {
    emit(state.copyWith(ifscCode: value, clearError: true));
  }

  void updateType(String value) {
    emit(state.copyWith(type: value, clearError: true));
  }

  Future<void> pickBankBook() async {
    emit(state.copyWith(clearError: true));
    final picked = await _filePickerService.pickImage();
    if (picked == null) return;
    emit(state.copyWith(bankBookPath: picked.path));
  }

  void removeBankBook() {
    emit(state.copyWith(bankBookPath: null));
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    if (!state.canSubmit) {
      emit(
        state.copyWith(
          status: BankDetailsStatus.error,
          errorMessage: 'Please fill all fields correctly.',
        ),
      );
      return;
    }

    final path = state.bankBookPath!;
    _log('Add bank details -> submit file=$path');
    emit(state.copyWith(status: BankDetailsStatus.loading, clearError: true));

    try {
      final details = await _repository.addBankDetails(
        accountHolderName: state.accountHolderName,
        bankName: state.bankName,
        accountNumber: state.accountNumber,
        confirmAccountNumber: state.confirmAccountNumber,
        ifscCode: state.ifscCode,
        type: state.type,
        bankBook: File(path),
      );
      _log('Add bank details <- ${details.toJson()}');
      emit(state.copyWith(status: BankDetailsStatus.success, details: details));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      _log('Add bank details error <- $msg');
      emit(
        state.copyWith(
          status: BankDetailsStatus.error,
          errorMessage: msg.isEmpty ? 'Failed to add bank details.' : msg,
        ),
      );
    }
  }

  Future<void> loadBankDetails() async {
    if (state.isLoading) return;
    emit(state.copyWith(status: BankDetailsStatus.loading, clearError: true));
    try {
      final details = await _repository.getBankDetails();
      emit(state.copyWith(status: BankDetailsStatus.success, details: details));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      emit(
        state.copyWith(
          status: BankDetailsStatus.error,
          errorMessage: msg.isEmpty ? 'Failed to fetch bank details.' : msg,
        ),
      );
    }
  }

  void reset() => emit(BankDetailsState.initial());
}
