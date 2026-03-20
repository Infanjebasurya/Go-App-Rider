import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:image/image.dart' as img;

sealed class DocumentImageCropResult {
  const DocumentImageCropResult();
}

class DocumentImageCropConfirmed extends DocumentImageCropResult {
  const DocumentImageCropConfirmed(this.bytes);

  final Uint8List bytes;
}

class DocumentImageCropRetake extends DocumentImageCropResult {
  const DocumentImageCropRetake();
}

class DocumentImageCropPage extends StatefulWidget {
  const DocumentImageCropPage({
    super.key,
    required this.imageBytes,
    this.title = 'Crop',
    this.cardAspectRatio,
    this.defaultToCardAspect = false,
    this.allowRetake = true,
  });

  final Uint8List imageBytes;
  final String title;
  final double? cardAspectRatio;
  final bool defaultToCardAspect;
  final bool allowRetake;

  @override
  State<DocumentImageCropPage> createState() => _DocumentImageCropPageState();
}

class _DocumentImageCropPageState extends State<DocumentImageCropPage> {
  final CropController _controller = CropController();

  Uint8List? _imageBytes;
  double? _aspectRatio;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
    _aspectRatio = (widget.defaultToCardAspect && widget.cardAspectRatio != null)
        ? widget.cardAspectRatio
        : null;
  }

  void _rotate({required bool clockwise}) {
    final Uint8List? bytes = _imageBytes;
    if (bytes == null || bytes.isEmpty) return;
    try {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      final img.Image rotated = img.copyRotate(
        decoded,
        angle: clockwise ? 90 : 270,
      );
      final Uint8List encoded = Uint8List.fromList(
        img.encodeJpg(rotated, quality: 95),
      );
      setState(() => _imageBytes = encoded);
      _controller.image = encoded;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _imageBytes;
    final bool showAspectToggle = widget.cardAspectRatio != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title),
        actions: [
          if (showAspectToggle)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: _AspectToggle(
                  enabled: !_cropping,
                  isCard: _aspectRatio != null,
                  onToggle: (isCard) {
                    setState(
                      () => _aspectRatio = isCard ? widget.cardAspectRatio : null,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: bytes == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.emerald,
                        ),
                      ),
                    )
                  : Crop(
                      controller: _controller,
                      image: bytes,
                      aspectRatio: _aspectRatio,
                      baseColor: Colors.black,
                      maskColor: Colors.black.withValues(alpha: 0.55),
                      radius: 10,
                      onCropped: (result) {
                        if (!mounted) return;
                        if (result is CropFailure) {
                          setState(() => _cropping = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to crop image. Try again.'),
                            ),
                          );
                          return;
                        }
                        if (result is CropSuccess) {
                          Navigator.of(context).pop(
                            DocumentImageCropConfirmed(result.croppedImage),
                          );
                        }
                      },
                    ),
            ),
            _BottomBar(
              allowRetake: widget.allowRetake,
              enabled: !_cropping && bytes != null,
              onRetake: () => Navigator.of(context).pop(
                const DocumentImageCropRetake(),
              ),
              onRotateLeft: () => _rotate(clockwise: false),
              onRotateRight: () => _rotate(clockwise: true),
              onConfirm: () {
                if (_cropping) return;
                setState(() => _cropping = true);
                _controller.crop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.allowRetake,
    required this.enabled,
    required this.onRetake,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onConfirm,
  });

  final bool allowRetake;
  final bool enabled;
  final VoidCallback onRetake;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          if (allowRetake)
            TextButton.icon(
              onPressed: enabled ? onRetake : null,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Retake',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Rotate left',
            onPressed: enabled ? onRotateLeft : null,
            icon: const Icon(Icons.rotate_left_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Rotate right',
            onPressed: enabled ? onRotateRight : null,
            icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: enabled ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Use photo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectToggle extends StatelessWidget {
  const _AspectToggle({
    required this.enabled,
    required this.isCard,
    required this.onToggle,
  });

  final bool enabled;
  final bool isCard;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('Card'),
          icon: Icon(Icons.crop_16_9_rounded),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('Free'),
          icon: Icon(Icons.crop_free_rounded),
        ),
      ],
      selected: <bool>{isCard},
      onSelectionChanged: enabled
          ? (selection) {
              final bool next = selection.contains(true);
              onToggle(next);
            }
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.emerald;
          return Colors.white.withValues(alpha: 0.12);
        }),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
