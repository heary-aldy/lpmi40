// dashboard_sections.dart - Main content sections of the dashboard

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
import 'dashboard_helpers.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSearchField(context),
        const SizedBox(height: 24),
        _buildVerseOfTheDayCard(context),
        const SizedBox(height: 24),
        _buildQuickAccessSection(context),
        const SizedBox(height: 24),
        _buildMoreFromUsSection(context),
        if (favoriteSongs.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecentFavoritesSection(context),
        ],
        if (isAdmin) ...[
          const SizedBox(height: 24),
          _buildAdminInfoSection(context),
        ],
        const SizedBox(height: 24),
        _buildFooter(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const MainPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Search Songs by Number or Title...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context) {
    if (verseOfTheDaySong == null || verseOfTheDayVerse == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verse of the Day",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    SongLyricsPage(songNumber: verseOfTheDaySong!.number))),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '"${verseOfTheDayVerse!.lyrics}"\n',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(
                      text: '\n— ${verseOfTheDaySong!.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
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
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.grey.shade700,
        'onTap': () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const SettingsPage()))
      },
      // ✅ UPDATED: Report Song only for registered users (not anonymous/guest)
      if (currentUser != null && !currentUser!.isAnonymous) ...[
        {
          'icon': Icons.flag,
          'label': 'Report Song',
          'color': Colors.amber.shade700,
          'onTap': () async {
            try {
              // TODO: Navigate to your existing song report page
              showInfoMessage(context,
                  'Song report feature available for registered users!');
            } catch (e) {
              showErrorMessage(context, 'Error opening song report: $e');
            }
          }
        },
      ],
      // Admin features
      if (isAdmin) ...[
        {
          'icon': Icons.add_circle,
          'label': 'Add Song',
          'color': Colors.green,
          'onTap': () async {
            try {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (context) => const AddEditSongPage()),
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
      ],
      // Super admin only features
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
          const Text("Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isSuperAdmin ? Colors.red : Colors.orange)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSuperAdmin ? Colors.red : Colors.orange, width: 1),
              ),
              child: Text(
                isSuperAdmin ? 'SUPER ADMIN MODE' : 'ADMIN MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSuperAdmin ? Colors.red : Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback);
          },
        ),
      )
    ]);
  }

  Widget _buildMoreFromUsSection(BuildContext context) {
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
      const Text("More From Us",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildAccessCard(context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => _launchURL(action['url'] as String));
          },
        ),
      )
    ]);
  }

  Widget _buildAccessCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))
            ])),
      ),
    );
  }

  Widget _buildRecentFavoritesSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Recent Favorites",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: favoriteSongs.length > 5 ? 5 : favoriteSongs.length,
        itemBuilder: (context, index) {
          final song = favoriteSongs[index];
          return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: Text(song.number,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${song.verses.length} verses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SongLyricsPage(songNumber: song.number))),
              ));
        },
      ),
    ]);
  }

  Widget _buildAdminInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isSuperAdmin ? Icons.security : Icons.admin_panel_settings,
                color: isSuperAdmin ? Colors.red : Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(isSuperAdmin ? "Super Admin Dashboard" : "Admin Dashboard",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: (isSuperAdmin ? Colors.red : Colors.orange).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person,
                        color: isSuperAdmin ? Colors.red : Colors.orange,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Logged in as: ${currentUser?.email ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.security,
                        color: isSuperAdmin ? Colors.red : Colors.orange,
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                        isSuperAdmin
                            ? 'Super admin privileges: Active'
                            : 'Admin privileges: Active',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isSuperAdmin
                      ? 'You have full access to song management, user management, reports, and Firebase debugging.'
                      : 'You have access to song management and reports. User management requires super admin privileges.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Made With Love: HaweeInc',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Lagu Pujian Masa Ini © ${DateTime.now().year}',
          style: TextStyle(
            fontSize: 12,
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
