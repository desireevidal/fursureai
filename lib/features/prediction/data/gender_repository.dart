import 'dart:io';

import 'package:fursure/core/config/app_config.dart';
import 'package:fursure/core/ml/audio_preprocessor.dart';
import 'package:fursure/core/ml/inference_runner.dart';
import 'package:fursure/services/audio_service.dart';
import 'package:fursure/services/model_download_service.dart';
import 'package:fursure/services/tflite_service.dart';

import 'gender_result.dart';

class GenderRepository {
  GenderRepository({
    required this.tfliteService,
    required this.inferenceRunner,
    required this.modelDownloadService,
    required this.audioPreprocessor,
    required this.audioService,
  });

  final TfliteService tfliteService;
  final InferenceRunner inferenceRunner;
  final ModelDownloadService modelDownloadService;
  final AudioPreprocessor audioPreprocessor;
  final AudioService audioService;

  Future<GenderResult> predict(File audioFile) async {
    final modelPath =
        await modelDownloadService.ensureModel(AppConfig.genderSpec);
    await tfliteService.loadModel(modelPath);

    final preparedAudio = await audioService.prepareAudioForInference(audioFile);

    try {
      final input = audioPreprocessor.extractFeatures(preparedAudio);
      final output = inferenceRunner.run(input);
      return _parseOutput(output);
    } finally {
      await audioService.deletePreparedAudio(preparedAudio);
    }
  }

  GenderResult _parseOutput(List<double> output) {
    final pMale = output[0];
    if (pMale >= 0.5) {
      return GenderResult(gender: 'Male', confidence: pMale);
    } else {
      return GenderResult(gender: 'Female', confidence: 1.0 - pMale);
    }
  }
}
