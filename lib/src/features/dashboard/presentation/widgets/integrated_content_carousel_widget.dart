// TODO Implement this library.
// lib/src/features/dashboard/presentation/widgets/integrated_content_carousel_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/core/services/announcement_service.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_contentItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daily Inspiration",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCarousel(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daily Inspiration",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 140,
              maxHeight: 200,
            ),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading inspiration...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return GestureDetector(
      onPanStart: (_) => _stopAutoScroll(),
      onPanEnd: (_) => _startAutoScroll(),
      child: Stack(
        children: [
          // ✅ UPDATED: Dynamic height based on content
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 140,
              maxHeight: 200, // Allow more space for longer text
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _contentItems.length,
              itemBuilder: (context, index) {
                final item = _contentItems[index];
                return _buildContentCard(item);
              },
            ),
          ),

          // Page indicators
          if (widget.showIndicators && _contentItems.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),
        ],
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: item.isVerse
          ? _buildVerseCard(item)
          : item.announcement!.isImage
              ? _buildImageAnnouncementCard(item.announcement!)
              : _buildTextAnnouncementCard(item.announcement!),
    );
  }

  Widget _buildVerseCard(ContentItem item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SongLyricsPage(songNumber: item.song!.number),
      )),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
          mainAxisSize: MainAxisSize.min, // ✅ Allow flexible height
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Verse of the Day",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ UPDATED: More flexible text display
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5, // Better line spacing
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
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // ✅ UPDATED: Allow more lines, but still reasonable limit
              maxLines: 8, // Increased from 4 to 8
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8), // Bottom padding for indicators
          ],
        ),
      ),
    );
  }

  Widget _buildTextAnnouncementCard(Announcement announcement) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
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
        mainAxisSize: MainAxisSize.min, // ✅ Allow flexible height
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign,
                color: Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  maxLines: 2, // Allow title to wrap
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ UPDATED: More flexible text display
          Text(
            announcement.content,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.5, // Better line spacing
            ),
            maxLines: 6, // Increased from 4 to 6
            overflow: TextOverflow.ellipsis,
          ),
          // Show expiration info if expires soon
          if (announcement.expiresSoon) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${announcement.formattedExpirationDate}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8), // Bottom padding for indicators
        ],
      ),
    );
  }

  Widget _buildImageAnnouncementCard(Announcement announcement) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(
        minHeight: 140,
        maxHeight: 200,
      ),
      child: Stack(
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
                return _buildTextAnnouncementCard(announcement);
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
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  maxLines: 2, // Allow title to wrap
                  overflow: TextOverflow.ellipsis,
                ),
                if (announcement.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    maxLines: 3, // Allow more content lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
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
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentIndex == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4),
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
