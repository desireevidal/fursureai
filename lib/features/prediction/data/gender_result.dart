class GenderResult {
  const GenderResult({required this.gender, required this.confidence});

  final String gender;
  final double confidence;

  @override
  String toString() =>
      'GenderResult(gender: $gender, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
