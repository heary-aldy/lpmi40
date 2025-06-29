import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    const fontFamilies = ['Roboto', 'Arial', 'Times New Roman', 'Courier New'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsRow(
                context: context,
                title: 'Dark Mode',
                icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                child: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) =>
                      context.read<SettingsNotifier>().updateDarkMode(value),
                  // FIX: Explicitly set thumb color for better visibility
                  thumbColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Colors.grey.shade400; // Visible color in light mode
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5);
                    }
                    return Colors.grey.shade200;
                  }),
                ),
              ),
              _buildDivider(),
              _buildColorThemePicker(context, settings),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'Text Display',
            children: [
              _buildFontSizeSlider(context, settings),
              _buildDivider(),
              _SettingsRow(
                context: context,
                title: 'Font Family',
                icon: Icons.font_download,
                child: DropdownButton<String>(
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
              _buildDivider(),
              _buildTextAlignSelector(context, settings),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'About',
            children: [
              _SettingsRow(
                context: context,
                title: 'LPMI40',
                subtitle: 'Lagu Pujian Masa Ini v2.0.0',
                icon: Icons.music_note,
              ),
              _buildDivider(),
              _SettingsRow(
                context: context,
                title: 'Developer',
                subtitle: 'Built with Flutter',
                icon: Icons.developer_mode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemePicker(
      BuildContext context, SettingsNotifier settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color Theme', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AppTheme.colorThemes.entries.map((entry) {
              final themeKey = entry.key;
              final color = entry.value;
              final isSelected = settings.colorThemeKey == themeKey;
              return GestureDetector(
                onTap: () =>
                    context.read<SettingsNotifier>().updateColorTheme(themeKey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, SettingsNotifier settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font Size', style: theme.textTheme.titleMedium),
              Text('${settings.fontSize.toInt()}px',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
          Slider(
            value: settings.fontSize,
            min: 12.0,
            max: 30.0,
            divisions: 9,
            label: '${settings.fontSize.round()}px',
            onChanged: (value) =>
                context.read<SettingsNotifier>().updateFontSize(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAlignSelector(
      BuildContext context, SettingsNotifier settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
                value: TextAlign.left, icon: Icon(Icons.format_align_left)),
            ButtonSegment(
                value: TextAlign.center, icon: Icon(Icons.format_align_center)),
            ButtonSegment(
                value: TextAlign.right, icon: Icon(Icons.format_align_right)),
          ],
          selected: {settings.textAlign},
          onSelectionChanged: (newSelection) {
            context
                .read<SettingsNotifier>()
                .updateTextAlign(newSelection.first);
          },
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? child;

  const _SettingsRow({
    required this.context,
    required this.title,
    required this.icon,
    this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: child,
    );
  }
}
