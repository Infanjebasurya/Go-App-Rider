import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/file_picker_service.dart';
import 'package:goapp/core/service/image_picker_service.dart';
import 'package:goapp/features/documents/pan_upload/domain/repositories/pan_upload_repository.dart';
import 'package:goapp/features/documents/pan_upload/presentation/cubit/pan_upload_state.dart';

class PanUploadCubit extends Cubit<PanUploadState> {
  PanUploadCubit({
    required PanUploadRepository repository,
    required ImagePickerService imagePickerService,
    required FilePickerService filePickerService,
  }) : _repository = repository,
       _imagePickerService = imagePickerService,
       _filePickerService = filePickerService,
       super(PanUploadState.initial());

  final PanUploadRepository _repository;
  final ImagePickerService _imagePickerService;
  final FilePickerService _filePickerService;

  void _log(String message) {
    developer.log(message, name: 'PanUpload');
  }

  void updatePanNumber(String value) {
    emit(
      state.copyWith(
        panNumber: value.toUpperCase(),
        panError: null,
        clearError: true,
        clearResponse: true,
      ),
    );
  }

  Future<void> pickFromCamera() async {
    emit(state.copyWith(clearError: true, clearResponse: true));
    final picked = await _imagePickerService.pickImage(
      source: AppImageSource.camera,
      imageQuality: 95,
    );
    if (picked == null) return;
    emit(
      state.copyWith(
        filePath: picked.path,
        fileName: picked.name,
        clearPanError: true,
      ),
    );
  }

  Future<void> pickFromGallery() async {
    emit(state.copyWith(clearError: true, clearResponse: true));
    final picked = await _filePickerService.pickImage();
    if (picked == null) return;
    emit(
      state.copyWith(
        filePath: picked.path,
        fileName: picked.name,
        clearPanError: true,
      ),
    );
  }

  void removeFile() {
    emit(state.copyWith(clearFile: true));
  }

  Future<void> submit() async {
    final pan = state.panNumber.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      emit(state.copyWith(panError: 'Enter a valid PAN (e.g., ABCDE1234F).'));
      return;
    }
    final path = state.filePath;
    if (path == null || path.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Please upload your PAN card image.'));
      return;
    }

    _log('PAN upload -> submit pan=$pan, file=$path');
    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearResponse: true),
    );

    try {
      final response = await _repository.uploadPan(
        file: File(path),
        panNumber: pan,
      );
      _log('PAN upload response <- ${response.toJson()}');
      emit(state.copyWith(isSubmitting: false, response: response));
    } catch (e) {
      final msg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', '');
      _log('PAN upload error <- $msg');
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: msg.isEmpty ? 'Upload failed.' : msg,
        ),
      );
    }
  }

  void reset() {
    emit(PanUploadState.initial());
  }
}
