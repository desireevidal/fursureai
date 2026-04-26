import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../features/prediction/data/prediction_constants.dart';

class ImagePreprocessor {
  const ImagePreprocessor();

  static const int _size = PredictionConstants.imageInputSize;

  List<dynamic> preprocess(File imageFile) {
    return preprocessFlat(imageFile).reshape([1, _size, _size, 3]);
  }

  Uint8List preprocessBytes(File imageFile) {
    final input = preprocessFlat(imageFile);
    return input.buffer.asUint8List();
  }

  Float32List preprocessFlat(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(
      image,
      width: _size,
      height: _size,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * _size * _size * 3);
    var index = 0;
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r.toDouble();
        input[index++] = pixel.g.toDouble();
        input[index++] = pixel.b.toDouble();
      }
    }

    return input;
  }
}
