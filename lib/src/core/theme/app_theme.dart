// lib/src/core/theme/app_theme.dart

import 'package:flutter/material.dart';

/// A class to hold the application's theme data.
/// REASON: Centralizing theme data ensures a consistent UI, makes rebranding
/// easier, and cleans up widget code by removing inline styling.
class AppTheme {
  // Define color themes map that's referenced in settings
  static const Map<String, Color> colorThemes = {
    'Blue': Color(0xFF2196F3),
    'Green': Color(0xFF4CAF50),
    'Purple': Color(0xFF9C27B0),
    'Orange': Color(0xFFFF9800),
    'Red': Color(0xFFF44336),
    'Teal': Color(0xFF009688),
  };

  // Legacy constants for backward compatibility
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color lightGreyColor = Color(0xFFF5F5F5);

  /// Generate theme based on parameters
  static ThemeData getTheme({
    required bool isDarkMode,
    required String themeColorKey,
  }) {
    final Color selectedColor =
        colorThemes[themeColorKey] ?? colorThemes['Blue']!;

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: selectedColor,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF121212) : lightGreyColor,

      // Define default text styles
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
        labelLarge: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Define a global style for all ElevatedButtons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Define a global style for all TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: selectedColor, width: 2),
        ),
      ),
    );
  }

  /// The main theme for the application (Light Mode) - kept for backward compatibility
  static ThemeData get lightTheme {
    return getTheme(isDarkMode: false, themeColorKey: 'Green');
  }
}
