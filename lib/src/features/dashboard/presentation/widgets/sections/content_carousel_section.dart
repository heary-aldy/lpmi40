// lib/src/features/dashboard/presentation/widgets/sections/content_carousel_section.dart
// Content carousel section with announcements and verse of the day

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/announcement_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';
import 'package:lpmi40/utils/constants.dart';

class ContentCarouselSection extends StatelessWidget {
  final Song? verseOfTheDaySong;
  final Verse? verseOfTheDayVerse;
  final double scale;
  final double spacing;

  const ContentCarouselSection({
    super.key,
    required this.verseOfTheDaySong,
    required this.verseOfTheDayVerse,
    required this.scale,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context, 'Daily Content', Icons.auto_stories, scale),
        SizedBox(height: 12 * scale),
        Container(
          height: 180 * scale,
          child: _buildAnnouncementCarousel(context, scale),
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

  Widget _buildAnnouncementCarousel(BuildContext context, double scale) {
    return FutureBuilder<List<Announcement>>(
      future: AnnouncementService().getActiveAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCarouselSkeleton(context, scale);
        }

        final List<Widget> contentItems = [];

        // Add Verse of the Day if available
        if (verseOfTheDaySong != null && verseOfTheDayVerse != null) {
          contentItems.add(_buildVerseOfTheDayCard(context, scale));
        }

        // Add announcements from Firebase
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (final announcement in snapshot.data!) {
            contentItems
                .add(_buildAnnouncementCard(context, scale, announcement));
          }
        } else {
          contentItems.add(_buildWelcomeCard(context, scale));
        }

        if (contentItems.isEmpty) {
          return _buildEmptyCarousel(context, scale);
        }

        return AnnouncementCarouselWidget(
          contentItems: contentItems,
          scale: scale,
        );
      },
    );
  }

  Widget _buildCarouselSkeleton(BuildContext context, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120 * scale,
                height: 16 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 12 * scale),
              Container(
                width: double.infinity,
                height: 14 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8 * scale),
              Container(
                width: 200 * scale,
                height: 14 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCarousel(BuildContext context, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0 * scale),
      child: Card(
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(20.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey[400],
                size: 48 * scale,
              ),
              SizedBox(height: 16 * scale),
              Text(
                'No content available',
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context, double scale) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
            ],
          ),
        ),
        padding: EdgeInsets.all(16.0 * scale),
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
            SizedBox(height: 12 * scale),
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
            SizedBox(height: 8 * scale),
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B1FA2),
              Color(0xFF6A1B9A),
            ],
          ),
        ),
        padding: EdgeInsets.all(16.0 * scale),
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
            SizedBox(height: 12 * scale),
            Text(
              'LPMI40 Digital Songbook',
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8 * scale),
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
    final icon = announcement?.selectedIcon != null
        ? _getIconFromString(announcement!.selectedIcon!)
        : Icons.campaign;

    Color primaryColor = const Color(0xFF388E3C);
    Color secondaryColor = const Color(0xFF2E7D32);

    if (announcement?.backgroundColor != null) {
      primaryColor =
          _getColorFromString(announcement!.backgroundColor!) ?? primaryColor;
      secondaryColor = primaryColor.withOpacity(0.8);
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20 * scale,
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              content,
              style: TextStyle(
                fontSize: 11 * scale,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

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

  Color? _getColorFromString(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Auto-scrolling carousel widget for announcements
class AnnouncementCarouselWidget extends StatefulWidget {
  final List<Widget> contentItems;
  final double scale;

  const AnnouncementCarouselWidget({
    super.key,
    required this.contentItems,
    required this.scale,
  });

  @override
  State<AnnouncementCarouselWidget> createState() =>
      _AnnouncementCarouselWidgetState();
}

class _AnnouncementCarouselWidgetState
    extends State<AnnouncementCarouselWidget> {
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
          SizedBox(height: 12 * widget.scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.contentItems.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3 * widget.scale),
                width: 8 * widget.scale,
                height: 8 * widget.scale,
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
