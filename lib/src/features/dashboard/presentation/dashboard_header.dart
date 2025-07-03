// dashboard_header.dart - Header section with greeting and profile

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/pages/profile_page.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final IconData greetingIcon;
  final String userName;
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool? isEmailVerified; // ✅ Email verification status (null = unknown)
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.greetingIcon,
    required this.userName,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    this.isEmailVerified,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/header_image.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ UPDATED: Clean greeting row - no badges
                        Row(
                          children: [
                            Icon(greetingIcon, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(greeting,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ✅ Username row with verified icon
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(userName,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              // ✅ Small verification icon next to name (if verified)
                              if (currentUser != null &&
                                  !currentUser!.isAnonymous &&
                                  isEmailVerified == true) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ✅ NEW: Badges row below username
                        if (currentUser != null &&
                            !currentUser!.isAnonymous &&
                            (isAdmin ||
                                isSuperAdmin ||
                                isEmailVerified == false))
                          Padding(
                            padding: const EdgeInsets.only(left: 36, top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Super Admin badge
                                if (isSuperAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('SUPER ADMIN',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                // Admin badge (if not super admin)
                                if (isAdmin && !isSuperAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('ADMIN',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                                // Unverified badge
                                if (isEmailVerified == false)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('UNVERIFIED',
                                        style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildProfileAvatar(context, settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, SettingsNotifier settings) {
    return InkWell(
      onTap: () {
        if (onProfileTap != null) {
          onProfileTap!();
        } else {
          // Default behavior (fallback)
          if (currentUser == null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AuthPage(
                isDarkMode: settings.isDarkMode,
                onToggleTheme: () =>
                    settings.updateDarkMode(!settings.isDarkMode),
              ),
            ));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()));
          }
        }
      },
      child: Consumer<UserProfileNotifier>(
        builder: (context, userProfileNotifier, child) {
          Widget avatarChild;
          Color? backgroundColor;

          if (currentUser == null) {
            // No user logged in - show login icon
            backgroundColor =
                Theme.of(context).colorScheme.primary.withOpacity(0.1);
            avatarChild = Icon(Icons.login,
                color: Theme.of(context).colorScheme.primary, size: 24);
          } else if (userProfileNotifier.isLoading) {
            // Loading state - show spinner
            backgroundColor = isSuperAdmin
                ? Colors.red.withOpacity(0.3)
                : isAdmin
                    ? Colors.orange.withOpacity(0.3)
                    : null;
            avatarChild = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            );
          } else if (userProfileNotifier.hasProfileImage) {
            // Local profile image exists - use it (highest priority)
            backgroundColor = null;
            avatarChild = Stack(
              children: [
                ClipOval(
                  child: Image.file(
                    userProfileNotifier.profileImage!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Error loading local profile image: $error');
                      return _buildFallbackAvatar();
                    },
                  ),
                ),
                // ✅ Small verification badge on avatar (if verified)
                if (!currentUser!.isAnonymous && isEmailVerified == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            );
          } else if (currentUser!.photoURL != null) {
            // Firebase Auth photoURL exists - use as fallback
            backgroundColor = null;
            avatarChild = Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    currentUser!.photoURL!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ Error loading Firebase photoURL: $error');
                      return _buildFallbackAvatar();
                    },
                  ),
                ),
                // ✅ Small verification badge on avatar (if verified)
                if (!currentUser!.isAnonymous && isEmailVerified == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            );
          } else {
            // No image available - show default icon
            avatarChild = _buildFallbackAvatar();
          }

          return CircleAvatar(
            radius: 24,
            backgroundColor: backgroundColor,
            child: avatarChild,
          );
        },
      ),
    );
  }

  // Helper method for fallback avatar
  Widget _buildFallbackAvatar() {
    Color? backgroundColor = isSuperAdmin
        ? Colors.red.withOpacity(0.3)
        : isAdmin
            ? Colors.orange.withOpacity(0.3)
            : null;

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: isSuperAdmin
                ? Colors.red
                : isAdmin
                    ? Colors.orange
                    : Colors.white,
            size: (isSuperAdmin || isAdmin) ? 28 : 24,
          ),
        ),
        // ✅ Small verification badge on fallback avatar (if verified)
        if (currentUser != null &&
            !currentUser!.isAnonymous &&
            isEmailVerified == true)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
