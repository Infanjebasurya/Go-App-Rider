import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/service/permission_service.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/profile_photo_capture/presentation/cubit/face_profile_photo_capture_cubit.dart';
import 'package:goapp/features/profile_photo_capture/presentation/cubit/face_profile_photo_capture_state.dart';
import 'package:goapp/features/profile_photo_capture/presentation/widgets/face_guide_overlay.dart';

class ProfilePhotoCapturePage extends StatelessWidget {
  const ProfilePhotoCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FaceProfilePhotoCaptureCubit>(
      create: (_) => sl<FaceProfilePhotoCaptureCubit>()..start(),
      child: const _ProfilePhotoCaptureView(),
    );
  }
}

class _ProfilePhotoCaptureView extends StatelessWidget {
  const _ProfilePhotoCaptureView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Capture Profile Photo'),
      ),
      body:
          BlocConsumer<
            FaceProfilePhotoCaptureCubit,
            FaceProfilePhotoCaptureState
          >(
            listener: (context, state) {
              if (state.status == FaceProfileCaptureStatus.failure) {
                SnackBarUtils.showError(context, state.message);
              }
            },
            builder: (context, state) {
              return switch (state.status) {
                FaceProfileCaptureStatus.permissionDenied =>
                  _PermissionDeniedView(
                    onOpenSettings: () =>
                        sl<PermissionService>().openAppSettings(),
                    onRetry: () =>
                        context.read<FaceProfilePhotoCaptureCubit>().start(),
                  ),
                FaceProfileCaptureStatus.preview => _PreviewView(
                  path: state.photo?.path,
                  onRetake: () =>
                      context.read<FaceProfilePhotoCaptureCubit>().retake(),
                  onConfirm: () {
                    final String? path = state.photo?.path;
                    if (path != null) {
                      unawaited(
                        context
                            .read<FaceProfilePhotoCaptureCubit>()
                            .prepareToExit(),
                      );
                      Navigator.of(context).pop<String>(path);
                    }
                  },
                ),
                FaceProfileCaptureStatus.capturing => const _BusyView(
                  title: 'Auto capturing...',
                ),
                FaceProfileCaptureStatus.processing => const _BusyView(
                  title: 'Processing photo...',
                ),
                FaceProfileCaptureStatus.failure => _FailureView(
                  message: state.message,
                  onRetry: () =>
                      context.read<FaceProfilePhotoCaptureCubit>().start(),
                ),
                FaceProfileCaptureStatus.timeout => _TimeoutView(
                  message: state.message,
                  onRetry: () =>
                      context.read<FaceProfilePhotoCaptureCubit>().retake(),
                ),
                FaceProfileCaptureStatus.scanning ||
                FaceProfileCaptureStatus.initializing => _LiveCameraView(
                  statusText: state.message,
                  progress: state.stabilityProgress,
                  debugFaceBox: state.debugFaceBox,
                  cameraReadyNonce: state.cameraReadyNonce,
                ),
              };
            },
          ),
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.white),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Retake'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCameraView extends StatelessWidget {
  const _LiveCameraView({
    required this.statusText,
    required this.progress,
    required this.debugFaceBox,
    required this.cameraReadyNonce,
  });

  final String statusText;
  final double progress;
  final Rect? debugFaceBox;
  final int cameraReadyNonce;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FaceProfilePhotoCaptureCubit>();
    final CameraController? controller = cubit.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const _BusyView(title: 'Opening camera...');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller, key: ValueKey('camera_$cameraReadyNonce')),
        FaceGuideOverlay(
          showDebugBox: kDebugMode && const bool.fromEnvironment('FACE_DEBUG'),
          normalizedDebugBox: debugFaceBox,
          statusText: statusText,
          progress: progress,
        ),
      ],
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.path,
    required this.onRetake,
    required this.onConfirm,
  });

  final String? path;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final String? localPath = path;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Preview',
            style: textTheme.titleLarge?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AspectRatio(
                  aspectRatio: 3.5 / 4.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.black87,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (localPath == null)
                          const ColoredBox(color: Colors.black)
                        else
                          Image.file(
                            File(localPath),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F0ED),
                    foregroundColor: const Color(0xFF1F2937),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Confirm & Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A86B),
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.onOpenSettings,
    required this.onRetry,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Camera permission required',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable camera permission in Settings to capture your profile photo.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpenSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
