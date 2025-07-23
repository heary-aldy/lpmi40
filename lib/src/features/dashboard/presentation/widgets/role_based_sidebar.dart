// lib/src/features/dashboard/presentation/widgets/role_based_sidebar.dart
// Intelligent sidebar that adapts to user roles and preferences

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

// Admin imports
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/collection_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';

import 'package:lpmi40/utils/constants.dart';
import 'gif_icon_widget.dart';

class RoleBasedSidebar extends StatefulWidget {
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final String userRole;
  final List<SongCollection> availableCollections;
  final VoidCallback onRefreshCollections;
  final bool isInline;

  const RoleBasedSidebar({
    super.key,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.userRole,
    required this.availableCollections,
    required this.onRefreshCollections,
    this.isInline = false,
  });

  @override
  State<RoleBasedSidebar> createState() => _RoleBasedSidebarState();
}

class _RoleBasedSidebarState extends State<RoleBasedSidebar> {
  String _expandedSection = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);

    return Container(
      width: widget.isInline ? 280 : null,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: widget.isInline
            ? Border(right: BorderSide(color: theme.dividerColor))
            : null,
      ),
      child: Column(
        children: [
          // User profile header
          _buildUserHeader(context, scale),

          // Navigation sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Core Navigation
                _buildNavigationSection(
                  context,
                  'Core Navigation',
                  Icons.home,
                  _buildCoreNavigationItems(context, scale),
                  scale,
                ),

                // Collections
                if (widget.availableCollections.isNotEmpty)
                  _buildNavigationSection(
                    context,
                    'Collections',
                    Icons.folder_special,
                    _buildCollectionItems(context, scale),
                    scale,
                  ),

                // User Features
                if (widget.currentUser != null)
                  _buildNavigationSection(
                    context,
                    'Personal',
                    Icons.person,
                    _buildUserFeatureItems(context, scale),
                    scale,
                  ),

                // Admin sections
                if (widget.isAdmin)
                  _buildNavigationSection(
                    context,
                    'Content Management',
                    Icons.admin_panel_settings,
                    _buildAdminItems(context, scale),
                    scale,
                  ),

                if (widget.isSuperAdmin)
                  _buildNavigationSection(
                    context,
                    'System Administration',
                    Icons.security,
                    _buildSuperAdminItems(context, scale),
                    scale,
                  ),

                // Support
                _buildNavigationSection(
                  context,
                  'Support & Tools',
                  Icons.help,
                  _buildSupportItems(context, scale),
                  scale,
                ),
              ],
            ),
          ),

          // Account actions
          if (widget.currentUser != null) _buildAccountActions(context, scale),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, double scale) {
    if (widget.currentUser == null) {
      return Container(
        height: 140 * scale,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 48 * scale,
                ),
                SizedBox(height: 8 * scale),
                Text(
                  'Guest User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 140 * scale,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24 * scale,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: widget.currentUser!.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              widget.currentUser!.photoURL!,
                              width: 48 * scale,
                              height: 48 * scale,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24 * scale,
                          ),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser!.displayName ??
                              widget.currentUser!.email?.split('@')[0] ??
                              'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildRoleBadge(context, scale),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, double scale) {
    Color badgeColor;
    String badgeText;

    if (widget.isSuperAdmin) {
      badgeColor = Colors.red;
      badgeText = 'Super Admin';
    } else if (widget.isAdmin) {
      badgeColor = Colors.orange;
      badgeText = 'Admin';
    } else {
      badgeColor = Colors.blue;
      badgeText = 'User';
    }

    return Container(
      margin: EdgeInsets.only(top: 4 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNavigationSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> items,
    double scale,
  ) {
    final isExpanded = _expandedSection == title;

    // Map icon to GIF path
    String? gifPath;
    switch (icon) {
      case Icons.home:
        gifPath = 'assets/dashboard_icons/dashboard.gif';
        break;
      case Icons.folder_special:
        gifPath = 'assets/dashboard_icons/collection_management.gif';
        break;
      case Icons.person:
        gifPath = 'assets/dashboard_icons/profile.gif';
        break;
      case Icons.admin_panel_settings:
        gifPath = 'assets/dashboard_icons/admin_management.gif';
        break;
      case Icons.security:
        gifPath = 'assets/dashboard_icons/user_management.gif';
        break;
      case Icons.help:
        gifPath = 'assets/dashboard_icons/settings.gif';
        break;
    }

    return Column(
      children: [
        ListTile(
          leading: SizedBox(
            width: 20 * scale,
            height: 20 * scale,
            child: GifIconWidget(
              gifAssetPath: gifPath,
              fallbackIcon: icon,
              size: 20 * scale,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20 * scale,
          ),
          dense: true,
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? '' : title;
            });
          },
        ),
        if (isExpanded) ...items,
        const Divider(height: 1),
      ],
    );
  }

  List<Widget> _buildCoreNavigationItems(BuildContext context, double scale) {
    return [
      _buildNavItem(
        context,
        'All Songs',
        Icons.library_music,
        () => _navigateToMainPage(context, 'All'),
        scale,
        gifPath: 'assets/dashboard_icons/song_management.gif',
      ),
    ];
  }

  List<Widget> _buildCollectionItems(BuildContext context, double scale) {
    return widget.availableCollections.map((collection) {
      return _buildCollectionNavItem(
        context,
        collection.name,
        collection.id,
        () => _navigateToMainPage(context, collection.id),
        scale,
        subtitle: '${collection.songCount} songs',
        color: _getCollectionColor(collection.id),
      );
    }).toList();
  }

  List<Widget> _buildUserFeatureItems(BuildContext context, double scale) {
    return [
      _buildNavItem(
        context,
        'My Favorites',
        Icons.favorite,
        () => _navigateToMainPage(context, 'Favorites'),
        scale,
        color: Colors.red,
        gifPath: 'assets/dashboard_icons/favorites.gif',
      ),
    ];
  }

  List<Widget> _buildAdminItems(BuildContext context, double scale) {
    return [
      _buildNavItem(
        context,
        'Add Song',
        Icons.add_circle,
        () => _navigateTo(context, const AddEditSongPage()),
        scale,
        color: Colors.green,
        gifPath: 'assets/dashboard_icons/add_song.gif',
      ),
      _buildNavItem(
        context,
        'Manage Songs',
        Icons.edit_note,
        () => _navigateTo(context, const SongManagementPage()),
        scale,
        color: Colors.purple,
        gifPath: 'assets/dashboard_icons/song_management.gif',
      ),
      _buildNavItem(
        context,
        'Collections',
        Icons.folder_special,
        () => _navigateTo(context, const CollectionManagementPage()),
        scale,
        color: Colors.blue,
        gifPath: 'assets/dashboard_icons/collection_management.gif',
      ),
    ];
  }

  List<Widget> _buildSuperAdminItems(BuildContext context, double scale) {
    return [
      _buildNavItem(
        context,
        'User Management',
        Icons.people,
        () => _navigateTo(context, const UserManagementPage()),
        scale,
        color: Colors.indigo,
        gifPath: 'assets/dashboard_icons/user_management.gif',
      ),
      _buildNavItem(
        context,
        'Firebase Debug',
        Icons.bug_report,
        () => _navigateTo(context, const FirebaseDebugPage()),
        scale,
        color: Colors.red,
        gifPath: 'assets/dashboard_icons/debug.gif',
      ),
    ];
  }

  List<Widget> _buildSupportItems(BuildContext context, double scale) {
    return [
      _buildNavItem(
        context,
        'Donation',
        Icons.volunteer_activism,
        () => _navigateTo(context, const DonationPage()),
        scale,
        color: Colors.teal,
        gifPath: 'assets/dashboard_icons/donation.gif',
      ),
      _buildNavItem(
        context,
        'Settings',
        Icons.settings,
        () => _navigateTo(context, const SettingsPage()),
        scale,
        color: Colors.grey[600]!,
        gifPath: 'assets/dashboard_icons/settings.gif',
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    double scale, {
    String? subtitle,
    Color? color,
    String? gifPath,
  }) {
    return ListTile(
      leading: SizedBox(
        width: 20 * scale,
        height: 20 * scale,
        child: GifIconWidget(
          gifAssetPath: gifPath,
          fallbackIcon: icon,
          size: 20 * scale,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14 * scale),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12 * scale),
            )
          : null,
      dense: true,
      contentPadding: EdgeInsets.only(left: 48.0 * scale, right: 16.0 * scale),
      onTap: () {
        if (!widget.isInline) {
          Navigator.of(context).pop(); // Close drawer on mobile
        }
        onTap();
      },
    );
  }

  Widget _buildCollectionNavItem(
    BuildContext context,
    String title,
    String collectionId,
    VoidCallback onTap,
    double scale, {
    String? subtitle,
    Color? color,
  }) {
    return ListTile(
      leading: GifIconWidget(
        gifAssetPath: DashboardIconHelper.getCollectionGifPath(collectionId),
        fallbackIcon:
            DashboardIconHelper.getCollectionFallbackIcon(collectionId),
        size: 20 * scale,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14 * scale),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12 * scale),
            )
          : null,
      dense: true,
      contentPadding: EdgeInsets.only(left: 48.0 * scale, right: 16.0 * scale),
      onTap: () {
        if (!widget.isInline) {
          Navigator.of(context).pop(); // Close drawer on mobile
        }
        onTap();
      },
    );
  }

  Widget _buildAccountActions(BuildContext context, double scale) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, size: 20 * scale),
        title: Text('Logout', style: TextStyle(fontSize: 14 * scale)),
        onTap: () async {
          if (!widget.isInline) {
            Navigator.of(context).pop(); // Close drawer
          }
          await FirebaseAuth.instance.signOut();
        },
      ),
    );
  }

  // Helper methods
  void _navigateToMainPage(BuildContext context, String filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainPage(initialFilter: filter),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Colors.blue;
      case 'SRD':
        return Colors.purple;
      case 'Lagu_belia':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
