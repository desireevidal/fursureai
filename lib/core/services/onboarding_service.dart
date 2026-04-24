import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _welcomeKey = 'hasSeenOnboarding';
  static const _firstUseGuideKey = 'hasSeenFirstUseGuide';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
  }

  Future<bool> hasSeenFirstUseGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstUseGuideKey) ?? false;
  }

  Future<void> markFirstUseGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstUseGuideKey, true);
  }
}
