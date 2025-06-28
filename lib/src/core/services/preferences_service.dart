import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  // Private constructor
  PreferencesService._(this._prefs);

  // Static factory method to create an instance
  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // Define keys for the preferences to avoid typos
  static const String _keyTheme = 'theme';
  static const String _keyFontSize = 'font_size';
  static const String _keyFontStyle = 'font_style';
  static const String _keyTextAlign = 'text_align';

  // --- Theme Preference ---
  Future<void> saveTheme(bool isDarkMode) async {
    await _prefs.setBool(_keyTheme, isDarkMode);
  }

  bool get isDarkMode =>
      _prefs.getBool(_keyTheme) ?? false; // Default to light mode

  // --- Font Size Preference ---
  Future<void> saveFontSize(double fontSize) async {
    await _prefs.setDouble(_keyFontSize, fontSize);
  }

  double get fontSize =>
      _prefs.getDouble(_keyFontSize) ?? 16.0; // Default to 16.0

  // --- Font Style Preference ---
  Future<void> saveFontStyle(String fontStyle) async {
    await _prefs.setString(_keyFontStyle, fontStyle);
  }

  String get fontStyle =>
      _prefs.getString(_keyFontStyle) ?? 'Roboto'; // Default to Roboto

  // --- Text Align Preference ---
  Future<void> saveTextAlign(TextAlign textAlign) async {
    // Store the enum's index as an integer
    await _prefs.setInt(_keyTextAlign, textAlign.index);
  }

  TextAlign get textAlign {
    final index = _prefs.getInt(_keyTextAlign);
    if (index != null && index < TextAlign.values.length) {
      return TextAlign.values[index];
    }
    return TextAlign.left; // Default to left alignment
  }
}
