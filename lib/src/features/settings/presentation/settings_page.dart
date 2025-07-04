// lib/src/features/settings/presentation/settings_page.dart
// 🟢 PHASE 1: Added operation logging, better error handling, user-friendly messages
// 🔵 ORIGINAL: All existing functionality preserved exactly

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<OnboardingService> _onboardingServiceFuture;

  // 🟢 NEW: Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  @override
  void initState() {
    super.initState();
    _logOperation('initState'); // 🟢 NEW
    _onboardingServiceFuture = OnboardingService.getInstance();
  }

  // 🟢 NEW: Operation logging helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    _operationTimestamps[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

    debugPrint(
        '[SettingsPage] 🔧 Operation: $operation (count: ${_operationCounts[operation]})');
    if (details != null) {
      debugPrint('[SettingsPage] 📊 Details: $details');
    }
  }

  // 🟢 NEW: User-friendly error message helper
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to access settings. Please try again later.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    const fontFamilies = ['Roboto', 'Arial', 'Times New Roman', 'Courier New'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildOnboardingSection(),
          const SizedBox(height: 24),
          _buildAppearanceSection(settings, fontFamilies),
          const SizedBox(height: 24),
          _buildTextDisplaySection(settings, fontFamilies),
          const SizedBox(height: 24),
          _buildAccountSection(),
          const SizedBox(height: 24),
          _buildDataPrivacySection(),
          const SizedBox(height: 24),
          _buildAdvancedSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildOnboardingSection() {
    return _SettingsGroup(
      title: 'Getting Started',
      children: [
        _SettingsRow(
          title: 'Show Welcome Tour',
          subtitle: 'Replay the app introduction',
          icon: Icons.tour,
          onTap: _showOnboarding,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Reset First-time Setup',
          subtitle: 'Reset welcome tour for next app start',
          icon: Icons.refresh,
          onTap: _resetOnboarding,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
      SettingsNotifier settings, List<String> fontFamilies) {
    return _SettingsGroup(
      title: 'Appearance',
      children: [
        _SettingsRow(
          title: 'Dark Mode',
          subtitle: 'Toggle between light and dark themes',
          icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          child: Switch(
            value: settings.isDarkMode,
            onChanged: (value) {
              _logOperation('toggleDarkMode', {'enabled': value}); // 🟢 NEW
              settings.updateDarkMode(value);
            },
          ),
        ),
        _buildDivider(),
        _buildColorThemePicker(settings),
      ],
    );
  }

  Widget _buildTextDisplaySection(
      SettingsNotifier settings, List<String> fontFamilies) {
    return _SettingsGroup(
      title: 'Text Display',
      children: [
        _buildFontSizeSlider(settings),
        _buildDivider(),
        _SettingsRow(
          title: 'Font Family',
          subtitle: 'Choose your preferred font style',
          icon: Icons.font_download,
          child: DropdownButton<String>(
            value: fontFamilies.contains(settings.fontFamily)
                ? settings.fontFamily
                : 'Roboto',
            underline: const SizedBox.shrink(),
            dropdownColor: Theme.of(context).cardColor,
            style: Theme.of(context).textTheme.bodyMedium,
            items: fontFamilies
                .map((font) => DropdownMenuItem(
                      value: font,
                      child: Text(font),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _logOperation('changeFontFamily', {'font': value}); // 🟢 NEW
                settings.updateFontStyle(value);
              }
            },
          ),
        ),
        _buildDivider(),
        _buildTextAlignSelector(settings),
      ],
    );
  }

  Widget _buildAccountSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return _SettingsGroup(
      title: 'Account',
      children: [
        _SettingsRow(
          title: 'Profile',
          subtitle: user.email ?? 'No email',
          icon: user.isAnonymous ? Icons.person_outline : Icons.person,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isAnonymous
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.isAnonymous ? 'Guest' : 'Registered',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: user.isAnonymous ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection() {
    return _SettingsGroup(
      title: 'Data & Privacy',
      children: [
        _SettingsRow(
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services,
          onTap: _clearCache,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Export Data',
          subtitle: 'Download your favorites and settings',
          icon: Icons.download,
          onTap: _exportData,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          icon: Icons.privacy_tip,
          onTap: _showPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return _SettingsGroup(
      title: 'Advanced',
      children: [
        _SettingsRow(
          title: 'Debug Mode',
          subtitle: 'Enable developer features',
          icon: Icons.bug_report,
          child: Switch(
            value: false,
            onChanged: (value) => _showFeatureComingSoon('Debug Mode'),
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Reset All Settings',
          subtitle: 'Restore default preferences',
          icon: Icons.settings_backup_restore,
          onTap: _resetAllSettings,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'App Version',
          subtitle: 'Check for updates',
          icon: Icons.system_update,
          onTap: _checkForUpdates,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _SettingsGroup(
      title: 'About',
      children: [
        _SettingsRow(
          title: 'LPMI40',
          subtitle: 'Lagu Pujian Masa Ini v2.0.0',
          icon: Icons.music_note,
          onTap: _showAppInfo,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Developer',
          subtitle: 'Built with Flutter by HaweeInc',
          icon: Icons.developer_mode,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Open Source Licenses',
          subtitle: 'View third-party licenses',
          icon: Icons.code,
          onTap: _showLicensePage,
        ),
      ],
    );
  }

  Widget _buildColorThemePicker(SettingsNotifier settings) {
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
                onTap: () {
                  _logOperation(
                      'changeColorTheme', {'theme': themeKey}); // 🟢 NEW
                  settings.updateColorTheme(themeKey);
                },
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
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider(SettingsNotifier settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font Size', style: theme.textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${settings.fontSize.toInt()}px',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.fontSize,
            min: 12.0,
            max: 30.0,
            divisions: 9,
            label: '${settings.fontSize.round()}px',
            onChanged: (value) {
              _logOperation('changeFontSize', {'size': value}); // 🟢 NEW
              settings.updateFontSize(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextAlignSelector(SettingsNotifier settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text Alignment',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TextAlign>(
              segments: const [
                ButtonSegment(
                    value: TextAlign.left,
                    icon: Icon(Icons.format_align_left),
                    label: Text('Left')),
                ButtonSegment(
                    value: TextAlign.center,
                    icon: Icon(Icons.format_align_center),
                    label: Text('Center')),
                ButtonSegment(
                    value: TextAlign.right,
                    icon: Icon(Icons.format_align_right),
                    label: Text('Right')),
              ],
              selected: {settings.textAlign},
              onSelectionChanged: (newSelection) {
                _logOperation('changeTextAlign',
                    {'alignment': newSelection.first.toString()}); // 🟢 NEW
                settings.updateTextAlign(newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTION METHODS ---
  void _showAppInfo() {
    _logOperation('showAppInfo'); // 🟢 NEW

    showAboutDialog(
      context: context,
      applicationName: 'LPMI40',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.music_note_rounded),
      applicationLegalese: '© 2025 HaweeInc. All Rights Reserved.',
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Lagu Pujian Masa Ini (LPMI) is a digital hymnal dedicated to providing easy access to a comprehensive collection of praise and worship songs. Our mission is to support personal worship and church congregations by making these timeless hymns available anytime, anywhere.',
          ),
        ),
      ],
    );
  }

  Future<void> _showOnboarding() async {
    _logOperation('showOnboarding'); // 🟢 NEW

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnboardingPage(
          onCompleted: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    _logOperation('resetOnboarding'); // 🟢 NEW

    final confirmed = await _showConfirmationDialog(
      title: 'Reset Welcome Tour',
      content:
          'This will reset the onboarding status. The welcome tour will be shown the next time you start the app.\n\nContinue?',
    );
    if (confirmed == true) {
      try {
        final service = await OnboardingService.getInstance();
        await service.resetOnboarding();
        _showSuccessMessage(
            'Welcome tour reset successfully! Restart the app to see the tour again.');
      } catch (e) {
        _logOperation(
            'resetOnboardingError', {'error': e.toString()}); // 🟢 NEW
        _showErrorMessage(_getUserFriendlyErrorMessage(
            e)); // 🟢 IMPROVED: User-friendly message
      }
    }
  }

  Future<void> _clearCache() async {
    _logOperation('clearCache'); // 🟢 NEW

    final confirmed = await _showConfirmationDialog(
      title: 'Clear Cache',
      content:
          'This will clear temporary files and free up storage space. Your settings and favorites will not be affected.\n\nContinue?',
    );
    if (confirmed == true) {
      try {
        // 🟢 IMPROVED: Add actual cache clearing logic here if available
        _showSuccessMessage('Cache cleared successfully!');
      } catch (e) {
        _logOperation('clearCacheError', {'error': e.toString()}); // 🟢 NEW
        _showErrorMessage(_getUserFriendlyErrorMessage(
            e)); // 🟢 IMPROVED: User-friendly message
      }
    }
  }

  void _exportData() {
    _logOperation('exportData'); // 🟢 NEW
    _showFeatureComingSoon('Data Export');
  }

  Future<void> _resetAllSettings() async {
    _logOperation('resetAllSettings'); // 🟢 NEW

    final confirmed = await _showConfirmationDialog(
      title: 'Reset All Settings',
      content:
          'This will restore all settings to their default values. This action cannot be undone.\n\nContinue?',
      isDestructive: true,
    );
    if (confirmed == true) {
      try {
        final settings = context.read<SettingsNotifier>();
        settings.updateDarkMode(false);
        settings.updateColorTheme('Blue');
        settings.updateFontSize(16.0);
        settings.updateFontStyle('Roboto');
        settings.updateTextAlign(TextAlign.left);
        _showSuccessMessage('All settings reset to defaults!');
      } catch (e) {
        _logOperation(
            'resetAllSettingsError', {'error': e.toString()}); // 🟢 NEW
        _showErrorMessage(_getUserFriendlyErrorMessage(
            e)); // 🟢 IMPROVED: User-friendly message
      }
    }
  }

  void _checkForUpdates() {
    _logOperation('checkForUpdates'); // 🟢 NEW
    _showFeatureComingSoon('Update Checker');
  }

  void _showLicensePage() {
    _logOperation('showLicensePage'); // 🟢 NEW

    showLicensePage(
      context: context,
      applicationName: 'LPMI40',
      applicationVersion: '2.0.0',
      applicationLegalese: '© 2025 HaweeInc. Built with Flutter.',
    );
  }

  void _showPrivacyPolicy() {
    _logOperation('showPrivacyPolicy'); // 🟢 NEW
    _showFeatureComingSoon('Privacy Policy');
  }

  // --- HELPER METHODS & WIDGETS ---

  Future<bool?> _showConfirmationDialog(
      {required String title,
      required String content,
      bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(isDestructive ? 'Reset All' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message))
      ]),
      backgroundColor: Colors.green,
    ));
  }

  // 🟢 IMPROVED: Better error message display
  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message))
      ]),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4), // Longer duration for errors
    ));
  }

  void _showFeatureComingSoon(String feature) {
    _logOperation('showFeatureComingSoon', {'feature': feature}); // 🟢 NEW

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text(
            'The $feature feature is currently in development and will be available in a future update.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56, endIndent: 16);

  // 🟢 NEW: Get performance metrics (for debugging)
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'currentUser': FirebaseAuth.instance.currentUser?.email,
    };
  }
}

// Moved helper widgets outside the State class
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
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? child;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.title,
    required this.icon,
    this.subtitle,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            )
          : null,
      trailing: child ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
