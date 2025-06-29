// lib/app/themes/app_theme.dart

import 'package:flutter/material.dart';

/// A class to hold the application's theme data.
/// REASON: Centralizing theme data ensures a consistent UI, makes rebranding
/// easier, and cleans up widget code by removing inline styling.
class AppTheme {
  // NEW: Define primary colors for easy reuse.
  static const Color primaryColor = Color(0xFF4CAF50); // A nice green
  static const Color secondaryColor =
      Color(0xFFFF9800); // A complementary orange
  static const Color lightGreyColor = Color(0xFFF5F5F5);

  /// The main theme for the application (Light Mode).
  static ThemeData get lightTheme {
    return ThemeData(
      // NEW: Use colorScheme for modern theming.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: lightGreyColor, // Background color for scaffolds
        error: Colors.red[700],
      ),
      scaffoldBackgroundColor: lightGreyColor,

      // NEW: Define default text styles.
      textTheme: const TextTheme(
        // For large titles like "LPMI IAIN PALOPO"
        displayLarge: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        // For standard body text
        bodyLarge: TextStyle(
          fontSize: 16.0,
          color: Colors.black87,
        ),
        // For button labels
        labelLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // NEW: Define a global style for all ElevatedButtons.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 52), // Full width, 52px height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // NEW: Define a global style for all TextFields.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // No border for a cleaner look
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
