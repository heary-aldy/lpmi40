import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late PreferencesService _prefsService;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  // Local state for UI controls
  late double _fontSize;
  late String _fontFamily;
  late TextAlign _textAlign;
  late bool _isDarkMode;

  // List of available fonts
  final List<String> _fontFamilies = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefsService = await PreferencesService.init();
    if (mounted) {
      setState(() {
        _fontSize = _prefsService.fontSize;
        _fontFamily = _prefsService.fontStyle;
        _textAlign = _prefsService.textAlign;
        _isDarkMode = _prefsService.isDarkMode;
        _isLoading = false;
      });
    }
  }

  void _onSettingChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    await _prefsService.saveFontSize(_fontSize);
    await _prefsService.saveFontStyle(_fontFamily);
    await _prefsService.saveTextAlign(_textAlign);
    await _prefsService.saveTheme(_isDarkMode);

    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<bool> _handlePop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard')),
          FilledButton(
            onPressed: () async {
              await _saveSettings();
              if (mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('Save'),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionHeader(
                      'Text Display', Icons.text_fields_rounded),
                  _buildFontSizeSlider(),
                  const Divider(),
                  _buildFontFamilySelector(),
                  const Divider(),
                  _buildTextAlignmentSelector(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Appearance', Icons.palette_rounded),
                  _buildDarkModeSwitch(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Preview', Icons.preview_rounded),
                  _buildPreviewPane(),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Font Size'),
      subtitle: Slider(
        value: _fontSize,
        min: 12.0,
        max: 30.0,
        divisions: 9,
        label: _fontSize.round().toString(),
        onChanged: (value) {
          setState(() => _fontSize = value);
          _onSettingChanged();
        },
      ),
      trailing: Text('${_fontSize.toInt()}px'),
    );
  }

  // CORRECTED: This now displays font names as plain text to prevent freezing.
  Widget _buildFontFamilySelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Font Family'),
      trailing: DropdownButton<String>(
        value: _fontFamily,
        items: _fontFamilies
            .map((font) => DropdownMenuItem(
                  value: font,
                  // The Text widget no longer applies the custom font family here.
                  child: Text(font),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null && _fontFamilies.contains(value)) {
            setState(() => _fontFamily = value);
            _onSettingChanged();
          }
        },
      ),
    );
  }

  Widget _buildTextAlignmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Alignment'),
        const SizedBox(height: 12),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
                value: TextAlign.left, icon: Icon(Icons.format_align_left)),
            ButtonSegment(
                value: TextAlign.center, icon: Icon(Icons.format_align_center)),
            ButtonSegment(
                value: TextAlign.right, icon: Icon(Icons.format_align_right)),
            ButtonSegment(
                value: TextAlign.justify,
                icon: Icon(Icons.format_align_justify)),
          ],
          selected: {_textAlign},
          onSelectionChanged: (newSelection) {
            setState(() => _textAlign = newSelection.first);
            _onSettingChanged();
          },
        ),
      ],
    );
  }

  Widget _buildDarkModeSwitch() {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: _isDarkMode,
      onChanged: (value) {
        setState(() => _isDarkMode = value);
        _onSettingChanged();
      },
      secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
    );
  }

  Widget _buildPreviewPane() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'This is how your song lyrics will appear with the current settings.',
          style: TextStyle(
              fontSize: _fontSize, fontFamily: _fontFamily, height: 1.5),
          textAlign: _textAlign,
        ),
      ),
    );
  }
}
