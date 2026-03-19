import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:goapp/core/service/permission_service.dart';
import 'package:goapp/features/profile_photo_capture/domain/models/processed_jpeg_image.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/face_auto_capture_policy.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/live_face_detection_service.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/profile_photo_image_processing_service.dart';
import 'package:goapp/features/profile_photo_capture/domain/usecases/save_profile_photo_usecase.dart';

import 'face_profile_photo_capture_state.dart';

class FaceProfilePhotoCaptureCubit extends Cubit<FaceProfilePhotoCaptureState> {
  FaceProfilePhotoCaptureCubit({
    required PermissionService permissionService,
    required LiveFaceDetectionService faceDetectionService,
    required FaceAutoCapturePolicy policy,
    required ProfilePhotoImageProcessingService imageProcessingService,
    required SaveProfilePhotoUseCase saveUseCase,
  }) : _permissionService = permissionService,
       _faceDetectionService = faceDetectionService,
       _policy = policy,
       _imageProcessingService = imageProcessingService,
       _saveUseCase = saveUseCase,
       super(FaceProfilePhotoCaptureState.initial());

  final PermissionService _permissionService;
  final LiveFaceDetectionService _faceDetectionService;
  final FaceAutoCapturePolicy _policy;
  final ProfilePhotoImageProcessingService _imageProcessingService;
  final SaveProfilePhotoUseCase _saveUseCase;

  CameraController? _controller;
  CameraDescription? _camera;

  DateTime? _scanStartedAt;
  DateTime? _stableSince;
  Rect? _lastStableBox; // normalized
  bool _isProcessingFrame = false;
  bool _didCapture = false;
  DateTime _lastFrameProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _scanTimeout = Duration(seconds: 30);
  static const Duration _stabilityRequired = Duration(milliseconds: 1200);
  static const Duration _frameThrottle = Duration(milliseconds: 120);

  CameraController? get controller => _controller;

  Future<void> prepareToExit() async {
    await _stopStreamIfNeeded();
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _camera = null;
  }

  Future<void> start() async {
    emit(
      state.copyWith(
        status: FaceProfileCaptureStatus.initializing,
        message: 'Initializing camera...',
      ),
    );

    final AppPermissionStatus current = await _permissionService.status(
      AppPermission.camera,
    );
    final AppPermissionStatus resolved = current == AppPermissionStatus.granted
        ? current
        : await _permissionService.request(AppPermission.camera);

    if (resolved != AppPermissionStatus.granted) {
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.permissionDenied,
          message: 'Camera permission required',
        ),
      );
      return;
    }

    try {
      final cams = await availableCameras();
      final CameraDescription? front = cams
          .cast<CameraDescription?>()
          .firstWhere(
            (c) => c?.lensDirection == CameraLensDirection.front,
            orElse: () => null,
          );
      _camera = front ?? (cams.isNotEmpty ? cams.first : null);
      if (_camera == null) {
        emit(
          state.copyWith(
            status: FaceProfileCaptureStatus.failure,
            message: 'No camera available',
          ),
        );
        return;
      }

      _controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await _controller!.initialize();
      _scanStartedAt = DateTime.now();
      _stableSince = null;
      _lastStableBox = null;
      _didCapture = false;
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.scanning,
          message: 'Scanning face...',
          stabilityProgress: 0,
          cameraReadyNonce: state.cameraReadyNonce + 1,
          clearPhoto: true,
        ),
      );

      await _controller!.startImageStream(_onCameraImage);
    } catch (e) {
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.failure,
          message: 'Failed to start camera: $e',
        ),
      );
    }
  }

  Future<void> retake() async {
    await _stopStreamIfNeeded();
    _stableSince = null;
    _lastStableBox = null;
    _didCapture = false;
    _scanStartedAt = DateTime.now();
    emit(
      state.copyWith(
        status: FaceProfileCaptureStatus.scanning,
        message: 'Scanning face...',
        stabilityProgress: 0,
        clearPhoto: true,
      ),
    );
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.startImageStream(_onCameraImage);
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.failure,
          message: 'Failed to restart camera: $e',
        ),
      );
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_didCapture) return;
    if (_isProcessingFrame) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastFrameProcessedAt) < _frameThrottle) return;
    _lastFrameProcessedAt = now;

    unawaited(_processFrame(image));
  }

  Future<void> _processFrame(CameraImage image) async {
    _isProcessingFrame = true;
    try {
      if (state.status != FaceProfileCaptureStatus.scanning) return;
      final DateTime startedAt = _scanStartedAt ?? DateTime.now();
      if (DateTime.now().difference(startedAt) > _scanTimeout) {
        emit(
          state.copyWith(
            status: FaceProfileCaptureStatus.timeout,
            message: 'Timed out. Tap Retake to try again.',
          ),
        );
        await _stopStreamIfNeeded();
        return;
      }

      final CameraController? controller = _controller;
      final CameraDescription? camera = _camera;
      if (controller == null ||
          camera == null ||
          !controller.value.isInitialized) {
        return;
      }

      final InputImage? inputImage = _toInputImage(image, camera);
      if (inputImage == null) {
        return;
      }
      final faces = await _faceDetectionService.detect(inputImage);
      final Size imageSize = inputImage.metadata?.size ?? const Size(0, 0);
      final Size effectiveSize = _effectiveImageSize(
        imageSize,
        inputImage.metadata?.rotation,
      );
      final evaluation = _policy.evaluate(
        faces: faces,
        imageSize: effectiveSize,
      );
      final Rect? normalizedBox = evaluation.normalizedFaceBox;

      emit(
        state.copyWith(
          message: evaluation.message,
          debugFaceBox: normalizedBox,
          clearDebugFaceBox: normalizedBox == null,
        ),
      );
      if (!evaluation.isOk || normalizedBox == null) {
        _stableSince = null;
        _lastStableBox = null;
        emit(state.copyWith(stabilityProgress: 0));
        return;
      }

      final bool stablePosition = _isStableComparedToLast(normalizedBox);
      if (!stablePosition) {
        _stableSince = null;
        _lastStableBox = normalizedBox;
        emit(state.copyWith(stabilityProgress: 0));
        return;
      }

      _lastStableBox = normalizedBox;
      _stableSince ??= DateTime.now();
      final Duration stableFor = DateTime.now().difference(_stableSince!);
      final double progress =
          (stableFor.inMilliseconds / _stabilityRequired.inMilliseconds).clamp(
            0.0,
            1.0,
          );
      emit(state.copyWith(stabilityProgress: progress));

      if (stableFor >= _stabilityRequired) {
        await _autoCapture();
      }
    } catch (e) {
      // Keep scanning; transient frame errors shouldn't hard-fail.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Face scan frame error: $e');
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  bool _isStableComparedToLast(Rect normalizedBox) {
    final Rect? last = _lastStableBox;
    if (last == null) return true;
    final double dcx = (normalizedBox.center.dx - last.center.dx).abs();
    final double dcy = (normalizedBox.center.dy - last.center.dy).abs();
    final double dh = (normalizedBox.height - last.height).abs();
    return dcx <= 0.03 && dcy <= 0.03 && dh <= 0.05;
  }

  Size _effectiveImageSize(Size size, InputImageRotation? rotation) {
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return Size(size.height, size.width);
    }
    return size;
  }

  Future<void> _autoCapture() async {
    if (_didCapture) return;
    _didCapture = true;
    emit(
      state.copyWith(
        status: FaceProfileCaptureStatus.capturing,
        message: 'Auto capturing...',
      ),
    );
    await _stopStreamIfNeeded();

    try {
      final CameraController? controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        emit(
          state.copyWith(
            status: FaceProfileCaptureStatus.failure,
            message: 'Camera not ready',
          ),
        );
        return;
      }
      final XFile raw = await controller.takePicture();
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.processing,
          message: 'Processing photo...',
        ),
      );

      final ProcessedJpegImage processed = await _imageProcessingService
          .processCapturedImage(raw.path);
      final saved = await _saveUseCase(processed);

      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.preview,
          message: 'Preview',
          stabilityProgress: 1,
          photo: saved,
        ),
      );

      unawaited(_bestEffortDelete(raw.path));
    } catch (e) {
      emit(
        state.copyWith(
          status: FaceProfileCaptureStatus.failure,
          message: 'Capture failed: $e',
        ),
      );
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    try {
      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final InputImageRotation rotation = _inputImageRotation(camera);

      final Uint8List bytes;
      final int bytesPerRow;
      final InputImageFormat format;

      if (Platform.isAndroid) {
        bytesPerRow = image.planes.first.bytesPerRow;
        format = InputImageFormat.nv21;
        bytes = image.planes.length == 1
            ? image.planes.first.bytes
            : _yuv420ToNv21(image);
      } else {
        // iOS typically provides BGRA8888.
        final Plane plane = image.planes.first;
        bytesPerRow = plane.bytesPerRow;
        bytes = plane.bytes;
        format =
            InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.bgra8888;
      }
      final InputImageMetadata metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int ySize = width * height;
    final Uint8List out = Uint8List(ySize + (ySize ~/ 2));

    // Copy Y plane (handle row stride).
    int outIndex = 0;
    for (int row = 0; row < height; row++) {
      final int rowStart = row * yPlane.bytesPerRow;
      out.setRange(outIndex, outIndex + width, yPlane.bytes, rowStart);
      outIndex += width;
    }

    final int uvHeight = height ~/ 2;
    final int uvWidth = width ~/ 2;
    final int uRowStride = uPlane.bytesPerRow;
    final int vRowStride = vPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    // Interleave V and U as NV21.
    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        final int uIndex = row * uRowStride + col * uPixelStride;
        final int vIndex = row * vRowStride + col * vPixelStride;
        out[outIndex++] = vPlane.bytes[vIndex];
        out[outIndex++] = uPlane.bytes[uIndex];
      }
    }

    return out;
  }

  InputImageRotation _inputImageRotation(CameraDescription camera) {
    final CameraController? controller = _controller;
    final DeviceOrientation deviceOrientation =
        controller?.value.deviceOrientation ?? DeviceOrientation.portraitUp;

    final int deviceDegrees = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

    int rotationDegrees;
    if (Platform.isIOS) {
      rotationDegrees = camera.sensorOrientation;
    } else {
      final int sensor = camera.sensorOrientation;
      rotationDegrees = camera.lensDirection == CameraLensDirection.front
          ? (sensor + deviceDegrees) % 360
          : (sensor - deviceDegrees + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotationDegrees) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> _stopStreamIfNeeded() async {
    try {
      final CameraController? controller = _controller;
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
  }

  Future<void> _bestEffortDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await prepareToExit();
    try {
      await _faceDetectionService.close();
    } catch (_) {}
    return super.close();
  }
}
