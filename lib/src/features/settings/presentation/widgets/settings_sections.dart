// lib/src/features/settings/presentation/widgets/settings_sections.dart
// ✅ NEW: Extracted individual sections from settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';
import 'package:lpmi40/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:lpmi40/src/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:lpmi40/src/features/settings/presentation/dialogs/settings_dialogs.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/utils/constants.dart';

// ✅ USER PROFILE SECTION
class UserProfileSection extends StatelessWidget {
  final DeviceType deviceType;

  const UserProfileSection({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final user = controller.getCurrentUser();
        if (user == null) return const SizedBox.shrink();

        final scale = AppConstants.getTypographyScale(deviceType);
        final spacing = AppConstants.getSpacing(deviceType);

        return SettingsGroup(
          title: 'Profile',
          deviceType: deviceType,
          children: [
            Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24 * scale,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.isAnonymous
                          ? 'G'
                          : (user.displayName?.isNotEmpty == true
                              ? user.displayName![0].toUpperCase()
                              : user.email![0].toUpperCase()),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isAnonymous
                              ? 'Guest User'
                              : user.displayName ?? 'LPMI User',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: (Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.fontSize ??
                                            16) *
                                        scale,
                                  ),
                        ),
                        Text(
                          user.email ?? 'No email',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: (Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.fontSize ??
                                            12) *
                                        scale,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: user.isAnonymous
                          ? Colors.orange.withOpacity(0.2)
                          : (controller.isPremium
                              ? Colors.purple.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.getUserStatusText(),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: user.isAnonymous
                            ? Colors.orange
                            : (controller.isPremium
                                ? Colors.purple
                                : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ✅ DISPLAY SETTINGS SECTION
class DisplaySettingsSection extends StatelessWidget {
  final DeviceType deviceType;

  const DisplaySettingsSection({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsNotifier>(
      builder: (context, settings, child) {
        return SettingsGroup(
          title: 'Display',
          deviceType: deviceType,
          children: [
            SettingsTile(
              title: 'Dark Mode',
              subtitle: settings.isDarkMode ? 'Enabled' : 'Disabled',
              icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              deviceType: deviceType,
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: (value) {
                  // ✅ FIX: Ensure proper theme update
                  settings.updateDarkMode(value);
                  // Force rebuild of MaterialApp
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      // This ensures the theme change propagates properly
                      (context as Element).markNeedsBuild();
                    }
                  });
                },
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: 'Font Size',
              subtitle: '${settings.fontSize.toStringAsFixed(0)}px',
              icon: Icons.format_size,
              deviceType: deviceType,
              onTap: () => _showFontSizeDialog(context, settings),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: 'Font Family',
              subtitle: settings.fontFamily,
              icon: Icons.font_download,
              deviceType: deviceType,
              onTap: () => _showFontFamilyDialog(context, settings),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: 'Text Alignment',
              subtitle: _getTextAlignmentName(settings.textAlign),
              icon: Icons.format_align_left,
              deviceType: deviceType,
              onTap: () => _showTextAlignmentDialog(context, settings),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: 'Color Theme',
              subtitle: settings.colorThemeKey,
              icon: Icons.palette,
              deviceType: deviceType,
              onTap: () => _showColorThemeDialog(context, settings),
            ),
          ],
        );
      },
    );
  }

  String _getTextAlignmentName(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'Left';
      case TextAlign.center:
        return 'Center';
      case TextAlign.right:
        return 'Right';
      case TextAlign.justify:
        return 'Justify';
      default:
        return 'Left';
    }
  }

  void _showFontSizeDialog(BuildContext context, SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => FontSizeDialog(settings: settings),
    );
  }

  void _showFontFamilyDialog(BuildContext context, SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => FontFamilyDialog(settings: settings),
    );
  }

  void _showTextAlignmentDialog(
      BuildContext context, SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => TextAlignmentDialog(settings: settings),
    );
  }

  void _showColorThemeDialog(BuildContext context, SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => ColorThemeDialog(settings: settings),
    );
  }
}

// ✅ PREMIUM SETTINGS SECTION
class PremiumSettingsSection extends StatelessWidget {
  final DeviceType deviceType;

  const PremiumSettingsSection({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        if (controller.isLoadingPremium) {
          return SettingsGroup(
            title: 'Premium Features',
            deviceType: deviceType,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        return SettingsGroup(
          title: 'Premium Features',
          deviceType: deviceType,
          children: [
            if (controller.isPremium) ...[
              _buildPremiumActiveCard(context, deviceType),
              const SettingsDivider(),
              SettingsRow(
                title: 'Manage Premium',
                subtitle: 'Premium features and settings',
                icon: Icons.settings,
                deviceType: deviceType,
                onTap: () => _showPremiumManagement(context),
              ),
            ] else ...[
              _buildPremiumUpgradeCard(context, deviceType, controller),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPremiumActiveCard(BuildContext context, DeviceType deviceType) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.purple, size: 24 * scale),
              SizedBox(width: spacing * 0.5),
              Text(
                'Premium Active',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.75),
          Text(
            'You have access to all premium features including:',
            style: TextStyle(
              fontSize: 14 * scale,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          ...([
            '🎵 Audio playback for all songs',
            '⚙️ Advanced audio settings',
            '🎛️ Custom audio controls',
            '📱 Background audio playback',
            '🔄 Crossfade and audio effects',
          ].map((feature) => Padding(
                padding: EdgeInsets.only(bottom: spacing * 0.25),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeCard(BuildContext context, DeviceType deviceType,
      SettingsController controller) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: Colors.orange, size: 24 * scale),
              SizedBox(width: spacing * 0.5),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.75),
          Text(
            'Unlock premium features and enhance your experience:',
            style: TextStyle(
              fontSize: 14 * scale,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          ...([
            '🎵 Audio playback for all songs',
            '⚙️ Advanced audio settings',
            '🎛️ Premium audio controls',
            '📱 Background audio playback',
            '🔄 Audio effects and enhancements',
          ].map((feature) => Padding(
                padding: EdgeInsets.only(bottom: spacing * 0.25),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ))),
          SizedBox(height: spacing),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await PremiumUpgradeDialogs.showFullUpgradePage(
                  context,
                  feature: 'premium_settings',
                  customMessage: 'Upgrade to Premium to access advanced settings and premium features!',
                );
                // Refresh premium status after potential upgrade
                await controller.loadPremiumStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 18 * scale),
                  SizedBox(width: spacing * 0.5),
                  Text(
                    'Upgrade Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your premium subscription is active.'),
            SizedBox(height: 16),
            Text('Premium Features:'),
            Text('• Audio playback'),
            Text('• Advanced settings'),
            Text('• Premium audio controls'),
            Text('• Background playback'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ✅ AUDIO SETTINGS SECTION
class AudioSettingsSection extends StatelessWidget {
  final DeviceType deviceType;

  const AudioSettingsSection({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, SettingsController>(
      builder: (context, settingsProvider, controller, child) {
        return SettingsGroup(
          title: 'Audio Settings',
          deviceType: deviceType,
          children: [
            if (controller.isPremium) ...[
              SettingsTile(
                title: 'Auto-play on Select',
                subtitle:
                    settingsProvider.autoPlayOnSelect ? 'Enabled' : 'Disabled',
                icon: Icons.play_arrow,
                deviceType: deviceType,
                trailing: Switch(
                  value: settingsProvider.autoPlayOnSelect,
                  onChanged: (value) =>
                      settingsProvider.setAutoPlayOnSelect(value),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                title: 'Auto-play Next Song',
                subtitle:
                    settingsProvider.autoPlayNext ? 'Enabled' : 'Disabled',
                icon: Icons.skip_next,
                deviceType: deviceType,
                trailing: Switch(
                  value: settingsProvider.autoPlayNext,
                  onChanged: (value) => settingsProvider.setAutoPlayNext(value),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                title: 'Background Play',
                subtitle:
                    settingsProvider.backgroundPlay ? 'Enabled' : 'Disabled',
                icon: Icons.play_circle_outline,
                deviceType: deviceType,
                trailing: Switch(
                  value: settingsProvider.backgroundPlay,
                  onChanged: (value) =>
                      settingsProvider.setBackgroundPlay(value),
                ),
              ),
              const SettingsDivider(),
              SettingsRow(
                title: 'Audio Quality',
                subtitle: settingsProvider.audioQuality.displayName,
                icon: Icons.high_quality,
                deviceType: deviceType,
                onTap: () => _showAudioQualityDialog(context, settingsProvider),
              ),
              const SettingsDivider(),
              SettingsRow(
                title: 'Player Mode',
                subtitle: settingsProvider.playerMode.displayName,
                icon: Icons.music_video,
                deviceType: deviceType,
                onTap: () => _showPlayerModeDialog(context, settingsProvider),
              ),
              const SettingsDivider(),
              SettingsRow(
                title: 'Reset Audio Settings',
                subtitle: 'Restore audio defaults',
                icon: Icons.restore,
                deviceType: deviceType,
                onTap: () => _resetAudioSettings(context, settingsProvider),
              ),
            ] else ...[
              PremiumLockedSection(deviceType: deviceType),
            ],
          ],
        );
      },
    );
  }

  void _showAudioQualityDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          AudioQualityDialog(settingsProvider: settingsProvider),
    );
  }

  void _showPlayerModeDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          PlayerModeDialog(settingsProvider: settingsProvider),
    );
  }

  Future<void> _resetAudioSettings(
      BuildContext context, SettingsProvider settingsProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Audio Settings'),
        content: const Text(
            'This will restore all audio settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settingsProvider.resetAudioSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio settings reset to defaults.')),
        );
      }
    }
  }
}

// ✅ PREMIUM LOCKED SECTION
class PremiumLockedSection extends StatelessWidget {
  final DeviceType deviceType;

  const PremiumLockedSection({super.key, required this.deviceType});

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: Colors.orange, size: 32 * scale),
          SizedBox(height: spacing * 0.5),
          Text(
            'Premium Audio Settings',
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: spacing * 0.25),
          Text(
            'Upgrade to Premium to access advanced audio settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * scale,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: spacing),
          Consumer<SettingsController>(
            builder: (context, controller, child) {
              return ElevatedButton(
                onPressed: () async {
                  await PremiumUpgradeDialogs.showFullUpgradePage(
                    context,
                    feature: 'audio_settings',
                    customMessage: 'Upgrade to Premium to access advanced audio settings and controls!',
                  );
                  await controller.loadPremiumStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade Now'),
              );
            },
          ),
        ],
      ),
    );
  }
}
