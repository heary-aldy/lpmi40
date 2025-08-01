// lib/src/features/songbook/presentation/widgets/access_control_banners.dart
// ✅ COMPLETE UPDATED: Fixed all layout issues, overflow, and constraints

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/pages/auth_page.dart';

class AccessControlBanners extends StatelessWidget {
  final MainPageController controller;

  const AccessControlBanners({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.canAccessCurrentCollection) {
      return _buildAccessDeniedBanner(context);
    }

    return _buildBottomBanner(context);
  }

  Widget _buildAccessDeniedBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80), // ✅ Prevent overflow
      child: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          final user = FirebaseAuth.instance.currentUser;
          final isGuest = user == null;
          final isPremium = songProvider.isPremium;

          if (controller.accessDeniedReason == 'login_required') {
            return const LoginPromptBanner();
          } else if (controller.accessDeniedReason == 'premium_required' &&
              !isPremium) {
            return const AudioUpgradeBanner();
          } else {
            return const SizedBox.shrink(); // No banner needed
          }
        },
      ),
    );
  }

  Widget _buildBottomBanner(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    if (isGuest) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 80), // ✅ Prevent overflow
        child: const LoginPromptBanner(),
      );
    } else {
      // Check premium status from SongProvider
      return Container(
        constraints: const BoxConstraints(maxHeight: 80), // ✅ Prevent overflow
        child: Consumer<SongProvider>(
          builder: (context, songProvider, child) {
            final isPremium = songProvider.isPremium;

            // Only show upgrade banner if user is logged in BUT not premium
            if (isPremium) {
              return const SizedBox.shrink(); // Hide banner for premium users
            } else {
              return const AudioUpgradeBanner(); // Show upgrade for non-premium users
            }
          },
        ),
      );
    }
  }
}

class LoginPromptBanner extends StatelessWidget {
  const LoginPromptBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4), // ✅ Reduced margins
      padding: const EdgeInsets.all(12), // ✅ Reduced padding
      constraints: const BoxConstraints(maxHeight: 70), // ✅ Height constraint
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // ✅ Reduced padding
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // ✅ Smaller radius
            ),
            child: const Icon(
              Icons.login,
              color: Colors.blue,
              size: 20, // ✅ Smaller icon
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            // ✅ Changed from Expanded to Flexible
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ Prevent vertical overflow
              children: [
                Text(
                  'Sign in for more features',
                  style: theme.textTheme.titleSmall?.copyWith(
                    // ✅ Smaller text
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Save favorites, access premium collections',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade600,
                    fontSize: 11, // ✅ Smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70, // ✅ Fixed width to prevent infinite constraint
            height: 32, // ✅ Fixed height
            child: ElevatedButton(
              onPressed: () => _showLoginDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthPage(
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          onToggleTheme: () {},
        ),
      ),
    );
  }
}

class AudioUpgradeBanner extends StatelessWidget {
  const AudioUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4), // ✅ Reduced margins
      padding: const EdgeInsets.all(12), // ✅ Reduced padding
      constraints: const BoxConstraints(maxHeight: 70), // ✅ Height constraint
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // ✅ Reduced padding
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // ✅ Smaller radius
            ),
            child: const Icon(
              Icons.star,
              color: Colors.purple,
              size: 20, // ✅ Smaller icon
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            // ✅ Changed from Expanded to Flexible
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ Prevent vertical overflow
              children: [
                Text(
                  'Upgrade to Premium',
                  style: theme.textTheme.titleSmall?.copyWith(
                    // ✅ Smaller text
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Get unlimited audio playback and downloads',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.purple.shade600,
                    fontSize: 11, // ✅ Smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80, // ✅ Fixed width to prevent infinite constraint
            height: 32, // ✅ Fixed height
            child: ElevatedButton(
              onPressed: () => _showUpgradeDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(),
    );
  }
}

class PremiumUpgradeDialog extends StatelessWidget {
  const PremiumUpgradeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Upgrade to Premium',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Unlock premium features and enhance your worship experience:',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.music_note,
                      text: 'Unlimited audio playback',
                    ),
                    _buildFeatureItem(
                      icon: Icons.download,
                      text: 'Offline audio downloads',
                    ),
                    _buildFeatureItem(
                      icon: Icons.library_music,
                      text: 'Access to premium song collections',
                    ),
                    _buildFeatureItem(
                      icon: Icons.sync,
                      text: 'Sync across all your devices',
                    ),
                    _buildFeatureItem(
                      icon: Icons.support,
                      text: 'Priority customer support',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleUpgradeAction(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Upgrade'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.purple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpgradeAction(BuildContext context) {
    // Handle premium upgrade flow
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact for Premium'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To upgrade to Premium, please contact our admin:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text('haw33inc@gmail.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 8),
                Text('+60 13-5453900'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could open email app or phone dialer
            },
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
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
      onActionPressed = () {
        // Handle contact support
      };
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
              child: Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary,
              ),
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
                minimumSize: const Size(120, 48), // ✅ Minimum size constraint
              ),
            ),
          ],
        ),
      ),
    );
  }
}
