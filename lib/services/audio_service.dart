import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../core/error/app_exceptions.dart';
import '../features/prediction/data/prediction_constants.dart';

class AudioService {
  AudioService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  bool _isRecording = false;

  static const Set<String> _supportedExtensions = {
    'wav',
    'm4a',
    'mp3',
  };

  bool get isRecording => _isRecording;

  Future<void> startRecording(String filePath) async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw const PermissionDeniedException('Microphone permission denied');
    }

    if (_isRecording) return;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: PredictionConstants.audioSampleRate,
        numChannels: 1,
      ),
      path: filePath,
    );
    _isRecording = true;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  Future<Amplitude?> getAmplitude() async {
    if (!_isRecording) return null;
    return _recorder.getAmplitude();
  }

  bool isSupportedUpload(File file) {
    final ext = _extensionOf(file.path);
    return _supportedExtensions.contains(ext);
  }

  void assertSupportedUpload(File file) {
    if (!isSupportedUpload(file)) {
      throw const InferenceException(
        'Unsupported file. Please upload a WAV, M4A, or MP3 file.',
      );
    }
  }

  Future<File> prepareAudioForInference(File inputFile) async {
    assertSupportedUpload(inputFile);

    if (!await inputFile.exists()) {
      throw const InferenceException('Selected audio file was not found.');
    }

    final tempDir = await Directory.systemTemp.createTemp('fursure_audio_');
    final outputPath =
        '${tempDir.path}/prepared_${DateTime.now().millisecondsSinceEpoch}.wav';

    final command = [
      '-y',
      '-i',
      _quote(inputFile.path),
      '-vn',
      '-ac',
      '1',
      '-ar',
      '${PredictionConstants.audioSampleRate}',
      '-c:a',
      'pcm_s16le',
      _quote(outputPath),
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw const InferenceException(
        'Could not read this audio file. Please try another file.',
      );
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw const InferenceException(
        'Could not read this audio file. Please try another file.',
      );
    }

    return outputFile;
  }

  Future<void> deletePreparedAudio(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }

      final parent = file.parent;
      if (await parent.exists()) {
        final remaining = parent.listSync();
        if (remaining.isEmpty) {
          await parent.delete();
        }
      }
    } catch (_) {
      // ignore cleanup failures
    }
  }

  Future<void> dispose() async {
    if (_isRecording) await _recorder.stop();
    _recorder.dispose();
  }

  String _extensionOf(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return '';
    return path.substring(dotIndex + 1).toLowerCase();
  }

  String _quote(String path) {
    final escaped = path.replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
