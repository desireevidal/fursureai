import 'package:flutter_test/flutter_test.dart';

import 'package:fursure/features/prediction/data/breed_result.dart';

void main() {
  group('BreedResult', () {
    test('stores breed and confidence', () {
      const result = BreedResult(breed: 'Siamese', confidence: 0.95);
      expect(result.breed, 'Siamese');
      expect(result.confidence, 0.95);
    });

    test('toString formats correctly', () {
      const result = BreedResult(breed: 'Persian', confidence: 0.876);
      expect(result.toString(), contains('Persian'));
      expect(result.toString(), contains('87.6%'));
    });
  });
}
