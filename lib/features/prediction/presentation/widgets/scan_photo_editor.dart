import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';

class ScanPhotoEditor extends StatefulWidget {
  const ScanPhotoEditor({
    super.key,
    required this.sourcePath,
  });

  final String sourcePath;

  @override
  State<ScanPhotoEditor> createState() => _ScanPhotoEditorState();
}

class _ScanPhotoEditorState extends State<ScanPhotoEditor> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  Uint8List? _imageBytes;
  Size? _imageSize;
  Size? _displayImageSize;
  Size? _viewportSize;
  bool _isSaving = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final file = File(widget.sourcePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
    });
  }

  void _maybeInitTransform() {
    if (_isReady || _viewportSize == null || _imageSize == null) return;

    final viewport = _viewportSize!;
    final image = _imageSize!;
    final fitted = applyBoxFit(BoxFit.cover, image, viewport);
    final source = fitted.source;
    final destination = fitted.destination;

    final displayWidth = image.width * (destination.width / source.width);
    final displayHeight = image.height * (destination.height / source.height);
    final dx = (viewport.width - displayWidth) / 2;
    final dy = (viewport.height - displayHeight) / 2;
    _displayImageSize = Size(displayWidth, displayHeight);

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1);

    _isReady = true;
  }

  void _resetTransform() {
    _isReady = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeInitTransform();
    });
  }

  Future<void> _saveEditedImage() async {
    if (_isSaving) return;
    final boundaryContext = _cropKey.currentContext;
    if (boundaryContext == null) return;

    setState(() => _isSaving = true);
    try {
      final boundary =
          boundaryContext.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(2.0, 3.0),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(
        '${tempDir.path}${Platform.pathSeparator}edited_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await outputFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      Navigator.of(context).pop(outputFile.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final brand = context.brand;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cropSize = (screenWidth - (spacing.lg * 2)).clamp(240.0, 420.0);

    return AppPage(
      horizontalPadding: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.sm,
            spacing.lg,
            spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padded: false,
                    color: onSurface,
                  ),
                  SizedBox(width: spacing.sm),
                  const Expanded(
                    child: Label(
                      'Edit',
                      variant: LabelVariant.title,
                      size: 22,
                      weight: FontWeight.w700,
                      uppercase: false,
                    ),
                  ),
                  TextButton(
                    onPressed: _imageBytes == null || _isSaving
                        ? null
                        : _saveEditedImage,
                    child: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(brand.purple),
                            ),
                          )
                        : Label(
                            'Save',
                            variant: LabelVariant.title,
                            size: 18,
                            color: brand.purple,
                            uppercase: false,
                          ),
                  ),
                ],
              ),
              SizedBox(height: spacing.sm),
              Label(
                'Drag to reposition and pinch to zoom before continuing.',
                variant: LabelVariant.body,
                align: TextAlign.center,
                color: onSurfaceVariant,
                uppercase: false,
              ),
              SizedBox(height: spacing.lg),
              Expanded(
                child: Center(
                  child: _imageBytes == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final boxSize = Size(cropSize, cropSize);
                                _viewportSize = boxSize;
                                _maybeInitTransform();

                                return RepaintBoundary(
                                  key: _cropKey,
                                  child: Container(
                                    width: cropSize,
                                    height: cropSize,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      borderRadius: context.radius.lg,
                                      border: Border.all(
                                        color: brand.purple.withValues(alpha: 0.20),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      minScale: 1.0,
                                      maxScale: 3.2,
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      boundaryMargin: EdgeInsets.zero,
                                      clipBehavior: Clip.hardEdge,
                                      constrained: false,
                                      child: SizedBox(
                                        width: _displayImageSize!.width,
                                        height: _displayImageSize!.height,
                                        child: Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: spacing.lg),
                            Button(
                              label: 'Reset',
                              icon: Icons.refresh_rounded,
                              variant: ButtonVariant.outlined,
                              onPressed: _resetTransform,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
