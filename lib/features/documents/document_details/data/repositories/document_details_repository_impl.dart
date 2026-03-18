import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/features/documents/document_details/data/models/document_model.dart';
import 'package:goapp/features/documents/document_details/data/services/document_details_service.dart';
import 'package:goapp/features/documents/document_details/domain/repositories/document_details_repository.dart';
import 'package:goapp/features/documents/document_details/presentation/model/document_card_model.dart';

class DocumentDetailsRepositoryImpl implements DocumentDetailsRepository {
  DocumentDetailsRepositoryImpl({required DocumentDetailsService service})
    : _service = service;

  final DocumentDetailsService _service;

  @override
  Future<DocumentCardModel?> getAadhaarCard() async {
    final doc = await _service.getAadhaar();
    if (!doc.isActive) return null;
    return _toCard(doc, type: _DocType.aadhaar);
  }

  @override
  Future<DocumentCardModel?> getPanCard() async {
    final doc = await _service.getPan();
    if (!doc.isActive) return null;
    return _toCard(doc, type: _DocType.pan);
  }

  DocumentCardModel _toCard(DocumentModel doc, {required _DocType type}) {
    final String title = switch (type) {
      _DocType.aadhaar => 'Aadhaar',
      _DocType.pan => 'PAN',
    };

    final String masked = switch (type) {
      _DocType.aadhaar => _maskAadhaar(doc),
      _DocType.pan => _maskPan(doc),
    };

    final String status = doc.verificationStatus.trim().toLowerCase().isEmpty
        ? 'pending'
        : doc.verificationStatus.trim().toLowerCase();

    final String imageUrl = _resolveUrl(doc.documentUrl);
    final String uploadedDate = _formatDate(doc.uploadedAt.toLocal());

    return DocumentCardModel(
      title: title,
      numberMasked: masked,
      status: status,
      imageUrl: imageUrl,
      uploadedDate: uploadedDate,
    );
  }

  String _maskAadhaar(DocumentModel doc) {
    final String digits = (doc.documentNumber).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    String last4 = (doc.aadhaarLast4 ?? '').trim();
    if (last4.isEmpty && digits.length >= 4) {
      last4 = digits.substring(digits.length - 4);
    }
    if (last4.length != 4) return '**** **** ****';
    return '**** **** $last4';
  }

  String _maskPan(DocumentModel doc) {
    final String pan = (doc.panNumber ?? doc.documentNumber)
        .trim()
        .toUpperCase();
    if (pan.length != 10) return '**********';
    final String first5 = pan.substring(0, 5);
    final String last1 = pan.substring(9);
    return '$first5****$last1';
  }

  String _resolveUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) return trimmed;
    return ApiConfig.resolve(trimmed).toString();
  }

  String _formatDate(DateTime dt) {
    final months = const <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (dt.year <= 1970) return '';
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    return '${dt.day.toString().padLeft(2, '0')} $m ${dt.year}';
  }
}

enum _DocType { aadhaar, pan }
