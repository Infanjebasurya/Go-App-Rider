import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';

import '../../../document_verify/presentation/model/document_progress_store.dart';
import '../../../document_verify/presentation/model/document_model.dart'
    show DocumentType;
import '../../data/datasources/documents_list_remote_data_source.dart';
import '../../data/models/documents_list_models.dart';
import '../model/document_model.dart';
import 'documents_state.dart';

class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit({DocumentsListRemoteDataSource? remoteDataSource})
    : _remoteDataSource =
          remoteDataSource ?? DocumentsListRemoteDataSourceImpl(),
      super(const DocumentsInitial()) {
    // Backward compatible: older registrations/hot-reload may still call
    // `DocumentsCubit()` with no arguments.
    loadDocuments();
  }

  final DocumentsListRemoteDataSource _remoteDataSource;

  static const String _bankAccountId = 'bank_account';

  static const List<DocumentModel> _defaultDocuments = [
    DocumentModel(
      id: 'driving_license',
      title: 'Driving License',
      subtitle: 'STANDARD CLASSA',
      iconAsset: 'driving_license',
      status: DocumentStatus.verified,
    ),
    DocumentModel(
      id: 'vehicle_rc',
      title: 'Vehicle RC',
      subtitle: 'REGISTRATION CARD',
      iconAsset: 'vehicle_rc',
      status: DocumentStatus.verified,
    ),
    DocumentModel(
      id: 'aadhaar_card',
      title: 'Aadhaar Card',
      subtitle: 'IDENTITY PROOF',
      iconAsset: 'aadhaar_card',
      status: DocumentStatus.verified,
    ),
    DocumentModel(
      id: 'pan_card',
      title: 'PAN Card',
      subtitle: 'TAX IDENTIFICATION',
      iconAsset: 'pan_card',
      status: DocumentStatus.verified,
    ),
    DocumentModel(
      id: _bankAccountId,
      title: 'Linked Bank Account',
      subtitle: 'BANK TRANSFER',
      iconAsset: _bankAccountId,
      status: DocumentStatus.verified,
    ),
  ];

  Future<void> loadDocuments() async {
    emit(const DocumentsLoading());
    try {
      final DocumentsListResponseModel response = await _remoteDataSource
          .fetchAll();
      final docs = _mapFromApi(response.documents);
      final allVerified = docs.every(
        (d) => d.status == DocumentStatus.verified,
      );
      emit(DocumentsLoaded(documents: docs, allVerified: allVerified));
    } catch (e) {
      emit(DocumentsError(e.toString().replaceFirst('Exception: ', '').trim()));
    }
  }

  void updateDocumentStatus(String id, DocumentStatus newStatus) {
    if (state is! DocumentsLoaded) return;
    final current = state as DocumentsLoaded;
    final updated = current.documents.map((doc) {
      if (doc.id == id) return doc.copyWith(status: newStatus);
      return doc;
    }).toList();
    final allVerified = updated.every(
      (d) => d.status == DocumentStatus.verified,
    );
    emit(DocumentsLoaded(documents: updated, allVerified: allVerified));
  }

  void refresh() => loadDocuments();

  List<DocumentModel> _mapFromApi(List<DocumentListItemModel> items) {
    final DocumentBundle dl = _bundleFor(
      items,
      frontType: 'license_front',
      backType: 'license_back',
    );
    final DocumentBundle rc = _bundleFor(
      items,
      frontType: 'rc_book_front',
      backType: 'rc_book_back',
    );
    final DocumentBundle aadhaar = _bundleFor(
      items,
      frontType: 'aadhar_front',
      backType: 'aadhar_back',
      altFrontType: 'aadhaar_front',
      altBackType: 'aadhaar_back',
    );
    final DocumentBundle pan = _bundleFor(
      items,
      frontType: 'pan_front',
      backType: null,
      altFrontType: 'pan',
    );

    _persistBundle(DocumentType.drivingLicense, dl);
    _persistBundle(DocumentType.vehicleRC, rc);
    _persistBundle(DocumentType.aadhaarCard, aadhaar);
    _persistBundle(DocumentType.panCard, pan);

    final List<DocumentModel> docs = _defaultDocuments.map((base) {
      switch (base.id) {
        case 'driving_license':
          if (dl.status == DocumentStatus.notUploaded) {
            return _applyProgress(base);
          }
          return base.copyWith(
            status: dl.status,
            frontImagePath: dl.frontUrl,
            backImagePath: dl.backUrl,
            documentNumber: dl.number,
          );
        case 'vehicle_rc':
          if (rc.status == DocumentStatus.notUploaded) {
            return _applyProgress(base);
          }
          return base.copyWith(
            status: rc.status,
            frontImagePath: rc.frontUrl,
            backImagePath: rc.backUrl,
            documentNumber: rc.number,
          );
        case 'aadhaar_card':
          if (aadhaar.status == DocumentStatus.notUploaded) {
            return _applyProgress(base);
          }
          return base.copyWith(
            status: aadhaar.status,
            frontImagePath: aadhaar.frontUrl,
            backImagePath: aadhaar.backUrl,
            documentNumber: aadhaar.number,
          );
        case 'pan_card':
          if (pan.status == DocumentStatus.notUploaded) {
            return _applyProgress(base);
          }
          return base.copyWith(
            status: pan.status,
            frontImagePath: pan.frontUrl,
            backImagePath: pan.backUrl,
            documentNumber: pan.number,
          );
        case _bankAccountId:
          return _applyProgress(base);
        default:
          return base;
      }
    }).toList();

    if (!docs.any((d) => d.id == _bankAccountId)) {
      docs.add(
        DocumentModel(
          id: _bankAccountId,
          title: 'Link Bank Account',
          subtitle: 'BANK TRANSFER',
          iconAsset: _bankAccountId,
          status: DocumentStatus.notUploaded,
        ),
      );
    }

    // Show rejection reason (if any) for Aadhaar card using existing subtitle slot.
    if (aadhaar.rejectionReason != null &&
        aadhaar.rejectionReason!.trim().isNotEmpty) {
      final idx = docs.indexWhere((d) => d.id == 'aadhaar_card');
      if (idx >= 0 && docs[idx].status == DocumentStatus.rejected) {
        final current = docs[idx];
        docs[idx] = DocumentModel(
          id: current.id,
          title: current.title,
          subtitle: aadhaar.rejectionReason!.trim(),
          iconAsset: current.iconAsset,
          status: current.status,
          frontImagePath: current.frontImagePath,
          backImagePath: current.backImagePath,
          documentNumber: current.documentNumber,
        );
      }
    }

    return docs;
  }

  void _persistBundle(DocumentType type, DocumentBundle bundle) {
    if (bundle.frontUrl != null && bundle.frontUrl!.trim().isNotEmpty) {
      final String? existing = DocumentProgressStore.frontImagePath(type);
      if (_shouldOverwriteImagePath(existing, bundle.frontUrl)) {
        DocumentProgressStore.setFrontImagePath(type, bundle.frontUrl);
      }
    }
    if (bundle.backUrl != null && bundle.backUrl!.trim().isNotEmpty) {
      final String? existing = DocumentProgressStore.backImagePath(type);
      if (_shouldOverwriteImagePath(existing, bundle.backUrl)) {
        DocumentProgressStore.setBackImagePath(type, bundle.backUrl);
      }
    }
    if (bundle.number != null && bundle.number!.trim().isNotEmpty) {
      DocumentProgressStore.setDocumentNumber(type, bundle.number);
    }
    final bool hasRequired =
        (bundle.frontUrl?.trim().isNotEmpty ?? false) &&
        ((bundle.backUrl == null) || (bundle.backUrl!.trim().isNotEmpty)) &&
        (bundle.number?.trim().isNotEmpty ?? false);
    if (hasRequired) {
      DocumentProgressStore.setCompleted(type, true);
    }
  }

  bool _shouldOverwriteImagePath(String? existing, String? incoming) {
    final String e = (existing ?? '').trim();
    final String i = (incoming ?? '').trim();
    if (i.isEmpty) return false;
    if (e.isEmpty) return true;

    // Preserve local, recently captured images (like PAN) so UI reflects instantly.
    // Overwrite only when existing looks like a backend URL/path already.
    final String el = e.toLowerCase();
    final bool existingIsNetwork =
        el.startsWith('http://') || el.startsWith('https://');
    final bool existingIsBackendPath =
        el.startsWith('/api/') || el.contains('/api/v1/');
    return existingIsNetwork || existingIsBackendPath;
  }

  DocumentBundle _bundleFor(
    List<DocumentListItemModel> items, {
    required String frontType,
    required String? backType,
    String? altFrontType,
    String? altBackType,
  }) {
    DocumentListItemModel? front;
    DocumentListItemModel? back;
    for (final item in items) {
      final String t = (item.documentType ?? '').trim().toLowerCase();
      final bool isFrontMatch =
          t == frontType ||
          (altFrontType != null && t == altFrontType) ||
          (frontType == 'pan_front' && (t == 'pan' || t == 'pan_card')) ||
          (frontType == 'license_front' &&
              (t == 'license' ||
                  t == 'driving_license' ||
                  t == 'driving_license_front')) ||
          (frontType == 'rc_book_front' &&
              (t == 'rc_book' ||
                  t == 'vehicle_rc' ||
                  t == 'vehicle_rc_front' ||
                  t == 'rc_front')) ||
          (frontType == 'aadhar_front' &&
              (t == 'aadhar' ||
                  t == 'aadhaar' ||
                  t == 'aadhar_front' ||
                  t == 'aadhaar_front'));

      if (isFrontMatch) {
        front ??= item;
      }

      final bool isBackMatch =
          backType != null &&
          (t == backType ||
              (altBackType != null && t == altBackType) ||
              (backType == 'license_back' && t == 'driving_license_back') ||
              (backType == 'rc_book_back' &&
                  (t == 'vehicle_rc_back' || t == 'rc_back')) ||
              (backType == 'aadhar_back' &&
                  (t == 'aadhaar_back' || t == 'aadhar_back')));
      if (isBackMatch) {
        back ??= item;
      }
    }

    final String? number = (front?.documentNumber ?? back?.documentNumber)
        ?.toString();

    final String? statusRaw =
        (front?.verificationStatus ?? back?.verificationStatus)?.toString();
    final bool hasAny = front != null || back != null;
    final bool hasFront = front?.documentUrl?.trim().isNotEmpty ?? false;
    final bool hasBack = backType == null
        ? true
        : (back?.documentUrl?.trim().isNotEmpty ?? false);

    // Latest UX requirement: once uploaded, reflect as VERIFIED (unless rejected).
    final DocumentStatus status = (!hasAny || !hasFront || !hasBack)
        ? DocumentStatus.notUploaded
        : _statusFromApi(statusRaw);

    return DocumentBundle(
      frontUrl: _resolveUrl(front?.documentUrl),
      backUrl: _resolveUrl(back?.documentUrl),
      number: number?.trim().isEmpty ?? true ? null : number!.trim(),
      status: status,
      rejectionReason: (front?.rejectionReason ?? back?.rejectionReason)
          ?.toString(),
    );
  }

  String? _resolveUrl(String? raw) {
    final String v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return ApiConfig.resolve(v).toString();
  }

  DocumentStatus _statusFromApi(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.verified;
    }
  }

  DocumentModel _applyProgress(DocumentModel doc) {
    switch (doc.id) {
      case 'driving_license':
        final completed = DocumentProgressStore.isCompleted(
          DocumentType.drivingLicense,
        );
        return _withProgress(
          doc,
          DocumentProgressStore.frontImagePath(DocumentType.drivingLicense),
          DocumentProgressStore.backImagePath(DocumentType.drivingLicense),
          DocumentProgressStore.documentNumber(DocumentType.drivingLicense),
          completed: completed,
        );
      case 'vehicle_rc':
        final completed = DocumentProgressStore.isCompleted(
          DocumentType.vehicleRC,
        );
        return _withProgress(
          doc,
          DocumentProgressStore.frontImagePath(DocumentType.vehicleRC),
          DocumentProgressStore.backImagePath(DocumentType.vehicleRC),
          DocumentProgressStore.documentNumber(DocumentType.vehicleRC),
          completed: completed,
        );
      case 'aadhaar_card':
        final completed = DocumentProgressStore.isCompleted(
          DocumentType.aadhaarCard,
        );
        return _withProgress(
          doc,
          DocumentProgressStore.frontImagePath(DocumentType.aadhaarCard),
          DocumentProgressStore.backImagePath(DocumentType.aadhaarCard),
          DocumentProgressStore.documentNumber(DocumentType.aadhaarCard),
          completed: completed,
        );
      case 'pan_card':
        final completed = DocumentProgressStore.isCompleted(
          DocumentType.panCard,
        );
        return _withProgress(
          doc,
          DocumentProgressStore.frontImagePath(DocumentType.panCard),
          DocumentProgressStore.backImagePath(DocumentType.panCard),
          DocumentProgressStore.documentNumber(DocumentType.panCard),
          completed: completed,
        );
      case _bankAccountId:
        final accountNumber = DocumentProgressStore.bankDraftValue(
          'accountNumber',
        );
        final bankDocPath = DocumentProgressStore.frontImagePath(
          DocumentType.bankDetails,
        );
        final completed = DocumentProgressStore.isCompleted(
          DocumentType.bankDetails,
        );
        final status = completed
            ? DocumentStatus.verified
            : DocumentStatus.notUploaded;
        return DocumentModel(
          id: doc.id,
          title: completed ? 'Linked Bank Account' : 'Link Bank Account',
          subtitle: doc.subtitle,
          iconAsset: doc.iconAsset,
          status: status,
          frontImagePath: bankDocPath?.trim().isEmpty ?? true
              ? null
              : bankDocPath,
          documentNumber: accountNumber.trim().isEmpty ? null : accountNumber,
        );
      default:
        return doc;
    }
  }

  DocumentModel _withProgress(
    DocumentModel doc,
    String? frontPath,
    String? backPath,
    String? number, {
    required bool completed,
  }) {
    final hasImages =
        (frontPath?.isNotEmpty ?? false) && (backPath?.isNotEmpty ?? false);
    final status = (completed || hasImages)
        ? DocumentStatus.verified
        : DocumentStatus.notUploaded;
    return doc.copyWith(
      status: status,
      frontImagePath: frontPath,
      backImagePath: backPath,
      documentNumber: number?.trim().isEmpty ?? true ? null : number,
    );
  }
}

class DocumentBundle {
  const DocumentBundle({
    required this.status,
    this.frontUrl,
    this.backUrl,
    this.number,
    this.rejectionReason,
  });

  final DocumentStatus status;
  final String? frontUrl;
  final String? backUrl;
  final String? number;
  final String? rejectionReason;
}
