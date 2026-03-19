import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/file_picker_service.dart';
import 'package:goapp/core/service/image_picker_service.dart';
import 'package:goapp/features/documents/aadhaar_upload/domain/repositories/aadhaar_upload_repository.dart';
import 'package:goapp/features/documents/aadhaar_upload/presentation/cubit/aadhaar_upload_state.dart';

enum AadhaarImageSide { front, back }

class AadhaarUploadCubit extends Cubit<AadhaarUploadState> {
  AadhaarUploadCubit({
    required AadhaarUploadRepository repository,
    required ImagePickerService imagePickerService,
    required FilePickerService filePickerService,
  }) : _repository = repository,
       _imagePickerService = imagePickerService,
       _filePickerService = filePickerService,
       super(AadhaarUploadState.initial());

  final AadhaarUploadRepository _repository;
  final ImagePickerService _imagePickerService;
  final FilePickerService _filePickerService;

  void _log(String message) {
    developer.log(message, name: 'AadhaarUpload');
  }

  void updateAadhaarNumber(String value) {
    final normalized = value.trim();
    final valid =
        normalized.isEmpty || RegExp(r'^\d{0,12}$').hasMatch(normalized);
    emit(
      state.copyWith(
        aadhaarNumber: value,
        aadhaarError: valid ? null : 'Digits only',
        clearError: true,
        clearResponse: true,
      ),
    );
  }

  Future<void> pickFromCamera(AadhaarImageSide side) async {
    emit(state.copyWith(clearError: true, clearResponse: true));
    final picked = await _imagePickerService.pickImage(
      source: AppImageSource.camera,
      imageQuality: 95,
    );
    if (picked == null) return;
    switch (side) {
      case AadhaarImageSide.front:
        emit(
          state.copyWith(
            frontFilePath: picked.path,
            frontFileName: picked.name,
            clearAadhaarError: true,
          ),
        );
        return;
      case AadhaarImageSide.back:
        emit(
          state.copyWith(
            backFilePath: picked.path,
            backFileName: picked.name,
            clearAadhaarError: true,
          ),
        );
        return;
    }
  }

  Future<void> pickFromGallery(AadhaarImageSide side) async {
    emit(state.copyWith(clearError: true, clearResponse: true));
    final picked = await _filePickerService.pickImage();
    if (picked == null) return;
    switch (side) {
      case AadhaarImageSide.front:
        emit(
          state.copyWith(
            frontFilePath: picked.path,
            frontFileName: picked.name,
            clearAadhaarError: true,
          ),
        );
        return;
      case AadhaarImageSide.back:
        emit(
          state.copyWith(
            backFilePath: picked.path,
            backFileName: picked.name,
            clearAadhaarError: true,
          ),
        );
        return;
    }
  }

  void removeFile(AadhaarImageSide side) {
    switch (side) {
      case AadhaarImageSide.front:
        emit(state.copyWith(clearFrontFile: true));
        return;
      case AadhaarImageSide.back:
        emit(state.copyWith(clearBackFile: true));
        return;
    }
  }

  Future<void> submit() async {
    final aadhaar = state.aadhaarNumber.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      emit(
        state.copyWith(aadhaarError: 'Enter a valid 12-digit Aadhaar number.'),
      );
      return;
    }
    final frontPath = state.frontFilePath;
    if (frontPath == null || frontPath.trim().isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Please upload your Aadhaar front image.'),
      );
      return;
    }
    final backPath = state.backFilePath;
    if (backPath == null || backPath.trim().isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Please upload your Aadhaar back image.'),
      );
      return;
    }

    _log(
      'Aadhaar upload -> submit aadhaar=$aadhaar, front=$frontPath, back=$backPath',
    );
    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearResponse: true),
    );

    try {
      final response = await _repository.uploadAadhaar(
        frontFile: File(frontPath),
        backFile: File(backPath),
        aadhaarNumber: aadhaar,
      );
      _log('Aadhaar upload response <- ${response.toJson()}');
      emit(state.copyWith(isSubmitting: false, response: response));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      _log('Aadhaar upload error <- $msg');
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: msg.isEmpty ? 'Upload failed.' : msg,
        ),
      );
    }
  }

  void reset() {
    emit(AadhaarUploadState.initial());
  }
}
