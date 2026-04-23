import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:fursure/features/prediction/data/breed_repository.dart';
import 'package:fursure/core/ml/image_preprocessor.dart';
import 'package:fursure/core/ml/inference_runner.dart';
import 'package:fursure/services/model_download_service.dart';
import 'package:fursure/core/config/model_spec.dart';
import 'package:fursure/services/tflite_service.dart';

/// Captures the input tensor passed to [InferenceRunner.run] so tests can
/// assert on the preprocessing output without loading a real TFLite model.
class _CapturingInferenceRunner extends InferenceRunner {
  _CapturingInferenceRunner() : super(_NoOpTfliteService());

  List<dynamic>? capturedInput;

  @override
  List<double> run(List<dynamic> input) {
    capturedInput = input;
    return <double>[1.0, 0.0, 0.0];
  }
}

class _NoOpTfliteService extends TfliteService {
  @override
  Future<void> loadModel(String modelPath) async {}
}

class _FakeModelDownloadService extends ModelDownloadService {
  @override
  Future<String> ensureModel(ModelSpec spec) async => '/tmp/breed_model.tflite';
}

List<double> _flattenNumbers(Object value) {
  if (value is num) return <double>[value.toDouble()];
  if (value is List<dynamic>) {
    return value
        .expand<double>((dynamic item) => _flattenNumbers(item))
        .toList();
  }
  throw StateError('Unsupported tensor value: $value');
}

void main() {
  group('BreedRepository preprocessing', () {
    test('passes raw 0 to 255 RGB floats to EfficientNet input', () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'breed_repository_test',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final File imageFile = File('${tempDirectory.path}/pixel.png');
      final img.Image image = img.Image(width: 1, height: 1);
      image.setPixelRgb(0, 0, 255, 128, 64);
      await imageFile.writeAsBytes(img.encodePng(image));

      final runner = _CapturingInferenceRunner();
      final BreedRepository repository = BreedRepository(
        tfliteService: _NoOpTfliteService(),
        inferenceRunner: runner,
        modelDownloadService: _FakeModelDownloadService(),
        imagePreprocessor: const ImagePreprocessor(),
      );

      await repository.predict(imageFile);

      final List<double> flattened = _flattenNumbers(runner.capturedInput!);

      expect(flattened[0], 255.0);
      expect(flattened[1], 128.0);
      expect(flattened[2], 64.0);
    });
  });
}
