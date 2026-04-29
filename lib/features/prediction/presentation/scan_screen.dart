import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fursure/core/error/app_exceptions.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_cat_name_dialog.dart';
import 'package:fursure/core/widgets/app_confirmation_dialog.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/results/presentation/results_controller.dart';
import 'scan_prediction_controller.dart';
import 'scan_session.dart';
import 'scan_step.dart';
import 'widgets/scan_audio_recorder.dart';
import 'widgets/scan_loading_step.dart';
import 'widgets/scan_photo_step.dart';
import 'widgets/scan_preview_step.dart';
import 'widgets/scan_results_step.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  static const Set<String> _acceptedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  ScanStep _step = ScanStep.photo;
  ScanSession _session = const ScanSession();
  late final ProviderSubscription<AsyncValue<ScanPredictionResult?>>
      _predictionListener;

  @override
  void initState() {
    super.initState();
    _predictionListener = ref.listenManual(
      scanPredictionControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (result) {
            if (result != null && mounted) {
              setState(() {
                _session = _session.copyWith(pendingRecord: result.pendingRecord);
                _step = ScanStep.results;
              });
            }
          },
          error: (error, _) async {
            final message = error is AppException ? error.message : '$error';
            if (!mounted) {
              return;
            }

            if (message.startsWith('No meow detected')) {
              await _showNoMeowDetectedDialog();
              if (!mounted) return;

              ref.invalidate(scanPredictionControllerProvider);
              setState(() {
                _session = _session.copyWith(
                  clearAudioPath: true,
                  clearPendingRecord: true,
                );
                _step = ScanStep.audio;
              });
              return;
            }

            await _showBreedPredictionErrorDialog(message);
            if (!mounted) return;

            ref.invalidate(scanPredictionControllerProvider);
            setState(() {
              _session = _session.copyWith(clearPendingRecord: true);
              _step = ScanStep.photo;
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _predictionListener.close();
    _deleteSessionAudioFile(_session.audioPath);
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) {
      return;
    }

    if (!_hasAcceptedExtension(picked.path, _acceptedImageExtensions)) {
      return;
    }

    setState(() {
      _session = _session.copyWith(selectedImage: File(picked.path));
      _step = ScanStep.audio;
    });
  }

  void _onAudioSelected(String path) {
    _deleteSessionAudioFile(_session.audioPath, exceptPath: path);
    setState(() {
      _session = _session.copyWith(audioPath: path);
      _step = ScanStep.preview;
    });
  }

  void _onConfirmPreview() {
    setState(() => _step = ScanStep.loading);
    ref.read(scanPredictionControllerProvider.notifier).predict(
      image: _session.selectedImage,
      audioPath: _session.audioPath,
      catName: _session.catName,
    );
  }

  void _retake() {
    _deleteSessionAudioFile(_session.audioPath);
    setState(() {
      _session = const ScanSession();
      _step = ScanStep.photo;
    });
  }

  Future<void> _handlePreviewNo() async {
    final shouldRerecord = await showAppConfirmationDialog(
      context,
      title: 'Rerecord meow?',
      message: 'Would you like to rerecord the meow for this cat?',
      cancelLabel: 'Take Pic Again',
      confirmLabel: 'Rerecord',
    );

    if (!mounted) return;

    if (shouldRerecord == true) {
      _deleteSessionAudioFile(_session.audioPath);
      setState(() {
        _session = _session.copyWith(
          clearAudioPath: true,
          clearPendingRecord: true,
        );
        _step = ScanStep.audio;
      });
      return;
    }

    if (shouldRerecord == false) {
      _retake();
    }
  }

  Future<void> _editCatName() async {
    final result = await showAppCatNameDialog(
      context,
      initialName: _session.catName,
    );
    if (result != null && result.trim().isNotEmpty) {
      final trimmedName = result.trim();
      setState(() {
        _session = _session.copyWith(
          catName: trimmedName,
          pendingRecord: _session.pendingRecord?.copyWith(catName: trimmedName),
        );
      });
    }
  }

  Future<void> _saveAndDone() async {
    final record = _session.pendingRecord;
    if (record != null) {
      await ref.read(resultsControllerProvider.notifier).saveResult(record);
    }
    _deleteSessionAudioFile(_session.audioPath);
    if (mounted) context.go('/history');
  }

  Future<void> _confirmDiscardResult() async {
    final shouldDiscard = await showAppConfirmationDialog(
      context,
      title: 'Discard Result?',
      message: 'This result will be discarded if you leave without saving it.',
      cancelLabel: 'Keep Result',
      confirmLabel: 'Discard',
    );

    if (shouldDiscard == true && mounted) {
      _retake();
    }
  }

  Future<void> _deleteSessionAudioFile(
    String? path, {
    String? exceptPath,
  }) async {
    if (path == null || path == exceptPath) {
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore cleanup failures
    }
  }

  Future<void> _showNoMeowDetectedDialog() {
    final spacing = context.spacing;
    final brand = context.brand;
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.xl,
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.m,
            spacing.lg,
            spacing.lg,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: context.radius.lg,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.mic_off_rounded,
                size: 36,
                color: brand.pink,
              ),
              SizedBox(height: spacing.sm),
              const Label(
                'No Meow Detected',
                variant: LabelVariant.title,
                size: 20,
                weight: FontWeight.w800,
                align: TextAlign.center,
                uppercase: false,
              ),
              SizedBox(height: spacing.sm),
              Label(
                'We could not detect a clear meow in the recording. Please try again and capture a short, audible meow.',
                variant: LabelVariant.body,
                align: TextAlign.center,
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
                uppercase: false,
              ),
              SizedBox(height: spacing.lg),
              Button(
                label: 'Try Again',
                backgroundColor: brand.pink,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBreedPredictionErrorDialog(String message) {
    final spacing = context.spacing;
    final brand = context.brand;
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.xl,
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.m,
            spacing.lg,
            spacing.lg,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: context.radius.lg,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.image_not_supported_outlined,
                size: 36,
                color: brand.pink,
              ),
              SizedBox(height: spacing.sm),
              const Label(
                'Breed Prediction Failed',
                variant: LabelVariant.title,
                size: 20,
                weight: FontWeight.w800,
                align: TextAlign.center,
                uppercase: false,
              ),
              SizedBox(height: spacing.sm),
              Label(
                message,
                variant: LabelVariant.body,
                align: TextAlign.center,
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
                uppercase: false,
              ),
              SizedBox(height: spacing.lg),
              Button(
                label: 'Try Again',
                backgroundColor: brand.pink,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasAcceptedExtension(String path, Set<String> extensions) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return false;
    }

    final ext = path.substring(dotIndex + 1).toLowerCase();
    return extensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      ScanStep.photo => ScanPhotoStep(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
        onBack: () => Navigator.of(context).maybePop(),
      ),
      ScanStep.audio => ScanAudioRecorder(
        onAudioSelected: _onAudioSelected,
        onBack: () => setState(() => _step = ScanStep.photo),
      ),
      ScanStep.preview => ScanPreviewStep(
        selectedImage: _session.selectedImage,
        audioPath: _session.audioPath,
        onConfirm: _onConfirmPreview,
        onRetake: _handlePreviewNo,
        onBack: () => setState(() => _step = ScanStep.audio),
      ),
      ScanStep.loading => const ScanLoadingStep(),
      ScanStep.results => ScanResultsStep(
        catName: _session.catName,
        selectedImage: _session.selectedImage,
        predictionResult: ref.watch(scanPredictionControllerProvider).asData?.value,
        onEditName: _editCatName,
        onSave: _saveAndDone,
        onCancel: _confirmDiscardResult,
      ),
    };
  }
}
