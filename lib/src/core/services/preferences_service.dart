import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
