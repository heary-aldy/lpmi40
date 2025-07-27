// lib/src/features/dashboard/presentation/widgets/revamped_dashboard_sections.dart
// Modern dashboard sections with role-based content and personalization

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/favorites_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/smart_search_page.dart';
import 'package:lpmi40/src/features/bible/presentation/bible_main_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

// Add missing imports
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';

// Admin imports
import 'package:lpmi40/src/features/admin/presentation/add_edit_song_page.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/collection_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/user_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/reports_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/announcement_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/admin_management_page.dart';
import 'package:lpmi40/src/features/admin/presentation/asset_sync_utility_page.dart';

// Debug imports
import 'package:lpmi40/src/features/debug/firebase_debug_page.dart';
import 'package:lpmi40/src/features/debug/sync_debug_page.dart';

// Announcement services
import 'package:lpmi40/src/core/services/announcement_service.dart';

import 'package:lpmi40/utils/constants.dart';

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
          // Quick Search
          _buildQuickSearchSection(context, scale, spacing),
          SizedBox(height: spacing),

          // Content Carousel (Verse of the Day, Announcements, Promotions)
          _buildContentCarouselSection(context, scale, spacing),
          SizedBox(height: spacing),

          // Personalized Quick Access
          _buildPersonalizedQuickAccess(context, scale, spacing),
          SizedBox(height: spacing),

          // Collections Grid
          _buildCollectionsGrid(context, scale, spacing),
          SizedBox(height: spacing),

          // User-specific content
          if (currentUser != null) ...[
            _buildUserContentSection(context, scale, spacing),
            SizedBox(height: spacing),
          ],

          // Role-based sections
          if (isAdmin) ...[
            _buildAdminSection(context, scale, spacing),
            SizedBox(height: spacing),
          ],

          if (isSuperAdmin) ...[
            _buildSuperAdminSection(context, scale, spacing),
            SizedBox(height: spacing),
          ],

          // Recent Songs Section
          _buildRecentSongsSection(context, scale, spacing),
          SizedBox(height: spacing * 2),

          // Footer section at the bottom
          _buildFooterSection(context, scale, spacing),
        ],
      ),
    );
  }

  Widget _buildQuickSearchSection(
      BuildContext context, double scale, double spacing) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MainPage()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0 * scale,
            vertical:
                12.0 * scale, // ✅ REDUCED: From 16.0 to 12.0 for smaller height
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 24 * scale,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  'Search songs by number, title, or lyrics...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16 * scale,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Content Carousel Section - Verse of the Day, Announcements, Promotions
  Widget _buildContentCarouselSection(
      BuildContext context, double scale, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Daily Content', Icons.auto_stories, scale),
        SizedBox(height: 12 * scale),
        SizedBox(
          height: 180 * scale,
          child: _buildAnnouncementCarousel(context, scale),
        ),
      ],
    );
  }

  // Enhanced Announcement Carousel with Auto-scroll and optimized loading
  Widget _buildAnnouncementCarousel(BuildContext context, double scale) {
    return FutureBuilder<List<Announcement>>(
      future: AnnouncementService().getActiveAnnouncements().timeout(
        const Duration(seconds: 5), // Reduced timeout from 8 seconds to 5
        onTimeout: () {
          debugPrint(
              '⚠️ [Dashboard] Announcement loading timed out, showing fallback content');
          return <Announcement>[]; // Return empty list on timeout
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show minimal loading indicator
          return SizedBox(
            height: 120 * scale,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2 * scale),
            ),
          );
        }

        final List<Widget> contentItems = [];

        // Add Verse of the Day if available (always show this quickly)
        if (verseOfTheDaySong != null && verseOfTheDayVerse != null) {
          contentItems.add(_buildVerseOfTheDayCard(context, scale));
        }

        // Add announcements from Firebase (if loaded successfully)
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (final announcement in snapshot.data!) {
            contentItems
                .add(_buildAnnouncementCard(context, scale, announcement));
          }
        } else if (snapshot.hasError) {
          // Log error but don't show it to user, just show fallback content
          debugPrint(
              '⚠️ [Dashboard] Announcement loading error: ${snapshot.error}');
          contentItems.add(_buildWelcomeCard(context, scale));
        } else {
          // Add fallback welcome card if no announcements
          contentItems.add(_buildWelcomeCard(context, scale));
        }

        if (contentItems.isEmpty) {
          return SizedBox(
            height: 120 * scale,
            child: Center(
              child: Text(
                'Welcome to LPMI.40',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }

        return _AnnouncementCarouselWidget(
          contentItems: contentItems,
          scale: scale,
        );
      },
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context, double scale) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
            ],
          ),
        ),
        padding: EdgeInsets.all(12.0 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 18 * scale,
                ),
                SizedBox(width: 6 * scale),
                Text(
                  'Verse of the Day',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Text(
              verseOfTheDaySong!.title,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6 * scale),
            Text(
              verseOfTheDayVerse!.lyrics,
              style: TextStyle(
                fontSize: 11 * scale,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, double scale) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B1FA2),
              Color(0xFF6A1B9A),
            ],
          ),
        ),
        padding: EdgeInsets.all(12.0 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 18 * scale,
                ),
                SizedBox(width: 6 * scale),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Text(
              'LPMI40 Digital Songbook',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              'Explore our collection of praise and worship songs. Find your favorites, discover new songs, and enhance your worship experience.',
              style: TextStyle(
                fontSize: 11 * scale,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, double scale,
      [Announcement? announcement]) {
    final title = announcement?.title ?? 'What\'s New';
    final subtitle =
        announcement?.title != null ? 'Announcement' : 'Latest Updates';
    final content = announcement?.content ??
        'Check out our enhanced dashboard with improved design, better navigation, and new features for a better user experience.';

    // ✅ NEW: Check if this is an image announcement
    final isImageAnnouncement = announcement?.isImage == true &&
        announcement?.imageUrl.isNotEmpty == true;

    debugPrint('🎯 Building announcement card: ${announcement?.title}');
    debugPrint(
        '🎯 Type: ${announcement?.type}, IsImage: ${announcement?.isImage}');
    debugPrint('🎯 ImageURL: "${announcement?.imageUrl}"');
    debugPrint('🎯 IsImageAnnouncement: $isImageAnnouncement');
    debugPrint(
        '🎯 HasLink: ${announcement?.hasLink}, LinkURL: "${announcement?.linkUrl}"');

    if (isImageAnnouncement) {
      debugPrint(
          '🖼️ Building IMAGE announcement card for: ${announcement!.title}');
      return _buildImageAnnouncementCard(context, scale, announcement);
    }

    // ✅ FIXED: Apply all announcement styling properties
    final icon = announcement?.selectedIcon != null
        ? _getIconFromString(announcement!.selectedIcon!)
        : Icons.campaign;

    // Get custom colors and styling
    final textColor = announcement?.textColor != null
        ? _getTextColorFromAnnouncement(announcement!.textColor!)
        : Colors.white;

    final iconColor = announcement?.iconColor != null
        ? _getTextColorFromAnnouncement(announcement!.iconColor!)
        : Colors.white;

    final fontSize = announcement?.fontSize ?? 14.0;
    final fontWeight = announcement?.textStyle?.contains('bold') == true
        ? FontWeight.bold
        : FontWeight.w600;
    final fontStyle = announcement?.textStyle?.contains('italic') == true
        ? FontStyle.italic
        : FontStyle.normal;

    // Background styling
    Color? solidBackgroundColor;
    Gradient? backgroundGradient;

    if (announcement?.backgroundGradient != null) {
      // Use gradient if specified
      backgroundGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _getGradientColorsFromAnnouncement(
            announcement!.backgroundGradient!),
      );
    } else if (announcement?.backgroundColor != null) {
      // Use solid color if specified
      solidBackgroundColor =
          _getBackgroundColorFromAnnouncement(announcement!.backgroundColor!);
    } else {
      // Default gradient
      backgroundGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
      );
    }

    final cardWidget = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: solidBackgroundColor,
          gradient: backgroundGradient,
        ),
        padding: EdgeInsets.all(12.0 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 20 * scale,
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: (fontSize + 1) * scale, // Title slightly larger
                      fontWeight: fontWeight == FontWeight.w600
                          ? FontWeight.bold
                          : FontWeight.w900, // Make title even bolder
                      fontStyle: fontStyle,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: (fontSize - 1) * scale,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                color: textColor.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              content,
              style: TextStyle(
                fontSize: (fontSize - 2) * scale,
                fontWeight: announcement?.textStyle?.contains('bold') == true
                    ? FontWeight.normal
                    : FontWeight.normal,
                fontStyle: fontStyle,
                color: textColor.withOpacity(0.8),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    // ✅ NEW: Make text card clickable if it has a link
    if (announcement?.hasLink == true) {
      debugPrint('🔗 Making text card clickable for: ${announcement!.title}');
      return InkWell(
        onTap: () => _launchAnnouncementUrl(announcement.linkUrl!),
        borderRadius: BorderRadius.circular(16),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// ✅ NEW: Build image announcement card
  Widget _buildImageAnnouncementCard(
      BuildContext context, double scale, Announcement announcement) {
    debugPrint('🖼️ Creating image card for: ${announcement.title}');
    debugPrint('🖼️ Image URL: ${announcement.imageUrl}');
    debugPrint('🖼️ Scale: $scale');
    debugPrint('🖼️ Has link: ${announcement.hasLink}');
    if (announcement.hasLink) {
      debugPrint('🔗 Link URL: ${announcement.linkUrl}');
    }

    // Get custom styling
    final textColor = announcement.textColor != null
        ? _getTextColorFromAnnouncement(announcement.textColor!)
        : Colors.white;

    final iconColor = announcement.iconColor != null
        ? _getTextColorFromAnnouncement(announcement.iconColor!)
        : Colors.white;

    final icon = announcement.selectedIcon != null
        ? _getIconFromString(announcement.selectedIcon!)
        : Icons.campaign;

    final fontSize = announcement.fontSize ?? 14.0;
    final fontWeight = announcement.textStyle?.contains('bold') == true
        ? FontWeight.bold
        : FontWeight.w600;
    final fontStyle = announcement.textStyle?.contains('italic') == true
        ? FontStyle.italic
        : FontStyle.normal;

    final cardWidget = Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 200 * scale, // Fixed height for image cards
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              announcement.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  debugPrint(
                      '✅ Image loaded successfully for: ${announcement.title}');
                  return child;
                }
                debugPrint(
                    '⏳ Loading image progress for ${announcement.title}: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Image failed to load for ${announcement.title}');
                debugPrint('❌ Error: $error');
                debugPrint('❌ URL: ${announcement.imageUrl}');
                // Fallback to text card if image fails
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
                    ),
                  ),
                  padding: EdgeInsets.all(16.0 * scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          color: Colors.white, size: 40 * scale),
                      SizedBox(height: 8 * scale),
                      Text(
                        'Image not available',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12 * scale),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Dark overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Text overlay
            Positioned(
              bottom: 16 * scale,
              left: 16 * scale,
              right: 16 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: 20 * scale,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(
                            fontSize: (fontSize + 2) * scale,
                            fontWeight: FontWeight.bold,
                            fontStyle: fontStyle,
                            color: textColor,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (announcement.content.isNotEmpty) ...[
                    SizedBox(height: 8 * scale),
                    Text(
                      announcement.content,
                      style: TextStyle(
                        fontSize: fontSize * scale,
                        fontWeight: fontWeight,
                        fontStyle: fontStyle,
                        color: textColor.withOpacity(0.9),
                        height: 1.4,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ✅ NEW: Make card clickable if it has a link
    if (announcement.hasLink) {
      return InkWell(
        onTap: () => _launchAnnouncementUrl(announcement.linkUrl!),
        borderRadius: BorderRadius.circular(20),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// ✅ NEW: Handle URL launching for clickable announcements
  Future<void> _launchAnnouncementUrl(String url) async {
    try {
      debugPrint('🔗 Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external browser/app
        );
        debugPrint('✅ Successfully launched URL: $url');
      } else {
        debugPrint('❌ Cannot launch URL: $url');
        // You could show a snackbar or dialog here
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      // You could show an error message to the user here
    }
  }

  Widget _buildPersonalizedQuickAccess(
      BuildContext context, double scale, double spacing) {
    final quickActions = [
      {
        'id': 'smart_search',
        'label': 'Smart Search',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SmartSearchPage(),
              ),
            ),
      },
      // ✅ ADD: LPMI Collection for all users (including guests)
      {
        'id': 'lpmi_collection',
        'label': 'LPMI Collection',
        'color': const Color(0xFF2196F3), // Blue color for LPMI
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MainPage(initialFilter: 'LPMI'),
              ),
            ),
      },
      // ✅ ADD: Bible for Premium Users
      {
        'id': 'bible',
        'label': 'Bible',
        'color': Colors.brown,
        'isPremium': true, // Mark as premium feature
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BibleMainPage(),
              ),
            ),
      },
      if (currentUser != null)
        {
          'id': 'favorites',
          'label': 'My Favorites',
          'color': Colors.red,
          'onTap': () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              ),
        },
      {
        'id': 'settings',
        'label': 'Settings',
        'color': Colors.grey[700]!,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
      },
      {
        'id': 'donation',
        'label': 'Donation',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DonationPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Quick Access', Icons.flash_on, scale),
        SizedBox(height: 12 * scale),
        SizedBox(
          height: 120 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            separatorBuilder: (context, index) => SizedBox(width: 12 * scale),
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return _buildQuickActionCard(
                context,
                action: action,
                scale: scale,
                isPinned: pinnedFeatures.contains(action['id']),
                onPin: () => onFeaturePinToggle(action['id'] as String),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsGrid(
      BuildContext context, double scale, double spacing) {
    if (availableCollections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Song Collections', Icons.folder_special, scale),
        SizedBox(height: 12 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getGridCrossAxisCount(context),
            crossAxisSpacing: 12 * scale,
            mainAxisSpacing: 12 * scale,
            childAspectRatio: 1.0, // Changed from 1.2 to 1.0 for more height
          ),
          itemCount: availableCollections.length,
          itemBuilder: (context, index) {
            final collection = availableCollections[index];
            return _buildCollectionCard(context, collection, scale);
          },
        ),
      ],
    );
  }

  Widget _buildUserContentSection(
      BuildContext context, double scale, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Your Content', Icons.person, scale),
        SizedBox(height: 12 * scale),
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  ),
                ),
              ),
            if (favoriteSongs.isNotEmpty && recentSongs.isNotEmpty)
              SizedBox(width: 12 * scale),
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

  Widget _buildAdminSection(
      BuildContext context, double scale, double spacing) {
    final adminActions = [
      {
        'id': 'add_song',
        'label': 'Add Song',
        'color': Colors.green,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddEditSongPage()),
            ),
      },
      {
        'id': 'song_management',
        'label': 'Manage Songs',
        'color': Colors.purple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const SongManagementPage()),
            ),
      },
      {
        'id': 'collection_management',
        'label': 'Collections',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const CollectionManagementPage()),
            ),
      },
      {
        'id': 'reports',
        'label': 'Reports',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ReportsManagementPage()),
            ),
      },
      {
        'id': 'announcements',
        'label': 'Announcements',
        'color': Colors.indigo,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AnnouncementManagementPage()),
            ),
      },
      {
        'id': 'reports', // Content management uses reports for now
        'label': 'Content Mgmt',
        'color': Colors.brown,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ReportsManagementPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Admin Tools', Icons.admin_panel_settings, scale),
        SizedBox(height: 12 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // More items per row since they're simpler
            childAspectRatio:
                0.75, // Taller cards to accommodate larger icons and text
            crossAxisSpacing: 16 * scale,
            mainAxisSpacing: 16 * scale,
          ),
          itemCount: adminActions.length,
          itemBuilder: (context, index) {
            final action = adminActions[index];
            return _buildAdminActionCard(context, action, scale);
          },
        ),
      ],
    );
  }

  Widget _buildSuperAdminSection(
      BuildContext context, double scale, double spacing) {
    final superAdminActions = [
      {
        'id': 'user_management',
        'label': 'User Management',
        'color': Colors.deepPurple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const UserManagementPage()),
            ),
      },
      {
        'id': 'admin_management',
        'label': 'Admin Management',
        'color': Colors.red.shade900,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AdminManagementPage()),
            ),
      },
      {
        'id': 'debug',
        'label': 'Firebase Debug',
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const FirebaseDebugPage()),
            ),
      },
      {
        'id': 'sync_debug',
        'label': 'Sync Debug',
        'color': Colors.orange.shade700,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SyncDebugPage()),
            ),
      },
      {
        'id': 'system_analytics',
        'label': 'System Analytics',
        'color': Colors.amber.shade800,
        'onTap': () {
          // Navigate to analytics page when available
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analytics page coming soon!')),
          );
        },
      },
      {
        'id': 'sync_debug', // Asset sync uses sync_debug GIF
        'label': 'Asset Sync',
        'color': Colors.indigo.shade700,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const AssetSyncUtilityPage()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Super Admin', Icons.security, scale),
        SizedBox(height: 12 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                3, // Fewer items per row for super admin to give more prominence
            childAspectRatio:
                0.8, // Taller cards to accommodate larger icons and text
            crossAxisSpacing: 20 * scale,
            mainAxisSpacing: 20 * scale,
          ),
          itemCount: superAdminActions.length,
          itemBuilder: (context, index) {
            final action = superAdminActions[index];
            return _buildSuperAdminActionCard(context, action, scale);
          },
        ),
      ],
    );
  }

  // Recent Songs Section
  Widget _buildRecentSongsSection(
      BuildContext context, double scale, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Recently Added Songs', Icons.new_releases, scale),
        SizedBox(height: 12 * scale),
        FutureBuilder<List<Song>>(
          future: SongRepository().getRecentlyAddedSongs(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 100 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Error loading recent songs'),
                  subtitle: Text('${snapshot.error}'),
                ),
              );
            }

            final recentSongs = snapshot.data ?? [];

            if (recentSongs.isEmpty) {
              return Card(
                child: ListTile(
                  leading: Icon(Icons.music_note, color: Colors.grey),
                  title: Text('No recent songs'),
                  subtitle: Text('New songs will appear here when added'),
                ),
              );
            }

            return Column(
              children: recentSongs.map((song) {
                return Card(
                  margin: EdgeInsets.only(bottom: 8 * scale),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Text(
                        song.number,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12 * scale,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * scale,
                      ),
                    ),
                    subtitle: Text(
                      'Recently added • ${song.verses.length} verse${song.verses.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12 * scale),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16 * scale,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // Navigate to main page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MainPage(),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Footer section with app info and logout
  Widget _buildFooterSection(
      BuildContext context, double scale, double spacing) {
    return Column(
      children: [
        const Divider(),
        SizedBox(height: 8 * scale),
        Container(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            children: [
              // App name and version
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    color: Theme.of(context).primaryColor,
                    size: 20 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    'LPMI40',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4 * scale),
              Text(
                'Lagu Pujian Masa Ini',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                'Version 4.0.0',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                ),
              ),

              // Logout button for logged in users
              if (currentUser != null) ...[
                SizedBox(height: 16 * scale),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        // Clear collections and logout
                        CollectionService.invalidateCache();
                        CollectionNotifierService().clear();
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                    icon: Icon(Icons.logout, size: 16 * scale),
                    label: Text(
                      'Logout',
                      style: TextStyle(fontSize: 14 * scale),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 16 * scale),

              // Copyright notice
              Text(
                '© 2024 LPMI40. All rights reserved.',
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, double scale) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20 * scale),
        SizedBox(width: 8 * scale),
        Text(
          title,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required Map<String, dynamic> action,
    required double scale,
    required bool isPinned,
    required VoidCallback onPin,
  }) {
    return SizedBox(
      width: 100 * scale,
      child: Card(
        elevation: isPinned ? 4 : 2,
        child: InkWell(
          onTap: action['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12.0 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clean icon without background box
                    Icon(
                      _getDashboardFunctionIcon(action['id'] as String),
                      color: action['color'] as Color,
                      size: 32 * scale,
                    ),
                    SizedBox(height: 8 * scale),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onPin,
                  child: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 16 * scale,
                    color: isPinned ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
      BuildContext context, SongCollection collection, double scale) {
    final collectionColor = _getCollectionColor(collection.id);
    final collectionIcon = _getCollectionIcon(collection.id);

    return Card(
      elevation: 4,
      shadowColor: collectionColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToMainPage(context, collection.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                collectionColor.withOpacity(0.7),
                collectionColor.withOpacity(0.9),
              ],
            ),
            // Optional: Add background pattern/image
            image: _getCollectionBackgroundImage(collection.id),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            padding: EdgeInsets.all(12.0 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        collectionIcon,
                        color: collectionColor,
                        size: 20 * scale,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 3 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${collection.songCount}',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                          color: collectionColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * scale),
                Text(
                  collection.name,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'songs',
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    double scale, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          padding: EdgeInsets.all(20.0 * scale),
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
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Admin action card with simplified icon + text layout (no boxes)
  Widget _buildAdminActionCard(
      BuildContext context, Map<String, dynamic> action, double scale) {
    final color = action['color'] as Color;

    return InkWell(
      onTap: action['onTap'] as VoidCallback,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 6 * scale,
            horizontal: 4 * scale), // Reduced vertical padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fixed height container for consistent icon alignment
            SizedBox(
              height: 36 * scale, // Fixed height for icon area
              child: Center(
                child: Icon(
                  _getDashboardFunctionIcon(action['id'] as String),
                  color: color,
                  size: 32 * scale, // Slightly smaller icon to fit better
                ),
              ),
            ),
            SizedBox(height: 6 * scale), // Consistent spacing
            // Fixed height container for text alignment
            Expanded(
              child: Center(
                child: Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 12 * scale, // Slightly smaller font to fit better
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black87,
                    height: 1.2, // Consistent line height
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Super admin action card with simplified icon + text layout (no boxes)
  Widget _buildSuperAdminActionCard(
      BuildContext context, Map<String, dynamic> action, double scale) {
    final color = action['color'] as Color;

    return InkWell(
      onTap: action['onTap'] as VoidCallback,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 6 * scale,
            horizontal: 4 * scale), // Reduced vertical padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fixed height container for consistent icon alignment
            SizedBox(
              height: 42 *
                  scale, // Fixed height for icon area (slightly larger for super admin)
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    _getDashboardFunctionIcon(action['id'] as String),
                    color: color,
                    size: 36 *
                        scale, // Slightly smaller icon for super admin to fit better
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * scale), // Consistent spacing
            // Fixed height container for text alignment
            Expanded(
              child: Center(
                child: Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 13 *
                        scale, // Slightly smaller font for super admin to fit better
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.95)
                        : Colors.black87,
                    height: 1.2, // Consistent line height
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
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

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return const Color(0xFF1976D2); // Deep Blue
      case 'SRD':
        return const Color(0xFF7B1FA2); // Deep Purple
      case 'Lagu_belia':
        return const Color(0xFF388E3C); // Deep Green
      case 'PPL':
        return const Color(0xFFD32F2F); // Deep Red
      case 'Advent':
        return const Color(0xFFFF9800); // Deep Orange
      case 'Natal':
        return const Color(0xFF5D4037); // Brown
      case 'Paskah':
        return const Color(0xFFE91E63); // Pink
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.church;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      case 'lagu_krismas_26346':
        return Icons.celebration;
      case 'PPL':
        return Icons.favorite;
      case 'Advent':
        return Icons.star;
      case 'Natal':
        return Icons.celebration;
      case 'Paskah':
        return Icons.brightness_5;
      default:
        return Icons.library_music;
    }
  }

  DecorationImage? _getCollectionBackgroundImage(String collectionId) {
    // Add subtle background patterns for different collections
    switch (collectionId) {
      case 'LPMI':
        return const DecorationImage(
          image: AssetImage('assets/images/header_image.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        );
      case 'SRD':
        return const DecorationImage(
          image: AssetImage('assets/images/header_image.png'),
          fit: BoxFit.cover,
          opacity: 0.08,
        );
      default:
        return null; // No background image for other collections
    }
  }

  // Utility methods for announcement customization
  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'campaign':
        return Icons.campaign;
      case 'info':
        return Icons.info;
      case 'notification_important':
        return Icons.notification_important;
      case 'star':
        return Icons.star;
      case 'celebration':
        return Icons.celebration;
      case 'new_releases':
        return Icons.new_releases;
      case 'event':
        return Icons.event;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.campaign;
    }
  }

  // ✅ NEW: Helper methods for announcement styling using AnnouncementTheme
  Color _getTextColorFromAnnouncement(String colorName) {
    try {
      return AnnouncementTheme.getTextColor(colorName);
    } catch (e) {
      return Colors.white; // Fallback
    }
  }

  Color _getBackgroundColorFromAnnouncement(String colorName) {
    try {
      return AnnouncementTheme.getBackgroundColor(colorName);
    } catch (e) {
      return const Color(0xFF388E3C); // Fallback
    }
  }

  List<Color> _getGradientColorsFromAnnouncement(String gradientName) {
    try {
      return AnnouncementTheme.getGradientColors(gradientName);
    } catch (e) {
      return [const Color(0xFF388E3C), const Color(0xFF2E7D32)]; // Fallback
    }
  }

  // Helper method to get dashboard function icons
  IconData _getDashboardFunctionIcon(String functionId) {
    switch (functionId) {
      case 'smart_search':
        return Icons.search;
      case 'favorites':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'donation':
        return Icons.volunteer_activism;
      case 'add_song':
        return Icons.add_circle;
      case 'song_management':
        return Icons.music_note;
      case 'collection_management':
        return Icons.collections_bookmark;
      case 'reports':
        return Icons.report;
      case 'announcements':
        return Icons.campaign;
      case 'user_management':
        return Icons.people;
      case 'admin_management':
        return Icons.admin_panel_settings;
      case 'debug':
        return Icons.bug_report;
      case 'sync_debug':
        return Icons.sync;
      case 'system_analytics':
        return Icons.analytics;
      default:
        return Icons.widgets;
    }
  }
}

// Auto-scrolling carousel widget for announcements
class _AnnouncementCarouselWidget extends StatefulWidget {
  final List<Widget> contentItems;
  final double scale;

  const _AnnouncementCarouselWidget({
    required this.contentItems,
    required this.scale,
  });

  @override
  State<_AnnouncementCarouselWidget> createState() =>
      _AnnouncementCarouselWidgetState();
}

class _AnnouncementCarouselWidgetState
    extends State<_AnnouncementCarouselWidget> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.contentItems.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % widget.contentItems.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.contentItems.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0 * widget.scale),
              child: widget.contentItems[index],
            ),
          ),
        ),
        if (widget.contentItems.length > 1) ...[
          SizedBox(height: 8 * widget.scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.contentItems.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 2 * widget.scale),
                width: 6 * widget.scale,
                height: 6 * widget.scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentIndex
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
