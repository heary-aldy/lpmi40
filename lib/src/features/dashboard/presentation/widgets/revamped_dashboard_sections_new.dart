// lib/src/features/dashboard/presentation/widgets/revamped_dashboard_sections_new.dart
// ✅ REFACTORED: Modular dashboard with separated sections for better maintainability

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/utils/constants.dart';

// Import modular sections
import 'sections/quick_search_section.dart';
import 'sections/content_carousel_section.dart';
import 'sections/quick_access_section.dart';
import 'sections/collections_section.dart';
import 'sections/admin_section.dart';

// Import remaining sections that need to be created
import 'sections/super_admin_section.dart';
import 'sections/recent_songs_section.dart';
import 'sections/support_section.dart';
import 'sections/footer_section.dart';

class RevampedDashboardSections extends StatelessWidget {
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final String userRole;
  final Song? verseOfTheDaySong;
  final Verse? verseOfTheDayVerse;
  final List<Song> favoriteSongs;
  final List<Song> recentSongs;
  final List<SongCollection> availableCollections;
  final List<String> pinnedFeatures;
  final Map<String, dynamic> userPreferences;
  final VoidCallback onRefreshDashboard;
  final Function(String) onFeaturePinToggle;

  const RevampedDashboardSections({
    super.key,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.userRole,
    required this.verseOfTheDaySong,
    required this.verseOfTheDayVerse,
    required this.favoriteSongs,
    required this.recentSongs,
    required this.availableCollections,
    required this.pinnedFeatures,
    required this.userPreferences,
    required this.onRefreshDashboard,
    required this.onFeaturePinToggle,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);
    final scale = AppConstants.getTypographyScale(deviceType);

    return Padding(
      padding: EdgeInsets.all(16.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Search Section
          QuickSearchSection(
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 1.5),

          // Content Carousel Section
          ContentCarouselSection(
            verseOfTheDaySong: verseOfTheDaySong,
            verseOfTheDayVerse: verseOfTheDayVerse,
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 1.5),

          // Quick Access Section
          QuickAccessSection(
            currentUser: currentUser,
            pinnedFeatures: pinnedFeatures,
            onFeaturePinToggle: onFeaturePinToggle,
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 1.5),

          // Collections Section
          CollectionsSection(
            availableCollections: availableCollections,
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 1.5),

          // User content stats
          if (currentUser != null) ...[
            UserContentSection(
              favoriteSongs: favoriteSongs,
              recentSongs: recentSongs,
              scale: scale,
              spacing: spacing,
            ),
            SizedBox(height: spacing * 1.5),
          ],

          // Admin sections with visual separation
          if (isAdmin || isSuperAdmin) ...[
            RoleSeparatorWidget(spacing: spacing),
            SizedBox(height: spacing),
          ],

          if (isAdmin) ...[
            AdminSection(
              scale: scale,
              spacing: spacing,
            ),
            SizedBox(height: spacing * 1.5),
          ],

          if (isSuperAdmin) ...[
            SuperAdminSection(
              scale: scale,
              spacing: spacing,
            ),
            SizedBox(height: spacing * 1.5),
          ],

          // Recent Songs Section
          RecentSongsSection(
            onRefreshDashboard: onRefreshDashboard,
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 1.5),

          // Support & Analytics Section
          SupportSection(
            isAdmin: isAdmin,
            scale: scale,
            spacing: spacing,
          ),
          SizedBox(height: spacing * 2),

          // Footer Section
          FooterSection(
            currentUser: currentUser,
            scale: scale,
            spacing: spacing,
          ),

          // Extra bottom padding for better scrolling
          SizedBox(height: spacing * 2),
        ],
      ),
    );
  }
}

// Simple User Content Section Widget
class UserContentSection extends StatelessWidget {
  final List<Song> favoriteSongs;
  final List<Song> recentSongs;
  final double scale;
  final double spacing;

  const UserContentSection({
    super.key,
    required this.favoriteSongs,
    required this.recentSongs,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Your Content', Icons.person, scale),
        SizedBox(height: 16 * scale),
        Row(
          children: [
            if (favoriteSongs.isNotEmpty)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Favorites',
                  favoriteSongs.length.toString(),
                  Icons.favorite,
                  Colors.red,
                  scale,
                ),
              ),
            if (favoriteSongs.isNotEmpty && recentSongs.isNotEmpty)
              SizedBox(width: 16 * scale),
            if (recentSongs.isNotEmpty)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Recent',
                  recentSongs.length.toString(),
                  Icons.history,
                  Colors.blue,
                  scale,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 4 * scale),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4 * scale),
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    double scale,
  ) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(24.0 * scale),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32 * scale),
            ),
            SizedBox(height: 12 * scale),
            Text(
              value,
              style: TextStyle(
                fontSize: 26 * scale,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 13 * scale,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Role Separator Widget
class RoleSeparatorWidget extends StatelessWidget {
  final double spacing;

  const RoleSeparatorWidget({
    super.key,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(context).primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                'ADMIN PANEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(context).primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
