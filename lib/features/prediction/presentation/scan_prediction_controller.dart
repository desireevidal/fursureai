import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fursure/core/config/app_config.dart';
import 'package:fursure/providers/app_providers.dart';
import 'package:fursure/features/results/data/prediction_record.dart';
import '../data/breed_result.dart';
import '../data/gender_result.dart';

@immutable
class ScanPredictionResult {
  const ScanPredictionResult({
    required this.pendingRecord,
    this.breedResult,
    this.genderResult,
  });

  final PredictionRecord pendingRecord;
  final BreedResult? breedResult;
  final GenderResult? genderResult;
}

class ScanPredictionController extends AsyncNotifier<ScanPredictionResult?> {
  @override
  ScanPredictionResult? build() => null;

  Future<void> predict({
    required File? image,
    required String? audioPath,
    required String catName,
  }) async {
    state = const AsyncLoading();

    BreedResult? breedResult;
    GenderResult? genderResult;

    if (image != null) {
      try {
        breedResult = AppConfig.breedSpec.usePlaceholder
            ? await ref
                  .read(placeholderBreedRepositoryProvider)
                  .predict(image)
            : await ref.read(breedRepositoryProvider).predict(image);
      } catch (e, st) {
        debugPrint('Breed prediction failed: $e\n$st');
      }
    }

    if (audioPath != null) {
      try {
        genderResult = AppConfig.genderSpec.usePlaceholder
            ? await ref
                  .read(placeholderGenderRepositoryProvider)
                  .predict(File(audioPath))
            : await ref
                  .read(genderRepositoryProvider)
                  .predict(File(audioPath));
      } catch (e, st) {
        debugPrint('Gender prediction failed: $e\n$st');
      }
    }

    state = AsyncData(
      ScanPredictionResult(
        pendingRecord: PredictionRecord(
          catName: catName,
          breed: breedResult?.breed,
          breedConfidence: breedResult?.confidence,
          gender: genderResult?.gender,
          genderConfidence: genderResult?.confidence,
          timestamp: DateTime.now(),
          imagePath: image?.path,
        ),
        breedResult: breedResult,
        genderResult: genderResult,
      ),
    );
  }
}

final scanPredictionControllerProvider =
    AsyncNotifierProvider.autoDispose<ScanPredictionController, ScanPredictionResult?>(
      ScanPredictionController.new,
    );
