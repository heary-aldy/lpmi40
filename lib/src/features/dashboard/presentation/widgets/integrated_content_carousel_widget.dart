// lib/src/features/dashboard/presentation/widgets/integrated_content_carousel_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    debugPrint('🎬 IntegratedContentCarouselWidget: initState called');
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
    debugPrint('🚀 IntegratedContentCarouselWidget: Starting to load content...');
    setState(() {
      _isLoading = true;
    });

    try {
      final contentItems = <ContentItem>[];

      // Add verse of the day if available
      if (widget.verseOfTheDaySong != null &&
          widget.verseOfTheDayVerse != null) {
        debugPrint('📖 Adding verse of the day: ${widget.verseOfTheDaySong!.title}');
        contentItems.add(ContentItem.verse(
          song: widget.verseOfTheDaySong!,
          verse: widget.verseOfTheDayVerse!,
        ));
      } else {
        debugPrint('📖 No verse of the day available');
      }

      // Add active announcements
      debugPrint('🎯 About to fetch active announcements...');
      final announcements = await _announcementService.getActiveAnnouncements();
      debugPrint(
          '🎯 Found ${announcements.length} active announcements for carousel');
      for (final announcement in announcements) {
        debugPrint(
            '🎯 Adding announcement: ${announcement.title}, Type: ${announcement.type}, IsImage: ${announcement.isImage}');
        debugPrint('🎯 Announcement ID: ${announcement.id}');
        debugPrint('🎯 IsActive: ${announcement.isActive}');
        debugPrint('🎯 IsValid: ${announcement.isValid}');
        if (announcement.isImage) {
          debugPrint('🖼️ Image URL: "${announcement.imageUrl}"');
          debugPrint('🖼️ Image URL length: ${announcement.imageUrl.length}');
          debugPrint('🖼️ Image URL isEmpty: ${announcement.imageUrl.isEmpty}');
          debugPrint('🖼️ Image URL contains "http": ${announcement.imageUrl.contains("http")}');
        }
        contentItems.add(ContentItem.announcement(announcement));
      }

      if (mounted) {
        debugPrint('🎯 Setting content items: ${contentItems.length} total');
        setState(() {
          _contentItems = contentItems;
          _isLoading = false;
        });

        if (_contentItems.isNotEmpty) {
          debugPrint('✅ Starting auto scroll and fade animation');
          _startAutoScroll();
          _fadeController.forward();
        } else {
          debugPrint('⚠️ No content items to display');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading content: $e');
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

  /// Convert gs:// URL to download URL
  Future<String> _getDownloadUrl(String imageUrl) async {
    if (imageUrl.startsWith('gs://')) {
      try {
        debugPrint('🔄 Converting gs:// URL to download URL: $imageUrl');
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ Converted to download URL: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        debugPrint('❌ Failed to convert gs:// URL: $e');
        return imageUrl; // Return original URL as fallback
      }
    }
    return imageUrl; // Already a download URL
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
            height: 160,
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
          SizedBox(
            height: 160,
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
              bottom: 8,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),
        ],
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    if (item.isVerse) {
      debugPrint('🎯 Building verse card');
      return Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: _buildVerseCard(item),
      );
    } else {
      final announcement = item.announcement!;
      debugPrint('🎯 Building announcement card: ${announcement.title}');
      debugPrint('🎯 Announcement type: ${announcement.type}');
      debugPrint('🎯 Is image: ${announcement.isImage}');
      debugPrint('🎯 Image URL: "${announcement.imageUrl}"');
      
      if (announcement.isImage) {
        debugPrint('🖼️ Calling _buildImageAnnouncementCard');
      } else {
        debugPrint('📝 Calling _buildTextAnnouncementCard');
      }

      return Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: announcement.isImage
            ? _buildImageAnnouncementCard(announcement)
            : _buildTextAnnouncementCard(announcement),
      );
    }
  }

  Widget _buildVerseCard(ContentItem item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SongLyricsPage(songNumber: item.song!.number),
      )),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(14.0),
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
            // Header row
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Verse of the Day",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Verse content
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
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
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Apply custom styling to text announcements
  Widget _buildTextAnnouncementCard(Announcement announcement) {
    final theme = Theme.of(context);

    // ✅ NEW: Get custom styling or use defaults
    final textColor = _getTextColor(announcement.textColor, theme);
    final backgroundColor = _getBackgroundColor(announcement);
    final iconColor = _getIconColor(announcement.iconColor);
    final selectedIcon = _getIcon(announcement.selectedIcon);
    final fontSize = announcement.fontSize ?? 14.0;
    final fontWeight = announcement.fontWeight;
    final fontStyle = announcement.fontStyle;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        // ✅ NEW: Apply custom background
        color: backgroundColor,
        gradient: backgroundColor == null
            ? _getBackgroundGradient(announcement)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with custom icon and styling
          Row(
            children: [
              Icon(
                selectedIcon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: fontSize + 1, // Title slightly larger
                    fontWeight: fontWeight == FontWeight.normal
                        ? FontWeight.bold
                        : FontWeight.w900, // Make title bolder
                    fontStyle: fontStyle,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Content with custom styling
          Expanded(
            child: Text(
              announcement.content,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Show expiration info if expires soon
          if (announcement.expiresSoon) ...[
            const SizedBox(height: 6),
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
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ✅ UPDATED: Apply custom styling to image announcements
  Widget _buildImageAnnouncementCard(Announcement announcement) {
    debugPrint(
        '🖼️ Building image announcement card for: ${announcement.title}');
    debugPrint('🖼️ Image URL: ${announcement.imageUrl}');
    debugPrint('🖼️ Image URL isEmpty: ${announcement.imageUrl.isEmpty}');

    // ✅ FIX: Check if imageUrl is empty or invalid before trying to load
    if (announcement.imageUrl.isEmpty) {
      debugPrint('❌ Image URL is empty, falling back to text card');
      return _buildTextAnnouncementCard(announcement);
    }

    final theme = Theme.of(context);

    // ✅ NEW: Get custom styling or use defaults
    final textColor = _getTextColor(announcement.textColor, theme);
    final iconColor = _getIconColor(announcement.iconColor);
    final selectedIcon = _getIcon(announcement.selectedIcon);
    final fontSize = announcement.fontSize ?? 14.0;
    final fontWeight = announcement.fontWeight;
    final fontStyle = announcement.fontStyle;

    return SizedBox(
      height: 160,
      child: FutureBuilder<String>(
        future: _getDownloadUrl(announcement.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading while converting URL
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint('❌ Failed to get download URL: ${snapshot.error}');
            return _buildTextAnnouncementCard(announcement);
          }

          final downloadUrl = snapshot.data!;
          debugPrint('🖼️ Using download URL: $downloadUrl');
          debugPrint('🖼️ About to create Image.network widget');

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  downloadUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      debugPrint('✅ Image loaded successfully for: ${announcement.title}');
                      return child;
                    }
                    debugPrint('⏳ Loading image progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
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
                    debugPrint('❌ Failed to load image from URL: "$downloadUrl"');
                    debugPrint('❌ Error details: $error');
                    debugPrint('❌ Error type: ${error.runtimeType}');
                    if (stackTrace != null) {
                      debugPrint('❌ Stack trace: $stackTrace');
                    }
                    debugPrint('❌ Falling back to text card for announcement: ${announcement.title}');
                    return _buildTextAnnouncementCard(announcement);
                  },
                ),
              ),

              // ✅ NEW: Custom overlay gradient or solid overlay
              Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _getOverlayGradient(announcement),
            ),
          ),

          // Text overlay with custom styling
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ NEW: Title with custom icon and styling
                Row(
                  children: [
                    if (announcement.selectedIcon != null) ...[
                      Icon(
                        selectedIcon,
                        color: iconColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize + 1, // Title slightly larger
                          fontWeight: fontWeight == FontWeight.normal
                              ? FontWeight.bold
                              : FontWeight.w900, // Make title bolder
                          fontStyle: fontStyle,
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
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: fontSize - 1, // Content slightly smaller
                      fontWeight: fontWeight,
                      fontStyle: fontStyle,
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
          );
        },
      ),
    );
  }

  // ✅ NEW: Helper methods for custom styling
  Color _getTextColor(String? textColor, ThemeData theme) {
    if (textColor != null) {
      return AnnouncementTheme.getTextColor(textColor);
    }
    return theme.colorScheme.onSurface;
  }

  Color? _getBackgroundColor(Announcement announcement) {
    if (announcement.backgroundColor != null) {
      return AnnouncementTheme.getBackgroundColor(announcement.backgroundColor);
    }
    return null;
  }

  LinearGradient _getBackgroundGradient(Announcement announcement) {
    if (announcement.backgroundGradient != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AnnouncementTheme.getGradientColors(
            announcement.backgroundGradient),
      );
    }
    // Default gradient for announcements
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.indigo.withOpacity(0.05),
        Colors.indigo.withOpacity(0.02),
      ],
    );
  }

  Color _getIconColor(String? iconColor) {
    if (iconColor != null) {
      return AnnouncementTheme.getIconColor(iconColor);
    }
    return Colors.indigo;
  }

  IconData _getIcon(String? iconName) {
    if (iconName != null) {
      return AnnouncementTheme.getIcon(iconName);
    }
    return Icons.campaign;
  }

  LinearGradient _getOverlayGradient(Announcement announcement) {
    // For image announcements, we need a good overlay for text readability
    // If custom background is set, use a lighter overlay
    if (announcement.backgroundColor != null ||
        announcement.backgroundGradient != null) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.4),
        ],
      );
    }
    // Default stronger overlay
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.7),
      ],
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
          // ✅ NEW: Use custom indicator color for styled announcements
          final announcement = item.announcement!;
          if (announcement.selectedIcon != null ||
              announcement.textColor != null ||
              announcement.backgroundColor != null ||
              announcement.backgroundGradient != null) {
            indicatorColor = _currentIndex == index
                ? Colors.purple
                : Colors.purple.withOpacity(0.3);
          } else {
            indicatorColor = _currentIndex == index
                ? Colors.indigo
                : Colors.indigo.withOpacity(0.3);
          }
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
