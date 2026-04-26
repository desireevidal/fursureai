class PredictionRecord {
  const PredictionRecord({
    this.id,
    this.catName,
    this.breed,
    this.breedConfidence,
    this.secondaryBreed,
    this.secondaryBreedConfidence,
    this.gender,
    this.genderConfidence,
    required this.timestamp,
    this.imagePath,
  });

  final int? id;
  final String? catName;
  final String? breed;
  final double? breedConfidence;
  final String? secondaryBreed;
  final double? secondaryBreedConfidence;
  final String? gender;
  final double? genderConfidence;
  final DateTime timestamp;
  final String? imagePath;

  PredictionRecord copyWith({
    int? id,
    String? catName,
    String? breed,
    double? breedConfidence,
    String? secondaryBreed,
    double? secondaryBreedConfidence,
    String? gender,
    double? genderConfidence,
    DateTime? timestamp,
    String? imagePath,
  }) {
    return PredictionRecord(
      id: id ?? this.id,
      catName: catName ?? this.catName,
      breed: breed ?? this.breed,
      breedConfidence: breedConfidence ?? this.breedConfidence,
      secondaryBreed: secondaryBreed ?? this.secondaryBreed,
      secondaryBreedConfidence:
          secondaryBreedConfidence ?? this.secondaryBreedConfidence,
      gender: gender ?? this.gender,
      genderConfidence: genderConfidence ?? this.genderConfidence,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'catName': catName,
      'breed': breed,
      'breedConfidence': breedConfidence,
      'secondaryBreed': secondaryBreed,
      'secondaryBreedConfidence': secondaryBreedConfidence,
      'gender': gender,
      'genderConfidence': genderConfidence,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory PredictionRecord.fromMap(Map<String, dynamic> map) {
    return PredictionRecord(
      id: map['id'] as int?,
      catName: map['catName'] as String?,
      breed: map['breed'] as String?,
      breedConfidence: (map['breedConfidence'] as num?)?.toDouble(),
      secondaryBreed: map['secondaryBreed'] as String?,
      secondaryBreedConfidence:
          (map['secondaryBreedConfidence'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      genderConfidence: (map['genderConfidence'] as num?)?.toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePath: map['imagePath'] as String?,
    );
  }
}
