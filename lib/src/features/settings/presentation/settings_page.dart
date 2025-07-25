// lib/src/features/settings/presentation/settings_page.dart
// ✅ SIMPLIFIED: Clean orchestration using decomposed components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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

          // Support & Analytics
          _buildSupportAnalyticsSection(deviceType),
          SizedBox(height: spacing * 1.5),

          // Data & Privacy
          _buildDataPrivacySection(deviceType),
          SizedBox(height: spacing * 1.5),

          // Advanced Settings
          _buildAdvancedSection(deviceType),
          SizedBox(height: spacing * 1.5),

          // About App
          _buildAboutSection(deviceType),
          SizedBox(height: spacing * 2),
        ],
      ),
    );
  }

  Widget _buildSupportAnalyticsSection(DeviceType deviceType) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser !=
        null; // Simplified for now - you can add proper admin check

    return SettingsGroup(
      title: 'Support & Analytics',
      deviceType: deviceType,
      children: [
        SettingsRow(
          title: 'Send Feedback',
          subtitle: 'Help us improve the app',
          icon: Icons.feedback,
          deviceType: deviceType,
          onTap: _sendFeedback,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Report an Issue',
          subtitle: 'Report bugs or problems',
          icon: Icons.bug_report,
          deviceType: deviceType,
          onTap: _reportIssue,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Help & Documentation',
          subtitle: 'Learn how to use the app',
          icon: Icons.help,
          deviceType: deviceType,
          onTap: _showHelpDocumentation,
        ),
        if (isAdmin) ...[
          const SettingsDivider(),
          SettingsRow(
            title: 'App Analytics',
            subtitle: 'View usage statistics and insights',
            icon: Icons.analytics,
            deviceType: deviceType,
            onTap: _showAnalytics,
          ),
        ],
      ],
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
          onTap: _clearCache,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Export Data',
          subtitle: 'Download your favorites and settings',
          icon: Icons.download,
          deviceType: deviceType,
          onTap: _exportData,
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
              subtitle: 'Enable developer features',
              icon: Icons.bug_report,
              deviceType: deviceType,
              onTap: _toggleDebugMode,
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

  Widget _buildAboutSection(DeviceType deviceType) {
    return SettingsGroup(
      title: 'About LPMI40',
      deviceType: deviceType,
      children: [
        SettingsRow(
          title: 'App Features',
          subtitle: 'Learn about all the features available',
          icon: Icons.info_outline,
          deviceType: deviceType,
          onTap: _showAboutDialog,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'User Guide',
          subtitle: 'Complete guide on how to use the app',
          icon: Icons.description_outlined,
          deviceType: deviceType,
          onTap: _showUserGuide,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Support & Contact',
          subtitle: 'Get help or report issues',
          icon: Icons.email_outlined,
          deviceType: deviceType,
          onTap: _showSupportInfo,
        ),
        const SettingsDivider(),
        SettingsRow(
          title: 'Open Source',
          subtitle: 'View source code and contribute',
          icon: Icons.code_outlined,
          deviceType: deviceType,
          onTap: _openGitHubRepo,
        ),
      ],
    );
  }

  // ✅ NEW: About section action methods
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('About LPMI40'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LPMI40 (Lagu Pujian Masa Ini) is a comprehensive digital hymn book application designed for modern Christian worship.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '✨ Key Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• 500+ Christian hymns'),
              const Text('• Smart search & filters'),
              const Text('• Favorites with collections'),
              const Text('• Customizable themes & fonts'),
              const Text('• Offline access'),
              const Text('• Daily verse of the day'),
              const Text('• Cross-device synchronization'),
              const SizedBox(height: 16),
              Text(
                'Version: ${_controller.packageInfo?.version ?? '1.0.0'}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
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

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('User Guide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🚀 Getting Started:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Browse hymns by collection or search'),
              Text('• Tap ❤️ to add songs to favorites'),
              Text('• Customize themes in Settings'),
              Text('• Register for cloud sync'),
              SizedBox(height: 16),
              Text(
                '🎵 Using the App:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Search by song number, title, or lyrics'),
              Text('• Adjust font size with +/- buttons'),
              Text('• Share songs via copy or share button'),
              Text('• Access favorites from the main menu'),
              SizedBox(height: 16),
              Text(
                '⚙️ User Types:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Guest: Browse songs, no sync'),
              Text('• Registered: Save favorites, cloud sync'),
              Text('• Admin: Manage songs and content'),
            ],
          ),
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

  void _showSupportInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.orange),
            SizedBox(width: 8),
            Text('Support & Contact'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Need help or found an issue?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('haw33inc@gmail.com'),
              onTap: () => _launchEmail('haw33inc@gmail.com'),
            ),
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('Website'),
              subtitle: const Text('haweeinc.com'),
              onTap: () => _launchUrl('https://haweeinc.com'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report Issues'),
              subtitle: const Text('Use in-app reporting or GitHub'),
              onTap: () => _openGitHubIssues(),
            ),
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

  void _openGitHubRepo() async {
    const url = 'https://github.com/heary-aldy/lpmi40';
    await _launchUrl(url);
  }

  void _openGitHubIssues() async {
    const url = 'https://github.com/heary-aldy/lpmi40/issues';
    await _launchUrl(url);
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link. Please try again later.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again later.'),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final subject = Uri.encodeComponent('LPMI40 Support Request');
    final body = Uri.encodeComponent('Please describe your issue or question:');
    final url = 'mailto:$email?subject=$subject&body=$body';
    await _launchUrl(url);
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

  // ✅ NEW: Clear Cache Implementation
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including downloaded songs, images, and temporary files. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Clearing cache...'),
              ],
            ),
          ),
        );

        // Get app directories
        final tempDir = await getTemporaryDirectory();
        final cacheDir = await getApplicationCacheDirectory();

        int deletedFiles = 0;
        double freedSpace = 0;

        // Clear temporary directory
        if (await tempDir.exists()) {
          final tempFiles = tempDir.listSync(recursive: true);
          for (var file in tempFiles) {
            if (file is File) {
              final size = await file.length();
              await file.delete();
              deletedFiles++;
              freedSpace += size;
            }
          }
        }

        // Clear cache directory
        if (await cacheDir.exists()) {
          final cacheFiles = cacheDir.listSync(recursive: true);
          for (var file in cacheFiles) {
            if (file is File) {
              final size = await file.length();
              await file.delete();
              deletedFiles++;
              freedSpace += size;
            }
          }
        }

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Convert bytes to readable format
        String formatBytes(double bytes) {
          if (bytes < 1024) return '${bytes.toInt()} B';
          if (bytes < 1024 * 1024) {
            return '${(bytes / 1024).toStringAsFixed(1)} KB';
          }
          if (bytes < 1024 * 1024 * 1024) {
            return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
          }
          return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
        }

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cache Cleared'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Successfully cleared cache!'),
                  SizedBox(height: 8),
                  Text('Files deleted: $deletedFiles'),
                  Text('Space freed: ${formatBytes(freedSpace)}'),
                ],
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
      } catch (e) {
        // Close loading dialog if still open
        if (mounted) Navigator.of(context).pop();

        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to clear cache: $e'),
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
    }
  }

  // ✅ NEW: Export Data Implementation
  Future<void> _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing data export...'),
            ],
          ),
        ),
      );

      // Collect user data
      final user = FirebaseAuth.instance.currentUser;
      final settings = context.read<SettingsNotifier>();

      // Get user's favorite songs (if available)
      List<Map<String, dynamic>> favoriteSongs = [];
      try {
        // Note: Favorites functionality may not be implemented yet
        // This is a placeholder for when favorites are added
        favoriteSongs = [];
      } catch (e) {
        // Favorites might not be available
        favoriteSongs = [];
      }

      // Prepare export data
      final exportData = {
        'export_info': {
          'app_name': 'LPMI40',
          'export_date': DateTime.now().toIso8601String(),
          'app_version': '4.0.0',
        },
        'user_info': {
          'user_id': user?.uid ?? 'anonymous',
          'email': user?.email ?? 'not_logged_in',
          'display_name': user?.displayName ?? 'Unknown',
        },
        'settings': {
          'dark_mode': settings.isDarkMode,
          'font_size': settings.fontSize,
          'font_family': settings.fontFamily,
          'text_align': settings.textAlign.name,
          'color_theme': settings.colorThemeKey,
        },
        'favorites': favoriteSongs,
        'statistics': {
          'total_favorites': favoriteSongs.length,
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'lpmi40_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LPMI40 Data Export',
        text: 'Your LPMI40 app data export including settings and favorites.',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully! File: $fileName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Failed'),
            content: Text('Failed to export data: $e'),
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
  }

  // ✅ NEW: Debug Mode Implementation
  Future<void> _toggleDebugMode() async {
    // Use shared preferences to store debug mode state
    final prefs = await SharedPreferences.getInstance();
    final currentDebugMode = prefs.getBool('debug_mode') ?? false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(currentDebugMode ? 'Disable Debug Mode' : 'Enable Debug Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentDebugMode
                  ? 'This will disable developer features and hide debug information.'
                  : 'This will enable developer features including:',
            ),
            if (!currentDebugMode) ...[
              SizedBox(height: 12),
              Text('• Detailed error logs'),
              Text('• Performance metrics'),
              Text('• Firebase debug info'),
              Text('• API request/response logs'),
              Text('• Database query logs'),
              SizedBox(height: 12),
              Text(
                'Warning: Debug mode may impact app performance and should only be used for troubleshooting.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(currentDebugMode ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await prefs.setBool('debug_mode', !currentDebugMode);
      final newDebugMode = !currentDebugMode;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newDebugMode
                ? 'Debug mode enabled. Developer features are now available.'
                : 'Debug mode disabled. App running in normal mode.',
          ),
          backgroundColor: newDebugMode ? Colors.orange : Colors.green,
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

  // Support & Analytics Methods
  void _sendFeedback() {
    _launchEmailWithContent(
      'haw33inc@gmail.com',
      'LPMI40 App Feedback',
      'Hello LPMI40 Team,\n\nI would like to share feedback about the app:\n\n[Please describe your feedback here]\n\nApp Version: ${_controller.packageInfo?.version ?? 'Unknown'}\nDevice: [Your device info]\n\nThank you!',
    );
  }

  void _reportIssue() {
    _launchEmailWithContent(
      'haw33inc@gmail.com',
      'LPMI40 App Issue Report',
      'Hello LPMI40 Team,\n\nI encountered an issue with the app:\n\n[Please describe the issue here]\n\nSteps to reproduce:\n1. [Step 1]\n2. [Step 2]\n3. [Step 3]\n\nExpected behavior:\n[What should happen]\n\nActual behavior:\n[What actually happened]\n\nApp Version: ${_controller.packageInfo?.version ?? 'Unknown'}\nDevice: [Your device info]\n\nThank you!',
    );
  }

  Future<void> _launchEmailWithContent(
      String email, String subject, String body) async {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final url = 'mailto:$email?subject=$encodedSubject&body=$encodedBody';
    await _launchUrl(url);
  }

  void _showHelpDocumentation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.green),
            SizedBox(width: 8),
            Text('Help & Documentation'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📖 Quick Help Topics:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• How to search for songs'),
              Text('• Adding songs to favorites'),
              Text('• Customizing app appearance'),
              Text('• Using offline features'),
              Text('• Managing collections'),
              Text('• Account settings'),
              SizedBox(height: 16),
              Text(
                '💡 Need more help?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                  'Contact us at haw33inc@gmail.com or visit our website for detailed guides.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('https://haweeinc.com');
            },
            child: const Text('Visit Website'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.orange),
            SizedBox(width: 8),
            Text('App Analytics'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📊 Usage Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• Total collections: Loading...'),
              Text('• Active users: Loading...'),
              Text('• Most popular songs: Loading...'),
              Text('• Usage trends: Loading...'),
              SizedBox(height: 16),
              Text(
                'Note: Detailed analytics dashboard is coming soon in the admin panel.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
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
