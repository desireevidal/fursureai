import 'dart:io';

import 'package:fursure/core/ml/image_preprocessor.dart';
import 'package:fursure/core/ml/inference_runner.dart';
import 'package:fursure/core/config/app_config.dart';
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
  });

  final TfliteService tfliteService;
  final InferenceRunner inferenceRunner;
  final ModelDownloadService modelDownloadService;
  final ImagePreprocessor imagePreprocessor;

  Future<BreedResult> predict(File imageFile) async {
    final modelPath = await modelDownloadService.ensureModel(AppConfig.breedSpec);
    await tfliteService.loadModel(modelPath);

    final input = imagePreprocessor.preprocess(imageFile);
    final output = inferenceRunner.run(input);

    return _parseOutput(output);
  }

  BreedResult _parseOutput(List<double> output) {
    var maxIndex = 0;
    var maxVal = output[0];
    for (var i = 1; i < output.length; i++) {
      if (output[i] > maxVal) {
        maxVal = output[i];
        maxIndex = i;
      }
    }

    final label = maxIndex < PredictionConstants.breedLabels.length
        ? PredictionConstants.breedLabels[maxIndex]
        : 'Unknown';

    return BreedResult(breed: label, confidence: maxVal);
  }
}
