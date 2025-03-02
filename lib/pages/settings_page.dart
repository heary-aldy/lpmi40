import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final double currentFontSize;
  final String currentFontStyle;
  final TextAlign currentTextAlign;
  final bool isDarkMode;
  final ValueChanged<double?> onFontSizeChange;
  final ValueChanged<String?> onFontStyleChange;
  final ValueChanged<TextAlign?> onTextAlignChange;

  const SettingsPage({
    super.key,
    required this.currentFontSize,
    required this.currentFontStyle,
    required this.currentTextAlign,
    this.isDarkMode = false,
    required this.onFontSizeChange,
    required this.onFontStyleChange,
    required this.onTextAlignChange,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late double _fontSize;
  late String _fontStyle;
  late TextAlign _textAlign;

  // Available font styles
  final List<String> _availableFontStyles = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Open Sans',
  ];

  // Text alignment options
  final List<TextAlign> _textAlignOptions = [
    TextAlign.left,
    TextAlign.center,
    TextAlign.right,
    TextAlign.justify,
  ];

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentFontSize;
    _fontStyle = widget.currentFontStyle;
    _textAlign = widget.currentTextAlign;
  }

  void _updateFontSize(double value) {
    setState(() {
      _fontSize = value;
    });
    widget.onFontSizeChange(value);
  }

  void _updateFontStyle(String style) {
    setState(() {
      _fontStyle = style;
    });
    widget.onFontStyleChange(style);
  }

  void _updateTextAlign(TextAlign align) {
    setState(() {
      _textAlign = align;
    });
    widget.onTextAlignChange(align);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode;
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color subtextColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor = isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Font Size Section
                Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Font Size',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Slider(
                          value: _fontSize,
                          min: 12.0,
                          max: 30.0,
                          divisions: 18,
                          label: _fontSize.round().toString(),
                          activeColor: selectedColor,
                          inactiveColor: unselectedColor,
                          onChanged: _updateFontSize,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Font Style Section
                Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Font Style',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableFontStyles.map((style) {
                            final isSelected = _fontStyle == style;
                            return ChoiceChip(
                              label: Text(
                                style,
                                style: TextStyle(
                                  color: isSelected 
                                    ? Colors.white 
                                    : textColor,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: selectedColor,
                              backgroundColor: unselectedColor,
                              onSelected: (_) => _updateFontStyle(style),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Text Alignment Section
                Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Alignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _textAlignOptions.map((align) {
                            final isSelected = _textAlign == align;
                            return GestureDetector(
                              onTap: () => _updateTextAlign(align),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? selectedColor.withOpacity(0.2) 
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected 
                                      ? selectedColor 
                                      : unselectedColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  align == TextAlign.left 
                                    ? Icons.format_align_left 
                                    : (align == TextAlign.center 
                                      ? Icons.format_align_center 
                                      : (align == TextAlign.right 
                                        ? Icons.format_align_right 
                                        : Icons.format_align_justify)),
                                  color: isSelected 
                                    ? selectedColor 
                                    : subtextColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Preview Section
                Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview teks dengan pengaturan saat ini',
                          textAlign: _textAlign,
                          style: TextStyle(
                            fontSize: _fontSize,
                            fontFamily: _fontStyle,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}