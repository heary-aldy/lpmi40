// lib/src/features/dashboard/presentation/widgets/revamped_dashboard_header.dart
// Modern, personalized dashboard header with role-based information

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';

class RevampedDashboardHeader extends StatelessWidget {
  final String greeting;
  final IconData greetingIcon;
  final String userName;
  final String userRole;
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool? isEmailVerified;
  final bool isPremium;
  final DateTime? lastActivity;
  final int loadCount;
  final VoidCallback? onProfileTap;

  const RevampedDashboardHeader({
    super.key,
    required this.greeting,
    required this.greetingIcon,
    required this.userName,
    required this.userRole,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    this.isEmailVerified,
    this.isPremium = false,
    this.lastActivity,
    required this.loadCount,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);

    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/header_image.png'),
            fit: BoxFit.cover,
            opacity: 0.6, // Increased opacity for better visibility
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black
                    .withOpacity(0.3), // Reduced for better image visibility
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.0 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side with greeting and user info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Greeting row with icon
                        Row(
                          children: [
                            Icon(
                              greetingIcon,
                              color: Colors.white,
                              size: 24 * scale,
                            ),
                            SizedBox(width: 8 * scale),
                            Flexible(
                              child: Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 20 * scale,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6 * scale),

                        // Username
                        Padding(
                          padding: EdgeInsets.only(left: 32 * scale),
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 8 * scale),

                        // Status indicators in one line
                        if (currentUser != null)
                          Padding(
                            padding: EdgeInsets.only(left: 32 * scale),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Super Admin Badge
                                  if (isSuperAdmin) ...[
                                    _buildInlineStatusChip(
                                      'SUPER ADMIN',
                                      Colors.red,
                                      scale,
                                    ),
                                    SizedBox(width: 6 * scale),
                                  ]
                                  // Admin Badge (if not super admin)
                                  else if (isAdmin) ...[
                                    _buildInlineStatusChip(
                                      'ADMIN',
                                      Colors.orange,
                                      scale,
                                    ),
                                    SizedBox(width: 6 * scale),
                                  ],

                                  // Verified Status
                                  if (isEmailVerified == true) ...[
                                    _buildInlineStatusChip(
                                      'VERIFIED',
                                      Colors.green,
                                      scale,
                                      icon: Icons.verified,
                                    ),
                                    SizedBox(width: 6 * scale),
                                  ] else if (isEmailVerified == false) ...[
                                    _buildInlineStatusChip(
                                      'UNVERIFIED',
                                      Colors.orange.withOpacity(0.8),
                                      scale,
                                      icon: Icons.email,
                                    ),
                                    SizedBox(width: 6 * scale),
                                  ],

                                  // Premium Badge
                                  if (isPremium) ...[
                                    _buildInlineStatusChip(
                                      'PREMIUM',
                                      Colors.purple,
                                      scale,
                                      icon: Icons.star,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right side with user avatar
                  _buildProfileAvatar(context, scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build role badge
  Widget _buildRoleBadge(BuildContext context, double scale) {
    if (currentUser == null) return const SizedBox.shrink();

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (isSuperAdmin) {
      badgeColor = Colors.red;
      badgeIcon = Icons.security;
      badgeText = 'SUPER ADMIN';
    } else if (isAdmin) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.admin_panel_settings;
      badgeText = 'ADMIN';
    } else {
      badgeColor = Colors.blue;
      badgeIcon = Icons.person;
      badgeText = 'USER';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: badgeColor,
            size: 16 * scale,
          ),
          SizedBox(width: 6 * scale),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 3 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 10 * scale,
          ),
          SizedBox(width: 3 * scale),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Helper method to build inline status chips
  Widget _buildInlineStatusChip(
    String label,
    Color color,
    double scale, {
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 12 * scale,
            ),
            SizedBox(width: 3 * scale),
          ],
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9 * scale,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build profile avatar or login icon
  Widget _buildProfileAvatar(BuildContext context, double scale) {
    // If user is not logged in, show login icon
    if (currentUser == null) {
      return GestureDetector(
        onTap: () {
          if (onProfileTap != null) {
            onProfileTap!();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2 * scale),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24 * scale,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Icon(
              Icons.login,
              color: Theme.of(context).primaryColor,
              size: 28 * scale,
            ),
          ),
        ),
      );
    }

    // If user is logged in, show profile avatar
    return Consumer<UserProfileNotifier>(
      builder: (context, userNotifier, _) {
        final profileImage = userNotifier.profileImage;

        return GestureDetector(
          onTap: () {
            if (onProfileTap != null) {
              onProfileTap!();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24 * scale,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  profileImage != null ? FileImage(profileImage) : null,
              child: profileImage == null
                  ? Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: 28 * scale,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
