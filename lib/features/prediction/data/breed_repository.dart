import 'dart:io';

import 'package:fursure/core/config/app_config.dart';
import 'package:fursure/core/ml/image_preprocessor.dart';
import 'package:fursure/core/ml/inference_runner.dart';
import 'package:fursure/services/android_breed_model_service.dart';
import 'package:fursure/services/model_download_service.dart';
import 'package:fursure/services/tflite_service.dart';

import 'breed_result.dart';
import 'prediction_constants.dart';

class BreedRepository {
  BreedRepository({
    required this.tfliteService,
    required this.inferenceRunner,
    required this.modelDownloadService,
    required this.imagePreprocessor,
    this.androidBreedModelService,
  });

  final TfliteService tfliteService;
  final InferenceRunner inferenceRunner;
  final ModelDownloadService modelDownloadService;
  final ImagePreprocessor imagePreprocessor;
  final AndroidBreedModelService? androidBreedModelService;

  Future<BreedResult> predict(File imageFile) async {
    if (Platform.isAndroid && androidBreedModelService != null) {
      final inputBytes = imagePreprocessor.preprocessBytes(imageFile);
      final output = await androidBreedModelService!.run(inputBytes);
      return _parseOutput(output);
    }

    final modelPath = await modelDownloadService.ensureModel(AppConfig.breedSpec);
    await tfliteService.loadModel(modelPath);

    final input = imagePreprocessor.preprocess(imageFile);
    final output = inferenceRunner.run(input);

    return _parseOutput(output);
  }

  BreedResult _parseOutput(List<double> output) {
    if (output.isEmpty) {
      return const BreedResult(
        breed: 'Unknown',
        confidence: 0.0,
      );
    }

    final indexedScores = <_IndexedScore>[
      for (var i = 0; i < output.length; i++) _IndexedScore(i, output[i]),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final top1 = indexedScores[0];
    final top2 = indexedScores.length > 1 ? indexedScores[1] : null;

    return BreedResult(
      breed: _labelFor(top1.index),
      confidence: top1.score,
      secondaryBreed: top2 != null ? _labelFor(top2.index) : null,
      secondaryConfidence: top2?.score,
    );
  }

  String _labelFor(int index) {
    if (index < 0 || index >= PredictionConstants.breedLabels.length) {
      return 'Unknown';
    }
    return PredictionConstants.breedLabels[index];
  }
}

class _IndexedScore {
  const _IndexedScore(this.index, this.score);

  final int index;
  final double score;
}
