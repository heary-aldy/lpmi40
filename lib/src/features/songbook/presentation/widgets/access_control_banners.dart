// lib/src/features/songbook/presentation/widgets/access_control_banners.dart
// ✅ UPDATED: No overlapping banners, only dialogs

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/pages/auth_page.dart';

// ✅ MAIN CLASS: Now only returns empty widgets (no banners)
class AccessControlBanners extends StatelessWidget {
  final MainPageController controller;

  const AccessControlBanners({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: All banner logic - just return empty widget
    return const SizedBox.shrink();
  }
}

// ✅ LOGIN BANNER: Still available but returns empty (no overlap)
class LoginPromptBanner extends StatelessWidget {
  const LoginPromptBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: No banner display
    return const SizedBox.shrink();
  }
}

// ✅ AUDIO BANNER: Completely removed (no overlap)
class AudioUpgradeBanner extends StatelessWidget {
  const AudioUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED: No banner display
    return const SizedBox.shrink();
  }
}

// ✅ HELPER: For showing premium dialogs (use this in play buttons)
class PremiumUpgradeHelper {
  static Future<void> showUpgradeDialog(BuildContext context,
      {String feature = 'audio_playback'}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          // Force proper positioning
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 80),

          // Title with close button
          title: Row(
            children: [
              // Premium icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title text
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'For Audio Features',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),

          // Content
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: 400,
            ),
            child: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock premium audio features and enhance your worship experience!',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 20),

                  // Features list
                  Text(
                    'Premium Features:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('🎵 High-quality audio playback'),
                  SizedBox(height: 6),
                  Text('🎛️ Advanced audio controls'),
                  SizedBox(height: 6),
                  Text('📱 Mini-player & full-screen modes'),
                  SizedBox(height: 6),
                  Text('⚙️ Customizable audio settings'),
                  SizedBox(height: 6),
                  Text('❤️ Enhanced favorites management'),
                  SizedBox(height: 6),
                  Text('🔄 Background audio playback'),
                  SizedBox(height: 20),

                  // Contact info
                  Text(
                    'How to upgrade:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contact admin for premium access:\nadmin@haweeincorporation.com',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact: admin@haweeincorporation.com'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Contact Admin'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact admin to upgrade to Premium!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Get Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],

          // Force proper positioning
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        );
      },
    );
  }
}

// ✅ LEGACY: Keep old classes but make them empty (for compatibility)
class PremiumUpgradeDialog extends StatelessWidget {
  const PremiumUpgradeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to helper method
    return const SizedBox.shrink();
  }
}

class AccessDeniedState extends StatelessWidget {
  final MainPageController controller;
  final VoidCallback onLoginPressed;
  final VoidCallback onUpgradePressed;

  const AccessDeniedState({
    super.key,
    required this.controller,
    required this.onLoginPressed,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title, subtitle, actionText;
    IconData icon;
    VoidCallback onActionPressed;

    if (controller.accessDeniedReason == 'login_required') {
      title = 'Sign In Required';
      subtitle =
          'Please sign in to access this collection and save your favorites';
      icon = Icons.login;
      actionText = 'Sign In';
      onActionPressed = onLoginPressed;
    } else if (controller.accessDeniedReason == 'premium_required') {
      title = 'Premium Required';
      subtitle =
          'Upgrade to Premium to access this exclusive collection and audio features';
      icon = Icons.star;
      actionText = 'Upgrade to Premium';
      onActionPressed = onUpgradePressed;
    } else {
      title = 'Access Denied';
      subtitle = 'You don\'t have permission to access this collection';
      icon = Icons.lock;
      actionText = 'Contact Support';
      onActionPressed = () {};
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: Icon(icon),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(120, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
