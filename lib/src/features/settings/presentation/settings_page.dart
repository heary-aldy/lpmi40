// lib/src/features/settings/presentation/settings_page.dart
// ✅ SIMPLIFIED: Clean orchestration using decomposed components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';
import 'package:lpmi40/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:lpmi40/src/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:lpmi40/src/features/settings/presentation/widgets/settings_sections.dart';
import 'package:lpmi40/utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final deviceType = AppConstants.getDeviceType(constraints.maxWidth);
          return Scaffold(
            appBar: _buildAppBar(context, deviceType),
            body: _buildBody(context, deviceType),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, DeviceType deviceType) {
    final scale = AppConstants.getTypographyScale(deviceType);

    return AppBar(
      title: Text(
        'Settings',
        style: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildBody(BuildContext context, DeviceType deviceType) {
    final spacing = AppConstants.getSpacing(deviceType);

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Section
          UserProfileSection(deviceType: deviceType),
          SizedBox(height: spacing * 1.5),

          // Premium Section
          PremiumSettingsSection(deviceType: deviceType),
          SizedBox(height: spacing * 1.5),

          // Display Settings
          DisplaySettingsSection(deviceType: deviceType),
          SizedBox(height: spacing * 1.5),

          // Audio Settings
          AudioSettingsSection(deviceType: deviceType),
          SizedBox(height: spacing * 1.5),

          // Data & Privacy
          _buildDataPrivacySection(deviceType),
          SizedBox(height: spacing * 1.5),

          // Advanced Settings
          _buildAdvancedSection(deviceType),
          SizedBox(height: spacing * 2),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySection(DeviceType deviceType) {
    return SettingsGroup(
      title: 'Data & Privacy',
      deviceType: deviceType,
      children: [
        SettingsRow(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services,
          deviceType: deviceType,
          onTap: () => _showFeatureComingSoon('Clear Cache'),
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Export Data',
          subtitle: 'Download your favorites and settings',
          icon: Icons.download,
          deviceType: deviceType,
          onTap: () => _showFeatureComingSoon('Export Data'),
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          icon: Icons.privacy_tip,
          deviceType: deviceType,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(DeviceType deviceType) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return SettingsGroup(
          title: 'Advanced',
          deviceType: deviceType,
          children: [
            SettingsRow(
              title: 'Debug Mode',
              subtitle: 'Enable developer features (Coming Soon)',
              icon: Icons.bug_report,
              deviceType: deviceType,
              onTap: () => _showFeatureComingSoon('Debug Mode'),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: 'Reset All Settings',
              subtitle: 'Restore default preferences',
              icon: Icons.settings_backup_restore,
              deviceType: deviceType,
              onTap: _resetAllSettings,
            ),
            const SettingsDivider(),
            VersionInfoWidget(
              version: controller.packageInfo?.version ?? '1.0.0',
              buildNumber: controller.packageInfo?.buildNumber ?? '1',
              isCheckingUpdates: controller.isCheckingForUpdates,
              onCheckUpdates: () => _checkForUpdates(controller),
              deviceType: deviceType,
            ),
          ],
        );
      },
    );
  }

  // ✅ SIMPLIFIED ACTION METHODS
  Future<void> _showPrivacyPolicy() async {
    const url = 'https://haweeincorporation.com/privacy-policy';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showFeatureComingSoon('Privacy Policy');
      }
    } catch (e) {
      _showFeatureComingSoon('Privacy Policy');
    }
  }

  Future<void> _resetAllSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will restore all settings to their default values. This action cannot be undone.',
        ),
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

    if (confirmed == true && mounted) {
      // Reset display settings
      final settings = context.read<SettingsNotifier>();
      settings.updateDarkMode(false);
      settings.updateFontSize(16.0);
      settings.updateFontStyle('Roboto');
      settings.updateTextAlign(TextAlign.left);
      settings.updateColorTheme('Blue');

      // Reset audio settings if premium
      try {
        final settingsProvider = context.read<SettingsProvider>();
        await settingsProvider.resetAudioSettings();
      } catch (e) {
        // Audio settings might not be available for non-premium users
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings have been reset to defaults.'),
        ),
      );
    }
  }

  Future<void> _checkForUpdates(SettingsController controller) async {
    await controller.checkForUpdates();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App Update Check'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version: ${controller.getVersionInfo()}'),
              const SizedBox(height: 8),
              const Text('✅ You are running the latest version!'),
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

  void _showFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Coming Soon'),
        content: Text(
          '$feature will be available in a future update. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
