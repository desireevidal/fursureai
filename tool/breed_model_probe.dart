import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  final file = File('breed_model_probe.tflite');
  if (!file.existsSync()) {
    stderr.writeln('breed_model_probe.tflite not found');
    exitCode = 1;
    return;
  }

  final interpreter = Interpreter.fromFile(file);
  try {
    stdout.writeln('inputs: ${interpreter.getInputTensors().length}');
    stdout.writeln('outputs: ${interpreter.getOutputTensors().length}');
    final input = interpreter.getInputTensor(0);
    final output = interpreter.getOutputTensor(0);
    stdout.writeln('inputShape: ${input.shape}');
    stdout.writeln('inputType: ${input.type}');
    stdout.writeln('outputShape: ${output.shape}');
    stdout.writeln('outputType: ${output.type}');
  } finally {
    interpreter.close();
  }
}
