import 'package:goapp/features/documents/document_status/data/models/document_status_model.dart';
import 'package:goapp/features/documents/document_status/data/services/document_status_service.dart';
import 'package:goapp/features/documents/document_status/domain/repositories/document_status_repository.dart';
import 'package:goapp/features/documents/document_status/presentation/model/document_status_item_model.dart';

class DocumentStatusRepositoryImpl implements DocumentStatusRepository {
  DocumentStatusRepositoryImpl({required DocumentStatusService service})
    : _service = service;

  final DocumentStatusService _service;

  @override
  Future<DocumentStatusSummary> getSummary() async {
    final DocumentStatusModel raw = await _service.getDocumentStatus();

    final items = <DocumentStatusItemModel>[
      DocumentStatusItemModel(
        type: DocumentStatusItemType.profilePhoto,
        title: 'Profile Photo',
        status: _normalize(raw.profileImageStatus),
      ),
      DocumentStatusItemModel(
        type: DocumentStatusItemType.dl,
        title: 'Driving License',
        status: _normalize(raw.dlStatus),
      ),
      DocumentStatusItemModel(
        type: DocumentStatusItemType.rc,
        title: 'RC Book',
        status: _normalize(raw.rcStatus),
      ),
      DocumentStatusItemModel(
        type: DocumentStatusItemType.aadhaar,
        title: 'Aadhaar',
        status: _normalize(raw.aadhaarStatus),
      ),
      DocumentStatusItemModel(
        type: DocumentStatusItemType.pan,
        title: 'PAN',
        status: _normalize(raw.panStatus),
      ),
    ];

    final int verifiedCount = items.where((e) => e.status == 'verified').length;
    return DocumentStatusSummary(
      items: items,
      verifiedCount: verifiedCount,
      totalCount: items.length,
    );
  }

  String _normalize(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'verified' || v == 'approved') return 'verified';
    if (v == 'rejected' || v == 'failed') return 'rejected';
    return 'pending';
  }
}
