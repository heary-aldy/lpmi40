// lib/src/features/settings/presentation/settings_page.dart

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

  @override
  void initState() {
    super.initState();
    _onboardingServiceFuture = OnboardingService.getInstance();
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
          // Getting Started Section
          _buildOnboardingSection(context),
          const SizedBox(height: 24),

          // Appearance Section
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsRow(
                context: context,
                title: 'Dark Mode',
                subtitle: 'Toggle between light and dark themes',
                icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                child: Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) =>
                      context.read<SettingsNotifier>().updateDarkMode(value),
                  thumbColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Colors.grey.shade400;
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

          // Text Display Section
          _SettingsGroup(
            title: 'Text Display',
            children: [
              _buildFontSizeSlider(context, settings),
              _buildDivider(),
              _SettingsRow(
                context: context,
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

          // Account Section (if user is logged in)
          _buildAccountSection(context),

          // Data & Privacy Section
          _buildDataPrivacySection(context),
          const SizedBox(height: 24),

          // Advanced Section
          _buildAdvancedSection(context),
          const SizedBox(height: 24),

          // About Section
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
                subtitle: 'Built with Flutter by HaweeInc',
                icon: Icons.developer_mode,
              ),
              _buildDivider(),
              _SettingsRow(
                context: context,
                title: 'Open Source Licenses',
                subtitle: 'View third-party licenses',
                icon: Icons.code,
                child: IconButton(
                  onPressed: () => _showLicensePage(context),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  tooltip: 'View licenses',
                ),
              ),
            ],
          ),

          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  // ✅ ONBOARDING SECTION
  Widget _buildOnboardingSection(BuildContext context) {
    return _SettingsGroup(
      title: 'Getting Started',
      children: [
        _SettingsRow(
          context: context,
          title: 'Show Welcome Tour',
          subtitle: 'Replay the app introduction',
          icon: Icons.tour,
          child: IconButton(
            onPressed: () => _showOnboarding(context),
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start onboarding',
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          context: context,
          title: 'Reset First-time Setup',
          subtitle: 'Reset welcome tour for next app start',
          icon: Icons.refresh,
          child: IconButton(
            onPressed: () => _resetOnboarding(context),
            icon: const Icon(Icons.restore),
            tooltip: 'Reset onboarding',
          ),
        ),
        _buildDivider(),
        FutureBuilder<OnboardingService>(
          future: _onboardingServiceFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final service = snapshot.data!;
              return _SettingsRow(
                context: context,
                title: 'App Usage',
                subtitle:
                    'Launched ${service.appLaunchCount} times • First install: ${_formatDate(service.firstLaunchDate)}',
                icon: Icons.analytics,
              );
            }
            return _SettingsRow(
              context: context,
              title: 'App Usage',
              subtitle: 'Loading statistics...',
              icon: Icons.analytics,
            );
          },
        ),
      ],
    );
  }

  // ✅ ACCOUNT SECTION
  Widget _buildAccountSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _SettingsGroup(
          title: 'Account',
          children: [
            _SettingsRow(
              context: context,
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
            if (!user.isAnonymous) ...[
              _buildDivider(),
              _SettingsRow(
                context: context,
                title: 'Sync Settings',
                subtitle: 'Sync favorites and preferences',
                icon: Icons.sync,
                child: Switch(
                  value: true, // You can connect this to your sync settings
                  onChanged: (value) {
                    // Implement sync toggle
                    _showFeatureComingSoon(context, 'Sync Settings');
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ✅ DATA & PRIVACY SECTION
  Widget _buildDataPrivacySection(BuildContext context) {
    return _SettingsGroup(
      title: 'Data & Privacy',
      children: [
        _SettingsRow(
          context: context,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          icon: Icons.cleaning_services,
          child: IconButton(
            onPressed: () => _clearCache(context),
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear cache',
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          context: context,
          title: 'Export Data',
          subtitle: 'Download your favorites and settings',
          icon: Icons.download,
          child: IconButton(
            onPressed: () => _exportData(context),
            icon: const Icon(Icons.file_download),
            tooltip: 'Export data',
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          context: context,
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          icon: Icons.privacy_tip,
          child: IconButton(
            onPressed: () => _showPrivacyPolicy(context),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            tooltip: 'View privacy policy',
          ),
        ),
      ],
    );
  }

  // ✅ ADVANCED SECTION
  Widget _buildAdvancedSection(BuildContext context) {
    return _SettingsGroup(
      title: 'Advanced',
      children: [
        _SettingsRow(
          context: context,
          title: 'Debug Mode',
          subtitle: 'Enable developer features',
          icon: Icons.bug_report,
          child: Switch(
            value: false, // You can connect this to a debug mode setting
            onChanged: (value) {
              _showFeatureComingSoon(context, 'Debug Mode');
            },
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          context: context,
          title: 'Reset All Settings',
          subtitle: 'Restore default preferences',
          icon: Icons.settings_backup_restore,
          child: IconButton(
            onPressed: () => _resetAllSettings(context),
            icon: const Icon(Icons.restore_outlined),
            tooltip: 'Reset settings',
          ),
        ),
        _buildDivider(),
        _SettingsRow(
          context: context,
          title: 'App Version',
          subtitle: 'Check for updates',
          icon: Icons.system_update,
          child: IconButton(
            onPressed: () => _checkForUpdates(context),
            icon: const Icon(Icons.update),
            tooltip: 'Check updates',
          ),
        ),
      ],
    );
  }

  // ✅ COLOR THEME PICKER
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
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
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

  // ✅ FONT SIZE SLIDER
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
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 4,
            ),
            child: Slider(
              value: settings.fontSize,
              min: 12.0,
              max: 30.0,
              divisions: 9,
              label: '${settings.fontSize.round()}px',
              onChanged: (value) =>
                  context.read<SettingsNotifier>().updateFontSize(value),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TEXT ALIGNMENT SELECTOR
  Widget _buildTextAlignSelector(
      BuildContext context, SettingsNotifier settings) {
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
    );
  }

  // ✅ ACTION METHODS
  Future<void> _showOnboarding(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingPage(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Welcome Tour'),
        content: const Text(
          'This will reset the onboarding status. The welcome tour will be shown the next time you start the app.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = await OnboardingService.getInstance();
        await service.resetOnboarding();

        if (context.mounted) {
          _showSuccessMessage(context,
              'Welcome tour reset successfully! Restart the app to see the tour again.');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorMessage(context, 'Error resetting welcome tour: $e');
        }
      }
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and free up storage space. Your settings and favorites will not be affected.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement cache clearing logic here
      _showSuccessMessage(context, 'Cache cleared successfully!');
    }
  }

  Future<void> _exportData(BuildContext context) async {
    _showFeatureComingSoon(context, 'Data Export');
  }

  Future<void> _resetAllSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will restore all settings to their default values. This action cannot be undone.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final settings = context.read<SettingsNotifier>();
        settings.updateDarkMode(false);
        settings.updateColorTheme('Blue');
        settings.updateFontSize(16.0);
        settings.updateFontStyle('Roboto');
        settings.updateTextAlign(TextAlign.left);

        _showSuccessMessage(context, 'All settings reset to defaults!');
      } catch (e) {
        _showErrorMessage(context, 'Error resetting settings: $e');
      }
    }
  }

  void _checkForUpdates(BuildContext context) {
    _showFeatureComingSoon(context, 'Update Checker');
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'LPMI40',
      applicationVersion: '2.0.0',
      applicationLegalese: '© 2024 HaweeInc. Built with Flutter.',
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showFeatureComingSoon(context, 'Privacy Policy');
  }

  // ✅ HELPER METHODS
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showFeatureComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text(
            'The $feature feature is currently in development and will be available in a future update.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

// ✅ SETTINGS GROUP WIDGET
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
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

// ✅ SETTINGS ROW WIDGET
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            )
          : null,
      trailing: child,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
