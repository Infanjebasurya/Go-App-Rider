part of 'document_upload_cubit.dart';

void _updateDocumentNumber(DocumentUploadCubit cubit, String value) {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  final raw = value.trim();
  final normalized = _normalizeDocumentNumber(
    cubit.state.currentDocStep.step,
    raw,
  );
  final isAadhaarOrPan =
      cubit.state.currentDocStep.step == DocumentStep.identityAadhaar ||
      cubit.state.currentDocStep.step == DocumentStep.identityPan;
  final hasValue = raw.isNotEmpty;
  final error = isAadhaarOrPan
      ? null
      : (hasValue
            ? _validateDocumentNumber(
                cubit.state.currentDocStep.step,
                normalized,
              )
            : null);
  final updated = cubit.state.currentDocStep.copyWith(
    documentNumber: raw,
    numberError: error,
    clearError: true,
  );
  DocumentProgressStore.setDocumentNumber(
    cubit._mapStepToDocType(updated.step),
    normalized,
  );
  cubit._emitState(cubit.state.copyWithDocStep(updated));
}

bool _validateDocStep(DocumentUploadCubit cubit) {
  final step = cubit.state.currentDocStep;
  if (step.step == DocumentStep.profilePhoto) {
    if (step.frontCaptured) {
      DocumentProgressStore.setProfileImagePath(step.frontPath);
      return true;
    }
    cubit._emitState(
      cubit.state.copyWithDocStep(
        step.copyWith(
          imageError: 'Please upload your profile picture before proceeding.',
          clearError: true,
        ),
      ),
    );
    return false;
  }

  final bool requiresBackSide = step.requiresBackSide;
  if (!step.frontCaptured || (requiresBackSide && !step.backCaptured)) {
    final updated = step.copyWith(
      numberError: requiresBackSide
          ? 'Please upload both front and back documents'
          : 'Please upload the document image',
      imageError: requiresBackSide
          ? 'Please upload both front and back documents'
          : 'Please upload the document image',
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    DocumentProgressStore.setCompleted(
      cubit._mapStepToDocType(step.step),
      false,
    );
    return false;
  }

  final rawValue = step.documentNumber.trim();
  if (rawValue.isEmpty) {
    final updated = step.copyWith(numberError: 'Document number is required');
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    DocumentProgressStore.setCompleted(
      cubit._mapStepToDocType(step.step),
      false,
    );
    return false;
  }

  final normalized = _normalizeDocumentNumber(step.step, rawValue);
  final error = _validateDocumentNumber(step.step, normalized);
  if (error != null) {
    final updated = step.copyWith(numberError: error);
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    DocumentProgressStore.setCompleted(
      cubit._mapStepToDocType(step.step),
      false,
    );
    return false;
  }

  if (normalized != step.documentNumber) {
    final updated = step.copyWith(
      documentNumber: normalized,
      clearError: true,
      clearExpiryError: true,
      clearImageError: true,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  }
  if (step.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(step.copyWith(clearImageError: true)),
    );
  }
  if (step.step != DocumentStep.drivingLicense &&
      step.step != DocumentStep.vehicleRC) {
    DocumentProgressStore.setCompleted(
      cubit._mapStepToDocType(step.step),
      true,
    );
  }
  return true;
}

String _normalizeDocumentNumber(DocumentStep step, String value) {
  return DocumentNumberRules.normalize(step, value);
}

String? _validateDocumentNumber(DocumentStep step, String value) {
  return DocumentNumberRules.validate(step, value);
}

bool _validateBankStep(DocumentUploadCubit cubit) {
  final b = cubit.state.bankData;
  BankAccountData updated = b.copyWith(
    clearNameError: true,
    clearBankNameError: true,
    clearAccountNumberError: true,
    clearConfirmError: true,
    clearIfscError: true,
    clearBankDocumentError: true,
  );
  bool valid = true;

  if (b.accountHolderName.trim().isEmpty) {
    updated = updated.copyWith(nameError: 'Account holder name is required');
    valid = false;
  }
  if (b.accountHolderName.trim().isNotEmpty &&
      !RegExp(
        r'^[A-Z ]+$',
      ).hasMatch(b.accountHolderName.trim().toUpperCase())) {
    updated = updated.copyWith(nameError: 'Only alphabets are allowed');
    valid = false;
  }
  if (b.bankName.trim().isEmpty) {
    updated = updated.copyWith(bankNameError: 'Bank name is required');
    valid = false;
  } else if (!RegExp(r'^[A-Z ]+$').hasMatch(b.bankName.trim().toUpperCase())) {
    updated = updated.copyWith(bankNameError: 'Only alphabets are allowed');
    valid = false;
  }
  if (b.accountNumber.trim().isEmpty) {
    updated = updated.copyWith(
      accountNumberError: 'Account number is required',
    );
    valid = false;
  } else if (!RegExp(
    r'^[A-Z0-9]+$',
  ).hasMatch(b.accountNumber.trim().toUpperCase())) {
    updated = updated.copyWith(
      accountNumberError: 'Only alphabets and numbers are allowed',
    );
    valid = false;
  }
  if (b.confirmAccountNumber.trim().isEmpty) {
    updated = updated.copyWith(
      confirmAccountNumberError: 'Please confirm account number',
    );
    valid = false;
  } else if (!RegExp(
    r'^[A-Z0-9]+$',
  ).hasMatch(b.confirmAccountNumber.trim().toUpperCase())) {
    updated = updated.copyWith(
      confirmAccountNumberError: 'Only alphabets and numbers are allowed',
    );
    valid = false;
  } else if (b.confirmAccountNumber != b.accountNumber) {
    updated = updated.copyWith(
      confirmAccountNumberError: 'Account numbers do not match',
    );
    valid = false;
  }
  if (b.ifscCode.trim().isEmpty) {
    updated = updated.copyWith(ifscError: 'IFSC code is required');
    valid = false;
  } else if (!RegExp(
    r'^[A-Z]{4}0[A-Z0-9]{6}$',
  ).hasMatch(b.ifscCode.trim().toUpperCase())) {
    updated = updated.copyWith(ifscError: 'Enter a valid IFSC code');
    valid = false;
  }
  if (b.bankDocumentPath == null || b.bankDocumentPath!.trim().isEmpty) {
    updated = updated.copyWith(
      bankDocumentError: 'Please upload bank document',
    );
    valid = false;
  }

  if (updated != b) {
    cubit._emitState(cubit.state.copyWith(bankData: updated));
  }
  return valid;
}

Future<void> _saveAndNext(
  DocumentUploadCubit cubit, {
  required bool advance,
}) async {
  if (cubit.state.isSubmitting ||
      cubit._isPicking ||
      cubit.state.isProfileImageProcessing) {
    return;
  }
  if (cubit.state.isCurrentStepBank) {
    if (!_validateBankStep(cubit)) return;
    cubit._emitState(
      cubit.state.copyWith(
        isSubmitting: true,
        clearStatusMessage: true,
        statusIsError: false,
      ),
    );

    try {
      final b = cubit.state.bankData;
      final path = (b.bankDocumentPath ?? '').trim();
      await cubit._bankDetailsRepository.addBankDetails(
        accountHolderName: b.accountHolderName,
        bankName: b.bankName,
        accountNumber: b.accountNumber,
        confirmAccountNumber: b.confirmAccountNumber,
        ifscCode: b.ifscCode,
        type: 'savings',
        bankBook: File(path),
      );

      DocumentProgressStore.setCompleted(DocumentType.bankDetails, true);
      cubit._emitState(
        cubit.state.copyWith(
          isSubmitting: false,
          isAllDone: true,
          statusMessage: 'Bank details saved successfully.',
          statusIsError: false,
        ),
      );
    } catch (e) {
      DocumentProgressStore.setCompleted(DocumentType.bankDetails, false);
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      cubit._emitState(
        cubit.state.copyWith(
          isSubmitting: false,
          statusMessage: msg.isEmpty ? 'Failed to save bank details.' : msg,
          statusIsError: true,
        ),
      );
    }
  } else {
    cubit._emitState(cubit.state.copyWith(isSubmitting: true));
    if (!_validateDocStep(cubit)) {
      cubit._emitState(cubit.state.copyWith(isSubmitting: false));
      return;
    }

    if (cubit.state.currentDocStep.step == DocumentStep.profilePhoto) {
      try {
        await cubit._uploadProfileImageAndContinue(advance: advance);
      } catch (e) {
        cubit._emitState(
          cubit.state.copyWith(
            isSubmitting: false,
            statusMessage: e.toString().replaceFirst('Exception: ', '').trim(),
            statusIsError: true,
          ),
        );
      }
      return;
    }

    if (cubit.state.currentDocStep.step == DocumentStep.drivingLicense) {
      try {
        await cubit._uploadDrivingLicenseAndContinue(advance: advance);
      } catch (e) {
        DocumentProgressStore.setCompleted(DocumentType.drivingLicense, false);
        cubit._emitState(
          cubit.state.copyWith(
            isSubmitting: false,
            statusMessage: e.toString().replaceFirst('Exception: ', '').trim(),
            statusIsError: true,
          ),
        );
      }
      return;
    }

    if (cubit.state.currentDocStep.step == DocumentStep.vehicleRC) {
      try {
        await cubit._uploadVehicleRcAndContinue(advance: advance);
      } catch (e) {
        DocumentProgressStore.setCompleted(DocumentType.vehicleRC, false);
        cubit._emitState(
          cubit.state.copyWith(
            isSubmitting: false,
            statusMessage: e.toString().replaceFirst('Exception: ', '').trim(),
            statusIsError: true,
          ),
        );
      }
      return;
    }

    final DocumentStep stepType = cubit.state.currentDocStep.step;
    final String? successMessage = switch (stepType) {
      DocumentStep.identityAadhaar => 'Aadhaar uploaded successfully.',
      DocumentStep.identityPan => 'PAN uploaded successfully.',
      _ => null,
    };

    cubit._emitState(
      cubit.state.copyWith(
        isSubmitting: false,
        currentStepIndex: advance
            ? cubit.state.currentStepIndex + 1
            : cubit.state.currentStepIndex,
        statusMessage: successMessage,
        statusIsError: false,
      ),
    );
  }
}
