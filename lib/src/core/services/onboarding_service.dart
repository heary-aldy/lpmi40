// lib/src/core/services/onboarding_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
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

  /// Check if onboarding has been completed
  bool get isOnboardingCompleted {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_onboardingCompletedKey, true);
    debugPrint('✅ Onboarding marked as completed');
  }

  /// Reset onboarding (useful for testing or user request)
  Future<void> resetOnboarding() async {
    await _prefs.setBool(_onboardingCompletedKey, false);
    debugPrint('🔄 Onboarding reset - will show on next app start');
  }

  /// Get app launch count
  int get appLaunchCount {
    return _prefs.getInt(_appLaunchCountKey) ?? 0;
  }

  /// Increment app launch count
  Future<void> incrementLaunchCount() async {
    final currentCount = appLaunchCount;
    await _prefs.setInt(_appLaunchCountKey, currentCount + 1);

    // Set first launch date if this is the first launch
    if (currentCount == 0) {
      await _prefs.setString(
          _firstLaunchDateKey, DateTime.now().toIso8601String());
    }

    debugPrint('📱 App launched ${currentCount + 1} times');
  }

  /// Get first launch date
  DateTime? get firstLaunchDate {
    final dateString = _prefs.getString(_firstLaunchDateKey);
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        debugPrint('❌ Error parsing first launch date: $e');
        return null;
      }
    }
    return null;
  }

  /// Check if user is new (useful for showing onboarding to new users only)
  bool get isNewUser {
    return appLaunchCount <= 1 && !isOnboardingCompleted;
  }

  /// Check if we should force show onboarding (for testing)
  bool get shouldForceOnboarding {
    // You can add logic here for force-showing onboarding
    // For example, after app updates, or for testing
    return false;
  }

  /// Determine if onboarding should be shown
  bool get shouldShowOnboarding {
    // Show onboarding if:
    // 1. User is new AND hasn't completed onboarding
    // 2. OR if we're forcing onboarding (for testing/updates)
    return !isOnboardingCompleted || shouldForceOnboarding;
  }

  /// Get onboarding analytics data
  Map<String, dynamic> getOnboardingAnalytics() {
    return {
      'onboarding_completed': isOnboardingCompleted,
      'app_launch_count': appLaunchCount,
      'first_launch_date': firstLaunchDate?.toIso8601String(),
      'is_new_user': isNewUser,
      'days_since_install': firstLaunchDate != null
          ? DateTime.now().difference(firstLaunchDate!).inDays
          : 0,
    };
  }

  /// Clear all onboarding data (for complete reset)
  Future<void> clearAllData() async {
    await _prefs.remove(_onboardingCompletedKey);
    await _prefs.remove(_appLaunchCountKey);
    await _prefs.remove(_firstLaunchDateKey);
    debugPrint('🗑️ All onboarding data cleared');
  }

  /// Set custom onboarding completion (with timestamp)
  Future<void> setOnboardingCompletedWithTimestamp() async {
    await setOnboardingCompleted();
    await _prefs.setString(
      'onboarding_completed_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// Get when onboarding was completed
  DateTime? get onboardingCompletedAt {
    final dateString = _prefs.getString('onboarding_completed_at');
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        debugPrint('❌ Error parsing onboarding completion date: $e');
        return null;
      }
    }
    return null;
  }

  /// Update onboarding for app version (if you want to show onboarding for major updates)
  Future<void> checkVersionUpdate(String currentVersion) async {
    final lastVersion = _prefs.getString('last_onboarding_version');

    if (lastVersion != currentVersion) {
      // You can add logic here to determine if onboarding should be shown for this version
      // For now, we'll just update the stored version
      await _prefs.setString('last_onboarding_version', currentVersion);
      debugPrint('📱 App version updated: $lastVersion -> $currentVersion');
    }
  }
}
