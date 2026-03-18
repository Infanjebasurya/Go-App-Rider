import 'dart:io';

import 'package:goapp/features/documents/pan_upload/data/models/pan_upload_response.dart';
import 'package:goapp/features/documents/pan_upload/data/services/pan_upload_service.dart';
import 'package:goapp/features/documents/pan_upload/domain/repositories/pan_upload_repository.dart';

class PanUploadRepositoryImpl implements PanUploadRepository {
  PanUploadRepositoryImpl({required PanUploadService service})
    : _service = service;

  final PanUploadService _service;

  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');

  @override
  Future<PanUploadResponse> uploadPan({
    required File file,
    required String panNumber,
  }) async {
    final normalized = panNumber.trim().toUpperCase();
    if (!_panRegex.hasMatch(normalized)) {
      throw FormatException('Enter a valid PAN (e.g., ABCDE1234F).');
    }
    if (!await file.exists()) {
      throw Exception('Selected file not found.');
    }
    return _service.uploadPan(file: file, panNumber: normalized);
  }
}
