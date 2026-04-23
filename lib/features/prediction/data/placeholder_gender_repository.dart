import 'dart:io';

import 'gender_result.dart';

class PlaceholderGenderRepository {
  Future<GenderResult> predict(File audioFile) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const GenderResult(gender: 'Male', confidence: 0.80);
  }
}
