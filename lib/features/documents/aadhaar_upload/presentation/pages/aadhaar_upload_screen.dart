import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/documents/aadhaar_upload/presentation/cubit/aadhaar_upload_cubit.dart';
import 'package:goapp/features/documents/aadhaar_upload/presentation/cubit/aadhaar_upload_state.dart';

class AadhaarUploadScreen extends StatelessWidget {
  const AadhaarUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AadhaarUploadCubit>(
      create: (_) => sl<AadhaarUploadCubit>(),
      child: const _AadhaarUploadView(),
    );
  }
}

class _AadhaarUploadView extends StatefulWidget {
  const _AadhaarUploadView();

  @override
  State<_AadhaarUploadView> createState() => _AadhaarUploadViewState();
}

class _AadhaarUploadViewState extends State<_AadhaarUploadView> {
  final TextEditingController _aadhaarController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: 'Aadhaar Upload',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: BlocConsumer<AadhaarUploadCubit, AadhaarUploadState>(
          listener: (context, state) {
            if (state.errorMessage != null &&
                state.errorMessage!.trim().isNotEmpty) {
              SnackBarUtils.showError(context, state.errorMessage!.trim());
            }
            if (state.response != null && state.response!.success) {
              SnackBarUtils.show(context, 'Upload Successful');
            }
          },
          builder: (context, state) {
            final cubit = context.read<AadhaarUploadCubit>();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Aadhaar Number',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter 12-digit Aadhaar',
                            errorText: state.aadhaarError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: cubit.updateAadhaarNumber,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Aadhaar must be exactly 12 digits.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Upload Aadhaar',
                    child: Column(
                      children: [
                        _AadhaarSideUpload(
                          title: 'Front Image',
                          isSubmitting: state.isSubmitting,
                          badgeStatus: state.response?.front.verificationStatus,
                          filePath: state.frontFilePath,
                          networkUrl: _resolveSideUrl(
                            state.response?.front.documentUrl,
                          ),
                          onUpload: () =>
                              _showSourceSheet(context, AadhaarImageSide.front),
                          onRemove: state.hasFrontFile
                              ? () => cubit.removeFile(AadhaarImageSide.front)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _AadhaarSideUpload(
                          title: 'Back Image',
                          isSubmitting: state.isSubmitting,
                          badgeStatus: state.response?.back.verificationStatus,
                          filePath: state.backFilePath,
                          networkUrl: _resolveSideUrl(
                            state.response?.back.documentUrl,
                          ),
                          onUpload: () =>
                              _showSourceSheet(context, AadhaarImageSide.back),
                          onRemove: state.hasBackFile
                              ? () => cubit.removeFile(AadhaarImageSide.back)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (state.response != null) ...[
                    _SectionCard(
                      title: 'Status',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Front',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              _StatusBadge(
                                status:
                                    state.response!.front.verificationStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Front URL: ${state.response!.front.documentUrl}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Back',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              _StatusBadge(
                                status: state.response!.back.verificationStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Back URL: ${state.response!.back.documentUrl}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Document Type: ${state.response!.documentType}',
                            style: TextStyle(color: AppColors.gray.shade700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Request ID: ${state.response!.requestId}',
                            style: TextStyle(color: AppColors.gray.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ShadowButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: state.canSubmit ? cubit.submit : null,
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                  if (state.errorMessage != null &&
                      state.errorMessage!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Center(
                        child: TextButton(
                          onPressed: state.canSubmit ? cubit.submit : null,
                          child: const Text('Retry'),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String? _resolveSideUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final raw = rawUrl.trim();
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return ApiConfig.resolve(raw).toString();
  }

  Future<void> _showSourceSheet(
    BuildContext context,
    AadhaarImageSide side,
  ) async {
    final cubit = context.read<AadhaarUploadCubit>();
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Select Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingNavy,
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  cubit.pickFromCamera(side);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  cubit.pickFromGallery(side);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AadhaarSideUpload extends StatelessWidget {
  const _AadhaarSideUpload({
    required this.title,
    required this.isSubmitting,
    required this.badgeStatus,
    required this.filePath,
    required this.networkUrl,
    required this.onUpload,
    required this.onRemove,
  });

  final String title;
  final bool isSubmitting;
  final String? badgeStatus;
  final String? filePath;
  final String? networkUrl;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.headingNavy,
              ),
            ),
            const Spacer(),
            if (badgeStatus != null && badgeStatus!.trim().isNotEmpty)
              _StatusBadge(status: badgeStatus!.trim()),
          ],
        ),
        const SizedBox(height: 10),
        _PreviewBox(filePath: filePath, networkUrl: networkUrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShadowButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coolwhite,
                  foregroundColor: AppColors.headingNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.gray.shade200),
                  ),
                ),
                onPressed: onUpload,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_rounded),
                    SizedBox(width: 8),
                    Text('Upload'),
                  ],
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Remove',
                onPressed: isSubmitting ? null : onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_rounded,
                size: 18,
                color: AppColors.headingNavy,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.filePath, required this.networkUrl});

  final String? filePath;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    final hasLocal = filePath != null && filePath!.trim().isNotEmpty;
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.coolwhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Builder(
          builder: (_) {
            if (networkUrl != null && networkUrl!.trim().isNotEmpty) {
              return Image.network(
                networkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  if (hasLocal) {
                    return Image.file(File(filePath!), fit: BoxFit.cover);
                  }
                  return const _EmptyPreview();
                },
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              );
            }
            if (hasLocal) {
              return Image.file(File(filePath!), fit: BoxFit.cover);
            }
            return const _EmptyPreview();
          },
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload_rounded,
            color: AppColors.gray.shade400,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            'No file selected',
            style: TextStyle(color: AppColors.gray.shade600),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color bg;
    Color fg = AppColors.headingNavy;
    switch (normalized) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'pending' : normalized,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
