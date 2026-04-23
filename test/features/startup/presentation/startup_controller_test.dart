import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fursure/core/services/onboarding_service.dart';
import 'package:fursure/features/startup/presentation/startup_controller.dart';
import 'package:fursure/providers/app_providers.dart';
import 'package:fursure/services/model_download_service.dart';
import 'package:fursure/core/config/model_spec.dart';
import 'package:fursure/services/startup_service.dart';

class _FakeOnboardingService extends OnboardingService {
  _FakeOnboardingService({required this.hasSeen});

  final bool hasSeen;

  @override
  Future<bool> hasSeenOnboarding() async => hasSeen;
}

class _FakeStartupService extends StartupService {
  _FakeStartupService({required this.hasCompletedInitialPreload});

  bool hasCompletedInitialPreload;
  int markCompleteCalls = 0;

  @override
  Future<bool> hasCompletedInitialModelPreload() async =>
      hasCompletedInitialPreload;

  @override
  Future<void> markInitialModelPreloadComplete() async {
    hasCompletedInitialPreload = true;
    markCompleteCalls++;
  }
}

class _FakeModelDownloadService extends ModelDownloadService {
  int preloadCalls = 0;

  @override
  Future<void> preloadModels(
    List<({ModelSpec spec, void Function(double)? onProgress})> models, {
    bool forceRedownload = false,
  }) async => preloadCalls++;
}

void main() {
  group('StartupController', () {
    test('routes to welcome when onboarding has not been seen', () async {
      final _FakeStartupService startupService = _FakeStartupService(
        hasCompletedInitialPreload: true,
      );
      final _FakeModelDownloadService downloadService =
          _FakeModelDownloadService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWith(
            (Ref ref) => _FakeOnboardingService(hasSeen: false),
          ),
          startupServiceProvider.overrideWith((Ref ref) => startupService),
          modelDownloadServiceProvider.overrideWith(
            (Ref ref) => downloadService,
          ),
        ],
      );
      addTearDown(container.dispose);

      final String route = await container.read(
        startupControllerProvider.future,
      );

      expect(route, '/welcome');
      expect(downloadService.preloadCalls, 0);
    });

    test('routes to home when onboarding has been seen', () async {
      final _FakeStartupService startupService = _FakeStartupService(
        hasCompletedInitialPreload: true,
      );
      final _FakeModelDownloadService downloadService =
          _FakeModelDownloadService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          onboardingServiceProvider.overrideWith(
            (Ref ref) => _FakeOnboardingService(hasSeen: true),
          ),
          startupServiceProvider.overrideWith((Ref ref) => startupService),
          modelDownloadServiceProvider.overrideWith(
            (Ref ref) => downloadService,
          ),
        ],
      );
      addTearDown(container.dispose);

      final String route = await container.read(
        startupControllerProvider.future,
      );

      expect(route, '/home');
      expect(downloadService.preloadCalls, 0);
    });
  });
}
