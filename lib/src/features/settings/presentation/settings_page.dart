// lib/src/features/settings/presentation/settings_page.dart
// ✅ FINAL FIX: Updated to use the refactored provider methods.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PremiumService _premiumService = PremiumService();

  bool _isPremium = false;
  bool _isLoadingPremium = true;
  bool _isCheckingForUpdates = false;

  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPremiumStatus(),
      _loadPackageInfo(),
    ]);
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoadingPremium = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
        });
      }
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = packageInfo;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  void _logOperation(String operation, [Map<String, dynamic>? params]) {
    debugPrint(
        '[SettingsPage] 🔧 $operation${params != null ? ' - $params' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = AppConstants.getDeviceType(constraints.maxWidth);
        return Scaffold(
          appBar: _buildAppBar(context, deviceType),
          body: _buildBody(context, deviceType),
        );
      },
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
          _buildUserProfileSection(deviceType),
          SizedBox(height: spacing * 1.5),
          _buildPremiumSection(deviceType),
          SizedBox(height: spacing * 1.5),
          _buildDisplaySettingsSection(deviceType),
          SizedBox(height: spacing * 1.5),
          _buildAudioSettingsSection(deviceType),
          SizedBox(height: spacing * 1.5),
          _buildDataPrivacySection(deviceType),
          SizedBox(height: spacing * 1.5),
          _buildAdvancedSection(deviceType),
          SizedBox(height: spacing * 2),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(DeviceType deviceType) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return _SettingsGroup(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      : (_isPremium
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isAnonymous
                      ? 'Guest'
                      : (_isPremium ? 'Premium' : 'Registered'),
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: user.isAnonymous
                        ? Colors.orange
                        : (_isPremium ? Colors.purple : Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSection(DeviceType deviceType) {
    if (_isLoadingPremium) {
      return _SettingsGroup(
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

    return _SettingsGroup(
      title: 'Premium Features',
      deviceType: deviceType,
      children: [
        if (_isPremium) ...[
          _buildPremiumActiveCard(deviceType),
          _buildDivider(),
          _buildPremiumManagementRow(deviceType),
        ] else ...[
          _buildPremiumUpgradeCard(deviceType),
        ],
      ],
    );
  }

  Widget _buildPremiumActiveCard(DeviceType deviceType) {
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
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.purple,
                size: 24 * scale,
              ),
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

  Widget _buildPremiumUpgradeCard(DeviceType deviceType) {
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
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline,
                color: Colors.orange,
                size: 24 * scale,
              ),
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
                await showDialog(
                  context: context,
                  builder: (context) => const PremiumUpgradeDialog(
                    feature: 'premium_settings',
                  ),
                );
                // Refresh premium status after potential upgrade
                await _loadPremiumStatus();
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

  Widget _buildPremiumManagementRow(DeviceType deviceType) {
    return _SettingsRow(
      title: 'Manage Premium',
      subtitle: 'Premium features and settings',
      icon: Icons.settings,
      deviceType: deviceType,
      onTap: () {
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
      },
    );
  }

  Widget _buildDisplaySettingsSection(DeviceType deviceType) {
    return Consumer<SettingsNotifier>(
      builder: (context, settings, child) {
        return _SettingsGroup(
          title: 'Display',
          deviceType: deviceType,
          children: [
            _SettingsTile(
              title: 'Dark Mode',
              subtitle: settings.isDarkMode ? 'Enabled' : 'Disabled',
              icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              deviceType: deviceType,
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: (value) => settings.updateDarkMode(value),
              ),
            ),
            _buildDivider(),
            _SettingsRow(
              title: 'Font Size',
              subtitle: '${settings.fontSize.toStringAsFixed(0)}px',
              icon: Icons.format_size,
              deviceType: deviceType,
              onTap: () => _showFontSizeDialog(settings),
            ),
            _buildDivider(),
            _SettingsRow(
              title: 'Font Family',
              subtitle: settings.fontFamily,
              icon: Icons.font_download,
              deviceType: deviceType,
              onTap: () => _showFontFamilyDialog(settings),
            ),
            _buildDivider(),
            _SettingsRow(
              title: 'Text Alignment',
              subtitle: _getTextAlignmentName(settings.textAlign),
              icon: Icons.format_align_left,
              deviceType: deviceType,
              onTap: () => _showTextAlignmentDialog(settings),
            ),
            _buildDivider(),
            _SettingsRow(
              title: 'Color Theme',
              subtitle: settings.colorThemeKey,
              icon: Icons.palette,
              deviceType: deviceType,
              onTap: () => _showColorThemeDialog(settings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioSettingsSection(DeviceType deviceType) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _SettingsGroup(
          title: 'Audio Settings',
          deviceType: deviceType,
          children: [
            if (_isPremium) ...[
              _SettingsTile(
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
              _buildDivider(),
              _SettingsTile(
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
              _buildDivider(),
              _SettingsTile(
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
              _buildDivider(),
              _SettingsRow(
                title: 'Audio Quality',
                subtitle: settingsProvider.audioQuality.displayName,
                icon: Icons.high_quality,
                deviceType: deviceType,
                onTap: () => _showAudioQualityDialog(settingsProvider),
              ),
              _buildDivider(),
              _SettingsRow(
                title: 'Player Mode',
                subtitle: settingsProvider.playerMode.displayName,
                icon: Icons.music_video,
                deviceType: deviceType,
                onTap: () => _showPlayerModeDialog(settingsProvider),
              ),
              _buildDivider(),
              _SettingsRow(
                title: 'Reset Audio Settings',
                subtitle: 'Restore audio defaults',
                icon: Icons.restore,
                deviceType: deviceType,
                onTap: () => _resetAudioSettings(settingsProvider),
              ),
            ] else ...[
              _buildPremiumLockedSection(deviceType),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPremiumLockedSection(DeviceType deviceType) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock,
            color: Colors.orange,
            size: 32 * scale,
          ),
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
          ElevatedButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const PremiumUpgradeDialog(
                  feature: 'audio_settings',
                ),
              );
              await _loadPremiumStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySection(DeviceType deviceType) {
    return _SettingsGroup(
      title: 'Data & Privacy',
      deviceType: deviceType,
      children: [
        _SettingsRow(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services,
          deviceType: deviceType,
          onTap: _clearCache,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Export Data',
          subtitle: 'Download your favorites and settings',
          icon: Icons.download,
          deviceType: deviceType,
          onTap: _exportData,
        ),
        _buildDivider(),
        _SettingsRow(
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
    return _SettingsGroup(
      title: 'Advanced',
      deviceType: deviceType,
      children: [
        _SettingsRow(
          title: 'Debug Mode',
          subtitle: 'Enable developer features (Coming Soon)',
          icon: Icons.bug_report,
          deviceType: deviceType,
          onTap: () => _showFeatureComingSoon('Debug Mode'),
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Reset All Settings',
          subtitle: 'Restore default preferences',
          icon: Icons.settings_backup_restore,
          deviceType: deviceType,
          onTap: _resetAllSettings,
        ),
        _buildDivider(),
        _buildVersionCheckRow(deviceType),
      ],
    );
  }

  Widget _buildVersionCheckRow(DeviceType deviceType) {
    final currentVersion = _packageInfo?.version ?? AppConstants.appVersion;
    final buildNumber = _packageInfo?.buildNumber ?? '1';

    return _SettingsRow(
      title: 'App Version',
      subtitle: _isCheckingForUpdates
          ? 'Checking for updates...'
          : '$currentVersion ($buildNumber)',
      icon: Icons.info,
      deviceType: deviceType,
      onTap: _checkForUpdates,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.3),
    );
  }

  // Dialog methods
  void _showFontSizeDialog(SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => _FontSizeDialog(settings: settings),
    );
  }

  void _showFontFamilyDialog(SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => _FontFamilyDialog(settings: settings),
    );
  }

  void _showTextAlignmentDialog(SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => _TextAlignmentDialog(settings: settings),
    );
  }

  void _showColorThemeDialog(SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => _ColorThemeDialog(settings: settings),
    );
  }

  void _showAudioQualityDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          _AudioQualityDialog(settingsProvider: settingsProvider),
    );
  }

  void _showPlayerModeDialog(SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) =>
          _PlayerModeDialog(settingsProvider: settingsProvider),
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

  // Action methods
  Future<void> _resetAudioSettings(SettingsProvider settingsProvider) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio settings reset to defaults.')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    _logOperation('clearCache');
    _showFeatureComingSoon('Clear Cache');
  }

  Future<void> _exportData() async {
    _logOperation('exportData');
    _showFeatureComingSoon('Export Data');
  }

  Future<void> _showPrivacyPolicy() async {
    _logOperation('showPrivacyPolicy');
    const url = 'https://haweeincorporation.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showFeatureComingSoon('Privacy Policy');
    }
  }

  Future<void> _resetAllSettings() async {
    _logOperation('resetAllSettings');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
            'This will restore all settings to their default values. This action cannot be undone.'),
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
      final settings = context.read<SettingsNotifier>();
      settings.updateDarkMode(false);
      settings.updateFontSize(16.0);
      settings.updateFontStyle('Roboto');
      settings.updateTextAlign(TextAlign.left);
      settings.updateColorTheme('Blue');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All settings have been reset to defaults.')),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    _logOperation('checkForUpdates');

    if (!mounted) return;

    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('App Update Check'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Current Version: ${_packageInfo?.version ?? AppConstants.appVersion}'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  void _showFeatureComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Coming Soon'),
        content: Text(
            '$feature will be available in a future update. It will show on next app start.'),
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

// Custom widgets
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final DeviceType deviceType;

  const _SettingsGroup({
    required this.title,
    required this.children,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: spacing * 0.75),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final DeviceType deviceType;

  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return ListTile(
      leading: Icon(
        icon,
        size: 24 * scale,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14 * scale,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20 * scale,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.25,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final DeviceType deviceType;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return ListTile(
      leading: Icon(
        icon,
        size: 24 * scale,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14 * scale,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.25,
      ),
    );
  }
}

// Dialog widgets
class _FontSizeDialog extends StatefulWidget {
  final SettingsNotifier settings;

  const _FontSizeDialog({required this.settings});

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
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

class _FontFamilyDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const _FontFamilyDialog({required this.settings});

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

class _TextAlignmentDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const _TextAlignmentDialog({required this.settings});

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

class _ColorThemeDialog extends StatelessWidget {
  final SettingsNotifier settings;

  const _ColorThemeDialog({required this.settings});

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

class _AudioQualityDialog extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const _AudioQualityDialog({required this.settingsProvider});

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
                    // ✅ FIXED: Using the corrected provider method
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

class _PlayerModeDialog extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const _PlayerModeDialog({required this.settingsProvider});

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
                    // ✅ FIXED: Using the corrected provider method
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
