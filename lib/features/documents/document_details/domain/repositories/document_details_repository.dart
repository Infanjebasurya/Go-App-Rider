import 'package:goapp/features/documents/document_details/presentation/model/document_card_model.dart';

abstract interface class DocumentDetailsRepository {
  Future<DocumentCardModel?> getAadhaarCard();
  Future<DocumentCardModel?> getPanCard();
}
