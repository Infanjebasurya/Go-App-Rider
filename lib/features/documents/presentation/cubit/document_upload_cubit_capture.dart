part of 'document_upload_cubit.dart';

bool _requiresCr80CardAspect(DocumentStep step) {
  switch (step) {
    case DocumentStep.drivingLicense:
    case DocumentStep.vehicleRC:
    case DocumentStep.identityAadhaar:
    case DocumentStep.identityPan:
      return true;
    default:
      return false;
  }
}

Future<void> _setProfilePhotoFromPath(
  DocumentUploadCubit cubit, {
  required String path,
}) async {
  if (cubit.state.isCurrentStepBank || !cubit.state.isCurrentStepProfile) {
    return;
  }
  if (cubit._isPicking) return;

  final String trimmed = path.trim();
  if (trimmed.isEmpty) return;

  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }

  if (cubit._isTest) {
    DocumentProgressStore.setProfileImagePath(trimmed);
    await TextFieldStore.write(
      DocumentUploadCubit._profilePhotoStorageKey,
      trimmed,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: trimmed,
      frontType: DocumentUploadType.image,
      clearImageError: true,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }

  cubit._isPicking = true;
  cubit._emitState(cubit.state.copyWith(isProfileImageProcessing: true));
  try {
    if (!cubit._fileService.isValidImageFormat(trimmed)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError:
                'Only JPG, PNG, HEIC, HEIF, and WEBP images are allowed.',
          ),
        ),
      );
      return;
    }

    final int sizeBytes = await File(trimmed).length();
    if (!cubit._fileService.validateFileSize(sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    final String persistedPath = await cubit._fileService
        .persistImageToAppStorage(trimmed, prefix: 'profile_photo');
    final String? previousPath = cubit.state.currentDocStep.frontPath;
    if (previousPath != persistedPath) {
      await cubit._fileService.deleteManagedFileIfExists(previousPath);
    }

    DocumentProgressStore.setProfileImagePath(persistedPath);
    await TextFieldStore.write(
      DocumentUploadCubit._profilePhotoStorageKey,
      persistedPath,
    );
    final StepData updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: persistedPath,
      frontType: DocumentUploadType.image,
      clearImageError: true,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
    cubit._emitState(cubit.state.copyWith(isProfileImageProcessing: false));
  }
}

Future<void> _captureProfilePhoto(
  DocumentUploadCubit cubit, {
  required AppImageSource source,
}) async {
  if (cubit.state.isCurrentStepBank || !cubit.state.isCurrentStepProfile) {
    return;
  }
  if (cubit._isPicking) return;
  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }
  if (cubit._isTest) {
    const testPath = 'test_profile.jpg';
    DocumentProgressStore.setProfileImagePath(testPath);
    await TextFieldStore.write(
      DocumentUploadCubit._profilePhotoStorageKey,
      testPath,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: testPath,
      frontType: DocumentUploadType.image,
      clearImageError: true,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }
  if (!await cubit._fileService.ensurePermission(source)) return;

  cubit._isPicking = true;
  cubit._emitState(cubit.state.copyWith(isProfileImageProcessing: true));
  try {
    final picked = await _pickImageWithOptionalCrop(
      cubit,
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return;

    if (!cubit._fileService.isValidImageFormat(picked.path)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError:
                'Only JPG, PNG, HEIC, HEIF, and WEBP images are allowed.',
          ),
        ),
      );
      return;
    }

    final sizeBytes = await cubit._fileService.resolveImageSizeBytes(picked);
    if (!cubit._fileService.validateFileSize(sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    final persistedPath = await cubit._fileService.persistImageToAppStorage(
      picked.path,
      prefix: 'profile_photo',
    );
    final previousPath = cubit.state.currentDocStep.frontPath;
    if (previousPath != persistedPath) {
      await cubit._fileService.deleteManagedFileIfExists(previousPath);
    }
    DocumentProgressStore.setProfileImagePath(persistedPath);
    await TextFieldStore.write(
      DocumentUploadCubit._profilePhotoStorageKey,
      persistedPath,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: persistedPath,
      frontType: DocumentUploadType.image,
      clearImageError: true,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
    cubit._emitState(cubit.state.copyWith(isProfileImageProcessing: false));
  }
}

Future<void> _captureFront(
  DocumentUploadCubit cubit, {
  required AppImageSource source,
}) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  if (cubit._isPicking) return;
  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }
  if (cubit._isTest) {
    final updated = cubit.state.currentDocStep.copyWith(frontCaptured: true);
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }
  if (!await cubit._fileService.ensurePermission(source)) return;

  cubit._isPicking = true;
  try {
    final picked = await _pickImageWithOptionalCrop(
      cubit,
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return;

    final sizeBytes = await cubit._fileService.resolveImageSizeBytes(picked);
    if (!cubit._fileService.validateFileSize(sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    if (_requiresCr80CardAspect(cubit.state.currentDocStep.step)) {
      final String? ratioError = await cubit._fileService.validateCr80CardImage(
        picked.path,
      );
      if (ratioError != null) {
        cubit._emitState(
          cubit.state.copyWithDocStep(
            cubit.state.currentDocStep.copyWith(imageError: ratioError),
          ),
        );
        return;
      }
    }

    final persistedPath = await cubit._fileService.persistImageToAppStorage(
      picked.path,
      prefix: '${cubit.state.currentDocStep.step.name}_front',
    );
    final previousPath = cubit.state.currentDocStep.frontPath;
    if (previousPath != persistedPath) {
      await cubit._fileService.deleteManagedFileIfExists(previousPath);
    }
    DocumentProgressStore.setFrontImagePath(
      cubit._mapStepToDocType(cubit.state.currentDocStep.step),
      persistedPath,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: persistedPath,
      frontType: DocumentUploadType.image,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _captureFrontDocument(DocumentUploadCubit cubit) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  if (cubit._isPicking) return;
  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }
  if (cubit._isTest) {
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontType: DocumentUploadType.document,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }

  cubit._isPicking = true;
  try {
    final file = await cubit._filePickerService.pickCustom(
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (file == null) return;
    if (!cubit._fileService.validateFileSize(file.sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    await cubit._fileService.deleteManagedFileIfExists(
      cubit.state.currentDocStep.frontPath,
    );
    DocumentProgressStore.setFrontImagePath(
      cubit._mapStepToDocType(cubit.state.currentDocStep.step),
      file.path,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      frontCaptured: true,
      frontPath: file.path,
      frontType: DocumentUploadType.document,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _captureBack(
  DocumentUploadCubit cubit, {
  required AppImageSource source,
}) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  if (cubit._isPicking) return;
  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }
  if (cubit._isTest) {
    final updated = cubit.state.currentDocStep.copyWith(backCaptured: true);
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }
  if (!await cubit._fileService.ensurePermission(source)) return;

  cubit._isPicking = true;
  try {
    final picked = await _pickImageWithOptionalCrop(
      cubit,
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return;

    final sizeBytes = await cubit._fileService.resolveImageSizeBytes(picked);
    if (!cubit._fileService.validateFileSize(sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    if (_requiresCr80CardAspect(cubit.state.currentDocStep.step)) {
      final String? ratioError = await cubit._fileService.validateCr80CardImage(
        picked.path,
      );
      if (ratioError != null) {
        cubit._emitState(
          cubit.state.copyWithDocStep(
            cubit.state.currentDocStep.copyWith(imageError: ratioError),
          ),
        );
        return;
      }
    }

    final persistedPath = await cubit._fileService.persistImageToAppStorage(
      picked.path,
      prefix: '${cubit.state.currentDocStep.step.name}_back',
    );
    final previousPath = cubit.state.currentDocStep.backPath;
    if (previousPath != persistedPath) {
      await cubit._fileService.deleteManagedFileIfExists(previousPath);
    }
    DocumentProgressStore.setBackImagePath(
      cubit._mapStepToDocType(cubit.state.currentDocStep.step),
      persistedPath,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      backCaptured: true,
      backPath: persistedPath,
      backType: DocumentUploadType.image,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _captureBackDocument(DocumentUploadCubit cubit) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  if (cubit._isPicking) return;
  if (cubit.state.currentDocStep.imageError != null) {
    cubit._emitState(
      cubit.state.copyWithDocStep(
        cubit.state.currentDocStep.copyWith(clearImageError: true),
      ),
    );
  }
  if (cubit._isTest) {
    final updated = cubit.state.currentDocStep.copyWith(
      backCaptured: true,
      backType: DocumentUploadType.document,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
    return;
  }

  cubit._isPicking = true;
  try {
    final file = await cubit._filePickerService.pickCustom(
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (file == null) return;
    if (!cubit._fileService.validateFileSize(file.sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWithDocStep(
          cubit.state.currentDocStep.copyWith(
            imageError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    await cubit._fileService.deleteManagedFileIfExists(
      cubit.state.currentDocStep.backPath,
    );
    DocumentProgressStore.setBackImagePath(
      cubit._mapStepToDocType(cubit.state.currentDocStep.step),
      file.path,
    );
    final updated = cubit.state.currentDocStep.copyWith(
      backCaptured: true,
      backPath: file.path,
      backType: DocumentUploadType.document,
    );
    cubit._emitState(cubit.state.copyWithDocStep(updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _removeFront(DocumentUploadCubit cubit) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  await cubit._fileService.deleteManagedFileIfExists(
    cubit.state.currentDocStep.frontPath,
  );
  DocumentProgressStore.setFrontImagePath(
    cubit._mapStepToDocType(cubit.state.currentDocStep.step),
    null,
  );
  final updated = cubit.state.currentDocStep.copyWith(
    frontCaptured: false,
    clearFrontUpload: true,
    clearImageError: true,
  );
  cubit._emitState(cubit.state.copyWithDocStep(updated));
}

Future<void> _removeBack(DocumentUploadCubit cubit) async {
  if (cubit.state.isCurrentStepBank || cubit.state.isCurrentStepProfile) return;
  await cubit._fileService.deleteManagedFileIfExists(
    cubit.state.currentDocStep.backPath,
  );
  DocumentProgressStore.setBackImagePath(
    cubit._mapStepToDocType(cubit.state.currentDocStep.step),
    null,
  );
  final updated = cubit.state.currentDocStep.copyWith(
    backCaptured: false,
    clearBackUpload: true,
    clearImageError: true,
  );
  cubit._emitState(cubit.state.copyWithDocStep(updated));
}

Future<void> _captureBankDocument(
  DocumentUploadCubit cubit, {
  required AppImageSource source,
}) async {
  if (!cubit.state.isCurrentStepBank) return;
  if (cubit._isPicking) return;
  if (!await cubit._fileService.ensurePermission(source)) return;

  cubit._isPicking = true;
  try {
    final picked = await _pickImageWithOptionalCrop(
      cubit,
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return;

    final sizeBytes = await cubit._fileService.resolveImageSizeBytes(picked);
    if (!cubit._fileService.validateFileSize(sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWith(
          bankData: cubit.state.bankData.copyWith(
            bankDocumentError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    final persistedPath = await cubit._fileService.persistImageToAppStorage(
      picked.path,
      prefix: 'bank_book_front',
    );
    final previousPath = cubit.state.bankData.bankDocumentPath;
    if (previousPath != persistedPath) {
      await cubit._fileService.deleteManagedFileIfExists(previousPath);
    }
    DocumentProgressStore.setFrontImagePath(
      DocumentType.bankDetails,
      persistedPath,
    );
    final updated = cubit.state.bankData.copyWith(
      bankDocumentPath: persistedPath,
      bankDocumentType: DocumentUploadType.image,
      clearBankDocumentError: true,
    );
    cubit._emitState(cubit.state.copyWith(bankData: updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _captureBankDocumentFile(DocumentUploadCubit cubit) async {
  if (!cubit.state.isCurrentStepBank) return;
  if (cubit._isPicking) return;

  cubit._isPicking = true;
  try {
    final file = await cubit._filePickerService.pickCustom(
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (file == null) return;
    if (!cubit._fileService.validateFileSize(file.sizeBytes)) {
      cubit._emitState(
        cubit.state.copyWith(
          bankData: cubit.state.bankData.copyWith(
            bankDocumentError: 'File size must be under 5 MB',
          ),
        ),
      );
      return;
    }

    await cubit._fileService.deleteManagedFileIfExists(
      cubit.state.bankData.bankDocumentPath,
    );
    DocumentProgressStore.setFrontImagePath(
      DocumentType.bankDetails,
      file.path,
    );
    final updated = cubit.state.bankData.copyWith(
      bankDocumentPath: file.path,
      bankDocumentType: DocumentUploadType.document,
      clearBankDocumentError: true,
    );
    cubit._emitState(cubit.state.copyWith(bankData: updated));
  } finally {
    cubit._isPicking = false;
  }
}

Future<void> _removeBankDocument(DocumentUploadCubit cubit) async {
  if (!cubit.state.isCurrentStepBank) return;
  await cubit._fileService.deleteManagedFileIfExists(
    cubit.state.bankData.bankDocumentPath,
  );
  DocumentProgressStore.setFrontImagePath(DocumentType.bankDetails, null);
  final updated = cubit.state.bankData.copyWith(
    clearBankDocument: true,
    clearBankDocumentError: true,
  );
  cubit._emitState(cubit.state.copyWith(bankData: updated));
}

Future<PickedImage?> _pickImageWithOptionalCrop(
  DocumentUploadCubit cubit, {
  required AppImageSource source,
  int imageQuality = 100,
}) {
  return cubit._imagePickerService.pickImage(
    source: source,
    imageQuality: imageQuality,
  );
}
