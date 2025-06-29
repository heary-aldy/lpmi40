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
    'Indigo': Color(0xFF3F51B5),
    'Pink': Color(0xFFE91E63),
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
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54,
        ),
        labelLarge: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: isDarkMode ? Colors.white.withOpacity(0.87) : Colors.black87,
        iconColor: selectedColor,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedColor;
          }
          return isDarkMode ? Colors.grey[400] : Colors.grey[300];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedColor.withOpacity(0.5);
          }
          return isDarkMode ? Colors.grey[700] : Colors.grey[300];
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: selectedColor,
        thumbColor: selectedColor,
        inactiveTrackColor: selectedColor.withOpacity(0.3),
        overlayColor: selectedColor.withOpacity(0.2),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: selectedColor, width: 2),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        thickness: 1,
      ),
    );
  }

  /// The main theme for the application (Light Mode) - kept for backward compatibility
  static ThemeData get lightTheme {
    return getTheme(isDarkMode: false, themeColorKey: 'Green');
  }
}
