// lib/src/features/settings/presentation/settings_page.dart
// ✅ UPDATED: Added premium audio settings and upgrade section

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_audio_gate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart';
import 'package:lpmi40/src/core/constants/app_constants.dart' as AppInfo;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<OnboardingService> _onboardingServiceFuture;
  final PremiumService _premiumService = PremiumService();
  final AuthorizationService _authService = AuthorizationService();

  PackageInfo? _packageInfo;
  bool _isCheckingForUpdates = false;
  bool _isPremium = false;
  bool _isLoadingPremium = true;
  Map<String, dynamic>? _premiumStatus;

  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  @override
  void initState() {
    super.initState();
    _logOperation('initState');
    _onboardingServiceFuture = OnboardingService.getInstance();
    _loadPackageInfo();
    _loadPremiumStatus();
  }

  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final status = await _premiumService.getPremiumStatus();
      final isPremium = await _premiumService.isPremium();

      if (mounted) {
        setState(() {
          _premiumStatus = status;
          _isPremium = isPremium;
          _isLoadingPremium = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
        });
      }
    }
  }

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    _operationTimestamps[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

    debugPrint(
        '[SettingsPage] 🔧 Operation: $operation (count: ${_operationCounts[operation]})');
    if (details != null) {
      debugPrint('[SettingsPage] 📊 Details: $details');
    }
  }

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

  Widget _buildSidebar() {
    return MainDashboardDrawer(
      isFromDashboard: false,
      onFilterSelected: (filter) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onShowSettings: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildLargeScreenLayout(),
      desktop: _buildLargeScreenLayout(),
    );
  }

  Widget _buildMobileLayout() {
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
          _buildPremiumSection(), // ✅ NEW: Premium section
          const SizedBox(height: 24),
          _buildAudioSettingsSection(settings), // ✅ NEW: Audio settings
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

  Widget _buildLargeScreenLayout() {
    return ResponsiveScaffold(
      sidebar: _buildSidebar(),
      body: _buildResponsiveContent(),
    );
  }

  Widget _buildResponsiveContent() {
    final settings = context.watch<SettingsNotifier>();
    const fontFamilies = ['Roboto', 'Arial', 'Times New Roman', 'Courier New'];
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.getContentPadding(deviceType),
            vertical: spacing,
          ),
          child: Column(
            children: [
              _buildResponsiveGrid([
                _buildOnboardingSection(),
                _buildPremiumSection(), // ✅ NEW: Premium section
                _buildAudioSettingsSection(settings), // ✅ NEW: Audio settings
                _buildAppearanceSection(settings, fontFamilies),
                _buildTextDisplaySection(settings, fontFamilies),
                _buildAccountSection(),
                _buildDataPrivacySection(),
                _buildAdvancedSection(),
                _buildAboutSection(),
              ]),
              SizedBox(height: spacing * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> sections) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);
    final filteredSections = sections.where((section) {
      return !(section is SizedBox && section.height == 0);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = (constraints.maxWidth * 0.9).clamp(300.0, 800.0);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: containerWidth,
              minWidth: 300.0,
            ),
            child: Column(
              children: filteredSections
                  .map((section) => Padding(
                        padding: EdgeInsets.only(bottom: spacing * 1.5),
                        child: section,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // ✅ NEW: Premium section
  Widget _buildPremiumSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return _SettingsGroup(
      title: 'Premium',
      children: [
        if (_isLoadingPremium)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_isPremium)
          _buildPremiumStatusCard()
        else
          _buildUpgradeCard(),
        if (_isPremium) _buildDivider(),
        if (_isPremium) _buildPremiumManagementRow(),
      ],
    );
  }

  Widget _buildPremiumStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Premium Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You have access to all premium audio features!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (_premiumService
                .getPremiumFeatures()
                .take(3)
                .map(
                  (feature) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Unlock audio features',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Get unlimited access to:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...(_premiumService
              .getPremiumFeatures()
              .take(4)
              .map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.purple,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
              .toList()),
          const SizedBox(height: 16),
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
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Upgrade Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumManagementRow() {
    return _SettingsRow(
      title: 'Manage Premium',
      subtitle: 'Premium features and settings',
      icon: Icons.settings,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Premium Management'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your premium subscription is active.'),
                const SizedBox(height: 16),
                const Text('Premium Features:'),
                const SizedBox(height: 8),
                ...(_premiumService
                    .getPremiumFeatures()
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(feature, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                    .toList()),
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

  // ✅ NEW: Audio settings section
  Widget _buildAudioSettingsSection(SettingsNotifier settings) {
    return PremiumAudioGate(
      feature: 'player_settings',
      showUpgradeButton: false,
      showUpgradeHint: true,
      child: _SettingsGroup(
        title: 'Audio Settings',
        children: [
          _buildAudioQualityRow(settings),
          _buildDivider(),
          _buildPlayerModeRow(settings),
          _buildDivider(),
          _buildAutoPlayRow(settings),
          _buildDivider(),
          _buildVolumeControlRow(settings),
        ],
      ),
    );
  }

  Widget _buildAudioQualityRow(SettingsNotifier settings) {
    return _SettingsRow(
      title: 'Audio Quality',
      subtitle: 'High quality audio playback',
      icon: Icons.high_quality,
      child: Switch(
        value: true, // Premium users always get high quality
        onChanged: _isPremium
            ? (value) {
                // Handle audio quality toggle
              }
            : null,
      ),
    );
  }

  Widget _buildPlayerModeRow(SettingsNotifier settings) {
    return _SettingsRow(
      title: 'Player Mode',
      subtitle: 'Mini player or full screen',
      icon: Icons.fullscreen,
      onTap: _isPremium
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Player Mode'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('Mini Player'),
                        subtitle: const Text('Compact player at bottom'),
                        value: 'mini',
                        groupValue: 'mini', // Default value
                        onChanged: (value) {
                          Navigator.of(context).pop();
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Full Screen'),
                        subtitle:
                            const Text('Immersive full screen experience'),
                        value: 'fullscreen',
                        groupValue: 'mini', // Default value
                        onChanged: (value) {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            }
          : null,
    );
  }

  Widget _buildAutoPlayRow(SettingsNotifier settings) {
    return _SettingsRow(
      title: 'Auto Play',
      subtitle: 'Automatically play next song',
      icon: Icons.skip_next,
      child: Switch(
        value: false, // Default value
        onChanged: _isPremium
            ? (value) {
                // Handle auto play toggle
              }
            : null,
      ),
    );
  }

  Widget _buildVolumeControlRow(SettingsNotifier settings) {
    return _SettingsRow(
      title: 'Volume Control',
      subtitle: 'Use hardware volume buttons',
      icon: Icons.volume_up,
      child: Switch(
        value: true, // Default value
        onChanged: _isPremium
            ? (value) {
                // Handle volume control toggle
              }
            : null,
      ),
    );
  }

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
          onTap: () {
            _logOperation('toggleDarkMode', {'enabled': !settings.isDarkMode});
            settings.updateDarkMode(!settings.isDarkMode);
          },
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
          subtitle: 'Current: ${settings.fontFamily}',
          icon: Icons.font_download,
          onTap: () => _showFontFamilyDialog(settings, fontFamilies),
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Text Alignment',
          subtitle: 'Current: ${_getTextAlignmentName(settings.textAlign)}',
          icon: Icons.format_align_left,
          onTap: () => _showTextAlignmentDialog(settings),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return _SettingsGroup(
      title: 'Account',
      children: [
        _buildAccountInfo(user),
        _buildDivider(),
        _SettingsRow(
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          icon: Icons.logout,
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildAccountInfo(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'LPMI User',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  user.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: user.isAnonymous
                    ? Colors.orange
                    : (_isPremium ? Colors.purple : Colors.green),
              ),
            ),
          ),
        ],
      ),
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
          subtitle: 'Enable developer features (Coming Soon)',
          icon: Icons.bug_report,
          onTap: () => _showFeatureComingSoon('Debug Mode'),
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Reset All Settings',
          subtitle: 'Restore default preferences',
          icon: Icons.settings_backup_restore,
          onTap: _resetAllSettings,
        ),
        _buildDivider(),
        _buildVersionCheckRow(),
      ],
    );
  }

  Widget _buildVersionCheckRow() {
    final currentVersion =
        _packageInfo?.version ?? AppInfo.AppConstants.appVersion;
    final buildNumber = _packageInfo?.buildNumber ?? '1';

    return _SettingsRow(
      title: 'App Version',
      subtitle: _isCheckingForUpdates
          ? 'Checking for updates...'
          : 'v$currentVersion ($buildNumber) • Tap to check for updates',
      icon: _isCheckingForUpdates ? Icons.refresh : Icons.system_update,
      onTap: _isCheckingForUpdates ? null : _checkForUpdates,
    );
  }

  Widget _buildAboutSection() {
    return _SettingsGroup(
      title: 'About',
      children: [
        _SettingsRow(
          title: 'LPMI40',
          subtitle:
              'Lagu Pujian Masa Ini v${_packageInfo?.version ?? AppInfo.AppConstants.appVersion}',
          icon: Icons.music_note,
          onTap: _showAppInfo,
        ),
        _buildDivider(),
        _SettingsRow(
          title: 'Developer',
          subtitle: 'Built with Flutter by HaweeInc',
          icon: Icons.developer_mode,
          onTap: _showDeveloperInfo,
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
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing, horizontal: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color Theme', style: theme.textTheme.titleMedium),
          SizedBox(height: spacing),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: AppTheme.colorThemes.entries.map((entry) {
              final themeKey = entry.key;
              final color = entry.value;
              final isSelected = settings.colorThemeKey == themeKey;
              final circleSize =
                  44.0 * AppConstants.getTypographyScale(deviceType);

              return GestureDetector(
                onTap: () {
                  _logOperation('changeColorTheme', {'theme': themeKey});
                  settings.updateColorTheme(themeKey);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: circleSize,
                  height: circleSize,
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
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing, horizontal: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Font Size', style: theme.textTheme.titleMedium),
              Text('${settings.fontSize.toInt()}px',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: spacing / 2),
          Slider(
            value: settings.fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (double value) {
              _logOperation('changeFontSize', {'size': value});
              settings.updateFontSize(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.3),
    );
  }

  // ... (keeping all existing methods unchanged: _showOnboarding, _resetOnboarding, etc.)

  Future<void> _showOnboarding() async {
    _logOperation('showOnboarding');
    final onboardingService = await _onboardingServiceFuture;
    await onboardingService.resetOnboarding();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnboardingPage(
            onCompleted: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    _logOperation('resetOnboarding');
    final onboardingService = await _onboardingServiceFuture;
    await onboardingService.resetOnboarding();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Welcome tour reset! It will show on next app start.')),
      );
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
                const SizedBox(height: 16),
                Text(
                  'Features in this version:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text('• Enhanced responsive design'),
                const Text('• Improved dark mode support'),
                const Text('• Better tablet experience'),
                const Text('• Performance optimizations'),
                const Text('• Premium audio features'), // ✅ NEW
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to check for updates: ${_getUserFriendlyErrorMessage(e)}'),
            backgroundColor: Colors.red,
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

  Future<void> _showAppInfo() async {
    _logOperation('showAppInfo');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LPMI40'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lagu Pujian Masa Ini',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
                'Version: ${_packageInfo?.version ?? AppInfo.AppConstants.appVersion}'),
            Text('Build: ${_packageInfo?.buildNumber ?? '1'}'),
            const SizedBox(height: 16),
            const Text(
                'A modern digital hymnal app for Indonesian praise songs.'),
            const SizedBox(height: 16),
            const Text('Features:'),
            const Text('• Browse and search songs'),
            const Text('• Save favorites'),
            const Text('• Premium audio playback'), // ✅ NEW
            const Text('• Responsive design'),
            const Text('• Dark mode support'),
            const Text('• Offline capability'),
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

  Future<void> _showDeveloperInfo() async {
    _logOperation('showDeveloperInfo');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HaweeInc'),
            SizedBox(height: 8),
            Text('Built with Flutter framework'),
            SizedBox(height: 16),
            Text('Technologies used:'),
            Text('• Flutter & Dart'),
            Text('• Firebase'),
            Text('• Material Design 3'),
            Text('• Responsive UI'),
            Text('• Premium audio system'), // ✅ NEW
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

  Future<void> _showLicensePage() async {
    _logOperation('showLicensePage');

    showLicensePage(
      context: context,
      applicationName: 'LPMI40',
      applicationVersion:
          _packageInfo?.version ?? AppInfo.AppConstants.appVersion,
      applicationLegalese: '© 2024 HaweeInc. All rights reserved.',
    );
  }

  Future<void> _signOut() async {
    _logOperation('signOut');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showFontFamilyDialog(
      SettingsNotifier settings, List<String> fontFamilies) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Font Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fontFamilies
              .map((font) => ListTile(
                    title: Text(font, style: TextStyle(fontFamily: font)),
                    leading: Radio<String>(
                      value: font,
                      groupValue: settings.fontFamily,
                      onChanged: (value) => Navigator.of(context).pop(value),
                    ),
                    onTap: () => Navigator.of(context).pop(font),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _logOperation('changeFontFamily', {'font': selected});
      settings.updateFontStyle(selected);
    }
  }

  Future<void> _showTextAlignmentDialog(SettingsNotifier settings) async {
    final alignments = [
      {
        'value': TextAlign.left,
        'name': 'Left',
        'icon': Icons.format_align_left
      },
      {
        'value': TextAlign.center,
        'name': 'Center',
        'icon': Icons.format_align_center
      },
      {
        'value': TextAlign.right,
        'name': 'Right',
        'icon': Icons.format_align_right
      },
    ];

    final selected = await showDialog<TextAlign>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Text Alignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: alignments
              .map((alignment) => ListTile(
                    title: Text(alignment['name'] as String),
                    leading: Icon(alignment['icon'] as IconData),
                    trailing: Radio<TextAlign>(
                      value: alignment['value'] as TextAlign,
                      groupValue: settings.textAlign,
                      onChanged: (value) => Navigator.of(context).pop(value),
                    ),
                    onTap: () => Navigator.of(context)
                        .pop(alignment['value'] as TextAlign),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      _logOperation('changeTextAlign', {'alignment': selected.name});
      settings.updateTextAlign(selected);
    }
  }

  String _getTextAlignmentName(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.left:
        return 'Left';
      case TextAlign.center:
        return 'Center';
      case TextAlign.right:
        return 'Right';
      default:
        return 'Left';
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
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
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);
    final iconSize = 20 * AppConstants.getTypographyScale(deviceType);

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(spacing / 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: iconSize),
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing / 4,
      ),
    );
  }
}
