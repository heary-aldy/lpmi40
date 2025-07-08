// lib/src/features/dashboard/presentation/dashboard_sections.dart
// ✅ UPDATED: Added a "Donation" card to the Quick Access section.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/announcement_management_page.dart';
import 'package:lpmi40/src/features/dashboard/presentation/widgets/integrated_content_carousel_widget.dart';
import 'dashboard_helpers.dart';

// ✅ ADDED: Import for the DonationPage and responsive utilities
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

class DashboardSections extends StatelessWidget {
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final Song? verseOfTheDaySong;
  final Verse? verseOfTheDayVerse;
  final List<Song> favoriteSongs;
  final VoidCallback onRefreshDashboard;

  const DashboardSections({
    super.key,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.verseOfTheDaySong,
    required this.verseOfTheDayVerse,
    required this.favoriteSongs,
    required this.onRefreshDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        _buildSearchField(context),
        SizedBox(height: spacing),
        _buildVerseOfTheDayCard(context),
        SizedBox(height: spacing * 0.5),
        _buildQuickAccessSection(context),
        if (isAdmin) ...[
          SizedBox(height: spacing),
          _buildAdminActionsSection(context),
        ],
        SizedBox(height: spacing),
        _buildMoreFromUsSection(context),
        if (favoriteSongs.isNotEmpty) ...[
          SizedBox(height: spacing),
          _buildRecentFavoritesSection(context),
        ],
        if (isAdmin) ...[
          SizedBox(height: spacing),
          _buildAdminInfoSection(context),
        ],
        SizedBox(height: spacing),
        _buildFooter(context),
        SizedBox(height: spacing * 1.5),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const MainPage())),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20 * scale,
            ),
            SizedBox(width: 12 * scale),
            Text(
              'Search Songs by Number or Title...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    final cardPadding = switch (deviceType) {
      DeviceType.mobile => 16.0,
      DeviceType.tablet => 24.0,
      DeviceType.desktop => 32.0,
      DeviceType.largeDesktop => 40.0,
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardPadding * 0.25),
      child: IntegratedContentCarouselWidget(
        verseOfTheDaySong: verseOfTheDaySong,
        verseOfTheDayVerse: verseOfTheDayVerse,
        autoScrollDuration: const Duration(seconds: 4),
        showIndicators: true,
        autoScroll: true,
      ),
    );
  }

  // ✅ UPDATED: Added Donation card to the Quick Access list
  Widget _buildQuickAccessSection(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    final cardHeight = switch (deviceType) {
      DeviceType.mobile => 100.0,
      DeviceType.tablet => 120.0,
      DeviceType.desktop => 130.0,
      DeviceType.largeDesktop => 140.0,
    };

    final actions = [
      {
        'icon': Icons.music_note,
        'label': 'All Songs',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MainPage(initialFilter: 'All')))
      },
      {
        'icon': Icons.favorite,
        'label': 'Favorites',
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MainPage(initialFilter: 'Favorites')))
      },
      // ✅ NEW: Donation Card added to the list
      {
        'icon': Icons.volunteer_activism,
        'label': 'Donation',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const DonationPage()))
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.grey.shade700,
        'onTap': () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const SettingsPage()))
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Quick Access",
        style: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: spacing * 0.5),
      SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => SizedBox(width: spacing * 0.75),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
              height: cardHeight,
            );
          },
        ),
      )
    ]);
  }

  Widget _buildAdminActionsSection(BuildContext context) {
    if (!isAdmin) return const SizedBox.shrink();

    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    final cardHeight = switch (deviceType) {
      DeviceType.mobile => 100.0,
      DeviceType.tablet => 120.0,
      DeviceType.desktop => 130.0,
      DeviceType.largeDesktop => 140.0,
    };

    final adminActions = [
      {
        'icon': Icons.add_circle,
        'label': 'Add Song',
        'color': Colors.green,
        'onTap': () async {
          try {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const AddEditSongPage()),
            );
            if (result == true) {
              onRefreshDashboard();
              showSuccessMessage(context, 'Song added successfully!');
            }
          } catch (e) {
            showErrorMessage(context, 'Error adding song: $e');
          }
        }
      },
      {
        'icon': Icons.edit_note,
        'label': 'Manage Songs',
        'color': Colors.purple,
        'onTap': () async {
          try {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                  builder: (context) => const SongManagementPage()),
            );
            if (result == true) {
              onRefreshDashboard();
            }
          } catch (e) {
            showErrorMessage(context, 'Error opening song management: $e');
          }
        }
      },
      {
        'icon': Icons.report,
        'label': 'Manage Reports',
        'color': Colors.orange,
        'onTap': () async {
          try {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ReportsManagementPage(),
              ),
            );
          } catch (e) {
            showErrorMessage(context, 'Error opening reports management: $e');
          }
        }
      },
      {
        'icon': Icons.campaign,
        'label': 'Announcements',
        'color': Colors.indigo,
        'onTap': () async {
          try {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AnnouncementManagementPage(),
              ),
            );
          } catch (e) {
            showErrorMessage(
                context, 'Error opening announcements management: $e');
          }
        }
      },
      if (isSuperAdmin) ...[
        {
          'icon': Icons.people,
          'label': 'User Management',
          'color': Colors.indigo,
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const UserManagementPage()))
        },
        {
          'icon': Icons.bug_report,
          'label': 'Firebase Debug',
          'color': Colors.red,
          'onTap': () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const FirebaseDebugPage()))
        },
      ],
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Icon(
            isSuperAdmin ? Icons.security : Icons.admin_panel_settings,
            color: isSuperAdmin ? Colors.red : Colors.orange,
            size: 20 * scale,
          ),
          SizedBox(width: spacing * 0.5),
          Text(
            isSuperAdmin ? "Super Admin Actions" : "Admin Actions",
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: spacing * 0.5),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * scale,
              vertical: 2 * scale,
            ),
            decoration: BoxDecoration(
              color:
                  (isSuperAdmin ? Colors.red : Colors.orange).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(
                  color: isSuperAdmin ? Colors.red : Colors.orange, width: 1),
            ),
            child: Text(
              isSuperAdmin ? 'SUPER ADMIN MODE' : 'ADMIN MODE',
              style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
                color: isSuperAdmin ? Colors.red : Colors.orange,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing * 0.5),
      SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: adminActions.length,
          separatorBuilder: (context, index) => SizedBox(width: spacing * 0.75),
          itemBuilder: (context, index) {
            final action = adminActions[index];
            return _buildAccessCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
              height: cardHeight,
            );
          },
        ),
      )
    ]);
  }

  Widget _buildMoreFromUsSection(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    final cardHeight = switch (deviceType) {
      DeviceType.mobile => 100.0,
      DeviceType.tablet => 120.0,
      DeviceType.desktop => 130.0,
      DeviceType.largeDesktop => 140.0,
    };

    final actions = [
      {
        'icon': Icons.star,
        'label': 'Upgrade',
        'color': Colors.amber.shade700,
        'url':
            'https://play.google.com/store/apps/details?id=com.haweeinc.lpmi_premium'
      },
      {
        'icon': Icons.book,
        'label': 'Alkitab 1.0',
        'color': Colors.green,
        'url':
            'https://play.google.com/store/apps/details?id=com.haweeinc.alkitab'
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "More From Us",
        style: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: spacing * 0.5),
      SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => SizedBox(width: spacing * 0.75),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () => _launchURL(action['url'] as String),
              height: cardHeight,
            );
          },
        ),
      )
    ]);
  }

  Widget _buildAccessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double? height,
  }) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);

    final cardHeight = height ?? (100.0 * scale);
    final cardWidth = cardHeight;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        elevation: 4 * scale,
        shadowColor: color.withOpacity(0.3),
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: (32 * scale).clamp(24.0, 48.0),
                color: Colors.white,
              ),
              SizedBox(height: 8 * scale),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (12 * scale).clamp(10.0, 16.0),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFavoritesSection(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Recent Favorites",
        style: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: spacing * 0.5),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: favoriteSongs.length > 5 ? 5 : favoriteSongs.length,
        itemBuilder: (context, index) {
          final song = favoriteSongs[index];
          return Card(
            margin: EdgeInsets.only(bottom: spacing * 0.5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Text(
                  song.number,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14 * scale),
              ),
              subtitle: Text(
                '${song.verses.length} verses',
                style: TextStyle(fontSize: 12 * scale),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16 * scale,
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      SongLyricsPage(songNumber: song.number))),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildAdminInfoSection(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSuperAdmin ? Icons.security : Icons.admin_panel_settings,
              color: isSuperAdmin ? Colors.red : Colors.orange,
              size: 20 * scale,
            ),
            SizedBox(width: spacing * 0.5),
            Text(
              isSuperAdmin ? "Super Admin Info" : "Admin Info",
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.5),
        Card(
          color: (isSuperAdmin ? Colors.red : Colors.orange).withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(16.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: isSuperAdmin ? Colors.red : Colors.orange,
                      size: 16 * scale,
                    ),
                    SizedBox(width: spacing * 0.5),
                    Expanded(
                      child: Text(
                        'Logged in as: ${currentUser?.email ?? 'Unknown'}',
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 0.5),
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: isSuperAdmin ? Colors.red : Colors.orange,
                      size: 16 * scale,
                    ),
                    SizedBox(width: spacing * 0.5),
                    Text(
                      isSuperAdmin
                          ? 'Super admin privileges: Active'
                          : 'Admin privileges: Active',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 0.5),
                Text(
                  isSuperAdmin
                      ? 'You have full access to all administrative features including user management and system debugging.'
                      : 'You have access to song management and reports. Contact super admin for additional privileges.',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Column(
      children: [
        const Divider(),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red,
              size: 16 * scale,
            ),
            SizedBox(width: spacing * 0.5),
            Text(
              'Made With Love: HaweeInc',
              style: TextStyle(
                fontSize: 14 * scale,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.5),
        Text(
          'Lagu Pujian Masa Ini © ${DateTime.now().year}',
          style: TextStyle(
            fontSize: 12 * scale,
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
