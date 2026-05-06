import 'dart:io';
import 'dart:math' as math;
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
  int _quarterTurns = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

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
    _displayImageSize = Size(displayWidth, displayHeight);
    final effectiveDisplay = _effectiveDisplayImageSize!;
    final dx = (viewport.width - effectiveDisplay.width) / 2;
    final dy = (viewport.height - effectiveDisplay.height) / 2;

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

  bool get _isQuarterTurnOdd => _quarterTurns.isOdd;

  Size? get _effectiveDisplayImageSize {
    final display = _displayImageSize;
    if (display == null) return null;
    return _isQuarterTurnOdd ? Size(display.height, display.width) : display;
  }

  void _rotateLeft() {
    setState(() {
      _quarterTurns = (_quarterTurns + 3) % 4;
    });
    _resetTransform();
  }

  void _rotateRight() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
    _resetTransform();
  }

  void _toggleFlipHorizontal() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _toggleFlipVertical() {
    setState(() {
      _flipVertical = !_flipVertical;
    });
  }

  void _clampTransform() {
    final viewport = _viewportSize;
    final display = _effectiveDisplayImageSize;
    if (viewport == null || display == null) return;

    final matrix = _transformationController.value.clone();
    final scale = matrix.getMaxScaleOnAxis().clamp(1.0, 4.0);
    final scaledWidth = display.width * scale;
    final scaledHeight = display.height * scale;

    final minDx = math.min(viewport.width - scaledWidth, 0.0);
    final maxDx = 0.0;
    final minDy = math.min(viewport.height - scaledHeight, 0.0);
    final maxDy = 0.0;

    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[10] = 1.0;
    matrix.storage[15] = 1.0;
    matrix.storage[12] = matrix.storage[12].clamp(minDx, maxDx).toDouble();
    matrix.storage[13] = matrix.storage[13].clamp(minDy, maxDy).toDouble();

    _transformationController.value = matrix;
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
    final colorScheme = Theme.of(context).colorScheme;
    final pageBg = colorScheme.surface;
    final panelBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.78);
    final onSurface = colorScheme.onSurface;
    final onSurfaceSoft = colorScheme.onSurfaceVariant;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cropSize = math.min(
      (screenWidth - (spacing.lg * 2)).clamp(240.0, 420.0),
      (screenHeight * 0.5).clamp(240.0, 420.0),
    ).toDouble();

    return AppPage(
      horizontalPadding: false,
      backgroundColor: pageBg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.m,
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
                  Expanded(
                    child: Label(
                      'Crop Photo',
                      variant: LabelVariant.title,
                      size: 22,
                      weight: FontWeight.w700,
                      color: onSurface,
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
                            color: brand.pink,
                            uppercase: false,
                          ),
                  ),
                ],
              ),
              SizedBox(height: spacing.xl),
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

                                return Container(
                                  padding: EdgeInsets.all(spacing.sm),
                                  decoration: BoxDecoration(
                                    color: panelBg,
                                    borderRadius: context.radius.xl,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(alpha: 0.10),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: RepaintBoundary(
                                    key: _cropKey,
                                    child: Container(
                                      width: cropSize,
                                      height: cropSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: context.radius.lg,
                                        border: Border.all(
                                          color: brand.purple.withValues(alpha: 0.18),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          InteractiveViewer(
                                            transformationController:
                                                _transformationController,
                                            minScale: 1.0,
                                            maxScale: 4.0,
                                            panEnabled: true,
                                            scaleEnabled: true,
                                            boundaryMargin: EdgeInsets.zero,
                                            clipBehavior: Clip.hardEdge,
                                            constrained: false,
                                            onInteractionUpdate: (_) =>
                                                _clampTransform(),
                                            onInteractionEnd: (_) =>
                                                _clampTransform(),
                                            child: SizedBox(
                                              width: _effectiveDisplayImageSize!.width,
                                              height: _effectiveDisplayImageSize!.height,
                                              child: Center(
                                                child: Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.identity()
                                                    ..scaleByDouble(
                                                      _flipHorizontal ? -1.0 : 1.0,
                                                      _flipVertical ? -1.0 : 1.0,
                                                      1.0,
                                                      1.0,
                                                    )
                                                    ..rotateZ(_quarterTurns * math.pi / 2),
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
                                            ),
                                          ),
                                          IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius: context.radius.lg,
                                                border: Border.all(
                                                  color: brand.purple.withValues(alpha: 0.30),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: spacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _EditorIconButton(
                                  icon: Icons.rotate_left_rounded,
                                  backgroundColor: brand.pink,
                                  foregroundColor: Colors.white,
                                  onTap: _rotateLeft,
                                ),
                                SizedBox(width: spacing.m),
                                _EditorIconButton(
                                  icon: Icons.rotate_right_rounded,
                                  backgroundColor: brand.purple,
                                  foregroundColor: Colors.white,
                                  onTap: _rotateRight,
                                ),
                                SizedBox(width: spacing.m),
                                _EditorIconButton(
                                  icon: Icons.flip_rounded,
                                  backgroundColor: brand.pink,
                                  foregroundColor: Colors.white,
                                  onTap: _toggleFlipHorizontal,
                                ),
                                SizedBox(width: spacing.m),
                                _EditorIconButton(
                                  icon: Icons.swap_vert_rounded,
                                  backgroundColor: brand.purple,
                                  foregroundColor: Colors.white,
                                  onTap: _toggleFlipVertical,
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.xl),
                            Label(
                              'Drag to reposition and pinch to zoom inside the crop frame.',
                              variant: LabelVariant.body,
                              align: TextAlign.center,
                              color: onSurfaceSoft,
                              uppercase: false,
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

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: foregroundColor,
          size: 24,
        ),
      ),
    );
  }
}
