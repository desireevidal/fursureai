import 'package:flutter_test/flutter_test.dart';

import 'package:fursure/features/results/data/prediction_record.dart';

void main() {
  group('PredictionRecord', () {
    test('copyWith updates catName while preserving the remaining fields', () {
      final originalTimestamp = DateTime(2026, 3, 13, 10);
      final updatedTimestamp = DateTime(2026, 3, 13, 10, 30);
      final record = PredictionRecord(
        id: 7,
        catName: 'My Cat',
        breed: 'Siamese',
        breedConfidence: 0.9,
        gender: 'Female',
        genderConfidence: 0.8,
        timestamp: originalTimestamp,
        imagePath: '/tmp/cat.png',
      );

      final updatedRecord = record.copyWith(
        catName: 'Mochi',
        timestamp: updatedTimestamp,
      );

      expect(updatedRecord.id, 7);
      expect(updatedRecord.catName, 'Mochi');
      expect(updatedRecord.breed, 'Siamese');
      expect(updatedRecord.breedConfidence, 0.9);
      expect(updatedRecord.gender, 'Female');
      expect(updatedRecord.genderConfidence, 0.8);
      expect(updatedRecord.timestamp, updatedTimestamp);
      expect(updatedRecord.imagePath, '/tmp/cat.png');
    });
  });
}
