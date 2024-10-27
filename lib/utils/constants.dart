import 'package:flutter/material.dart';

class AppConstants {
  // App-wide Strings
  static const String appTitle = 'Lagu Pujian Masa Ini';
  static const String searchHint = 'Search Songs';
  static const String allSongsLabel = 'All Songs';
  static const String favoritesLabel = 'Favorites';
  static const String toggleThemeLabel = 'Toggle Theme';
  static const String settingsLabel = 'Settings';
  static const String homeLabel = 'Home';
  
  // Error Messages
  static const String loadErrorMessage = 'Failed to load songs data';

  // Font Options
  static const List<String> fontStyles = ['Roboto', 'Arial', 'Times New Roman'];

  // Font Sizes Options
  static const List<double> fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0];

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color favoriteIconColor = Colors.red;
  static const Color lightModeTextColor = Colors.black;
  static const Color darkModeTextColor = Colors.white;

  // AppBar Height (can be adjusted based on design needs)
  static const double appBarHeightFactor = 0.25; // 25% of screen height
}
