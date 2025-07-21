import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesService {
  final SharedPreferences _prefs;
  PreferencesService._(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // Define keys
  static const String _keyTheme = 'is_dark_mode';
  static const String _keyColorTheme = 'color_theme'; // New key
  static const String _keyFontSize = 'font_size';
  static const String _keyFontStyle = 'font_style';
  static const String _keyTextAlign = 'text_align';
  static const String _keyPinnedFeatures = 'pinned_features';
  static const String _keyDashboardPreferences = 'dashboard_preferences';
  static const String _keyLastActivity = 'last_activity';

  // --- Color Theme Preference ---
  Future<void> saveColorTheme(String themeKey) async {
    await _prefs.setString(_keyColorTheme, themeKey);
  }

  String get colorThemeKey =>
      _prefs.getString(_keyColorTheme) ?? 'Blue'; // Default to Blue

  // --- Other preferences remain the same ---
  bool get isDarkMode => _prefs.getBool(_keyTheme) ?? false;
  Future<void> saveTheme(bool isDarkMode) =>
      _prefs.setBool(_keyTheme, isDarkMode);

  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 16.0;
  Future<void> saveFontSize(double fontSize) =>
      _prefs.setDouble(_keyFontSize, fontSize);

  String get fontStyle => _prefs.getString(_keyFontStyle) ?? 'Roboto';
  Future<void> saveFontStyle(String fontStyle) =>
      _prefs.setString(_keyFontStyle, fontStyle);

  TextAlign get textAlign {
    final index = _prefs.getInt(_keyTextAlign);
    return (index != null && index < TextAlign.values.length)
        ? TextAlign.values[index]
        : TextAlign.left;
  }

  Future<void> saveTextAlign(TextAlign textAlign) =>
      _prefs.setInt(_keyTextAlign, textAlign.index);

  // --- New Dashboard Methods ---

  /// Get pinned features list
  Future<List<String>> getPinnedFeatures() async {
    final stringList = _prefs.getStringList(_keyPinnedFeatures);
    return stringList ?? [];
  }

  /// Save pinned features list
  Future<void> savePinnedFeatures(List<String> pinnedFeatures) async {
    await _prefs.setStringList(_keyPinnedFeatures, pinnedFeatures);
  }

  /// Get dashboard preferences as a map
  Future<Map<String, dynamic>> getDashboardPreferences() async {
    final jsonString = _prefs.getString(_keyDashboardPreferences);
    if (jsonString == null) return {};

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Save dashboard preferences
  Future<void> saveDashboardPreferences(
      Map<String, dynamic> preferences) async {
    final jsonString = json.encode(preferences);
    await _prefs.setString(_keyDashboardPreferences, jsonString);
  }

  /// Get last activity timestamp
  Future<DateTime?> getLastActivity() async {
    final timestamp = _prefs.getInt(_keyLastActivity);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Save last activity timestamp
  Future<void> saveLastActivity(DateTime lastActivity) async {
    await _prefs.setInt(_keyLastActivity, lastActivity.millisecondsSinceEpoch);
  }

  /// Update last activity to now
  Future<void> updateLastActivity() async {
    await saveLastActivity(DateTime.now());
  }
}
