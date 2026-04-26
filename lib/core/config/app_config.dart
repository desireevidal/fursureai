import 'model_spec.dart';

abstract final class AppConfig {
  static const bool usePlaceholders = bool.fromEnvironment(
    'USE_PLACEHOLDERS',
    defaultValue: false,
  );

  static const String breedModelUrl = String.fromEnvironment('BREED_MODEL_URL');
  static const String genderModelUrl = String.fromEnvironment('GENDER_MODEL_URL');

  static const String breedModelFilename = 'breed_model.tflite';
  static const String genderModelFilename = 'gender_model.tflite';
  static const String breedModelAssetPath = 'assets/models/breed_model.tflite';
  static const String genderModelAssetPath = 'assets/models/gender_model.tflite';

  static const String breedModelSha256 = String.fromEnvironment('BREED_MODEL_SHA256');
  static const String genderModelSha256 = String.fromEnvironment('GENDER_MODEL_SHA256');

  static ModelSpec get breedSpec => ModelSpec(
    label: 'breed',
    filename: breedModelFilename,
    url: breedModelUrl,
    assetPath: breedModelAssetPath,
    sha256: breedModelSha256,
    usePlaceholder: usePlaceholders || breedModelUrl.isEmpty,
  );

  static ModelSpec get genderSpec => ModelSpec(
    label: 'gender',
    filename: genderModelFilename,
    url: genderModelUrl,
    assetPath: genderModelAssetPath,
    sha256: genderModelSha256,
    usePlaceholder: usePlaceholders || genderModelUrl.isEmpty,
  );

  static void validateModelDownloadConfig() {}
}
