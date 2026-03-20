import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:goapp/core/service/image_picker_service.dart';
import 'package:goapp/core/service/permission_service.dart';
import 'package:goapp/core/service/path_provider_service.dart';
import 'package:image/image.dart' as img;

class DocumentUploadFileService {
  DocumentUploadFileService({
    required PathProviderService pathProvider,
    required PermissionService permissionService,
  }) : _pathProvider = pathProvider,
       _permissionService = permissionService;

  final PathProviderService _pathProvider;
  final PermissionService _permissionService;

  static const int maxBytes = 5 * 1024 * 1024;
  static const double cr80AspectRatio = 85.6 / 54.0;

  bool validateFileSize(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= maxBytes;
  }

  bool isValidImageFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif') ||
        lower.endsWith('.webp');
  }

  Future<int> resolveImageSizeBytes(PickedImage picked) async {
    final fileSize = await File(picked.path).length();
    final bytes = await File(picked.path).readAsBytes();
    return [fileSize, bytes.length].reduce((a, b) => a > b ? a : b);
  }

  Future<bool> ensurePermission(AppImageSource source) async {
    if (source == AppImageSource.gallery && Platform.isAndroid) {
      return true;
    }

    final AppPermission permission = source == AppImageSource.camera
        ? AppPermission.camera
        : AppPermission.photos;

    final AppPermissionStatus current = await _permissionService.status(
      permission,
    );
    final AppPermissionStatus resolved = current == AppPermissionStatus.granted
        ? current
        : await _permissionService.request(permission);
    return resolved == AppPermissionStatus.granted;
  }

  bool validateAspectRatio({
    required int widthPx,
    required int heightPx,
    required double target,
    double toleranceFraction = 0.06,
  }) {
    if (widthPx <= 0 || heightPx <= 0) return false;
    final double w = widthPx.toDouble();
    final double h = heightPx.toDouble();
    final double ratio = math.max(w, h) / math.min(w, h);
    final double diff = (ratio - target).abs() / target;
    return diff <= toleranceFraction;
  }

  Future<ui.Size?> tryDecodeImageSize(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return null;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image img = frame.image;
      final ui.Size size = ui.Size(img.width.toDouble(), img.height.toDouble());
      img.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Size?> tryDecodeImageSizeBytes(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) return null;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ui.Size size = ui.Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<String?> validateCr80CardImage(String path) async {
    final ui.Size? size = await tryDecodeImageSize(path);
    if (size == null) {
      return 'Unable to read image size. Please upload a clear card photo.';
    }
    final bool ok = validateAspectRatio(
      widthPx: size.width.round(),
      heightPx: size.height.round(),
      target: cr80AspectRatio,
    );
    if (!ok) {
      return 'Card photo must match CR80 size (85.6mm × 54mm).';
    }
    return null;
  }

  Future<String?> validateCr80CardBytes(Uint8List bytes) async {
    final ui.Size? size = await tryDecodeImageSizeBytes(bytes);
    if (size == null) {
      return 'Unable to read image size. Please upload a clear card photo.';
    }
    final bool ok = validateAspectRatio(
      widthPx: size.width.round(),
      heightPx: size.height.round(),
      target: cr80AspectRatio,
    );
    if (!ok) {
      return 'Card photo must match CR80 size (85.6mm Ã— 54mm).';
    }
    return null;
  }

  Future<Uint8List> optimizeToJpegUnderMaxBytes(
    Uint8List inputBytes, {
    int maxOutputBytes = maxBytes,
    int initialQuality = 92,
    int minQuality = 62,
    int qualityStep = 6,
    int minLongestSidePx = 900,
  }) async {
    final img.Image? decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes;

    img.Image working = decoded;
    int quality = initialQuality.clamp(1, 100);
    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(working, quality: quality),
    );

    while (encoded.length > maxOutputBytes && quality > minQuality) {
      quality = (quality - qualityStep).clamp(minQuality, 100);
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    int guard = 0;
    while (encoded.length > maxOutputBytes &&
        guard < 6 &&
        math.max(working.width, working.height) > minLongestSidePx) {
      guard++;
      final int longest = math.max(working.width, working.height);
      final int nextLongest = (longest * 0.85).round().clamp(
        minLongestSidePx,
        longest,
      );
      if (nextLongest >= longest) break;
      working = (working.width >= working.height)
          ? img.copyResize(working, width: nextLongest)
          : img.copyResize(working, height: nextLongest);
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    return encoded;
  }

  Future<String> persistJpegBytesToAppStorage(
    Uint8List bytes, {
    required String prefix,
  }) async {
    return persistImageBytesToAppStorage(bytes, prefix: prefix, extension: '.jpg');
  }

  Future<String> persistImageBytesToAppStorage(
    Uint8List bytes, {
    required String prefix,
    String? extension,
  }) async {
    final String resolvedExt = (extension ?? _sniffImageExtension(bytes)).trim();
    final String safeExt = resolvedExt.startsWith('.') ? resolvedExt : '.$resolvedExt';

    try {
      final directory = await _pathProvider.getApplicationDocumentsDirectory();
      final uploadsDir = Directory(
        '${directory.path}${Platform.pathSeparator}document_uploads',
      );
      if (!await uploadsDir.exists()) {
        await uploadsDir.create(recursive: true);
      }

      final targetPath =
          '${uploadsDir.path}${Platform.pathSeparator}${prefix}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      final Directory systemTemp = Directory.systemTemp;
      final String fallback =
          '${systemTemp.path}${Platform.pathSeparator}${prefix}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
      await File(fallback).writeAsBytes(bytes, flush: true);
      return fallback;
    }
  }

  Future<Uint8List?> readImageBytesForCropping(String path) async {
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return null;

      if (img.decodeImage(bytes) != null) {
        return bytes;
      }

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      codec.dispose();
      if (data == null) return bytes;
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<String> persistImageToAppStorage(
    String sourcePath, {
    required String prefix,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return sourcePath;

      final directory = await _pathProvider.getApplicationDocumentsDirectory();
      final uploadsDir = Directory(
        '${directory.path}${Platform.pathSeparator}document_uploads',
      );
      if (!await uploadsDir.exists()) {
        await uploadsDir.create(recursive: true);
      }

      final extension = _extractExtension(sourcePath);
      final targetPath =
          '${uploadsDir.path}${Platform.pathSeparator}${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final copied = await sourceFile.copy(targetPath);
      return copied.path;
    } catch (_) {
      return sourcePath;
    }
  }

  Future<void> deleteManagedFileIfExists(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      if (!await _isManagedUploadPath(path)) return;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> clearManagedUploadsDirectory() async {
    try {
      final directory = await _pathProvider.getApplicationDocumentsDirectory();
      final uploadsDir = Directory(
        '${directory.path}${Platform.pathSeparator}document_uploads',
      );
      if (await uploadsDir.exists()) {
        await uploadsDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<bool> _isManagedUploadPath(String path) async {
    try {
      final directory = await _pathProvider.getApplicationDocumentsDirectory();
      final uploadsDir = Directory(
        '${directory.path}${Platform.pathSeparator}document_uploads',
      ).path;
      final normalizedPath = path.replaceAll('\\', '/');
      final normalizedUploadsDir = '$uploadsDir${Platform.pathSeparator}'
          .replaceAll('\\', '/');
      return normalizedPath.startsWith(normalizedUploadsDir);
    } catch (_) {
      return false;
    }
  }

  String _extractExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return '.jpg';
    return path.substring(dotIndex);
  }

  String _sniffImageExtension(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) return '.jpg';
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return '.png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return '.webp';
    }
    return '.jpg';
  }
}
