import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:fursure/features/results/data/prediction_record.dart';

@immutable
class ScanSession {
  const ScanSession({
    this.selectedImage,
    this.audioPath,
    this.catName = 'My Cat',
    this.pendingRecord,
  });

  final File? selectedImage;
  final String? audioPath;
  final String catName;
  final PredictionRecord? pendingRecord;

  ScanSession copyWith({
    File? selectedImage,
    String? audioPath,
    String? catName,
    PredictionRecord? pendingRecord,
    bool clearSelectedImage = false,
    bool clearAudioPath = false,
    bool clearPendingRecord = false,
  }) {
    return ScanSession(
      selectedImage: clearSelectedImage
          ? null
          : (selectedImage ?? this.selectedImage),
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      catName: catName ?? this.catName,
      pendingRecord: clearPendingRecord
          ? null
          : (pendingRecord ?? this.pendingRecord),
    );
  }
}
