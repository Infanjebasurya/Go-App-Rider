import 'package:goapp/features/documents/document_status/presentation/model/document_status_item_model.dart';

class DocumentStatusSummary {
  const DocumentStatusSummary({
    required this.items,
    required this.verifiedCount,
    required this.totalCount,
  });

  final List<DocumentStatusItemModel> items;
  final int verifiedCount;
  final int totalCount;
}

abstract interface class DocumentStatusRepository {
  Future<DocumentStatusSummary> getSummary();
}
