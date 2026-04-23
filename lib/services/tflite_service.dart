import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../core/error/app_exceptions.dart';

/// Manages a single TFLite [Interpreter] lifecycle.
///
/// Responsibility: load, cache, and close the interpreter.
/// Inference execution is handled separately by [InferenceRunner].
class TfliteService {
  Interpreter? _interpreter;
  String? _loadedModelPath;

  /// The loaded interpreter. Throws [InferenceException] if no model has been
  /// loaded yet via [loadModel].
  Interpreter get interpreter {
    final i = _interpreter;
    if (i == null) throw const InferenceException('No model loaded');
    return i;
  }

  /// Loads the model at [modelPath]. No-ops if the same path is already loaded.
  Future<void> loadModel(String modelPath) async {
    if (_loadedModelPath == modelPath && _interpreter != null) return;

    try {
      _interpreter?.close();
      _interpreter = Interpreter.fromFile(File(modelPath));
      _loadedModelPath = modelPath;
    } catch (e) {
      throw ModelLoadException('Failed to load model: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loadedModelPath = null;
  }
}
