import 'package:flutter_test/flutter_test.dart';

import 'package:fursure/core/error/app_exceptions.dart';
import 'package:fursure/services/tflite_service.dart';

void main() {
  group('TfliteService', () {
    late TfliteService service;

    setUp(() {
      service = TfliteService();
    });

    tearDown(() {
      service.dispose();
    });

    test('interpreter getter throws InferenceException when no model loaded', () {
      expect(
        () => service.interpreter,
        throwsA(isA<InferenceException>()),
      );
    });
  });
}
