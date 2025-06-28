import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';

class SettingsNotifier extends ChangeNotifier {
  late PreferencesService _prefsService;

  // CORRECTED: All variables are initialized with safe default values.
  bool _isDarkMode = false;
  String _colorThemeKey = 'Blue'; // Default theme is Blue
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;

  // Public getters for widgets to access the settings
  bool get isDarkMode => _isDarkMode;
  String get colorThemeKey => _colorThemeKey;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  TextAlign get textAlign => _textAlign;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefsService = await PreferencesService.init();

    // Load saved settings, which will overwrite the defaults
    _isDarkMode = _prefsService.isDarkMode;
    _colorThemeKey = _prefsService.colorThemeKey;
    _fontSize = _prefsService.fontSize;
    _fontFamily = _prefsService.fontStyle;
    _textAlign = _prefsService.textAlign;

    // Notify any listening widgets that the real settings have been loaded.
    notifyListeners();
  }

  // --- Methods to update settings ---

  void updateDarkMode(bool value) {
    _isDarkMode = value;
    _prefsService.saveTheme(value);
    notifyListeners();
  }

  void updateColorTheme(String themeKey) {
    _colorThemeKey = themeKey;
    _prefsService.saveColorTheme(themeKey);
    notifyListeners();
  }

  void updateFontSize(double value) {
    _fontSize = value;
    _prefsService.saveFontSize(value);
    notifyListeners();
  }
}
