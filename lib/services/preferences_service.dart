import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  // Save theme mode preference
  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Retrieve theme mode preference
  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  // Save font size preference
  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
  }

  // Retrieve font size preference
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fontSize') ?? 16.0;
  }

  // Save font style preference
  Future<void> saveFontStyle(String fontStyle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontStyle', fontStyle);
  }

  // Retrieve font style preference
  Future<String> getFontStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fontStyle') ?? 'Roboto';
  }

  // Save text alignment preference
  Future<void> saveTextAlign(TextAlign textAlign) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('textAlign', textAlign.index);
  }

  // Retrieve text alignment preference
  Future<TextAlign> getTextAlign() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('textAlign') ?? 0;
    return TextAlign.values[index];
  }
}
