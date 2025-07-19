// lib/src/providers/settings_provider.dart
// ✅ UPDATED: Refactored to be fully type-safe using enums internally.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';

// ✅ NEW: Audio quality enum
enum AudioQuality {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case AudioQuality.low:
        return 'Low Quality';
      case AudioQuality.medium:
        return 'Medium Quality';
      case AudioQuality.high:
        return 'High Quality';
    }
  }

  // ✅ NEW: Description property for settings page
  String get description {
    switch (this) {
      case AudioQuality.low:
        return 'Low quality (96 kbps) - Saves data';
      case AudioQuality.medium:
        return 'Medium quality (128 kbps) - Balanced';
      case AudioQuality.high:
        return 'High quality (320 kbps) - Best sound';
    }
  }

  // ✅ NEW: Convert from string
  static AudioQuality fromString(String value) {
    return AudioQuality.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => AudioQuality.medium);
  }
}

// ✅ NEW: Player mode enum
enum PlayerMode {
  mini,
  full,
  auto;

  String get displayName {
    switch (this) {
      case PlayerMode.mini:
        return 'Mini Player';
      case PlayerMode.full:
        return 'Full Screen';
      case PlayerMode.auto:
        return 'Auto Mode';
    }
  }

  // ✅ NEW: Description property for settings page
  String get description {
    switch (this) {
      case PlayerMode.mini:
        return 'Mini player - Small floating player';
      case PlayerMode.full:
        return 'Full screen - Immersive player experience';
      case PlayerMode.auto:
        return 'Auto - Adapts to content and screen size';
    }
  }

  // ✅ NEW: Convert from string
  static PlayerMode fromString(String value) {
    return PlayerMode.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => PlayerMode.mini);
  }
}

// ✅ NEW: Extension for String to add displayName (for compatibility)
extension StringDisplayName on String {
  String get displayName {
    // Convert snake_case or camelCase to Title Case
    return split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
}

class SettingsProvider with ChangeNotifier {
  final PremiumService _premiumService = PremiumService();
  late SharedPreferences _prefs;

  // --- Settings (Internal state now uses Enums for type safety) ---
  bool _autoPlayOnSelect = true;
  bool _autoPlayNext = false;
  bool _backgroundPlay = false;
  AudioQuality _audioQuality = AudioQuality.high; // ✅ FIXED
  bool _enableCrossfade = false;
  double _crossfadeDuration = 2.0;
  bool _enableReplayGain = false;
  PlayerMode _playerMode = PlayerMode.mini; // ✅ FIXED

  // --- Getters (Now return the correct Enum types) ---
  bool get autoPlayOnSelect => _autoPlayOnSelect;
  bool get autoPlayNext => _autoPlayNext;
  bool get backgroundPlay => _backgroundPlay;
  AudioQuality get audioQuality => _audioQuality; // ✅ FIXED
  bool get enableCrossfade => _enableCrossfade;
  double get crossfadeDuration => _crossfadeDuration;
  bool get enableReplayGain => _enableReplayGain;
  PlayerMode get playerMode => _playerMode; // ✅ FIXED

  // --- Keys for SharedPreferences ---
  static const String _autoPlayKey = 'settings_autoPlayOnSelect';
  static const String _autoPlayNextKey = 'settings_autoPlayNext';
  static const String _backgroundPlayKey = 'settings_backgroundPlay';
  static const String _audioQualityKey = 'settings_audioQuality';
  static const String _crossfadeKey = 'settings_enableCrossfade';
  static const String _crossfadeDurationKey = 'settings_crossfadeDuration';
  static const String _replayGainKey = 'settings_enableReplayGain';
  static const String _playerModeKey = 'settings_playerMode';

  SettingsProvider() {
    _loadSettings();
  }

  /// Loads settings from SharedPreferences on startup.
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      _autoPlayOnSelect = _prefs.getBool(_autoPlayKey) ?? true;
      _autoPlayNext = _prefs.getBool(_autoPlayNextKey) ?? false;
      _backgroundPlay = _prefs.getBool(_backgroundPlayKey) ?? false;
      _enableCrossfade = _prefs.getBool(_crossfadeKey) ?? false;
      _crossfadeDuration = _prefs.getDouble(_crossfadeDurationKey) ?? 2.0;
      _enableReplayGain = _prefs.getBool(_replayGainKey) ?? false;

      // ✅ FIXED: Load strings and immediately convert to enums
      final savedQuality = _prefs.getString(_audioQualityKey) ?? 'high';
      _audioQuality = AudioQuality.fromString(savedQuality);

      final savedMode = _prefs.getString(_playerModeKey) ?? 'mini';
      _playerMode = PlayerMode.fromString(savedMode);

      notifyListeners();
      debugPrint('[SettingsProvider] ⚙️ Settings loaded');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error loading settings: $e');
    }
  }

  /// Updates the auto-play setting.
  Future<void> setAutoPlayOnSelect(bool value) async {
    try {
      _autoPlayOnSelect = value;
      await _prefs.setBool(_autoPlayKey, value);
      notifyListeners();
      debugPrint('[SettingsProvider] 💾 Saved setting: autoPlay = $value');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving autoPlay setting: $e');
    }
  }

  /// Updates the auto-play next setting.
  Future<void> setAutoPlayNext(bool value) async {
    try {
      _autoPlayNext = value;
      await _prefs.setBool(_autoPlayNextKey, value);
      notifyListeners();
      debugPrint('[SettingsProvider] 💾 Saved setting: autoPlayNext = $value');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving autoPlayNext setting: $e');
    }
  }

  /// Updates the background play setting (premium only).
  Future<void> setBackgroundPlay(bool value) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: Background play requires premium.');
      return;
    }

    try {
      _backgroundPlay = value;
      await _prefs.setBool(_backgroundPlayKey, value);
      notifyListeners();
      debugPrint(
          '[SettingsProvider] 💾 Saved setting: backgroundPlay = $value');
    } catch (e) {
      debugPrint(
          '[SettingsProvider] ❌ Error saving backgroundPlay setting: $e');
    }
  }

  /// ✅ FIXED: Updates the audio quality setting using an Enum (premium only).
  Future<void> setAudioQuality(AudioQuality quality) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium && quality == AudioQuality.high) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: High quality audio requires premium.');
      return;
    }

    try {
      _audioQuality = quality;
      await _prefs.setString(_audioQualityKey, quality.name);
      notifyListeners();
      debugPrint(
          '[SettingsProvider] 💾 Saved setting: audioQuality = ${quality.name}');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving audioQuality setting: $e');
    }
  }

  /// Updates the crossfade setting (premium only).
  Future<void> setEnableCrossfade(bool value) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: Crossfade requires premium.');
      return;
    }

    try {
      _enableCrossfade = value;
      await _prefs.setBool(_crossfadeKey, value);
      notifyListeners();
      debugPrint('[SettingsProvider] 💾 Saved setting: crossfade = $value');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving crossfade setting: $e');
    }
  }

  /// Updates the crossfade duration (premium only).
  Future<void> setCrossfadeDuration(double duration) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: Crossfade duration requires premium.');
      return;
    }

    final clampedDuration = duration.clamp(0.5, 10.0);

    try {
      _crossfadeDuration = clampedDuration;
      await _prefs.setDouble(_crossfadeDurationKey, clampedDuration);
      notifyListeners();
      debugPrint(
          '[SettingsProvider] 💾 Saved setting: crossfadeDuration = $clampedDuration');
    } catch (e) {
      debugPrint(
          '[SettingsProvider] ❌ Error saving crossfadeDuration setting: $e');
    }
  }

  /// Updates the replay gain setting (premium only).
  Future<void> setEnableReplayGain(bool value) async {
    final hasPremium = await _premiumService.isPremium();
    if (!hasPremium) {
      debugPrint(
          '[SettingsProvider] 🚫 Access Denied: Replay gain requires premium.');
      return;
    }

    try {
      _enableReplayGain = value;
      await _prefs.setBool(_replayGainKey, value);
      notifyListeners();
      debugPrint('[SettingsProvider] 💾 Saved setting: replayGain = $value');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving replayGain setting: $e');
    }
  }

  /// ✅ FIXED: Updates the player mode setting using an Enum.
  Future<void> setPlayerMode(PlayerMode mode) async {
    try {
      _playerMode = mode;
      await _prefs.setString(_playerModeKey, mode.name);
      notifyListeners();
      debugPrint(
          '[SettingsProvider] 💾 Saved setting: playerMode = ${mode.name}');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error saving playerMode setting: $e');
    }
  }

  /// Reset all settings to defaults.
  Future<void> resetAllSettings() async {
    try {
      await _prefs.clear(); // A simpler way to clear all settings

      // Reset to defaults
      _autoPlayOnSelect = true;
      _autoPlayNext = false;
      _backgroundPlay = false;
      _audioQuality = AudioQuality.high; // ✅ FIXED
      _enableCrossfade = false;
      _crossfadeDuration = 2.0;
      _enableReplayGain = false;
      _playerMode = PlayerMode.mini; // ✅ FIXED

      notifyListeners();
      debugPrint('[SettingsProvider] 🔄 All settings reset to defaults');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error resetting settings: $e');
    }
  }

  /// Reset only audio-related settings.
  Future<void> resetAudioSettings() async {
    try {
      // Reset audio settings to defaults
      _autoPlayNext = false;
      _backgroundPlay = false;
      _audioQuality = AudioQuality.high; // ✅ FIXED
      _enableCrossfade = false;
      _crossfadeDuration = 2.0;
      _enableReplayGain = false;
      _playerMode = PlayerMode.mini; // ✅ FIXED

      // Remove the specific keys from storage
      await _prefs.remove(_autoPlayNextKey);
      await _prefs.remove(_backgroundPlayKey);
      await _prefs.remove(_audioQualityKey);
      await _prefs.remove(_crossfadeKey);
      await _prefs.remove(_crossfadeDurationKey);
      await _prefs.remove(_replayGainKey);
      await _prefs.remove(_playerModeKey);

      notifyListeners();
      debugPrint('[SettingsProvider] 🔄 Audio settings reset to defaults');
    } catch (e) {
      debugPrint('[SettingsProvider] ❌ Error resetting audio settings: $e');
    }
  }

  /// Get all current settings as a map.
  Map<String, dynamic> getAllSettings() {
    return {
      'autoPlayOnSelect': _autoPlayOnSelect,
      'autoPlayNext': _autoPlayNext,
      'backgroundPlay': _backgroundPlay,
      'audioQuality': _audioQuality.name, // ✅ FIXED
      'enableCrossfade': _enableCrossfade,
      'crossfadeDuration': _crossfadeDuration,
      'enableReplayGain': _enableReplayGain,
      'playerMode': _playerMode.name, // ✅ FIXED
    };
  }

  /// Check if a feature requires premium access.
  Future<bool> requiresPremiumForFeature(String feature) async {
    final premiumFeatures = [
      'backgroundPlay',
      'highQualityAudio',
      'crossfade',
      'replayGain',
      'fullPlayerMode',
    ];
    return premiumFeatures.contains(feature);
  }

  /// Get available audio quality options based on premium status.
  Future<List<AudioQuality>> getAvailableAudioQualities() async {
    final hasPremium = await _premiumService.isPremium();
    if (hasPremium) {
      return AudioQuality.values;
    } else {
      return [AudioQuality.low, AudioQuality.medium];
    }
  }

  /// Get available player modes.
  List<PlayerMode> getAvailablePlayerModes() {
    return PlayerMode.values;
  }
}
