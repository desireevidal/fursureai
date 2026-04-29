import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
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
    'aac',
    'ogg',
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
        'Unsupported file. Please upload a WAV, M4A, MP3, AAC, or OGG file.',
      );
    }
  }

  Future<File> prepareAudioForInference(File inputFile) async {
    assertSupportedUpload(inputFile);

    if (!await inputFile.exists()) {
      throw const InferenceException('Selected audio file was not found.');
    }

    return _transcodeToMonoWav(
      inputFile,
      tempPrefix: 'fursure_audio_',
      filePrefix: 'prepared_',
      failureMessage: 'Could not read this audio file. Please try another file.',
    );
  }

  Future<File> prepareAudioForEditing(File inputFile) async {
    assertSupportedUpload(inputFile);

    if (!await inputFile.exists()) {
      throw const InferenceException('Selected audio file was not found.');
    }

    return _transcodeToMonoWav(
      inputFile,
      tempPrefix: 'fursure_editor_',
      filePrefix: 'editable_',
      failureMessage: 'Could not open this audio file for editing.',
    );
  }

  Future<File> trimPreparedAudio({
    required File inputFile,
    required Duration start,
    required Duration end,
  }) async {
    if (!await inputFile.exists()) {
      throw const InferenceException('Selected audio file was not found.');
    }

    final duration = end - start;
    if (duration <= Duration.zero) {
      throw const InferenceException('Please select a valid audio range.');
    }

    final tempDir = await Directory.systemTemp.createTemp('fursure_trim_');
    final outputPath =
        '${tempDir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.wav';

    final command = [
      '-y',
      '-ss',
      _formatFfmpegDuration(start),
      '-t',
      _formatFfmpegDuration(duration),
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
        'Could not save the trimmed meow. Please try again.',
      );
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw const InferenceException(
        'Could not save the trimmed meow. Please try again.',
      );
    }

    return outputFile;
  }

  Future<Duration> readWavDuration(File wavFile) async {
    final mediaInfoSession = await FFprobeKit.getMediaInformation(
      wavFile.path,
    );
    final mediaInformation = mediaInfoSession.getMediaInformation();
    final durationString = mediaInformation?.getDuration();
    final parsedSeconds = durationString == null
        ? null
        : double.tryParse(durationString);

    if (parsedSeconds != null && parsedSeconds > 0) {
      return Duration(
        microseconds: (parsedSeconds * Duration.microsecondsPerSecond).round(),
      );
    }

    final bytes = await wavFile.readAsBytes();
    if (bytes.length < 44) {
      throw const InferenceException('Could not read this audio file.');
    }

    final dataView = ByteData.sublistView(bytes);
    final byteRate = dataView.getUint32(28, Endian.little);
    final dataSize = dataView.getUint32(40, Endian.little);

    if (byteRate <= 0 || dataSize <= 0) {
      throw const InferenceException('Could not read this audio file.');
    }

    final seconds = dataSize / byteRate;
    return Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());
  }

  Future<List<double>> buildWaveformBars(
    File wavFile, {
    int barCount = 56,
  }) async {
    final bytes = await wavFile.readAsBytes();
    if (bytes.length <= 44 || barCount <= 0) {
      return List<double>.filled(barCount, 0.15);
    }

    final samples = <double>[];
    for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
      final sample = ByteData.sublistView(
        bytes,
        offset,
        offset + 2,
      ).getInt16(0, Endian.little);
      samples.add(sample.abs() / 32768.0);
    }

    if (samples.isEmpty) {
      return List<double>.filled(barCount, 0.15);
    }

    final bucketSize = (samples.length / barCount).ceil().clamp(1, samples.length);
    final bars = <double>[];

    for (var i = 0; i < barCount; i++) {
      final start = i * bucketSize;
      if (start >= samples.length) {
        bars.add(0.15);
        continue;
      }

      final end = (start + bucketSize).clamp(0, samples.length);
      var peak = 0.0;
      for (var j = start; j < end; j++) {
        if (samples[j] > peak) peak = samples[j];
      }
      bars.add(peak.clamp(0.08, 1.0));
    }

    return bars;
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

  Future<File> _transcodeToMonoWav(
    File inputFile, {
    required String tempPrefix,
    required String filePrefix,
    required String failureMessage,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp(tempPrefix);
    final outputPath =
        '${tempDir.path}${Platform.pathSeparator}${filePrefix}${DateTime.now().millisecondsSinceEpoch}.wav';

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
      throw InferenceException(failureMessage);
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw InferenceException(failureMessage);
    }

    return outputFile;
  }

  String _formatFfmpegDuration(Duration value) {
    final totalMilliseconds = value.inMilliseconds;
    final hours = (totalMilliseconds ~/ 3600000).toString().padLeft(2, '0');
    final minutes =
        ((totalMilliseconds % 3600000) ~/ 60000).toString().padLeft(2, '0');
    final seconds =
        ((totalMilliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final millis = (totalMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }
}
