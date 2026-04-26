class BreedResult {
  const BreedResult({
    required this.breed,
    required this.confidence,
    this.secondaryBreed,
    this.secondaryConfidence,
    this.imagePath,
  });

  final String breed;
  final double confidence;

  final String? secondaryBreed;
  final double? secondaryConfidence;

  final String? imagePath;

  bool get hasSecondary =>
      secondaryBreed != null && secondaryConfidence != null;

  bool get shouldShowSecondary {
    if (!hasSecondary) return false;

    final secondary = secondaryConfidence!;
    final gap = confidence - secondary;

    // Show secondary if:
    // 1) it is meaningful on its own, or
    // 2) the top 2 are close to each other
    return secondary >= 0.10 || gap <= 0.15;
  }

  double get primaryDisplayShare {
    if (!shouldShowSecondary) return confidence;
    final total = confidence + secondaryConfidence!;
    if (total <= 0) return confidence;
    return confidence / total;
  }

  double get secondaryDisplayShare {
    if (!shouldShowSecondary) return 0;
    final total = confidence + secondaryConfidence!;
    if (total <= 0) return 0;
    return secondaryConfidence! / total;
  }

  @override
  String toString() {
    final primaryText = '${(confidence * 100).toStringAsFixed(1)}%';

    if (!hasSecondary) {
      return 'BreedResult(breed: $breed, confidence: $primaryText)';
    }

    final secondaryText =
        '${(secondaryConfidence! * 100).toStringAsFixed(1)}%';

    return 'BreedResult('
        'breed: $breed, confidence: $primaryText, '
        'secondaryBreed: $secondaryBreed, secondaryConfidence: $secondaryText'
        ')';
  }
}
