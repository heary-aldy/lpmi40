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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Appearance Section ---
          ListTile(
            leading: Icon(Icons.palette_rounded, color: theme.primaryColor),
            title: Text("Appearance", style: theme.textTheme.titleLarge),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.isDarkMode,
            onChanged: (value) =>
                context.read<SettingsNotifier>().updateDarkMode(value),
            secondary:
                Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          // NEW: Color Theme Selector
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Color Theme'),
            trailing: Wrap(
              spacing: 8,
              children: AppTheme.colorThemes.entries.map((entry) {
                final themeKey = entry.key;
                final color = entry.value;
                final isSelected = settings.colorThemeKey == themeKey;
                return GestureDetector(
                  onTap: () => context
                      .read<SettingsNotifier>()
                      .updateColorTheme(themeKey),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(radius: 14, backgroundColor: color),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 32),

          // --- Text Display Section ---
          ListTile(
            leading: Icon(Icons.text_fields_rounded, color: theme.primaryColor),
            title: Text("Text Display", style: theme.textTheme.titleLarge),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Font Size'),
            subtitle: Slider(
              value: settings.fontSize,
              min: 12.0,
              max: 30.0,
              divisions: 9,
              label: settings.fontSize.round().toString(),
              onChanged: (value) =>
                  context.read<SettingsNotifier>().updateFontSize(value),
            ),
            trailing: Text('${settings.fontSize.toInt()}px'),
          ),
        ],
      ),
    );
  }
}
