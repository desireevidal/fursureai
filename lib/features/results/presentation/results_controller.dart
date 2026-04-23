import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fursure/providers/app_providers.dart';
import '../data/prediction_record.dart';

final resultsControllerProvider =
    AsyncNotifierProvider<ResultsController, List<PredictionRecord>>(
      ResultsController.new,
    );

class ResultsController extends AsyncNotifier<List<PredictionRecord>> {
  @override
  Future<List<PredictionRecord>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getRecentPredictions();
  }

  Future<void> saveResult(PredictionRecord record) async {
    final db = ref.read(databaseServiceProvider);
    await db.insertPrediction(record);
    ref.invalidateSelf();
  }

  Future<void> deleteResult(int id) async {
    final db = ref.read(databaseServiceProvider);
    final previousRecords = state.asData?.value;

    if (previousRecords != null) {
      state = AsyncData(
        previousRecords.where((record) => record.id != id).toList(),
      );
    }

    try {
      await db.deletePrediction(id);
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      if (previousRecords != null) {
        state = AsyncData(previousRecords);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> updateResult(PredictionRecord record) async {
    final db = ref.read(databaseServiceProvider);
    final previousRecords = state.asData?.value;

    if (record.id == null) return;

    if (previousRecords != null) {
      state = AsyncData([
        for (final existing in previousRecords)
          if (existing.id == record.id) record else existing,
      ]);
    }

    try {
      await db.updatePrediction(record);
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      if (previousRecords != null) {
        state = AsyncData(previousRecords);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }
}
