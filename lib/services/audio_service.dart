import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
    if (Platform.isAndroid && ext != 'wav') {
      return false;
    }
    return _supportedExtensions.contains(ext);
  }

  void assertSupportedUpload(File file) {
    if (!isSupportedUpload(file)) {
      if (Platform.isAndroid) {
        throw const InferenceException(
          'Please upload a WAV file on this device.',
        );
      }
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

    final copiedPrepared = await _copyPreparedWavToTempIfPossible(
      inputFile,
      tempPrefix: 'fursure_audio_',
      filePrefix: 'prepared_',
    );
    if (copiedPrepared != null) {
      return copiedPrepared;
    }

    final normalizedPrepared = await _normalizeWavToTempIfPossible(
      inputFile,
      tempPrefix: 'fursure_audio_',
      filePrefix: 'prepared_',
    );
    if (normalizedPrepared != null) {
      return normalizedPrepared;
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

    final copiedPrepared = await _copyPreparedWavToTempIfPossible(
      inputFile,
      tempPrefix: 'fursure_editor_',
      filePrefix: 'editable_',
    );
    if (copiedPrepared != null) {
      return copiedPrepared;
    }

    final normalizedPrepared = await _normalizeWavToTempIfPossible(
      inputFile,
      tempPrefix: 'fursure_editor_',
      filePrefix: 'editable_',
    );
    if (normalizedPrepared != null) {
      return normalizedPrepared;
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

    final copiedTrimmed = await _trimPreparedWavDirectly(
      inputFile: inputFile,
      start: start,
      end: end,
    );
    if (copiedTrimmed != null) {
      return copiedTrimmed;
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
      PredictionConstants.audioSampleRate.toString(),
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
    final wav = await _readDecodedWavIfPossible(wavFile);
    if (wav != null) {
      final seconds = wav.frameCount / wav.sampleRate;
      return Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
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

    final sampleCount = ((bytes.length - 44) / 2).floor();
    if (sampleCount <= 0) {
      return List<double>.filled(barCount, 0.15);
    }

    final bucketSize = (sampleCount / barCount).ceil().clamp(1, sampleCount);
    final peaks = List<double>.filled(barCount, 0.0);

    var sampleIndex = 0;
    for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
      final bucketIndex = math.min(sampleIndex ~/ bucketSize, barCount - 1);
      final sample = ByteData.sublistView(
        bytes,
        offset,
        offset + 2,
      ).getInt16(0, Endian.little);
      final normalized = sample.abs() / 32768.0;
      if (normalized > peaks[bucketIndex]) {
        peaks[bucketIndex] = normalized;
      }
      sampleIndex++;
    }

    return peaks
        .map((peak) => peak == 0.0 ? 0.15 : peak.clamp(0.08, 1.0))
        .toList(growable: false);
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

  Future<File?> _copyPreparedWavToTempIfPossible(
    File inputFile, {
    required String tempPrefix,
    required String filePrefix,
  }) async {
    final wav = await _readPreparedWavIfPossible(inputFile);
    if (wav == null) return null;

    final tempDir = await Directory.systemTemp.createTemp(tempPrefix);
    final tempPath = tempDir.path;
    final outputPath =
        '$tempPath${Platform.pathSeparator}$filePrefix${DateTime.now().millisecondsSinceEpoch}.wav';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(wav.bytes, flush: true);
    return outputFile;
  }

  Future<File?> _normalizeWavToTempIfPossible(
    File inputFile, {
    required String tempPrefix,
    required String filePrefix,
  }) async {
    final wav = await _readDecodedWavIfPossible(inputFile);
    if (wav == null) return null;

    final normalizedSamples = wav.toMonoPcm16Samples(
      targetSampleRate: PredictionConstants.audioSampleRate,
    );
    if (normalizedSamples == null || normalizedSamples.isEmpty) {
      return null;
    }

    final pcmData = Uint8List(normalizedSamples.length * 2);
    final pcmView = ByteData.sublistView(pcmData);
    for (var i = 0; i < normalizedSamples.length; i++) {
      pcmView.setInt16(i * 2, normalizedSamples[i], Endian.little);
    }

    final rebuilt = _buildPcmWavBytes(
      sampleRate: PredictionConstants.audioSampleRate,
      numChannels: 1,
      bitsPerSample: 16,
      pcmData: pcmData,
    );

    final tempDir = await Directory.systemTemp.createTemp(tempPrefix);
    final outputPath =
        '${tempDir.path}${Platform.pathSeparator}$filePrefix${DateTime.now().millisecondsSinceEpoch}.wav';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(rebuilt, flush: true);
    return outputFile;
  }

  Future<File?> _trimPreparedWavDirectly({
    required File inputFile,
    required Duration start,
    required Duration end,
  }) async {
    final wav = await _readPreparedWavIfPossible(inputFile);
    if (wav == null) return null;

    final bytesPerSample = wav.bitsPerSample ~/ 8;
    final bytesPerFrame = bytesPerSample * wav.numChannels;
    final startFrame = ((start.inMicroseconds / Duration.microsecondsPerSecond) *
            wav.sampleRate)
        .floor();
    final endFrame = ((end.inMicroseconds / Duration.microsecondsPerSecond) *
            wav.sampleRate)
        .ceil();

    final clampedStartFrame = startFrame.clamp(0, wav.frameCount);
    final clampedEndFrame = endFrame.clamp(clampedStartFrame, wav.frameCount);
    final trimmedData = wav.dataBytes.sublist(
      clampedStartFrame * bytesPerFrame,
      clampedEndFrame * bytesPerFrame,
    );

    final rebuilt = _buildPcmWavBytes(
      sampleRate: wav.sampleRate,
      numChannels: wav.numChannels,
      bitsPerSample: wav.bitsPerSample,
      pcmData: trimmedData,
    );

    final tempDir = await Directory.systemTemp.createTemp('fursure_trim_');
    final outputPath =
        '${tempDir.path}${Platform.pathSeparator}trimmed_${DateTime.now().millisecondsSinceEpoch}.wav';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(rebuilt, flush: true);
    return outputFile;
  }

  Future<_PreparedWav?> _readPreparedWavIfPossible(File file) async {
    final wav = await _readDecodedWavIfPossible(file);
    if (wav == null ||
        wav.audioFormat != 1 ||
        wav.numChannels != 1 ||
        wav.sampleRate != PredictionConstants.audioSampleRate ||
        wav.bitsPerSample != 16) {
      return null;
    }

    return _PreparedWav(
      bytes: wav.bytes,
      dataBytes: wav.dataBytes,
      sampleRate: wav.sampleRate,
      numChannels: wav.numChannels,
      bitsPerSample: wav.bitsPerSample,
    );
  }

  Future<_DecodedWav?> _readDecodedWavIfPossible(File file) async {
    if (_extensionOf(file.path) != 'wav') return null;

    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return null;

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return null;

    int offset = 12;
    int dataOffset = -1;
    int dataSize = -1;
    int audioFormat = -1;
    int numChannels = -1;
    int sampleRate = -1;
    int bitsPerSample = -1;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = ByteData.sublistView(bytes, offset + 4, offset + 8)
          .getUint32(0, Endian.little);

      if (chunkId == 'fmt ') {
        if (offset + 8 + 16 > bytes.length) return null;
        final fmtData = ByteData.sublistView(
          bytes,
          offset + 8,
          math.min(offset + 8 + chunkSize, bytes.length),
        );
        audioFormat = fmtData.getUint16(0, Endian.little);
        numChannels = fmtData.getUint16(2, Endian.little);
        sampleRate = fmtData.getUint32(4, Endian.little);
        bitsPerSample = fmtData.getUint16(14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      offset += 8 + chunkSize;
      if (chunkSize.isOdd) {
        offset += 1;
      }
    }

    if (dataOffset < 0 ||
        dataSize <= 0 ||
        audioFormat < 0 ||
        numChannels <= 0 ||
        sampleRate <= 0 ||
        bitsPerSample <= 0) {
      return null;
    }

    final safeEnd = math.min(dataOffset + dataSize, bytes.length);
    final safeSize = safeEnd - dataOffset;
    final bytesPerSample = bitsPerSample ~/ 8;
    final blockAlign = bytesPerSample * numChannels;
    if (safeSize <= 0 || bytesPerSample <= 0 || blockAlign <= 0) {
      return null;
    }

    return _DecodedWav(
      bytes: bytes,
      dataBytes: Uint8List.sublistView(bytes, dataOffset, safeEnd),
      audioFormat: audioFormat,
      sampleRate: sampleRate,
      numChannels: numChannels,
      bitsPerSample: bitsPerSample,
    );
  }

  Uint8List _buildPcmWavBytes({
    required int sampleRate,
    required int numChannels,
    required int bitsPerSample,
    required Uint8List pcmData,
  }) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final fileSize = 36 + pcmData.length;

    final buffer = BytesBuilder(copy: false);
    void addAscii(String value) => buffer.add(value.codeUnits);
    void add16(int value) {
      final data = ByteData(2)..setUint16(0, value, Endian.little);
      buffer.add(data.buffer.asUint8List());
    }
    void add32(int value) {
      final data = ByteData(4)..setUint32(0, value, Endian.little);
      buffer.add(data.buffer.asUint8List());
    }

    addAscii('RIFF');
    add32(fileSize);
    addAscii('WAVE');
    addAscii('fmt ');
    add32(16);
    add16(1);
    add16(numChannels);
    add32(sampleRate);
    add32(byteRate);
    add16(blockAlign);
    add16(bitsPerSample);
    addAscii('data');
    add32(pcmData.length);
    buffer.add(pcmData);

    return buffer.toBytes();
  }

  Future<File> _transcodeToMonoWav(
    File inputFile, {
    required String tempPrefix,
    required String filePrefix,
    required String failureMessage,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp(tempPrefix);
    final tempPath = tempDir.path;
    final outputPath =
        '$tempPath${Platform.pathSeparator}$filePrefix${DateTime.now().millisecondsSinceEpoch}.wav';

    final command = [
      '-y',
      '-i',
      _quote(inputFile.path),
      '-vn',
      '-ac',
      '1',
      '-ar',
      PredictionConstants.audioSampleRate.toString(),
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

class _PreparedWav {
  const _PreparedWav({
    required this.bytes,
    required this.dataBytes,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
  });

  final Uint8List bytes;
  final Uint8List dataBytes;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;

  int get frameCount => dataBytes.length ~/ (numChannels * (bitsPerSample ~/ 8));
}

class _DecodedWav {
  const _DecodedWav({
    required this.bytes,
    required this.dataBytes,
    required this.audioFormat,
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
  });

  final Uint8List bytes;
  final Uint8List dataBytes;
  final int audioFormat;
  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;

  int get bytesPerSample => bitsPerSample ~/ 8;
  int get blockAlign => bytesPerSample * numChannels;
  int get frameCount => blockAlign == 0 ? 0 : dataBytes.length ~/ blockAlign;

  Int16List? toMonoPcm16Samples({required int targetSampleRate}) {
    final monoSamples = _decodeMonoSamples();
    if (monoSamples == null || monoSamples.isEmpty) return null;

    final sourceRate = sampleRate.toDouble();
    final targetRate = targetSampleRate.toDouble();
    if (sourceRate <= 0 || targetRate <= 0) return null;

    if (sampleRate == targetSampleRate) {
      return _toPcm16(monoSamples);
    }

    final targetLength = math.max(
      1,
      (monoSamples.length * targetRate / sourceRate).round(),
    );
    final resampled = Float64List(targetLength);
    for (var i = 0; i < targetLength; i++) {
      final sourceIndex = i * sourceRate / targetRate;
      final leftIndex = sourceIndex.floor().clamp(0, monoSamples.length - 1);
      final rightIndex = math.min(leftIndex + 1, monoSamples.length - 1);
      final t = sourceIndex - leftIndex;
      resampled[i] =
          (monoSamples[leftIndex] * (1 - t)) + (monoSamples[rightIndex] * t);
    }
    return _toPcm16(resampled);
  }

  Float64List? _decodeMonoSamples() {
    if (audioFormat != 1 && audioFormat != 3) {
      return null;
    }
    if (bytesPerSample <= 0 || blockAlign <= 0 || frameCount <= 0) {
      return null;
    }

    final view = ByteData.sublistView(dataBytes);
    final mono = Float64List(frameCount);
    for (var frame = 0; frame < frameCount; frame++) {
      final frameOffset = frame * blockAlign;
      var sum = 0.0;
      for (var channel = 0; channel < numChannels; channel++) {
        final sampleOffset = frameOffset + (channel * bytesPerSample);
        sum += _decodeSample(view, sampleOffset);
      }
      mono[frame] = (sum / numChannels).clamp(-1.0, 1.0);
    }
    return mono;
  }

  double _decodeSample(ByteData view, int offset) {
    if (audioFormat == 1) {
      switch (bitsPerSample) {
        case 8:
          return ((view.getUint8(offset) - 128) / 128.0).clamp(-1.0, 1.0);
        case 16:
          return (view.getInt16(offset, Endian.little) / 32768.0).clamp(-1.0, 1.0);
        case 24:
          final b0 = dataBytes[offset];
          final b1 = dataBytes[offset + 1];
          final b2 = dataBytes[offset + 2];
          var value = b0 | (b1 << 8) | (b2 << 16);
          if ((value & 0x800000) != 0) {
            value |= ~0xFFFFFF;
          }
          return (value / 8388608.0).clamp(-1.0, 1.0);
        case 32:
          return (view.getInt32(offset, Endian.little) / 2147483648.0)
              .clamp(-1.0, 1.0);
      }
    } else if (audioFormat == 3 && bitsPerSample == 32) {
      return view.getFloat32(offset, Endian.little).clamp(-1.0, 1.0);
    }
    return 0.0;
  }

  Int16List _toPcm16(Float64List samples) {
    final pcm = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    }
    return pcm;
  }
}
