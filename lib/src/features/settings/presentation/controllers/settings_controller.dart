// lib/src/features/settings/presentation/controllers/settings_controller.dart
// ✅ NEW: Extracted business logic from settings_page.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';

class SettingsController extends ChangeNotifier {
  final PremiumService _premiumService = PremiumService();

  // State
  bool _isPremium = false;
  bool _isLoadingPremium = true;
  bool _isCheckingForUpdates = false;
  PackageInfo? _packageInfo;

  // Getters
  bool get isPremium => _isPremium;
  bool get isLoadingPremium => _isLoadingPremium;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  PackageInfo? get packageInfo => _packageInfo;

  // Initialize controller
  Future<void> initialize() async {
    await Future.wait([
      loadPremiumStatus(),
      _loadPackageInfo(),
    ]);
  }

  // Load premium status
  Future<void> loadPremiumStatus() async {
    try {
      _isLoadingPremium = true;
      notifyListeners();

      final isPremium = await _premiumService.isPremium();
      _isPremium = isPremium;
    } catch (e) {
      debugPrint('[SettingsController] ❌ Failed to load premium status: $e');
    } finally {
      _isLoadingPremium = false;
      notifyListeners();
    }
  }

  // Load package info
  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsController] ❌ Failed to load package info: $e');
    }
  }

  // Check for updates
  Future<void> checkForUpdates() async {
    _isCheckingForUpdates = true;
    notifyListeners();

    try {
      // Simulate update check
      await Future.delayed(const Duration(seconds: 2));
      // In real app, this would check app store/play store for updates
    } finally {
      _isCheckingForUpdates = false;
      notifyListeners();
    }
  }

  // Get current user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Get user status text
  String getUserStatusText() {
    final user = getCurrentUser();
    if (user == null) return 'Guest';
    if (user.isAnonymous) return 'Guest';
    return _isPremium ? 'Premium' : 'Registered';
  }

  // Get version info
  String getVersionInfo() {
    if (_packageInfo == null) return '1.0.0 (1)';
    return '${_packageInfo!.version} (${_packageInfo!.buildNumber})';
  }

  // Log operations for debugging
  void logOperation(String operation, [Map<String, dynamic>? params]) {
    debugPrint(
        '[SettingsController] 🔧 $operation${params != null ? ' - $params' : ''}');
  }
}
