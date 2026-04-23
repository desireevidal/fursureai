import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  ScanStep _step = ScanStep.photo;
  ScanSession _session = const ScanSession();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listenManual(scanPredictionControllerProvider, (previous, next) {
      next.whenData((result) {
        if (result != null) {
          setState(() {
            _session = _session.copyWith(pendingRecord: result.pendingRecord);
            _step = ScanStep.results;
          });
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() {
        _session = _session.copyWith(selectedImage: File(picked.path));
        _step = ScanStep.audio;
      });
    }
  }

  void _onAudioSelected(String path) {
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
    setState(() {
      _session = const ScanSession();
      _step = ScanStep.photo;
    });
  }

  Future<void> _editCatName() async {
    final controller = TextEditingController(text: _session.catName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cat name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
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
    if (mounted) context.go('/history');
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
        onRetake: _retake,
        onBack: () => setState(() => _step = ScanStep.audio),
      ),
      ScanStep.loading => const ScanLoadingStep(),
      ScanStep.results => ScanResultsStep(
        catName: _session.catName,
        selectedImage: _session.selectedImage,
        predictionResult: ref.watch(scanPredictionControllerProvider).asData?.value,
        onEditName: _editCatName,
        onSave: _saveAndDone,
        onCancel: _retake,
      ),
    };
  }
}
