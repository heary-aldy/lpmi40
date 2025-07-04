// lib/src/features/admin/presentation/widgets/announcement_customization_widgets.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';

/// Color picker widget for text and background colors
class ColorPickerWidget extends StatelessWidget {
  final String title;
  final Map<String, Color> colors;
  final String? selectedColor;
  final Function(String) onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.title,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.entries.map((entry) {
            final isSelected = selectedColor == entry.key;
            return GestureDetector(
              onTap: () => onColorSelected(entry.key),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Gradient picker widget for background gradients
class GradientPickerWidget extends StatelessWidget {
  final String? selectedGradient;
  final Function(String) onGradientSelected;

  const GradientPickerWidget({
    super.key,
    required this.selectedGradient,
    required this.onGradientSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Gradient',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AnnouncementTheme.backgroundGradients.entries.map((entry) {
            final isSelected = selectedGradient == entry.key;
            return GestureDetector(
              onTap: () => onGradientSelected(entry.key),
              child: Container(
                width: 60,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: entry.value,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Icon picker widget with categories
class IconPickerWidget extends StatefulWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;

  const IconPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  String _selectedCategory = 'general';

  final Map<String, List<String>> iconCategories = {
    'general': [
      'campaign',
      'announcement',
      'info',
      'star',
      'favorite',
      'thumb_up',
      'celebration'
    ],
    'events': ['event', 'calendar', 'schedule', 'alarm', 'access_time'],
    'business': [
      'business',
      'trending_up',
      'analytics',
      'money',
      'shopping',
      'local_offer'
    ],
    'social': ['people', 'group', 'forum', 'chat', 'message'],
    'technology': ['computer', 'phone', 'wifi', 'cloud', 'security', 'update'],
    'weather': ['wb_sunny', 'wb_cloudy', 'umbrella', 'ac_unit'],
    'food': ['restaurant', 'local_cafe', 'cake', 'local_pizza'],
    'transport': ['directions_car', 'flight', 'train', 'directions_bus'],
    'health': [
      'health_and_safety',
      'medical_services',
      'fitness_center',
      'spa'
    ],
    'education': ['school', 'menu_book', 'quiz', 'psychology'],
    'entertainment': ['movie', 'music_note', 'games', 'sports_soccer'],
    'location': ['location_on', 'map', 'home', 'work'],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Icon',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Category selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: iconCategories.keys.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Icon grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: iconCategories[_selectedCategory]!.map((iconName) {
            final isSelected = widget.selectedIcon == iconName;
            return GestureDetector(
              onTap: () => widget.onIconSelected(iconName),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.indigo.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  AnnouncementTheme.getIcon(iconName),
                  color: isSelected ? Colors.indigo : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Text style picker widget
class TextStylePickerWidget extends StatelessWidget {
  final String? selectedTextStyle;
  final Function(String) onTextStyleSelected;

  const TextStylePickerWidget({
    super.key,
    required this.selectedTextStyle,
    required this.onTextStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = {
      'normal': 'Normal',
      'bold': 'Bold',
      'italic': 'Italic',
      'bold-italic': 'Bold Italic',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Style',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: textStyles.entries.map((entry) {
            final isSelected = selectedTextStyle == entry.key;
            return GestureDetector(
              onTap: () => onTextStyleSelected(entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.indigo.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.indigo : Colors.grey.shade600,
                    fontWeight: entry.key.contains('bold')
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontStyle: entry.key.contains('italic')
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Font size slider widget
class FontSizeSliderWidget extends StatelessWidget {
  final double? fontSize;
  final Function(double) onFontSizeChanged;

  const FontSizeSliderWidget({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Font Size',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              '${(fontSize ?? 14.0).toInt()}px',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: fontSize ?? 14.0,
          min: 10.0,
          max: 24.0,
          divisions: 14,
          onChanged: onFontSizeChanged,
          activeColor: Colors.indigo,
        ),
      ],
    );
  }
}

/// Preview widget to show how the announcement will look
class AnnouncementPreviewWidget extends StatelessWidget {
  final String title;
  final String content;
  final String? selectedIcon;
  final String? iconColor;
  final String? textColor;
  final String? backgroundColor;
  final String? backgroundGradient;
  final String? textStyle;
  final double? fontSize;

  const AnnouncementPreviewWidget({
    super.key,
    required this.title,
    required this.content,
    this.selectedIcon,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.textStyle,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: backgroundGradient != null
                ? null
                : (backgroundColor != null
                    ? AnnouncementTheme.getBackgroundColor(backgroundColor)
                    : Colors.grey.shade100),
            gradient: backgroundGradient != null
                ? LinearGradient(
                    colors:
                        AnnouncementTheme.getGradientColors(backgroundGradient),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectedIcon != null) ...[
                    Icon(
                      AnnouncementTheme.getIcon(selectedIcon),
                      color: AnnouncementTheme.getIconColor(iconColor),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : 'Announcement Title',
                      style: TextStyle(
                        fontSize: (fontSize ?? 14.0) + 2,
                        fontWeight: textStyle?.contains('bold') == true
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontStyle: textStyle?.contains('italic') == true
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: AnnouncementTheme.getTextColor(textColor),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  content.isNotEmpty
                      ? content
                      : 'Your announcement content will appear here...',
                  style: TextStyle(
                    fontSize: fontSize ?? 14.0,
                    fontWeight: textStyle?.contains('bold') == true
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontStyle: textStyle?.contains('italic') == true
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: AnnouncementTheme.getTextColor(textColor),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
