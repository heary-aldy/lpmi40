// preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
  }

  Future<void> saveFontStyle(String fontStyle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontStyle', fontStyle);
  }

  Future<void> saveTextAlign(TextAlign textAlign) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('textAlign', textAlign.index);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fontSize') ?? 16.0;
  }

  Future<String> getFontStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fontStyle') ?? 'Roboto';
  }

  Future<TextAlign> getTextAlign() async {
    final prefs = await SharedPreferences.getInstance();
    return TextAlign.values[prefs.getInt('textAlign') ?? 0];
  }
}
