// lib/src/providers/settings_provider.dart
// ✅ FIXED: Corrected the method name to 'isPremium'.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';

class SettingsProvider with ChangeNotifier {
  final PremiumService _premiumService = PremiumService();
  late SharedPreferences _prefs;

  // --- Settings ---
  bool _autoPlayOnSelect = true; // Default setting

  // --- Getters ---
  bool get autoPlayOnSelect => _autoPlayOnSelect;

  // --- Keys for SharedPreferences ---
  static const String _autoPlayKey = 'settings_autoPlayOnSelect';

  SettingsProvider() {
    _loadSettings();
  }

  /// Loads settings from SharedPreferences on startup.
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _autoPlayOnSelect = _prefs.getBool(_autoPlayKey) ?? true;
    notifyListeners();
    debugPrint(
        '[SettingsProvider] ⚙️ Settings loaded: autoPlay = $_autoPlayOnSelect');
  }

  /// Updates the auto-play setting.
  Future<void> setAutoPlayOnSelect(bool value) async {
    _autoPlayOnSelect = value;
    await _prefs.setBool(_autoPlayKey, value);
    notifyListeners();
    debugPrint('[SettingsProvider] 💾 Saved setting: autoPlay = $value');
  }

  /// Example of a premium-only setting.
  Future<void> setPremiumOnlySetting(dynamic value) async {
    // ✅ FIX: Changed 'isPremiumUser' to 'isPremium'
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: Cannot change premium-only setting.');
      return;
    }

    debugPrint('[SettingsProvider] 👑 Saved premium setting.');
    notifyListeners();
  }
}
