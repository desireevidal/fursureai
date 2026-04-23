import 'package:shared_preferences/shared_preferences.dart';

class StartupService {
  StartupService({
    Future<SharedPreferences> Function()? sharedPreferencesLoader,
  }) : _sharedPreferencesLoader =
           sharedPreferencesLoader ?? SharedPreferences.getInstance;

  static const String _initialModelPreloadKey = 'initialModelPreloadComplete';

  final Future<SharedPreferences> Function() _sharedPreferencesLoader;

  Future<bool> hasCompletedInitialModelPreload() async {
    final SharedPreferences prefs = await _sharedPreferencesLoader();
    return prefs.getBool(_initialModelPreloadKey) ?? false;
  }

  Future<void> markInitialModelPreloadComplete() async {
    final SharedPreferences prefs = await _sharedPreferencesLoader();
    await prefs.setBool(_initialModelPreloadKey, true);
  }
}
