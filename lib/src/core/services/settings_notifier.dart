import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';

class SettingsNotifier extends ChangeNotifier {
  late PreferencesService _prefsService;

  // Initialize all settings with safe default values
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  String _colorThemeKey = 'Blue'; // State for color theme

  // Public getters for the UI to read the current settings
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  TextAlign get textAlign => _textAlign;
  String get colorThemeKey => _colorThemeKey; // Getter for color theme
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefsService = await PreferencesService.init();

    // Load all saved settings
    _isDarkMode = _prefsService.isDarkMode;
    _fontSize = _prefsService.fontSize;
    _fontFamily = _prefsService.fontStyle;
    _textAlign = _prefsService.textAlign;
    _colorThemeKey = _prefsService.colorThemeKey; // Load the saved color theme

    notifyListeners();
  }

  // --- Public methods to update the settings ---

  void updateDarkMode(bool value) {
    _isDarkMode = value;
    _prefsService.saveTheme(value);
    notifyListeners();
  }

  void updateFontSize(double value) {
    _fontSize = value;
    _prefsService.saveFontSize(value);
    notifyListeners();
  }

  void updateFontStyle(String value) {
    _fontFamily = value;
    _prefsService.saveFontStyle(value);
    notifyListeners();
  }

  void updateTextAlign(TextAlign value) {
    _textAlign = value;
    _prefsService.saveTextAlign(value);
    notifyListeners();
  }

  // Method to update the color theme
  void updateColorTheme(String themeKey) {
    _colorThemeKey = themeKey;
    _prefsService.saveColorTheme(themeKey);
    notifyListeners();
  }
}
