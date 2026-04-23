import 'dart:io';

import 'breed_result.dart';

class PlaceholderBreedRepository {
  Future<BreedResult> predict(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const BreedResult(breed: 'Persian', confidence: 0.85);
  }
}
