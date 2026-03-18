import 'dart:io';

import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/services/aadhaar_upload_service.dart';
import 'package:goapp/features/documents/aadhaar_upload/domain/repositories/aadhaar_upload_repository.dart';

class AadhaarUploadRepositoryImpl implements AadhaarUploadRepository {
  AadhaarUploadRepositoryImpl({required AadhaarUploadService service})
    : _service = service;

  final AadhaarUploadService _service;

  static final RegExp _aadhaarRegex = RegExp(r'^\d{12}$');

  @override
  Future<DocumentUploadResponse> uploadAadhaar({
    required File file,
    required String aadhaarNumber,
  }) async {
    final normalized = aadhaarNumber.trim();
    if (!_aadhaarRegex.hasMatch(normalized)) {
      throw FormatException('Aadhaar number must be 12 digits.');
    }
    if (!await file.exists()) {
      throw Exception('Selected file not found.');
    }
    return _service.uploadAadhaar(file: file, aadhaarNumber: normalized);
  }
}

