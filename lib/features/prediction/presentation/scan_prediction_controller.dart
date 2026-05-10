import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fursure/core/config/app_config.dart';
import 'package:fursure/core/error/app_exceptions.dart';
import 'package:fursure/providers/app_providers.dart';
import 'package:fursure/features/results/data/prediction_record.dart';
import '../data/breed_result.dart';
import '../data/gender_result.dart';

const String _meowRequiredMessage =
    'No meow detected. Please record or upload a clear meow before continuing.';

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

    if (audioPath == null || audioPath.trim().isEmpty) {
      state = AsyncError(
        const InferenceException(_meowRequiredMessage),
        StackTrace.current,
      );
      return;
    }

    if (image != null) {
      try {
        breedResult = AppConfig.breedSpec.usePlaceholder
            ? await ref
                  .read(placeholderBreedRepositoryProvider)
                  .predict(image)
            : await ref.read(breedRepositoryProvider).predict(image);
      } on AppException catch (e, st) {
        state = AsyncError(e, st);
        return;
      } catch (e, st) {
        debugPrint('Breed prediction failed: $e\n$st');
      }
    }

    try {
      genderResult = AppConfig.genderSpec.usePlaceholder
          ? await ref
                .read(placeholderGenderRepositoryProvider)
                .predict(File(audioPath))
          : await ref.read(genderRepositoryProvider).predict(File(audioPath));
    } on InferenceException catch (e, st) {
      debugPrint('Gender prediction failed: $e\n$st');
      state = AsyncError(
        InferenceException(
          e.message.startsWith('No meow detected')
              ? e.message
              : '$_meowRequiredMessage ${e.message}',
        ),
        st,
      );
      return;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return;
    } catch (e, st) {
      debugPrint('Gender prediction failed: $e\n$st');
      state = AsyncError(
        const InferenceException(
          'No meow detected. We could not analyze the meow. Please try again with a short, clear audio clip.',
        ),
        st,
      );
      return;
    }

    state = AsyncData(
      ScanPredictionResult(
        pendingRecord: PredictionRecord(
          catName: catName,
          breed: breedResult?.breed,
          breedConfidence: breedResult?.confidence,
          secondaryBreed: breedResult?.secondaryBreed,
          secondaryBreedConfidence: breedResult?.secondaryConfidence,
          gender: genderResult.gender,
          genderConfidence: genderResult.confidence,
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
