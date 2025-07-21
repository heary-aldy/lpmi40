// lib/src/features/songbook/presentation/widgets/song_list_item.dart
// ✅ ENHANCED: Updated SongListItem compatible with floating audio player
// ✅ FEATURES: Consistent audio controls, responsive design, premium integration
// ✅ COMPATIBILITY: Works seamlessly with enhanced SongProvider
// ✅ NEW: Added offline download support for premium users
// ✅ FIX: Removed redundant horizontal margins to work with SongListContainer

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/utils/constants.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool canPlay;
  final bool canAccessAudio; // ✅ NEW: Permission check for audio features
  final VoidCallback onTap;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onDownloadPressed; // ✅ NEW: Download callback

  const SongListItem({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.canPlay,
    this.canAccessAudio = false, // ✅ NEW: Default to false for regular users
    required this.onTap,
    this.onPlayPressed,
    this.onFavoritePressed,
    this.onDownloadPressed, // ✅ NEW: Download callback
    required bool showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // Check if song has audio and is favorite - also check permissions
    final hasAudio = song.audioUrl != null && song.audioUrl!.isNotEmpty;
    final canShowAudioFeatures =
        hasAudio && canAccessAudio; // ✅ NEW: Permission check
    final isFavorite = song.isFavorite;

    return Card(
      elevation: isPlaying ? 4 : 1,
      // ✅ FIX: Remove horizontal margin completely - SongListContainer now handles optimal spacing
      margin: EdgeInsets.symmetric(
        horizontal: 0.0, // No horizontal margin
        vertical: spacing * 0.4, // ✅ REDUCED: Slightly smaller vertical spacing
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background action buttons (revealed on swipe) - only for authorized users
            if (canShowAudioFeatures)
              _buildActionBackground(context, theme, spacing, scale),

            // Main content (swipeable)
            _buildSwipeableContent(context, theme, spacing, scale,
                canShowAudioFeatures, isFavorite),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBackground(
      BuildContext context, ThemeData theme, double spacing, double scale) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Download action
            Container(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        onDownloadPressed, // ✅ FIXED: Use callback instead of placeholder
                    icon: Icon(
                      Icons.download,
                      size: 32 * scale,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Download',
                    style: TextStyle(
                      fontSize: 10 * scale,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Play action (if available)
            if (canPlay && onPlayPressed != null)
              Container(
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onPlayPressed,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 32 * scale,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      isPlaying ? 'Pause' : 'Play',
                      style: TextStyle(
                        fontSize: 10 * scale,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeableContent(
      BuildContext context,
      ThemeData theme,
      double spacing,
      double scale,
      bool canShowAudioFeatures,
      bool isFavorite) {
    return Dismissible(
      key: Key('song_${song.number}_swipe'),
      direction: canShowAudioFeatures
          ? DismissDirection.endToStart
          : DismissDirection.none,
      dismissThresholds: const {DismissDirection.endToStart: 0.3},
      confirmDismiss: (direction) async {
        // Don't actually dismiss, just show the actions temporarily
        await Future.delayed(const Duration(milliseconds: 1500));
        return false; // Always return false to prevent actual dismissal
      },
      background:
          Container(), // Empty background since we handle it differently
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Padding(
              // ✅ OPTIMIZED: Reduced internal padding to maximize title space
              padding: EdgeInsets.fromLTRB(
                spacing * 0.8, // Reduced left padding
                spacing * 0.7, // Reduced top padding
                spacing * 0.5, // Reduced right padding for more title space
                spacing * 0.7, // Reduced bottom padding
              ),
              child: Row(
                children: [
                  // Song number circle - slightly smaller for more title space
                  Container(
                    width: 36 * scale, // ✅ REDUCED: From 40 to 36
                    height: 36 * scale, // ✅ REDUCED: From 40 to 36
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18 * scale),
                    ),
                    child: Center(
                      child: Text(
                        song.number,
                        style: TextStyle(
                          fontSize:
                              11 * scale, // ✅ SLIGHTLY REDUCED: From 12 to 11
                          fontWeight: FontWeight.bold,
                          color: isPlaying
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                      width: spacing *
                          0.6), // ✅ REDUCED: Smaller gap for more title space

                  // Song details - now gets maximum available width
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Song title with swipe indicator for audio songs
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title,
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontWeight: isPlaying
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isPlaying
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                                maxLines:
                                    3, // Allow up to 3 lines for longer titles
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Audio swipe indicator - only for authorized users
                            if (canShowAudioFeatures) ...[
                              SizedBox(width: 8),
                              _buildSwipeIndicator(theme, scale),
                            ],
                          ],
                        ),

                        // Verse count and preview - compact layout
                        if (song.verses.isNotEmpty) ...[
                          SizedBox(height: spacing * 0.15), // Reduced spacing
                          Row(
                            children: [
                              // Verse count
                              Text(
                                '${song.verses.length} verses',
                                style: TextStyle(
                                  fontSize: 10 *
                                      scale, // Smaller font for more title space
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Audio indicator inline - only for authorized users
                              if (canShowAudioFeatures) ...[
                                Text(' • ',
                                    style: TextStyle(
                                        fontSize: 10 * scale,
                                        color: theme.colorScheme.outline)),
                                Icon(
                                  Icons.music_note,
                                  size: 10 * scale,
                                  color: theme.colorScheme.secondary,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Audio',
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // First verse preview
                          SizedBox(height: spacing * 0.15),
                          Text(
                            _getPreviewText(song.verses.first.lyrics),
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ✅ OPTIMIZED: Compact action buttons pushed to the edge
                  SizedBox(
                      width: spacing *
                          0.3), // Minimal gap between title and buttons

                  // Action buttons container - fixed width to push to edge
                  SizedBox(
                    width: 32, // Fixed compact width
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite button - always visible, larger size
                        if (onFavoritePressed != null)
                          SizedBox(
                            width: 40, // Larger for better touch target
                            height: 40,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 24, // Larger icon
                              ),
                              color: isFavorite
                                  ? Colors.red
                                  : theme.colorScheme.outline,
                              onPressed: onFavoritePressed,
                              tooltip: isFavorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPreviewText(String lyrics) {
    // Get first line or first 50 characters
    final lines = lyrics.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 50)}...';
      }
      return firstLine;
    }
    return lyrics.length > 50 ? '${lyrics.substring(0, 50)}...' : lyrics;
  }

  Widget _buildSwipeIndicator(ThemeData theme, double scale) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: 1.0),
          onEnd: () {
            // Restart animation after a delay
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) {
                // Animation will restart automatically due to the widget rebuild
              }
            });
          },
          builder: (context, slideValue, child) {
            return Container(
              width: 20,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background arrows (static)
                  Positioned(
                    left: 2,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      size: 12 * scale,
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      size: 12 * scale,
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  // Animated arrow
                  Positioned(
                    left: 2 + (slideValue * 4), // Slides from 2 to 6
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: value,
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        size: 12 * scale,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
