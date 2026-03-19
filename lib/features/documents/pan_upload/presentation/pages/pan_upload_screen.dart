import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/documents/pan_upload/presentation/cubit/pan_upload_cubit.dart';
import 'package:goapp/features/documents/pan_upload/presentation/cubit/pan_upload_state.dart';
import 'package:goapp/features/documents/presentation/widgets/doc_number_field.dart';

class PanUploadScreen extends StatelessWidget {
  const PanUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PanUploadCubit>(
      create: (_) => sl<PanUploadCubit>(),
      child: const _PanUploadView(),
    );
  }
}

class _PanUploadView extends StatefulWidget {
  const _PanUploadView();

  @override
  State<_PanUploadView> createState() => _PanUploadViewState();
}

class _PanUploadViewState extends State<_PanUploadView> {
  final TextEditingController _panController = TextEditingController();

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: 'PAN Upload',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: BlocConsumer<PanUploadCubit, PanUploadState>(
          listener: (context, state) {
            if (state.errorMessage != null &&
                state.errorMessage!.trim().isNotEmpty) {
              SnackBarUtils.showError(context, state.errorMessage!.trim());
            }
            if (state.response != null && state.response!.success) {
              SnackBarUtils.show(context, 'PAN Uploaded Successfully');
            }
          },
          builder: (context, state) {
            final cubit = context.read<PanUploadCubit>();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'PAN Number',
                    child: DocNumberField(
                      label: 'PAN',
                      hint: 'ABCDE1234F',
                      controller: _panController,
                      onChanged: cubit.updatePanNumber,
                      forceUppercase: true,
                      formatAsPan: true,
                      maxLength: 10,
                      errorText: state.panError,
                      example: 'Example: ABCDE1234F',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Upload PAN Card',
                    child: Column(
                      children: [
                        _PreviewBox(
                          filePath: state.filePath,
                          networkUrl: _resolveDocumentUrl(state),
                        ),
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
                                    side: BorderSide(
                                      color: AppColors.gray.shade200,
                                    ),
                                  ),
                                ),
                                onPressed: () => _showSourceSheet(context),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_rounded),
                                    SizedBox(width: 8),
                                    Text('Upload PAN Card'),
                                  ],
                                ),
                              ),
                            ),
                            if (state.hasFile) ...[
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: state.isSubmitting
                                    ? null
                                    : cubit.removeFile,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ],
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
                                'Verification',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              _StatusBadge(
                                status: state.response!.verificationStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Document Type: ${state.response!.documentType}',
                            style: TextStyle(color: AppColors.gray.shade700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Document URL: ${state.response!.documentUrl}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray.shade600,
                            ),
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

  String? _resolveDocumentUrl(PanUploadState state) {
    final resp = state.response;
    if (resp == null || resp.documentUrl.trim().isEmpty) return null;
    final raw = resp.documentUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    return ApiConfig.resolve(raw).toString();
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    final cubit = context.read<PanUploadCubit>();
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
                  cubit.pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  cubit.pickFromGallery();
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
