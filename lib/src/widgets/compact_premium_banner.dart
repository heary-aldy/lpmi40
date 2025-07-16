// lib/src/widgets/compact_premium_banner.dart
// ✅ DEBUG VERSION: Added debug prints to all banners to identify which one is showing

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/utils/constants.dart';

class CompactPremiumBanner extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CompactPremiumBanner({
    super.key,
    this.message = 'Upgrade to Premium for audio features and more!',
    this.icon = Icons.star,
    this.backgroundColor,
    this.textColor,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  State<CompactPremiumBanner> createState() => _CompactPremiumBannerState();
}

class _CompactPremiumBannerState extends State<CompactPremiumBanner> {
  final PremiumService _premiumService = PremiumService();
  bool _isPremium = false;
  bool _isLoading = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_playback',
      ),
    );
  }

  void _dismissBanner() {
    setState(() {
      _isDismissed = true;
    });
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: CompactPremiumBanner build() called');
    print('🔍 DEBUG: CompactPremiumBanner message: "${widget.message}"');

    // Don't show banner if premium, loading, or dismissed
    if (_isLoading || _isPremium || _isDismissed) {
      print('🔍 DEBUG: CompactPremiumBanner returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }

    print('🔍 DEBUG: CompactPremiumBanner rendering banner with purple button');

    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(spacing * 0.5),
      padding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.75,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.indigo.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(spacing * 0.5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: Colors.purple,
                size: 16 * scale,
              ),
            ),

            SizedBox(width: spacing),

            // Message
            Expanded(
              child: Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.textColor ?? Colors.purple.shade700,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(width: spacing),

            // Upgrade button - ✅ FIXED: Better padding and constraints
            SizedBox(
              width: 90 *
                  scale, // Fixed width to prevent infinite constraint error
              child: ElevatedButton.icon(
                onPressed: _showUpgradeDialog,
                icon: Icon(Icons.star, size: 14 * scale),
                label: Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing * 0.5,
                    vertical: spacing * 0.25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Close button
            if (widget.showCloseButton) ...[
              SizedBox(width: spacing * 0.5),
              SizedBox(
                width: 32 * scale,
                height: 32 * scale,
                child: IconButton(
                  onPressed: _dismissBanner,
                  icon: Icon(
                    Icons.close,
                    size: 16 * scale,
                    color: Colors.grey.shade600,
                  ),
                  tooltip: 'Dismiss',
                  padding: EdgeInsets.all(spacing * 0.25),
                  constraints: BoxConstraints(
                    minWidth: 24 * scale,
                    minHeight: 24 * scale,
                    maxWidth: 32 * scale,
                    maxHeight: 32 * scale,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ✅ DEBUG VERSION: AudioUpgradeBanner with debug prints
class AudioUpgradeBanner extends StatefulWidget {
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AudioUpgradeBanner({
    super.key,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  State<AudioUpgradeBanner> createState() => _AudioUpgradeBannerState();
}

class _AudioUpgradeBannerState extends State<AudioUpgradeBanner> {
  final PremiumService _premiumService = PremiumService();
  bool _isPremium = false;
  bool _isLoading = true;

  // ✅ PERSISTENT DISMISS: Remember dismissal for the session
  static bool _isDismissedForSession = false;

  // ✅ CONTEXT-AWARE: Track if user has interacted with audio features
  static bool _hasTriedAudioFeatures = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: AudioUpgradeBanner build() called');
    print(
        '🔍 DEBUG: AudioUpgradeBanner _isLoading = $_isLoading, _isPremium = $_isPremium, _isDismissedForSession = $_isDismissedForSession');

    // Don't show banner if premium, loading, or dismissed for session
    if (_isLoading || _isPremium || _isDismissedForSession) {
      print('🔍 DEBUG: AudioUpgradeBanner returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }

    print(
        '🔍 DEBUG: AudioUpgradeBanner rendering banner with blue "Learn More" button');

    final theme = Theme.of(context);

    // ✅ COMPREHENSIVE POSITIONING FIX
    return LayoutBuilder(
      builder: (context, constraints) {
        print(
            '🔍 DEBUG: AudioUpgradeBanner available width: ${constraints.maxWidth}');

        return Container(
          // ✅ FORCE FULL WIDTH - Critical fix for positioning
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            minWidth: constraints.maxWidth,
          ),
          // ✅ REMOVE HORIZONTAL MARGIN - Prevent positioning issues
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            // ✅ MINIMAL: Very subtle background
            color: theme.brightness == Brightness.dark
                ? Colors.blueGrey.withOpacity(0.08)
                : Colors.blueGrey.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.blueGrey.withOpacity(0.3)
                  : Colors.blueGrey.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ ICON: Fixed size and positioning
                Icon(
                  Icons.headphones_outlined,
                  color: theme.brightness == Brightness.dark
                      ? Colors.blueGrey.shade300
                      : Colors.blueGrey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 12),

                // ✅ TEXT: Expanded to take available space
                Expanded(
                  child: Text(
                    _hasTriedAudioFeatures
                        ? 'Audio playback available for Premium users'
                        : 'Discover audio features with Premium',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.blueGrey.shade300
                          : Colors.blueGrey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // ✅ BUTTON: Fixed width to prevent layout issues
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () async {
                      // Show upgrade dialog
                      await showDialog(
                        context: context,
                        builder: (context) => const PremiumUpgradeDialog(
                          feature: 'audio_playback',
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      minimumSize: const Size(70, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.dark
                            ? Colors.blueGrey.shade400
                            : Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                ),

                // ✅ CLOSE BUTTON: Fixed size and positioning
                if (widget.showCloseButton) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      onPressed: () {
                        // ✅ PERSISTENT: Mark as dismissed for session
                        setState(() {
                          _isDismissedForSession = true;
                        });
                        if (widget.onClose != null) {
                          widget.onClose!();
                        }
                      },
                      icon: Icon(
                        Icons.close,
                        size: 14,
                        color: theme.brightness == Brightness.dark
                            ? Colors.blueGrey.shade400
                            : Colors.blueGrey.shade500,
                      ),
                      tooltip: 'Dismiss for this session',
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                        maxWidth: 28,
                        maxHeight: 28,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ CONTEXT-AWARE: Static method to mark when user tries audio features
  static void markAudioFeatureAttempt() {
    _hasTriedAudioFeatures = true;
  }

  // ✅ UTILITY: Reset for new app session (call in main.dart or app restart)
  static void resetForNewSession() {
    _isDismissedForSession = false;
    _hasTriedAudioFeatures = false;
  }
}

// ✅ Collection-specific banner
class CollectionAccessBanner extends StatelessWidget {
  final String collectionName;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CollectionAccessBanner({
    super.key,
    required this.collectionName,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    print(
        '🔍 DEBUG: CollectionAccessBanner build() called for collection: $collectionName');

    return CompactPremiumBanner(
      message: 'Login to access $collectionName collection and save favorites!',
      icon: Icons.lock_outline,
      backgroundColor: Colors.orange.withOpacity(0.1),
      textColor: Colors.orange.shade700,
      showCloseButton: showCloseButton,
      onClose: onClose,
    );
  }
}

// ✅ DEBUG VERSION: LoginPromptBanner with debug prints
class LoginPromptBanner extends StatelessWidget {
  final bool showCloseButton;
  final VoidCallback? onClose;

  const LoginPromptBanner({
    super.key,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 DEBUG: LoginPromptBanner build() called');
    print(
        '🔍 DEBUG: LoginPromptBanner rendering blue banner with "Login" button');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Login to save favorites and access more features',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // ✅ FIXED: Wrap ElevatedButton with SizedBox and proper navigation
            SizedBox(
              width: 80, // Fixed width to prevent infinite constraint error
              child: ElevatedButton(
                onPressed: () {
                  // ✅ FIXED: Use proper navigation pattern with AuthPage
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AuthPage(
                        isDarkMode:
                            Theme.of(context).brightness == Brightness.dark,
                        onToggleTheme: () {},
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (showCloseButton) ...[
              const SizedBox(width: 8),
              // ✅ FIXED: Also add width constraint to IconButton container
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: onClose,
                  icon:
                      Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                    maxWidth: 32,
                    maxHeight: 32,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
