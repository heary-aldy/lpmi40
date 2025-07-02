import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userNameKey = 'user_name'; // Key for the user's name
  static const String _appLaunchCountKey = 'app_launch_count';
  static const String _firstLaunchDateKey = 'first_launch_date';

  static OnboardingService? _instance;
  late SharedPreferences _prefs;

  OnboardingService._internal();

  static Future<OnboardingService> getInstance() async {
    _instance ??= OnboardingService._internal();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  // --- Core State Properties ---

  /// Check if onboarding has been completed
  bool get isOnboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;

  /// Get the stored user name
  String get userName => _prefs.getString(_userNameKey) ?? '';

  /// Determine if onboarding should be shown
  bool get shouldShowOnboarding => !isOnboardingCompleted;

  // --- Core State Modifiers ---

  /// Mark onboarding as completed and save the user's name.
  Future<void> completeOnboarding({required String name}) async {
    await _prefs.setBool(_onboardingCompletedKey, true);
    await _prefs.setString(_userNameKey, name);
  }

  /// Reset onboarding (useful for testing or user request)
  Future<void> resetOnboarding() async {
    await _prefs.setBool(_onboardingCompletedKey, false);
    await _prefs.setString(_userNameKey, '');
  }

  // --- Analytics & Extra Features ---

  /// Get app launch count
  int get appLaunchCount => _prefs.getInt(_appLaunchCountKey) ?? 0;

  /// Increment app launch count
  Future<void> incrementLaunchCount() async {
    final currentCount = appLaunchCount;
    await _prefs.setInt(_appLaunchCountKey, currentCount + 1);
    if (currentCount == 0) {
      await _prefs.setString(
          _firstLaunchDateKey, DateTime.now().toIso8601String());
    }
  }

  // ... other methods from your service like getFirstLaunchDate, getOnboardingAnalytics etc.
}
