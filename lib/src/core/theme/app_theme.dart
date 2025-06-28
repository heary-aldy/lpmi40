import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue.shade800,
      brightness: Brightness.light,
      primary: Colors.blue.shade800,
      secondary: Colors.teal.shade600,
      surface: Colors.grey.shade100, // Background color for the dashboard
    ),
    scaffoldBackgroundColor: Colors.grey.shade100,
    // CORRECTED: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium:
          TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      headlineSmall:
          TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue.shade700,
      brightness: Brightness.dark,
      primary: Colors.blue.shade300,
      secondary: Colors.teal.shade300,
      surface: const Color(0xFF121212), // Dark background
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    // CORRECTED: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
    ),
  );
}
