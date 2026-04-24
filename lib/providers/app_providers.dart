import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/services/onboarding_service.dart';
import '../features/prediction/data/breed_repository.dart';
import '../features/prediction/data/gender_repository.dart';
import '../features/prediction/data/placeholder_breed_repository.dart';
import '../features/prediction/data/placeholder_gender_repository.dart';
import '../services/app_settings_service.dart';
import '../core/ml/audio_preprocessor.dart';
import '../core/ml/image_preprocessor.dart';
import '../core/ml/inference_runner.dart';
import '../services/audio_service.dart';
import '../services/backup_service.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../services/model_download_service.dart';
import '../services/startup_service.dart';
import '../services/tflite_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(),
);

final appSettingsServiceProvider = Provider<AppSettingsService>(
  (ref) => AppSettingsService(),
);

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    db: ref.watch(databaseServiceProvider),
    settings: ref.watch(appSettingsServiceProvider),
  );
});

final modelDownloadServiceProvider = Provider<ModelDownloadService>(
  (ref) => ModelDownloadService(),
);

final startupServiceProvider = Provider<StartupService>(
  (ref) => StartupService(),
);

final breedTfliteServiceProvider = Provider<TfliteService>((ref) {
  final service = TfliteService();
  ref.onDispose(service.dispose);
  return service;
});

final genderTfliteServiceProvider = Provider<TfliteService>((ref) {
  final service = TfliteService();
  ref.onDispose(service.dispose);
  return service;
});

final breedInferenceRunnerProvider = Provider<InferenceRunner>(
  (ref) => InferenceRunner(ref.watch(breedTfliteServiceProvider)),
);

final genderInferenceRunnerProvider = Provider<InferenceRunner>(
  (ref) => InferenceRunner(ref.watch(genderTfliteServiceProvider)),
);

final imagePreprocessorProvider = Provider<ImagePreprocessor>(
  (ref) => const ImagePreprocessor(),
);

final audioPreprocessorProvider = Provider<AudioPreprocessor>(
  (ref) => const AudioPreprocessor(),
);

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final breedRepositoryProvider = Provider<BreedRepository>(
  (ref) => BreedRepository(
    tfliteService: ref.watch(breedTfliteServiceProvider),
    inferenceRunner: ref.watch(breedInferenceRunnerProvider),
    modelDownloadService: ref.watch(modelDownloadServiceProvider),
    imagePreprocessor: ref.watch(imagePreprocessorProvider),
  ),
);

final genderRepositoryProvider = Provider<GenderRepository>(
  (ref) => GenderRepository(
    tfliteService: ref.watch(genderTfliteServiceProvider),
    inferenceRunner: ref.watch(genderInferenceRunnerProvider),
    modelDownloadService: ref.watch(modelDownloadServiceProvider),
    audioPreprocessor: ref.watch(audioPreprocessorProvider),
  ),
);

final placeholderBreedRepositoryProvider = Provider<PlaceholderBreedRepository>(
  (_) => PlaceholderBreedRepository(),
);

final placeholderGenderRepositoryProvider =
    Provider<PlaceholderGenderRepository>((_) => PlaceholderGenderRepository());

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'Version ${info.version} (build ${info.buildNumber})';
});

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    if (state == themeMode) return;
    state = themeMode;
    await ref.read(appSettingsServiceProvider).saveThemeMode(themeMode);
  }
}
