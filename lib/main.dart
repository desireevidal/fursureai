import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'providers/app_providers.dart';
import 'services/app_settings_service.dart';

void main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  final savedTheme = await AppSettingsService().loadThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(savedTheme),
      ],
      child: const FursureApp(),
    ),
  );
  widgetsBinding.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}
