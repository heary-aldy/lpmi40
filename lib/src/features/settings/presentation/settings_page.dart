import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final theme = Theme.of(context);
    const fontFamilies = ['Roboto', 'Arial', 'Times New Roman', 'Courier New'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Appearance Section ---
          _buildSectionTitle(
            context,
            icon: Icons.palette_rounded,
            title: "Appearance",
          ),
          const SizedBox(height: 8),

          _buildSettingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  settings.isDarkMode
                      ? 'Dark theme enabled'
                      : 'Light theme enabled',
                  style: theme.textTheme.bodySmall,
                ),
                value: settings.isDarkMode,
                onChanged: (value) =>
                    context.read<SettingsNotifier>().updateDarkMode(value),
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
              ),

              const Divider(height: 1),

              // Improved Color Theme Selector
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.color_lens,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Color Theme',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AppTheme.colorThemes.entries.map((entry) {
                        final themeKey = entry.key;
                        final color = entry.value;
                        final isSelected = settings.colorThemeKey == themeKey;

                        return GestureDetector(
                          onTap: () => context
                              .read<SettingsNotifier>()
                              .updateColorTheme(themeKey),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${settings.colorThemeKey}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Text Display Section ---
          _buildSectionTitle(
            context,
            icon: Icons.text_fields_rounded,
            title: "Text Display",
          ),
          const SizedBox(height: 8),

          _buildSettingsCard(
            context,
            children: [
              // Font Size Slider
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_size,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Font Size',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${settings.fontSize.toInt()}px',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: theme.sliderTheme.copyWith(
                        showValueIndicator: ShowValueIndicator.always,
                        valueIndicatorColor: theme.colorScheme.primary,
                      ),
                      child: Slider(
                        value: settings.fontSize,
                        min: 12.0,
                        max: 30.0,
                        divisions: 9,
                        label: '${settings.fontSize.round()}px',
                        onChanged: (value) => context
                            .read<SettingsNotifier>()
                            .updateFontSize(value),
                      ),
                    ),
                    Text(
                      'Preview: The quick brown fox jumps',
                      style: TextStyle(fontSize: settings.fontSize),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Font Family Dropdown
              ListTile(
                leading: Icon(
                  Icons.font_download,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Font Family'),
                subtitle: Text(settings.fontFamily),
                trailing: DropdownButton<String>(
                  value: fontFamilies.contains(settings.fontFamily)
                      ? settings.fontFamily
                      : 'Roboto',
                  underline: const SizedBox.shrink(),
                  items: fontFamilies
                      .map((font) => DropdownMenuItem(
                            value: font,
                            child: Text(font),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsNotifier>().updateFontStyle(value);
                    }
                  },
                ),
              ),

              const Divider(height: 1),

              // Text Alignment
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_align_center,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Text Alignment',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TextAlign>(
                        segments: const [
                          ButtonSegment(
                            value: TextAlign.left,
                            icon: Icon(Icons.format_align_left),
                            label: Text('Left'),
                          ),
                          ButtonSegment(
                            value: TextAlign.center,
                            icon: Icon(Icons.format_align_center),
                            label: Text('Center'),
                          ),
                          ButtonSegment(
                            value: TextAlign.right,
                            icon: Icon(Icons.format_align_right),
                            label: Text('Right'),
                          ),
                        ],
                        selected: {settings.textAlign},
                        onSelectionChanged: (newSelection) {
                          context
                              .read<SettingsNotifier>()
                              .updateTextAlign(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionTitle(
            context,
            icon: Icons.info_outline,
            title: "About",
          ),
          const SizedBox(height: 8),

          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: Icon(
                  Icons.music_note,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('LPMI40'),
                subtitle: const Text('Lagu Pujian Masa Ini v2.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.developer_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Developer'),
                subtitle: const Text('Built with Flutter'),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
