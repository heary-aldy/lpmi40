import 'package:flutter/material.dart';

class AppTheme {
  // Map of available color themes
  static final Map<String, Color> colorThemes = {
    'Blue': Colors.blue.shade800,
    'Green': Colors.green.shade800,
    'Purple': Colors.purple.shade800,
    'Orange': Colors.orange.shade800,
  };

  static ThemeData getTheme(
      {required bool isDarkMode, required String themeColorKey}) {
    final seedColor = colorThemes[themeColorKey] ?? Colors.blue.shade800;
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        surface: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100,
      ),
      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 1),
        ),
      ),
    );
  }
}
