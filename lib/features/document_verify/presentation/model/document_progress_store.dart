import 'dart:async';
import 'dart:convert';

import 'package:goapp/core/storage/text_field_store.dart';

import 'document_model.dart';

class DocumentProgressStore {
  DocumentProgressStore._();
  static const String _storageKey = 'document_progress_store_v1';

  static final Map<DocumentType, bool> _completed = {
    DocumentType.drivingLicense: false,
    DocumentType.vehicleRC: false,
    DocumentType.aadhaarCard: false,
    DocumentType.panCard: false,
    DocumentType.bankDetails: false,
  };

  static final Map<DocumentType, String?> _frontImagePath = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _backImagePath = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _previousFrontImagePath = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _previousBackImagePath = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _documentNumber = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _documentId = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _expiryDate = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<DocumentType, String?> _previousDocumentNumber = {
    DocumentType.drivingLicense: null,
    DocumentType.vehicleRC: null,
    DocumentType.aadhaarCard: null,
    DocumentType.panCard: null,
    DocumentType.bankDetails: null,
  };

  static final Map<String, String> _bankDraft = <String, String>{
    'accountHolderName': '',
    'bankName': '',
    'accountNumber': '',
    'confirmAccountNumber': '',
    'ifscCode': '',
  };

  static String? _profileImagePath;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final raw = TextFieldStore.read(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _applyDecodedState(decoded);
        }
      } catch (_) {}
    }
    _initialized = true;
  }

  static void _applyDecodedState(Map<String, dynamic> json) {
    final completedRaw = json['completed'];
    if (completedRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = completedRaw[type.name];
        if (value is bool) _completed[type] = value;
      }
    }

    final frontRaw = json['frontImagePath'];
    if (frontRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = frontRaw[type.name];
        _frontImagePath[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final backRaw = json['backImagePath'];
    if (backRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = backRaw[type.name];
        _backImagePath[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final previousFrontRaw = json['previousFrontImagePath'];
    if (previousFrontRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = previousFrontRaw[type.name];
        _previousFrontImagePath[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final previousBackRaw = json['previousBackImagePath'];
    if (previousBackRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = previousBackRaw[type.name];
        _previousBackImagePath[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final numberRaw = json['documentNumber'];
    if (numberRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = numberRaw[type.name];
        _documentNumber[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final documentIdRaw = json['documentId'];
    if (documentIdRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = documentIdRaw[type.name];
        _documentId[type] = value is String && value.isNotEmpty ? value : null;
      }
    }

    final expiryRaw = json['expiryDate'];
    if (expiryRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = expiryRaw[type.name];
        _expiryDate[type] = value is String && value.isNotEmpty ? value : null;
      }
    }

    final previousNumberRaw = json['previousDocumentNumber'];
    if (previousNumberRaw is Map<String, dynamic>) {
      for (final type in DocumentType.values) {
        final value = previousNumberRaw[type.name];
        _previousDocumentNumber[type] = value is String && value.isNotEmpty
            ? value
            : null;
      }
    }

    final bankDraftRaw = json['bankDraft'];
    if (bankDraftRaw is Map<String, dynamic>) {
      for (final key in _bankDraft.keys) {
        final value = bankDraftRaw[key];
        _bankDraft[key] = value is String ? value : '';
      }
    }

    final profilePathRaw = json['profileImagePath'];
    _profileImagePath = profilePathRaw is String && profilePathRaw.isNotEmpty
        ? profilePathRaw
        : null;
  }

  static Map<String, dynamic> _toJson() {
    Map<String, dynamic> mapByType<T>(Map<DocumentType, T> source) {
      return source.map((key, value) => MapEntry(key.name, value));
    }

    return <String, dynamic>{
      'completed': mapByType(_completed),
      'frontImagePath': mapByType(_frontImagePath),
      'backImagePath': mapByType(_backImagePath),
      'previousFrontImagePath': mapByType(_previousFrontImagePath),
      'previousBackImagePath': mapByType(_previousBackImagePath),
      'documentNumber': mapByType(_documentNumber),
      'documentId': mapByType(_documentId),
      'expiryDate': mapByType(_expiryDate),
      'previousDocumentNumber': mapByType(_previousDocumentNumber),
      'bankDraft': Map<String, String>.from(_bankDraft),
      'profileImagePath': _profileImagePath,
    };
  }

  static void _persist() {
    unawaited(TextFieldStore.write(_storageKey, jsonEncode(_toJson())));
  }

  static bool isCompleted(DocumentType type) {
    return _completed[type] ?? false;
  }

  static void setCompleted(DocumentType type, bool completed) {
    _completed[type] = completed;
    _persist();
  }

  static String? frontImagePath(DocumentType type) {
    return _frontImagePath[type];
  }

  static String? backImagePath(DocumentType type) {
    return _backImagePath[type];
  }

  static String? previousFrontImagePath(DocumentType type) {
    return _previousFrontImagePath[type];
  }

  static String? previousBackImagePath(DocumentType type) {
    return _previousBackImagePath[type];
  }

  static void setFrontImagePath(DocumentType type, String? path) {
    _frontImagePath[type] = path;
    _persist();
  }

  static void setBackImagePath(DocumentType type, String? path) {
    _backImagePath[type] = path;
    _persist();
  }

  static void setPreviousFrontImagePath(DocumentType type, String? path) {
    _previousFrontImagePath[type] = path;
    _persist();
  }

  static void setPreviousBackImagePath(DocumentType type, String? path) {
    _previousBackImagePath[type] = path;
    _persist();
  }

  static String? documentNumber(DocumentType type) {
    return _documentNumber[type];
  }

  static String? documentId(DocumentType type) {
    return _documentId[type];
  }

  static String? expiryDate(DocumentType type) {
    return _expiryDate[type];
  }

  static String? previousDocumentNumber(DocumentType type) {
    return _previousDocumentNumber[type];
  }

  static void setDocumentNumber(DocumentType type, String? number) {
    _documentNumber[type] = number;
    _persist();
  }

  static void setDocumentId(DocumentType type, String? id) {
    _documentId[type] = id;
    _persist();
  }

  static void setExpiryDate(DocumentType type, String? value) {
    _expiryDate[type] = value;
    _persist();
  }

  static void setPreviousDocumentNumber(DocumentType type, String? number) {
    _previousDocumentNumber[type] = number;
    _persist();
  }

  static String bankDraftValue(String field) {
    return _bankDraft[field] ?? '';
  }

  static void setBankDraftValue(String field, String value) {
    _bankDraft[field] = value;
    _persist();
  }

  static void clearBankDraft() {
    _bankDraft.updateAll((_, _) => '');
    _persist();
  }

  static String? profileImagePath() {
    return _profileImagePath;
  }

  static bool isProfileImageUploaded() {
    return _profileImagePath != null && _profileImagePath!.trim().isNotEmpty;
  }

  static void setProfileImagePath(String? path) {
    _profileImagePath = path;
    _persist();
  }

  static void reset() {
    _completed.updateAll((_, _) => false);
    _frontImagePath.updateAll((_, _) => null);
    _backImagePath.updateAll((_, _) => null);
    _documentNumber.updateAll((_, _) => null);
    _documentId.updateAll((_, _) => null);
    _expiryDate.updateAll((_, _) => null);
    _previousFrontImagePath.updateAll((_, _) => null);
    _previousBackImagePath.updateAll((_, _) => null);
    _previousDocumentNumber.updateAll((_, _) => null);
    clearBankDraft();
    _profileImagePath = null;
    _persist();
  }
}
