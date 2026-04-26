import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/error/app_exceptions.dart';

class AndroidBreedModelService {
  static const MethodChannel _channel = MethodChannel('fursure/breed_native');

  ByteData? _cachedModelData;
  bool _isLoaded = false;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;

    final data =
        _cachedModelData ??= await rootBundle.load(AppConfig.breedModelAssetPath);

    try {
      await _channel.invokeMethod<void>('loadBreedModel', {
        'modelBytes': data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
      });
      _isLoaded = true;
    } on PlatformException catch (e) {
      _isLoaded = false;
      throw ModelLoadException(
        'Failed to load model: ${e.message ?? e.code}',
      );
    }
  }

  Future<List<double>> run(Uint8List inputBytes) async {
    await ensureLoaded();

    try {
      final output = await _channel.invokeListMethod<num>('runBreedModel', {
        'inputBytes': inputBytes,
      });

      if (output == null || output.isEmpty) {
        throw const InferenceException('Breed inference returned no output.');
      }

      return output.map((value) => value.toDouble()).toList(growable: false);
    } on PlatformException catch (e) {
      if ((e.message ?? '').contains('not loaded')) {
        _isLoaded = false;
      }
      throw InferenceException(
        'Inference failed: ${e.message ?? e.code}',
      );
    }
  }
}
