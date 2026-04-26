import '../error/app_exceptions.dart';
import '../../services/tflite_service.dart';

class InferenceRunner {
  const InferenceRunner(this._tfliteService);

  final TfliteService _tfliteService;

  List<double> run(List<dynamic> input) {
    try {
      final interpreter = _tfliteService.interpreter;
      final outputShape = interpreter.getOutputTensor(0).shape;
      final outputBuffer = _createOutputBuffer(outputShape);

      interpreter.run(input, outputBuffer);
      return _flattenOutput(outputBuffer);
    } on InferenceException {
      rethrow;
    } catch (e) {
      throw InferenceException('Inference failed: $e');
    }
  }

  dynamic _createOutputBuffer(List<int> shape, [int depth = 0]) {
    if (shape.isEmpty) return 0.0;
    final dimension = shape[depth];
    if (depth == shape.length - 1) {
      return List<double>.filled(dimension, 0.0, growable: false);
    }
    return List.generate(
      dimension,
      (_) => _createOutputBuffer(shape, depth + 1),
      growable: false,
    );
  }

  List<double> _flattenOutput(dynamic value) {
    if (value is num) {
      return [value.toDouble()];
    }
    if (value is List) {
      return value.expand<double>((item) => _flattenOutput(item)).toList();
    }
    throw InferenceException('Inference failed: unsupported output type.');
  }
}
