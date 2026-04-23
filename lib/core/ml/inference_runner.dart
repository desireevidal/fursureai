import '../error/app_exceptions.dart';
import '../../services/tflite_service.dart';

class InferenceRunner {
  const InferenceRunner(this._tfliteService);

  final TfliteService _tfliteService;

  List<double> run(List<dynamic> input) {
    try {
      final interpreter = _tfliteService.interpreter;
      final outputShape = interpreter.getOutputTensor(0).shape;
      final outputSize = outputShape.last;
      final outputBuffer = <dynamic>[List.filled(outputSize, 0.0)];

      interpreter.run(input, outputBuffer);
      return (outputBuffer[0] as List).cast<double>();
    } on InferenceException {
      rethrow;
    } catch (e) {
      throw InferenceException('Inference failed: $e');
    }
  }
}
