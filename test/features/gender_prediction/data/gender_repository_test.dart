import 'package:flutter_test/flutter_test.dart';

import 'package:fursure/features/prediction/data/gender_result.dart';

void main() {
  group('GenderResult', () {
    test('stores gender and confidence', () {
      const result = GenderResult(gender: 'Male', confidence: 0.88);
      expect(result.gender, 'Male');
      expect(result.confidence, 0.88);
    });

    test('toString formats correctly', () {
      const result = GenderResult(gender: 'Female', confidence: 0.923);
      expect(result.toString(), contains('Female'));
      expect(result.toString(), contains('92.3%'));
    });
  });
}
