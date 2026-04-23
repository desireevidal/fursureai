import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../features/prediction/data/prediction_constants.dart';
import '../core/error/app_exceptions.dart';

class AudioService {
  AudioService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  bool _isRecording = false;

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

  /// Returns the current amplitude in dBFS (negative values, 0 = max).
  /// Returns null if not recording.
  Future<Amplitude?> getAmplitude() async {
    if (!_isRecording) return null;
    return _recorder.getAmplitude();
  }

  Future<void> dispose() async {
    if (_isRecording) await _recorder.stop();
    _recorder.dispose();
  }
}
