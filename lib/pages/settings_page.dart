import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final double currentFontSize;
  final String currentFontStyle;
  final TextAlign currentTextAlign;
  final ValueChanged<double?> onFontSizeChange;
  final ValueChanged<String?> onFontStyleChange;
  final ValueChanged<TextAlign?> onTextAlignChange;

  const SettingsPage({
    super.key,
    required this.currentFontSize,
    required this.currentFontStyle,
    required this.currentTextAlign,
    required this.onFontSizeChange,
    required this.onFontStyleChange,
    required this.onTextAlignChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('Font Size'),
          trailing: DropdownButton<double>(
            value: currentFontSize,
            items: [12.0, 14.0, 16.0, 18.0, 20.0]
                .map((size) => DropdownMenuItem(value: size, child: Text(size.toString())))
                .toList(),
            onChanged: onFontSizeChange,
          ),
        ),
        ListTile(
          title: const Text('Font Style'),
          trailing: DropdownButton<String>(
            value: currentFontStyle,
            items: ['Roboto', 'Arial', 'Times New Roman']
                .map((style) => DropdownMenuItem(value: style, child: Text(style)))
                .toList(),
            onChanged: onFontStyleChange,
          ),
        ),
        ListTile(
          title: const Text('Text Alignment'),
          trailing: DropdownButton<TextAlign>(
            value: currentTextAlign,
            items: TextAlign.values
                .map((align) => DropdownMenuItem(value: align, child: Text(align.toString().split('.').last)))
                .toList(),
            onChanged: onTextAlignChange,
          ),
        ),
      ],
    );
  }
}
