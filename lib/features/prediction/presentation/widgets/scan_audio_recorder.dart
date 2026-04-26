import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/buttons.dart';
import 'package:fursure/providers/app_providers.dart';
import 'package:fursure/features/prediction/data/prediction_constants.dart';
import 'prediction_step_layout.dart';
import 'scan_tips_sheet.dart';

class ScanAudioRecorder extends ConsumerStatefulWidget {
  const ScanAudioRecorder({
    super.key,
    required this.onAudioSelected,
    required this.onBack,
  });

  final ValueChanged<String> onAudioSelected;
  final VoidCallback onBack;

  @override
  ConsumerState<ScanAudioRecorder> createState() => _ScanAudioRecorderState();
}

class _ScanAudioRecorderState extends ConsumerState<ScanAudioRecorder>
    with SingleTickerProviderStateMixin {
  static const Set<String> _acceptedAudioExtensions = {
    'wav',
    'mp3',
    'm4a',
    'aac',
    'ogg',
  };

  bool _isRecording = false;
  double _currentAmplitude = 0.0;

  late final AnimationController _pulseController;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _autoStopTimer;
  Timer? _amplitudeTimer;

  static const _minRecordDuration = Duration(
    seconds: PredictionConstants.audioMinDurationSeconds,
  );
  static const _maxRecordDuration = Duration(
    seconds: PredictionConstants.audioMaxDurationSeconds,
  );

  bool get _canStop => _stopwatch.elapsed >= _minRecordDuration;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoStopTimer?.cancel();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      if (!_canStop) return;
      await _stopRecording();
    } else {
      final audioService = ref.read(audioServiceProvider);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/meow_${DateTime.now().millisecondsSinceEpoch}.wav';
      await audioService.startRecording(path);
      _pulseController.repeat();
      _stopwatch.reset();
      _stopwatch.start();
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 80), (_) async {
        final amp = await audioService.getAmplitude();
        if (amp != null && mounted) {
          final normalized = ((amp.current + 50) / 50).clamp(0.0, 1.0);
          setState(() => _currentAmplitude = normalized);
        }
      });
      _autoStopTimer = Timer(_maxRecordDuration, () {
        if (mounted && _isRecording) _stopRecording();
      });
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    _pulseController.stop();
    _pulseController.reset();
    _autoStopTimer?.cancel();
    _amplitudeTimer?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() {
      _isRecording = false;
      _currentAmplitude = 0.0;
    });
    final audioService = ref.read(audioServiceProvider);
    final path = await audioService.stopRecording();
    if (path != null && mounted) {
      widget.onAudioSelected(path);
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _pickerExtensions(),
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    if (!_hasAcceptedExtension(path)) {
      return;
    }

    widget.onAudioSelected(path);
  }

  bool _hasAcceptedExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return false;
    }

    return _acceptedAudioExtensions.contains(
      path.substring(dotIndex + 1).toLowerCase(),
    );
  }

  List<String> _pickerExtensions() {
    final extensions = <String>{
      ..._acceptedAudioExtensions,
      ..._acceptedAudioExtensions.map((ext) => ext.toUpperCase()),
    }.toList();
    extensions.sort();
    return extensions;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final illustration = SvgPicture.asset(
      'assets/images/cat_record_illustration.svg',
    );

    return PredictionStepLayout(
      title: 'Record a Meow',
      subtitle: _isRecording
          ? 'Listening\u2026 Tap Stop when done.'
          : 'Tap the button and let your cat speak!\n'
                'A 1\u20132 second meow works best.',
      illustration: _isRecording
          ? _AmplitudeRecordingIndicator(
              amplitude: _currentAmplitude,
              color: brand.softRed,
              child: illustration,
            )
          : illustration,
      onBack: widget.onBack,
      trailing: ScanTipsButton(
        onTap: () => showScanTipsSheet(
          context,
          type: ScanTipsType.meow,
        ),
      ),
      actions: [
        Button(
          label: _isRecording ? 'Stop Recording' : 'Start Recording',
          icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          backgroundColor: _isRecording ? brand.softRed : brand.pink,
          onPressed: _isRecording && !_canStop ? null : _toggleRecording,
          semanticLabel:
              _isRecording ? 'Stop recording audio' : 'Start recording a meow',
        ),
        if (!_isRecording)
          Button(
            label: 'Choose from Files',
            icon: Icons.folder_open_outlined,
            backgroundColor: brand.purple,
            onPressed: _pickAudioFile,
            semanticLabel: 'Choose an audio file from your device',
          ),
      ],
    );
  }
}

class _AmplitudeRecordingIndicator extends StatelessWidget {
  const _AmplitudeRecordingIndicator({
    required this.amplitude,
    required this.color,
    required this.child,
  });

  final double amplitude;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final innerScale = 1.0 + amplitude * 0.08;
    final innerOpacity = (0.15 + amplitude * 0.35).clamp(0.0, 1.0);
    final outerOpacity = (0.08 + amplitude * 0.20).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(6 + amplitude * 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: innerOpacity),
          width: 3.0 + amplitude * 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: outerOpacity),
            blurRadius: 8 + amplitude * 20,
            spreadRadius: amplitude * 8,
          ),
        ],
      ),
      transform: Matrix4.diagonal3Values(innerScale, innerScale, 1.0),
      transformAlignment: Alignment.center,
      child: child,
    );
  }
}
