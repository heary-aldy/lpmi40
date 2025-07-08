// lib/src/features/dashboard/presentation/widgets/integrated_content_carousel_widget.dart
// ✅ ENHANCED: Made fully responsive with dynamic heights

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/core/services/announcement_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';

// ✅ NEW: Import responsive utilities
import 'package:lpmi40/utils/constants.dart';

class IntegratedContentCarouselWidget extends StatefulWidget {
  final Song? verseOfTheDaySong;
  final Verse? verseOfTheDayVerse;
  final Duration autoScrollDuration;
  final bool showIndicators;
  final bool autoScroll;

  const IntegratedContentCarouselWidget({
    super.key,
    required this.verseOfTheDaySong,
    required this.verseOfTheDayVerse,
    this.autoScrollDuration = const Duration(seconds: 4),
    this.showIndicators = true,
    this.autoScroll = true,
  });

  @override
  State<IntegratedContentCarouselWidget> createState() =>
      _IntegratedContentCarouselWidgetState();
}

class _IntegratedContentCarouselWidgetState
    extends State<IntegratedContentCarouselWidget>
    with TickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  final PageController _pageController = PageController();

  List<ContentItem> _contentItems = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadContent();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contentItems = <ContentItem>[];

      // Add verse of the day if available
      if (widget.verseOfTheDaySong != null &&
          widget.verseOfTheDayVerse != null) {
        contentItems.add(ContentItem.verse(
          song: widget.verseOfTheDaySong!,
          verse: widget.verseOfTheDayVerse!,
        ));
      }

      // Add active announcements
      final announcements = await _announcementService.getActiveAnnouncements();
      for (final announcement in announcements) {
        contentItems.add(ContentItem.announcement(announcement));
      }

      if (mounted) {
        setState(() {
          _contentItems = contentItems;
          _isLoading = false;
        });

        if (_contentItems.isNotEmpty) {
          _startAutoScroll();
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    if (!widget.autoScroll || _contentItems.length <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (mounted && _pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % _contentItems.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ✅ NEW: Get responsive dimensions
  Map<String, double> _getResponsiveDimensions() {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // Calculate responsive heights based on available space
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight * 0.4; // Use up to 40% of screen height

    final cardHeight = switch (deviceType) {
      DeviceType.mobile => availableHeight.clamp(180.0, 220.0),
      DeviceType.tablet => availableHeight.clamp(350.0, 420.0),
      DeviceType.desktop => availableHeight.clamp(400.0, 480.0),
      DeviceType.largeDesktop => availableHeight.clamp(450.0, 520.0),
    };

    return {
      'cardHeight': cardHeight,
      'headerHeight': 40.0 * scale,
      'spacing': spacing,
      'scale': scale,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions();
    final totalHeight = dimensions['cardHeight']! +
        dimensions['headerHeight']! +
        dimensions['spacing']!;

    if (_isLoading) {
      return _buildLoadingState(dimensions);
    }

    if (_contentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ RESPONSIVE: Use calculated height instead of hardcoded
    return SizedBox(
      height: totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: dimensions['headerHeight'],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daily Inspiration",
                style: TextStyle(
                  fontSize: 18 * dimensions['scale']!,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: dimensions['spacing']! * 0.5),
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCarousel(dimensions),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED: Responsive loading state
  Widget _buildLoadingState(Map<String, double> dimensions) {
    final totalHeight = dimensions['cardHeight']! +
        dimensions['headerHeight']! +
        dimensions['spacing']!;

    return SizedBox(
      height: totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: dimensions['headerHeight'],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daily Inspiration",
                style: TextStyle(
                  fontSize: 18 * dimensions['scale']!,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: dimensions['spacing']! * 0.5),
          Expanded(
            child: Card(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16 * dimensions['scale']!),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16 * dimensions['scale']!,
                        height: 16 * dimensions['scale']!,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * dimensions['scale']!),
                      Text(
                        'Loading inspiration...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14 * dimensions['scale']!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED: Responsive carousel
  Widget _buildCarousel(Map<String, double> dimensions) {
    return GestureDetector(
      onPanStart: (_) => _stopAutoScroll(),
      onPanEnd: (_) => _startAutoScroll(),
      child: Stack(
        children: [
          // ✅ RESPONSIVE: Expand to fill available space instead of fixed height
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _contentItems.length,
              itemBuilder: (context, index) {
                final item = _contentItems[index];
                return _buildContentCard(item, dimensions);
              },
            ),
          ),

          // Page indicators
          if (widget.showIndicators && _contentItems.length > 1)
            Positioned(
              bottom: 12 * dimensions['scale']!,
              left: 0,
              right: 0,
              child: _buildPageIndicators(dimensions),
            ),
        ],
      ),
    );
  }

  // ✅ ENHANCED: Responsive content card
  Widget _buildContentCard(ContentItem item, Map<String, double> dimensions) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: item.isVerse
          ? _buildVerseCard(item, dimensions)
          : item.announcement!.isImage
              ? _buildImageAnnouncementCard(item.announcement!, dimensions)
              : _buildTextAnnouncementCard(item.announcement!, dimensions),
    );
  }

  // ✅ ENHANCED: Responsive verse card
  Widget _buildVerseCard(ContentItem item, Map<String, double> dimensions) {
    final theme = Theme.of(context);
    final scale = dimensions['scale']!;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SongLyricsPage(songNumber: item.song!.number),
      )),
      child: Container(
        padding: EdgeInsets.all(16.0 * scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              theme.primaryColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.primaryColor,
                  size: 20 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  "Verse of the Day",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 15 * scale,
                    height: 1.4,
                    color: theme.colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '"${item.verse!.lyrics}"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(
                      text: '\n\n— ${item.song!.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 13 * scale,
                      ),
                    ),
                  ],
                ),
                maxLines:
                    null, // ✅ RESPONSIVE: Allow more lines on larger screens
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ENHANCED: Responsive text announcement card
  Widget _buildTextAnnouncementCard(
      Announcement announcement, Map<String, double> dimensions) {
    final theme = Theme.of(context);
    final scale = dimensions['scale']!;

    return Container(
      padding: EdgeInsets.all(16.0 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.05),
            Colors.indigo.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign,
                color: Colors.indigo,
                size: 20 * scale,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Expanded(
            child: Text(
              announcement.content,
              style: TextStyle(
                fontSize: 14 * scale,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
              maxLines:
                  null, // ✅ RESPONSIVE: Allow more content on larger screens
              overflow: TextOverflow.fade,
            ),
          ),
          // Show expiration info if expires soon
          if (announcement.expiresSoon) ...[
            SizedBox(height: 8 * scale),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12 * scale,
                  color: Colors.orange[700],
                ),
                SizedBox(width: 4 * scale),
                Text(
                  'Expires: ${announcement.formattedExpirationDate}',
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ✅ ENHANCED: Responsive image announcement card
  Widget _buildImageAnnouncementCard(
      Announcement announcement, Map<String, double> dimensions) {
    final scale = dimensions['scale']!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            announcement.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
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
              return _buildTextAnnouncementCard(announcement, dimensions);
            },
          ),
        ),

        // Overlay gradient for text readability
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
          bottom: 12 * scale,
          left: 16 * scale,
          right: 16 * scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                announcement.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (announcement.content.isNotEmpty) ...[
                SizedBox(height: 4 * scale),
                Text(
                  announcement.content,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13 * scale,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ✅ ENHANCED: Responsive page indicators
  Widget _buildPageIndicators(Map<String, double> dimensions) {
    final scale = dimensions['scale']!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_contentItems.length, (index) {
        final item = _contentItems[index];
        Color indicatorColor;

        if (item.isVerse) {
          indicatorColor = _currentIndex == index
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.3);
        } else {
          indicatorColor = _currentIndex == index
              ? Colors.indigo
              : Colors.indigo.withOpacity(0.3);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3 * scale),
          width: (_currentIndex == index ? 12 : 8) * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4 * scale),
          ),
        );
      }),
    );
  }
}

// Helper class to represent different types of content
class ContentItem {
  final Song? song;
  final Verse? verse;
  final Announcement? announcement;

  ContentItem.verse({
    required this.song,
    required this.verse,
  }) : announcement = null;

  ContentItem.announcement(this.announcement)
      : song = null,
        verse = null;

  bool get isVerse => song != null && verse != null;
  bool get isAnnouncement => announcement != null;
}
