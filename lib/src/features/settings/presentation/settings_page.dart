import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';

class SettingsPage extends StatefulWidget {
  // Callbacks to notify the parent widget (SongLyricsPage) of live changes
  final ValueChanged<double> onFontSizeChange;
  final ValueChanged<String> onFontStyleChange;
  final ValueChanged<TextAlign> onTextAlignChange;

  const SettingsPage({
    super.key,
    required this.onFontSizeChange,
    required this.onFontStyleChange,
    required this.onTextAlignChange,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late PreferencesService _prefsService;
  bool _isLoading = true;

  // Local state for UI
  late double _fontSize;
  late String _fontStyle;
  late TextAlign _textAlign;

  final List<String> _availableFontStyles = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Open Sans',
  ];

  final List<TextAlign> _textAlignOptions = [
    TextAlign.left,
    TextAlign.center,
    TextAlign.right,
    TextAlign.justify,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Asynchronously load settings from device storage
  Future<void> _loadSettings() async {
    _prefsService = await PreferencesService.init();
    setState(() {
      _fontSize = _prefsService.fontSize;
      _fontStyle = _prefsService.fontStyle;
      _textAlign = _prefsService.textAlign;
      _isLoading = false;
    });
  }

  // --- Update Methods ---

  void _updateFontSize(double value) {
    setState(() {
      _fontSize = value;
    });
    _prefsService.saveFontSize(value);
    widget.onFontSizeChange(value); // Notify parent
  }

  void _updateFontStyle(String style) {
    setState(() {
      _fontStyle = style;
    });
    _prefsService.saveFontStyle(style);
    widget.onFontStyleChange(style); // Notify parent
  }

  void _updateTextAlign(TextAlign align) {
    setState(() {
      _textAlign = align;
    });
    _prefsService.saveTextAlign(align);
    widget.onTextAlignChange(align); // Notify parent
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;

    // Show a loading spinner while preferences are being loaded
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Text Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // --- Font Size Section ---
            Text('Font Size', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 30.0,
              divisions: 18,
              label: _fontSize.round().toString(),
              activeColor: selectedColor,
              onChanged: _updateFontSize,
            ),
            const SizedBox(height: 24),

            // --- Font Style Section ---
            Text('Font Style', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableFontStyles.map((style) {
                final isSelected = _fontStyle == style;
                return ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  selectedColor: selectedColor,
                  onSelected: (_) => _updateFontStyle(style),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // --- Text Alignment Section ---
            Text('Text Alignment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _textAlignOptions.map((align) {
                final isSelected = _textAlign == align;
                return GestureDetector(
                  onTap: () => _updateTextAlign(align),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? selectedColor : unselectedColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getIconForTextAlign(align),
                      color: isSelected
                          ? selectedColor
                          : Theme.of(context).iconTheme.color,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // --- Preview Section ---
            Text('Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Text(
                'This is a preview of the text with the current settings.',
                textAlign: _textAlign,
                style: TextStyle(
                    fontSize: _fontSize, fontFamily: _fontStyle, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.center:
        return Icons.format_align_center;
      case TextAlign.right:
        return Icons.format_align_right;
      case TextAlign.justify:
        return Icons.format_align_justify;
      default:
        return Icons.format_align_left;
    }
  }
}
