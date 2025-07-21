// lib/src/features/settings/presentation/dialogs/settings_dialogs.dart
// ✅ NEW: Extracted dialog widgets from settings_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';

// ✅ FONT SIZE DIALOG
class FontSizeDialog extends StatefulWidget {
  final SettingsNotifier settings;

  const FontSizeDialog({super.key, required this.settings});

  @override
  State<FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<FontSizeDialog> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.settings.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Font Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Size: ${_fontSize.toStringAsFixed(0)}px'),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (value) => setState(() => _fontSize = value),
          ),
          const SizedBox(height: 16),
          Text(
            'Sample text at ${_fontSize.toStringAsFixed(0)}px',
            style: TextStyle(fontSize: _fontSize),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.settings.updateFontSize(_fontSize);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// ✅ FONT FAMILY DIALOG
class FontFamilyDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const FontFamilyDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final fonts = ['Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins'];

    return AlertDialog(
      title: const Text('Font Family'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fonts.length,
          itemBuilder: (context, index) {
            final font = fonts[index];
            final isSelected = settings.fontFamily == font;

            return ListTile(
              title: Text(
                font,
                style: TextStyle(fontFamily: font),
              ),
              leading: Radio<String>(
                value: font,
                groupValue: settings.fontFamily,
                onChanged: (value) {
                  if (value != null) {
                    settings.updateFontStyle(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              selected: isSelected,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ✅ TEXT ALIGNMENT DIALOG
class TextAlignmentDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const TextAlignmentDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final alignments = [
      (TextAlign.left, 'Left', Icons.format_align_left),
      (TextAlign.center, 'Center', Icons.format_align_center),
      (TextAlign.right, 'Right', Icons.format_align_right),
      (TextAlign.justify, 'Justify', Icons.format_align_justify),
    ];

    return AlertDialog(
      title: const Text('Text Alignment'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: alignments.length,
          itemBuilder: (context, index) {
            final (align, name, icon) = alignments[index];
            final isSelected = settings.textAlign == align;

            return ListTile(
              leading: Icon(icon),
              title: Text(name),
              trailing: Radio<TextAlign>(
                value: align,
                groupValue: settings.textAlign,
                onChanged: (value) {
                  if (value != null) {
                    settings.updateTextAlign(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              selected: isSelected,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ✅ COLOR THEME DIALOG
class ColorThemeDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const ColorThemeDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final themes = [
      ('Blue', Colors.blue),
      ('Green', Colors.green),
      ('Purple', Colors.purple),
      ('Orange', Colors.orange),
      ('Red', Colors.red),
      ('Teal', Colors.teal),
    ];

    return AlertDialog(
      title: const Text('Color Theme'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final (name, color) = themes[index];
            final isSelected = settings.colorThemeKey == name;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                radius: 12,
              ),
              title: Text(name),
              trailing: Radio<String>(
                value: name,
                groupValue: settings.colorThemeKey,
                onChanged: (value) {
                  if (value != null) {
                    settings.updateColorTheme(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              selected: isSelected,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ✅ AUDIO QUALITY DIALOG
class AudioQualityDialog extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const AudioQualityDialog({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Audio Quality'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AudioQuality.values.length,
          itemBuilder: (context, index) {
            final quality = AudioQuality.values[index];
            final isSelected = settingsProvider.audioQuality == quality;

            return ListTile(
              title: Text(quality.displayName),
              subtitle: Text(quality.description),
              trailing: Radio<AudioQuality>(
                value: quality,
                groupValue: settingsProvider.audioQuality,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setAudioQuality(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              selected: isSelected,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ✅ PLAYER MODE DIALOG
class PlayerModeDialog extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const PlayerModeDialog({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Player Mode'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: PlayerMode.values.length,
          itemBuilder: (context, index) {
            final mode = PlayerMode.values[index];
            final isSelected = settingsProvider.playerMode == mode;

            return ListTile(
              title: Text(mode.displayName),
              subtitle: Text(mode.description),
              trailing: Radio<PlayerMode>(
                value: mode,
                groupValue: settingsProvider.playerMode,
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setPlayerMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              selected: isSelected,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ✅ CONFIRMATION DIALOG (Reusable)
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}

// ✅ INFO DIALOG (Reusable)
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? content;
  final String buttonText;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.content,
    this.buttonText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content ?? Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

// ✅ COMING SOON DIALOG
class ComingSoonDialog extends StatelessWidget {
  final String feature;

  const ComingSoonDialog({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$feature - Coming Soon'),
      content: Text(
        '$feature will be available in a future update. Stay tuned for more features!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// ✅ LOADING DIALOG
class LoadingDialog extends StatelessWidget {
  final String message;

  const LoadingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}
