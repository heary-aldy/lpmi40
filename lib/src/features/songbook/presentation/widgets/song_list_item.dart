// lib/src/features/songbook/presentation/widgets/song_list_item.dart
// ✅ ENHANCED: Updated SongListItem compatible with floating audio player
// ✅ FEATURES: Consistent audio controls, responsive design, premium integration
// ✅ COMPATIBILITY: Works seamlessly with enhanced SongProvider
// ✅ NEW: Added offline download support for premium users

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/audio/widgets/download_audio_button.dart';
import 'package:lpmi40/utils/constants.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final bool canPlay;
  final VoidCallback onTap;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onFavoritePressed;

  const SongListItem({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.canPlay,
    required this.onTap,
    this.onPlayPressed,
    this.onFavoritePressed,
    required bool showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // Check if song has audio and is favorite
    final hasAudio = song.audioUrl != null && song.audioUrl!.isNotEmpty;
    final isFavorite = song.isFavorite;

    return Card(
      elevation: isPlaying ? 4 : 1,
      margin: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing * 0.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isPlaying
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: Row(
                children: [
                  // Song number circle
                  Container(
                    width: 40 * scale,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Center(
                      child: Text(
                        song.number,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                          color: isPlaying
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: spacing),

                  // Song details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Song title - allow multiple lines
                        Text(
                          song.title,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight:
                                isPlaying ? FontWeight.bold : FontWeight.w600,
                            color: isPlaying
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2, // Allow up to 2 lines for title
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Verse count information
                        if (song.verses.isNotEmpty) ...[
                          SizedBox(height: spacing * 0.2),
                          Text(
                            '${song.verses.length} verses',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // First verse preview (if available)
                        if (song.verses.isNotEmpty) ...[
                          SizedBox(height: spacing * 0.25),
                          Text(
                            _getPreviewText(song.verses.first.lyrics),
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Audio indicator
                        if (hasAudio) ...[
                          SizedBox(height: spacing * 0.25),
                          Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 12 * scale,
                                color: theme.colorScheme.secondary,
                              ),
                              SizedBox(width: spacing * 0.25),
                              Text(
                                'Audio Available',
                                style: TextStyle(
                                  fontSize: 10 * scale,
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons - Flexible to prevent overflow
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Download button (only if song has audio)
                        if (hasAudio) ...[
                          SizedBox(
                            width: 28 * scale,
                            height: 28 * scale,
                            child: DownloadAudioButton(
                              song: song,
                              isCompact: true,
                            ),
                          ),
                        ],

                        // Play/Pause button (only if song has audio and can play)
                        if (canPlay && hasAudio && onPlayPressed != null) ...[
                          SizedBox(
                            width: 28 * scale,
                            height: 28 * scale,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_outline,
                                size: 22 * scale,
                              ),
                              color: theme.colorScheme.primary,
                              onPressed: onPlayPressed,
                              tooltip: isPlaying ? 'Pause' : 'Play',
                            ),
                          ),
                        ] else if (hasAudio && !canPlay) ...[
                          // Show disabled play button with tooltip
                          SizedBox(
                            width: 28 * scale,
                            height: 28 * scale,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.play_circle_outline,
                                size: 22 * scale,
                              ),
                              color: theme.disabledColor,
                              onPressed: null,
                              tooltip: 'Audio not available in this collection',
                            ),
                          ),
                        ],

                        // Favorite button
                        if (onFavoritePressed != null) ...[
                          SizedBox(
                            width: 28 * scale,
                            height: 28 * scale,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18 * scale,
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
}
