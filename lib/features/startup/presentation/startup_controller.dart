import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fursure/core/config/app_config.dart';
import 'package:fursure/providers/app_providers.dart';

// ── Download progress state ──────────────────────────────────────────────────

class ModelDownloadState {
  const ModelDownloadState({
    this.breedProgress = 0.0,
    this.genderProgress = 0.0,
    this.isDownloading = false,
    this.isComplete = false,
  });

  final double breedProgress;
  final double genderProgress;
  final bool isDownloading;
  final bool isComplete;

  ModelDownloadState copyWith({
    double? breedProgress,
    double? genderProgress,
    bool? isDownloading,
    bool? isComplete,
  }) {
    return ModelDownloadState(
      breedProgress: breedProgress ?? this.breedProgress,
      genderProgress: genderProgress ?? this.genderProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, ModelDownloadState>(
      DownloadProgressNotifier.new,
    );

class DownloadProgressNotifier extends Notifier<ModelDownloadState> {
  @override
  ModelDownloadState build() => const ModelDownloadState();

  void startDownloading() => state = state.copyWith(isDownloading: true);
  void setBreedProgress(double p) => state = state.copyWith(breedProgress: p);
  void setGenderProgress(double p) =>
      state = state.copyWith(genderProgress: p);
  void markComplete() => state = state.copyWith(isComplete: true);
}

// ── Startup controller ───────────────────────────────────────────────────────

final startupControllerProvider =
    AsyncNotifierProvider<StartupController, String>(StartupController.new);

class StartupController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    // Yield so Riverpod finishes registering this provider before we mutate
    // downloadProgressProvider, which would otherwise throw:
    // "Providers are not allowed to modify other providers during their initialization."
    await Future<void>.microtask(() {});

    if (!AppConfig.breedSpec.usePlaceholder || !AppConfig.genderSpec.usePlaceholder) {
      final bool hasCompletedInitialPreload = kDebugMode
          ? false
          : await ref
                .read(startupServiceProvider)
                .hasCompletedInitialModelPreload();

      if (!hasCompletedInitialPreload) {
        final progressNotifier = ref.read(downloadProgressProvider.notifier);
        progressNotifier.startDownloading();

        await ref.read(modelDownloadServiceProvider).preloadModels(
          [
            (spec: AppConfig.breedSpec, onProgress: progressNotifier.setBreedProgress),
            (spec: AppConfig.genderSpec, onProgress: progressNotifier.setGenderProgress),
          ],
          forceRedownload: kDebugMode,
        );

        progressNotifier.markComplete();
        // Brief pause so the user sees the confirmation state.
        await Future<void>.delayed(const Duration(milliseconds: 1800));

        if (!kDebugMode) {
          await ref
              .read(startupServiceProvider)
              .markInitialModelPreloadComplete();
        }
      }
    }

    final bool hasSeenOnboarding = await ref
        .read(onboardingServiceProvider)
        .hasSeenOnboarding();

    return hasSeenOnboarding ? '/home' : '/welcome';
  }
}
