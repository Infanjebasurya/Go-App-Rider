import 'dart:io';

import 'package:goapp/features/documents/pan_upload/data/models/pan_upload_response.dart';

abstract interface class PanUploadRepository {
  Future<PanUploadResponse> uploadPan({
    required File file,
    required String panNumber,
  });
}
