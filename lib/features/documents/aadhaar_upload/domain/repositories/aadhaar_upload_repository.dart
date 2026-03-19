import 'dart:io';

import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';

abstract interface class AadhaarUploadRepository {
  Future<AadhaarUploadResponse> uploadAadhaar({
    required File frontFile,
    required File backFile,
    required String aadhaarNumber,
  });
}
