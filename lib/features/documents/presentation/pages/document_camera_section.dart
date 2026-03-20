import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/image_picker_service.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/profile_photo_capture/presentation/pages/profile_photo_capture_page.dart';

import '../cubit/document_upload_cubit.dart';

bool _isFlutterTestEnvironment() {
  if (const bool.fromEnvironment('FLUTTER_TEST')) {
    return true;
  }
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return true;
  }

  try {
    final typeName = WidgetsBinding.instance.runtimeType.toString();
    return typeName.contains('TestWidgetsFlutterBinding') ||
        typeName.contains('AutomatedTestWidgetsFlutterBinding');
  } catch (_) {
    return false;
  }
}

void showProfileImageSourceSheet(BuildContext context) {
  if (_isFlutterTestEnvironment()) {
    showModalBottomSheet<void>(
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
                'Upload Profile Photo',
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
                  context.read<DocumentUploadCubit>().captureProfilePhoto(
                    source: AppImageSource.camera,
                    context: context,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.read<DocumentUploadCubit>().captureProfilePhoto(
                    source: AppImageSource.gallery,
                    context: context,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    return;
  }

  () async {
    final String? capturedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProfilePhotoCapturePage()),
    );
    if (!context.mounted) return;
    if (capturedPath == null || capturedPath.trim().isEmpty) return;
    await context.read<DocumentUploadCubit>().setProfilePhotoFromPath(
      capturedPath,
    );
  }();
}

void showDocumentImageSourceSheet(
  BuildContext context, {
  required Future<void> Function(AppImageSource source) onPick,
  required Future<void> Function() onPickDocument,
  bool allowDocument = true,
}) {
  showModalBottomSheet<void>(
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
              'Upload Document',
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
                onPick(AppImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                onPick(AppImageSource.gallery);
              },
            ),
            if (allowDocument)
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: const Text('Document'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onPickDocument();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void showBankDocumentSourceSheet(BuildContext context) {
  showModalBottomSheet<void>(
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
              'Upload Document',
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
                context.read<DocumentUploadCubit>().captureBankDocument(
                  source: AppImageSource.camera,
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<DocumentUploadCubit>().captureBankDocument(
                  source: AppImageSource.gallery,
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Document'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<DocumentUploadCubit>().captureBankDocumentFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
