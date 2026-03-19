import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/features/document_verify/presentation/model/document_model.dart'
    show DocumentType;
import 'package:goapp/features/document_verify/presentation/model/document_progress_store.dart';
import 'package:goapp/features/documents/presentation/model/document_model.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/documents/presentation/pages/driving_license_upload_screen.dart';
import 'package:goapp/features/documents/presentation/pages/vehicle_rc_upload_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isEmpty = false;

  bool get _isDrivingLicense => widget.document.iconAsset == 'driving_license';
  bool get _isVehicleRc => widget.document.iconAsset == 'vehicle_rc';

  @override
  void initState() {
    super.initState();
    // Static (local) reflection: show whatever user uploaded immediately,
    // without depending on the details GET APIs.
    if (_isDrivingLicense) {
      _isEmpty = !_hasLocalOrUploaded(DocumentType.drivingLicense);
    } else if (_isVehicleRc) {
      _isEmpty = !_hasLocalOrUploaded(DocumentType.vehicleRC);
    }
  }

  bool _hasLocalOrUploaded(DocumentType type) {
    final String front = (DocumentProgressStore.frontImagePath(type) ?? '')
        .trim();
    final String back = (DocumentProgressStore.backImagePath(type) ?? '')
        .trim();
    final String number = (DocumentProgressStore.documentNumber(type) ?? '')
        .trim();
    return front.isNotEmpty && back.isNotEmpty && number.isNotEmpty;
  }

  String _resolveDocumentUrl(String rawUrl) {
    final String trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return ApiConfig.resolve(trimmed).toString();
  }

  @override
  Widget build(BuildContext context) {
    final isVehicleRc = widget.document.iconAsset == 'vehicle_rc';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildBody(context),
            ),
          ),
          if (isVehicleRc && !_isEmpty) const _VehicleRcBottomPrompt(),
          if (isVehicleRc && !_isEmpty)
            _VehicleRcEditButton(onPressed: _editVehicleRc),
          if (!isVehicleRc) _EncryptionFooter(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(widget.document.title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.strokeLight, height: 1),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isDrivingLicense || _isVehicleRc) {
      if (_isEmpty) {
        return _EmptyState(
          title: _isDrivingLicense
              ? 'No Driving License Uploaded'
              : 'No Vehicle RC Uploaded',
          buttonLabel: _isDrivingLicense
              ? 'Upload Driving License'
              : 'Upload RC',
          onUpload: _isDrivingLicense ? _uploadDrivingLicense : _editVehicleRc,
        );
      }
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final frontImagePath = _resolvedFrontImagePath();
    final backImagePath = _resolvedBackImagePath();
    final documentNumber = _resolvedDocumentNumber();
    switch (widget.document.iconAsset) {
      case 'driving_license':
        final String? preferredFront = _displayPath(frontImagePath);
        final String? preferredBack = _displayPath(backImagePath);
        return _DrivingLicenseDetail(
          frontImagePath: preferredFront,
          backImagePath: preferredBack,
          licenseNumber: documentNumber,
        );
      case 'vehicle_rc':
        final String? preferredFront = _displayPath(frontImagePath);
        final String? preferredBack = _displayPath(backImagePath);
        final oldFront = DocumentProgressStore.previousFrontImagePath(
          DocumentType.vehicleRC,
        );
        final oldBack = DocumentProgressStore.previousBackImagePath(
          DocumentType.vehicleRC,
        );
        final oldNumber = DocumentProgressStore.previousDocumentNumber(
          DocumentType.vehicleRC,
        );
        final hasOld =
            (oldFront != null && oldFront.trim().isNotEmpty) ||
            (oldBack != null && oldBack.trim().isNotEmpty) ||
            (oldNumber != null && oldNumber.trim().isNotEmpty);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VehicleRCDetail(
              frontImagePath: preferredFront,
              backImagePath: preferredBack,
              vehicleNumber: documentNumber,
              headerText: 'NEW RC',
              statusText: null,
              uploadedAtText: null,
            ),
            if (hasOld) ...[
              const SizedBox(height: 22),
              _VehicleRCDetail(
                headerText: 'OLD RC',
                frontImagePath: oldFront,
                backImagePath: oldBack,
                vehicleNumber: oldNumber,
              ),
            ],
          ],
        );
      case 'aadhaar_card':
        return _AadhaarCardDetail(
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
          aadhaarNumber: documentNumber,
        );
      case 'pan_card':
        return _PanCardDetail(
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
          panNumber: documentNumber,
        );
      case 'bank_account':
      case 'add bank account':
        return _BankAccountDetail(frontImagePath: frontImagePath);
      default:
        return _DrivingLicenseDetail(
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
        );
    }
  }

  String? _displayPath(String? raw) {
    final String v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    // Backend paths we want to turn into a full URL.
    final String lower = v.toLowerCase();
    final bool looksLikeBackendPath =
        lower.startsWith('/api/') ||
        lower.startsWith('api/') ||
        lower.startsWith('/v1/') ||
        lower.startsWith('v1/') ||
        lower.contains('/api/v1/');

    if (looksLikeBackendPath) {
      return _resolveDocumentUrl(v.startsWith('/') ? v : '/$v');
    }

    // Local file paths on Android are absolute and start with `/` (e.g. `/storage/...`).
    // Keep them untouched so `Image.file` renders (same behavior as PAN page).
    return v;
  }

  DocumentType? _documentTypeFromAsset() {
    switch (widget.document.iconAsset) {
      case 'driving_license':
        return DocumentType.drivingLicense;
      case 'vehicle_rc':
        return DocumentType.vehicleRC;
      case 'aadhaar_card':
        return DocumentType.aadhaarCard;
      case 'pan_card':
        return DocumentType.panCard;
      case 'bank_account':
      case 'add bank account':
        return DocumentType.bankDetails;
      default:
        return null;
    }
  }

  String? _resolvedFrontImagePath() {
    final type = _documentTypeFromAsset();
    final latest = type == null
        ? null
        : DocumentProgressStore.frontImagePath(type);
    if (latest != null && latest.trim().isNotEmpty) return latest;
    return widget.document.frontImagePath;
  }

  String? _resolvedBackImagePath() {
    final type = _documentTypeFromAsset();
    final latest = type == null
        ? null
        : DocumentProgressStore.backImagePath(type);
    if (latest != null && latest.trim().isNotEmpty) return latest;
    return widget.document.backImagePath;
  }

  String? _resolvedDocumentNumber() {
    final type = _documentTypeFromAsset();
    final latest = type == null
        ? null
        : DocumentProgressStore.documentNumber(type);
    if (latest != null && latest.trim().isNotEmpty) return latest;
    return widget.document.documentNumber;
  }

  Future<void> _editVehicleRc() async {
    final previousCompleted = DocumentProgressStore.isCompleted(
      DocumentType.vehicleRC,
    );
    final previousFront = DocumentProgressStore.frontImagePath(
      DocumentType.vehicleRC,
    );
    final previousBack = DocumentProgressStore.backImagePath(
      DocumentType.vehicleRC,
    );
    final previousNumber = DocumentProgressStore.documentNumber(
      DocumentType.vehicleRC,
    );

    final resolvedFront = _resolvedFrontImagePath();
    final resolvedBack = _resolvedBackImagePath();
    final resolvedNumber = _resolvedDocumentNumber();

    DocumentProgressStore.setCompleted(DocumentType.vehicleRC, false);
    DocumentProgressStore.setFrontImagePath(DocumentType.vehicleRC, null);
    DocumentProgressStore.setBackImagePath(DocumentType.vehicleRC, null);
    DocumentProgressStore.setDocumentNumber(DocumentType.vehicleRC, null);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const VehicleRcUploadScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      final hasOld =
          (resolvedFront != null && resolvedFront.trim().isNotEmpty) ||
          (resolvedBack != null && resolvedBack.trim().isNotEmpty) ||
          (resolvedNumber != null && resolvedNumber.trim().isNotEmpty);
      if (hasOld) {
        DocumentProgressStore.setPreviousFrontImagePath(
          DocumentType.vehicleRC,
          resolvedFront,
        );
        DocumentProgressStore.setPreviousBackImagePath(
          DocumentType.vehicleRC,
          resolvedBack,
        );
        DocumentProgressStore.setPreviousDocumentNumber(
          DocumentType.vehicleRC,
          resolvedNumber,
        );
      } else {
        DocumentProgressStore.setPreviousFrontImagePath(
          DocumentType.vehicleRC,
          null,
        );
        DocumentProgressStore.setPreviousBackImagePath(
          DocumentType.vehicleRC,
          null,
        );
        DocumentProgressStore.setPreviousDocumentNumber(
          DocumentType.vehicleRC,
          null,
        );
      }
    } else {
      DocumentProgressStore.setCompleted(
        DocumentType.vehicleRC,
        previousCompleted,
      );
      DocumentProgressStore.setFrontImagePath(
        DocumentType.vehicleRC,
        previousFront,
      );
      DocumentProgressStore.setBackImagePath(
        DocumentType.vehicleRC,
        previousBack,
      );
      DocumentProgressStore.setDocumentNumber(
        DocumentType.vehicleRC,
        previousNumber,
      );
    }
    setState(() {
      _isEmpty = !_hasLocalOrUploaded(DocumentType.vehicleRC);
    });
  }

  Future<void> _uploadDrivingLicense() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const DrivingLicenseUploadScreen(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isEmpty = !_hasLocalOrUploaded(DocumentType.drivingLicense);
    });
  }
}

class _DrivingLicenseDetail extends StatelessWidget {
  final String? frontImagePath;
  final String? backImagePath;
  final String? licenseNumber;

  const _DrivingLicenseDetail({
    this.frontImagePath,
    this.backImagePath,
    this.licenseNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBack =
        backImagePath != null && backImagePath!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubHeader(text: 'Government of India • Digital Copy'),
        const SizedBox(height: 16),
        if (hasBack)
          Row(
            children: [
              Expanded(
                child: _CardImageBox(
                  label: 'FRONT VIEW',
                  color: AppColors.hexFF8A9BAE,
                  imagePath: frontImagePath,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardImageBox(
                  label: 'BACK VIEW',
                  color: AppColors.hexFF2C3A4A,
                  imagePath: backImagePath,
                ),
              ),
            ],
          )
        else
          _CardImageBox(
            label: 'DRIVING LICENSE',
            color: AppColors.hexFF8A9BAE,
            fullWidth: true,
            preserveOriginalAspect: true,
            imagePath: frontImagePath,
          ),
        const SizedBox(height: 20),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'LICENSE NUMBER',
              value: licenseNumber?.isNotEmpty == true ? licenseNumber! : '—',
              valueLarge: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _VehicleRCDetail extends StatelessWidget {
  final String headerText;
  final String? frontImagePath;
  final String? backImagePath;
  final String? vehicleNumber;
  final String? uploadedAtText;
  final String? statusText;

  const _VehicleRCDetail({
    this.headerText = 'Registration Document',
    this.frontImagePath,
    this.backImagePath,
    this.vehicleNumber,
    this.uploadedAtText,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBack =
        backImagePath != null && backImagePath!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubHeader(text: headerText),
        const SizedBox(height: 16),
        if (hasBack)
          Row(
            children: [
              Expanded(
                child: _CardImageBox(
                  label: 'FRONT VIEW',
                  color: AppColors.hexFF8A9BAE,
                  imagePath: frontImagePath,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardImageBox(
                  label: 'BACK VIEW',
                  color: AppColors.hexFF2C3A4A,
                  imagePath: backImagePath,
                ),
              ),
            ],
          )
        else
          _CardImageBox(
            label: 'VEHICLE RC',
            color: AppColors.hexFF8A9BAE,
            fullWidth: true,
            preserveOriginalAspect: true,
            imagePath: frontImagePath,
          ),
        const SizedBox(height: 20),
        _InfoCard(
          children: [
            _InfoRow(
              label: 'VEHICLE NUMBER',
              value: vehicleNumber?.isNotEmpty == true ? vehicleNumber! : '—',
              valueLarge: true,
            ),
            if (statusText != null && statusText!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'STATUS', value: statusText!),
            ],
            if (uploadedAtText != null &&
                uploadedAtText!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _InfoRow(label: 'UPLOADED', value: uploadedAtText!),
            ],
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.buttonLabel,
    required this.onUpload,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 46,
              color: AppColors.neutralAAA,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.headingDark,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AadhaarCardDetail extends StatefulWidget {
  final String? frontImagePath;
  final String? backImagePath;
  final String? aadhaarNumber;

  const _AadhaarCardDetail({
    this.frontImagePath,
    this.backImagePath,
    this.aadhaarNumber,
  });

  @override
  State<_AadhaarCardDetail> createState() => _AadhaarCardDetailState();
}

class _AadhaarCardDetailState extends State<_AadhaarCardDetail> {
  bool _masked = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardImageBox(
          label: 'FRONT VIEW',
          color: AppColors.hexFF9EC8B0,
          showVerified: true,
          fullWidth: true,
          preserveOriginalAspect: true,
          imagePath: widget.frontImagePath,
        ),
        const SizedBox(height: 14),
        _CardImageBox(
          label: 'BACK VIEW',
          color: AppColors.hexFFA8C4B8,
          showVerified: true,
          fullWidth: true,
          preserveOriginalAspect: true,
          imagePath: widget.backImagePath,
        ),
        const SizedBox(height: 20),
        _VerifiedSection(
          children: [
            const Text(
              'Aadhaar Number:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.neutral888,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _masked
                      ? _maskLast4(widget.aadhaarNumber) ?? '—'
                      : (widget.aadhaarNumber?.isNotEmpty == true
                            ? widget.aadhaarNumber!
                            : '—'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingDark,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _masked = !_masked),
                  child: Icon(
                    _masked
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.neutral888,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String? _maskLast4(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 4) return trimmed;
    final last4 = trimmed.substring(trimmed.length - 4);
    return '****$last4';
  }
}

class _PanCardDetail extends StatefulWidget {
  final String? frontImagePath;
  final String? backImagePath;
  final String? panNumber;

  const _PanCardDetail({
    this.frontImagePath,
    this.backImagePath,
    this.panNumber,
  });

  @override
  State<_PanCardDetail> createState() => _PanCardDetailState();
}

class _PanCardDetailState extends State<_PanCardDetail> {
  bool _masked = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardImageBox(
          label: 'FRONT VIEW',
          color: AppColors.hexFF7FB5C8,
          showVerified: true,
          fullWidth: true,
          preserveOriginalAspect: true,
          imagePath: widget.frontImagePath,
        ),
        const SizedBox(height: 20),
        _VerifiedSection(
          children: [
            const Text(
              'Pan Number:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral888,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _masked
                      ? _maskLast4(widget.panNumber) ?? '—'
                      : (widget.panNumber?.isNotEmpty == true
                            ? widget.panNumber!
                            : '—'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingDark,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _masked = !_masked),
                  child: Icon(
                    _masked
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.neutral888,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This PAN card has been successfully verified with the issuing authority and linked to your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutralAAA,
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _maskLast4(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 4) return trimmed;
    final last4 = trimmed.substring(trimmed.length - 4);
    return '****$last4';
  }
}

class _BankAccountDetail extends StatelessWidget {
  final String? frontImagePath;

  const _BankAccountDetail({this.frontImagePath});

  @override
  Widget build(BuildContext context) {
    final name = _readDraft('accountHolderName');
    final ifsc = _readDraft('ifscCode');
    final account = _maskAccount(_readDraft('accountNumber'));
    final bankName = _readDraft('bankName');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _CardImageBox(
          label: 'BANK DOCUMENT',
          color: AppColors.hexFF8A9BAE,
          fullWidth: true,
          imagePath: frontImagePath,
        ),
        const SizedBox(height: 16),
        _LinkedBankSection(
          children: [
            const SizedBox(height: 12),
            _InfoField(label: 'ACCOUNT HOLDER', value: name ?? '—'),
            const SizedBox(height: 16),
            _InfoField(label: 'BANK NAME', value: bankName ?? '—'),
            const SizedBox(height: 16),
            _InfoField(label: 'IFSC CODE', value: ifsc ?? '—'),
            const SizedBox(height: 16),
            _InfoField(label: 'ACCOUNT NUMBER', value: account ?? '—'),
          ],
        ),
      ],
    );
  }

  String? _readDraft(String field) {
    final raw = DocumentProgressStore.bankDraftValue(field);
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _maskAccount(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length <= 4) return value;
    final last4 = value.substring(value.length - 4);
    return '****$last4';
  }
}

class _SubHeader extends StatelessWidget {
  final String text;

  const _SubHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.neutral888,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _CardImageBox extends StatelessWidget {
  final String label;
  final Color color;
  final bool showVerified;
  final bool fullWidth;
  final bool preserveOriginalAspect;
  final String? imagePath;

  const _CardImageBox({
    required this.label,
    required this.color,
    this.showVerified = false,
    this.fullWidth = false,
    this.preserveOriginalAspect = false,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral888,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            _ImageBox(
              imagePath: imagePath,
              color: color,
              fullWidth: fullWidth,
              preserveOriginalAspect: preserveOriginalAspect,
            ),
            if (showVerified)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.verifiedMint,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.verifiedMint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String? imagePath;
  final Color color;
  final bool fullWidth;
  final bool preserveOriginalAspect;

  const _ImageBox({
    required this.imagePath,
    required this.color,
    required this.fullWidth,
    required this.preserveOriginalAspect,
  });

  @override
  Widget build(BuildContext context) {
    final width = fullWidth ? double.infinity : null;
    final height = fullWidth ? 160.0 : 90.0;
    final isDocument = _isDocumentPath(imagePath);
    final isNetwork = _isNetworkUrl(imagePath);
    final headers = _authHeaders();
    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            Icons.credit_card,
            color: AppColors.white.withValues(alpha: 0.3),
            size: 36,
          ),
        ),
      );
    }
    if (isDocument) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_rounded,
                color: AppColors.white,
                size: 36,
              ),
              const SizedBox(height: 6),
              Text(
                _basename(imagePath),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isNetwork) {
      if (preserveOriginalAspect) {
        return AspectRatio(
          aspectRatio: 1.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: color.withValues(alpha: 0.16),
              child: Image.network(
                imagePath!,
                width: width,
                fit: BoxFit.contain,
                headers: headers,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => _imageFallback(width, height),
              ),
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imagePath!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          headers: headers,
          errorBuilder: (_, _, _) => _imageFallback(width, height),
        ),
      );
    }

    if (preserveOriginalAspect) {
      return FutureBuilder<double>(
        future: _readAspectRatio(imagePath!),
        builder: (context, snapshot) {
          final aspectRatio = snapshot.data ?? 1.58;
          return AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: color.withValues(alpha: 0.16),
                child: Image.file(
                  File(imagePath!),
                  width: width,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => _imageFallback(width, height),
                ),
              ),
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(imagePath!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(width, height),
      ),
    );
  }

  Widget _imageFallback(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.credit_card,
          color: Colors.white.withValues(alpha: 0.3),
          size: 36,
        ),
      ),
    );
  }

  Future<double> _readAspectRatio(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ratio = image.height == 0 ? 1.58 : image.width / image.height;
      image.dispose();
      codec.dispose();
      return ratio;
    } catch (_) {
      return 1.58;
    }
  }

  bool _isDocumentPath(String? path) {
    if (path == null || path.isEmpty) return false;
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx');
  }

  bool _isNetworkUrl(String? path) {
    if (path == null || path.isEmpty) return false;
    final lower = path.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Map<String, String>? _authHeaders() {
    final String token = (AuthTokenStore.accessToken() ?? '').trim();
    if (token.isEmpty) return null;
    final String tokenType = (AuthTokenStore.tokenType() ?? 'Bearer').trim();
    return <String, String>{'Authorization': '$tokenType $token'};
  }

  String _basename(String? path) {
    if (path == null || path.isEmpty) return '';
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.strokeLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueLarge;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralAAA,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueLarge ? 32 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.headingDark,
            letterSpacing: valueLarge ? 1.2 : 0,
          ),
        ),
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralAAA,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.headingDark,
          ),
        ),
      ],
    );
  }
}

class _VerifiedSection extends StatelessWidget {
  final List<Widget> children;

  const _VerifiedSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.strokeLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'VERIFIED IDENTIFICATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceF0),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LinkedBankSection extends StatelessWidget {
  final List<Widget> children;

  const _LinkedBankSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.strokeLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BANK DETAILS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingDark,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceF0),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _EncryptionFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceF0)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: AppColors.gold, size: 14),
          SizedBox(width: 6),
          Text(
            'SECURE ENCRYPTION ACTIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.neutralAAA,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleRcBottomPrompt extends StatelessWidget {
  const _VehicleRcBottomPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.65,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.hexFFF0FDF4,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riding a different vehicle?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emerald,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Update your current vehicle details so rider\ncan identify your vehicle easily',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleRcEditButton extends StatelessWidget {
  const _VehicleRcEditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Upload New RC',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
