class BreedResult {
  const BreedResult({
    required this.breed,
    required this.confidence,
    this.imagePath,
  });

  final String breed;
  final double confidence;
  final String? imagePath;

  @override
  String toString() =>
      'BreedResult(breed: $breed, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
