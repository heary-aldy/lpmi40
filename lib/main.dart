import 'package:flutter/material.dart';
import 'package:lpmi40/services/preferences_service.dart';
import 'package:lpmi40/pages/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  double fontSize = 16.0;
  String fontStyle = 'Roboto';
  TextAlign textAlign = TextAlign.left;
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final darkMode = await _preferencesService.getThemeMode();
    final fSize = await _preferencesService.getFontSize();
    final fStyle = await _preferencesService.getFontStyle();
    final tAlign = await _preferencesService.getTextAlign();

    setState(() {
      isDarkMode = darkMode;
      fontSize = fSize;
      fontStyle = fStyle;
      textAlign = tAlign;
    });
  }

  void _updateThemeMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _preferencesService.saveThemeMode(isDarkMode);
  }

  void _updateFontSize(double? size) {
    if (size != null) {
      setState(() {
        fontSize = size;
      });
      _preferencesService.saveFontSize(fontSize);
    }
  }

  void _updateFontStyle(String? style) {
    if (style != null) {
      setState(() {
        fontStyle = style;
      });
      _preferencesService.saveFontStyle(fontStyle);
    }
  }

  void _updateTextAlign(TextAlign? align) {
    if (align != null) {
      setState(() {
        textAlign = align;
      });
      _preferencesService.saveTextAlign(textAlign);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lagu Pujian Masa Ini',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize, fontFamily: fontStyle),
        ),
      ),
      home: MainPage(
        isDarkMode: isDarkMode,
        fontSize: fontSize,
        fontStyle: fontStyle,
        textAlign: textAlign,
        onToggleTheme: _updateThemeMode,
        onFontSizeChange: _updateFontSize,
        onFontStyleChange: _updateFontStyle,
        onTextAlignChange: _updateTextAlign,
      ),
    );
  }
}
