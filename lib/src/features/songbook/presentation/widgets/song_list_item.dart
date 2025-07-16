// lib/src/features/songbook/presentation/widgets/song_list_item.dart
// ✅ FIXED: Resolved infinite width constraint error from dashboard navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/utils/constants.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onPlayPressed;
  final bool isPlaying;
  final bool canPlay;
  final bool showPlayButton;
  final bool compactMode;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoritePressed,
    this.onPlayPressed,
    this.isPlaying = false,
    this.canPlay = false,
    this.showPlayButton = true,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use MediaQuery instead of LayoutBuilder to avoid infinite constraints
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    if (compactMode) {
      return _buildCompactListItem(context, deviceType);
    } else {
      return _buildStandardListItem(context, deviceType);
    }
  }

  Widget _buildStandardListItem(BuildContext context, DeviceType deviceType) {
    final theme = Theme.of(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // ✅ FIX: Add safety bounds for scale values
    final safeScale = scale.clamp(0.8, 2.0);
    final safeSpacing = spacing.clamp(8.0, 32.0);

    return Consumer2<SongProvider, SettingsProvider>(
      builder: (context, songProvider, settingsProvider, child) {
        final isCurrentSong = songProvider.isCurrentSong(song);
        final isPlayingCurrent = isCurrentSong && songProvider.isPlaying;
        final isLoadingCurrent = isCurrentSong && songProvider.isLoading;
        final isPremium = songProvider.isPremium;
        final hasAudio = song.hasAudio;

        return Card(
          margin: EdgeInsets.symmetric(
            vertical: safeSpacing * 0.25,
            horizontal: safeSpacing * 0.1,
          ),
          elevation: isCurrentSong ? 3 : 1,
          color: isCurrentSong
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.cardColor,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: safeSpacing,
              vertical: safeSpacing * 0.5,
            ),

            // ✅ SONG NUMBER LEADING
            leading: Container(
              width: 50 * safeScale,
              height: 50 * safeScale,
              decoration: BoxDecoration(
                color: isCurrentSong
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: isCurrentSong
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.number,
                    style: TextStyle(
                      fontSize: 14 * safeScale,
                      fontWeight: FontWeight.bold,
                      color: isCurrentSong
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  // ✅ AUDIO INDICATOR
                  if (hasAudio) ...[
                    SizedBox(height: 2 * safeScale),
                    Icon(
                      Icons.music_note,
                      size: 12 * safeScale,
                      color: isPremium ? Colors.green : Colors.orange,
                    ),
                  ],
                ],
              ),
            ),

            // ✅ SONG TITLE AND STATUS
            title: Text(
              song.title,
              style: TextStyle(
                fontSize: 16 * safeScale,
                fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w500,
                color: isCurrentSong
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ✅ SUBTITLE WITH COLLECTION INFO - FIXED: Handle overflow properly
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlayingCurrent) ...[
                  Icon(
                    Icons.graphic_eq,
                    size: 14 * safeScale,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: safeSpacing * 0.25),
                  Flexible(
                    child: Text(
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 12 * safeScale,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ] else if (isLoadingCurrent) ...[
                  SizedBox(
                    width: 12 * safeScale,
                    height: 12 * safeScale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: safeSpacing * 0.25),
                  Flexible(
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12 * safeScale,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ] else if (hasAudio) ...[
                  Icon(
                    Icons.headphones,
                    size: 14 * safeScale,
                    color: isPremium ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: safeSpacing * 0.25),
                  Flexible(
                    child: Text(
                      isPremium ? 'Audio Available' : 'Premium Audio',
                      style: TextStyle(
                        fontSize: 12 * safeScale,
                        color: isPremium ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: Text(
                      'Lyrics Only',
                      style: TextStyle(
                        fontSize: 12 * safeScale,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),

            // ✅ ACTION BUTTONS TRAILING - OPTIMIZED: Reduce spacing to prevent overflow
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ PLAY/PAUSE BUTTON (Premium-gated)
                if (showPlayButton && hasAudio) ...[
                  if (isPremium) ...[
                    // Premium user - functional play button
                    IconButton(
                      icon: Icon(
                        isLoadingCurrent
                            ? Icons.hourglass_empty
                            : isPlayingCurrent
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                        color: isCurrentSong
                            ? theme.colorScheme.primary
                            : Colors.green,
                      ),
                      iconSize: 32 * safeScale,
                      onPressed: isLoadingCurrent
                          ? null
                          : () {
                              if (onPlayPressed != null) {
                                onPlayPressed!();
                              } else {
                                songProvider.selectSong(song);
                              }
                            },
                      tooltip: isPlayingCurrent ? 'Pause' : 'Play',
                    ),
                  ] else ...[
                    // Non-premium user - upgrade prompt
                    IconButton(
                      icon: Icon(
                        Icons.star_outline,
                        color: Colors.orange,
                      ),
                      iconSize: 28 * safeScale,
                      onPressed: () => _showPremiumUpgradeDialog(context),
                      tooltip: 'Upgrade to Premium',
                    ),
                  ],
                ],

                // ✅ FAVORITE BUTTON
                IconButton(
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite ? Colors.red : Colors.grey,
                  ),
                  iconSize: 24 * safeScale,
                  onPressed: onFavoritePressed,
                  tooltip: song.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),

                // ✅ NAVIGATION ARROW - Reduced size on small screens
                Icon(
                  Icons.chevron_right,
                  size: 18 * safeScale,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              ],
            ),

            onTap: onTap,
          ),
        );
      },
    );
  }

  Widget _buildCompactListItem(BuildContext context, DeviceType deviceType) {
    final theme = Theme.of(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // ✅ FIX: Add safety bounds for scale values
    final safeScale = scale.clamp(0.8, 2.0);
    final safeSpacing = spacing.clamp(8.0, 32.0);

    return Consumer2<SongProvider, SettingsProvider>(
      builder: (context, songProvider, settingsProvider, child) {
        final isCurrentSong = songProvider.isCurrentSong(song);
        final isPlayingCurrent = isCurrentSong && songProvider.isPlaying;
        final isPremium = songProvider.isPremium;
        final hasAudio = song.hasAudio;

        return Container(
          margin: EdgeInsets.symmetric(vertical: safeSpacing * 0.1),
          child: Material(
            color: isCurrentSong
                ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: safeSpacing * 0.75,
                vertical: safeSpacing * 0.25,
              ),

              // ✅ COMPACT LEADING
              leading: Container(
                width: 36 * safeScale,
                height: 36 * safeScale,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    song.number,
                    style: TextStyle(
                      fontSize: 12 * safeScale,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),

              // ✅ COMPACT TITLE
              title: Text(
                song.title,
                style: TextStyle(
                  fontSize: 14 * safeScale,
                  fontWeight:
                      isCurrentSong ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentSong
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ✅ COMPACT TRAILING - FIXED: Handle overflow properly
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlayingCurrent)
                    Icon(
                      Icons.graphic_eq,
                      color: theme.colorScheme.primary,
                      size: 16 * safeScale,
                    ),
                  if (song.isFavorite) ...[
                    SizedBox(width: safeSpacing * 0.25),
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 14 * safeScale,
                    ),
                  ],
                  if (hasAudio) ...[
                    SizedBox(width: safeSpacing * 0.25),
                    Icon(
                      Icons.headphones,
                      color: isPremium ? Colors.green : Colors.orange,
                      size: 14 * safeScale,
                    ),
                  ],
                  SizedBox(width: safeSpacing * 0.25),
                  Icon(
                    Icons.chevron_right,
                    size: 16 * safeScale,
                    color: theme.iconTheme.color?.withOpacity(0.5),
                  ),
                ],
              ),

              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPremiumUpgradeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_playback',
      ),
    );
  }
}

/// ✅ SPECIALIZED: Grid view song item for alternative layouts
class SongGridItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onPlayPressed;
  final bool isPlaying;
  final bool canPlay;

  const SongGridItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onFavoritePressed,
    this.onPlayPressed,
    this.isPlaying = false,
    this.canPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<SongProvider, SettingsProvider>(
      builder: (context, songProvider, settingsProvider, child) {
        final isCurrentSong = songProvider.isCurrentSong(song);
        final isPlayingCurrent = isCurrentSong && songProvider.isPlaying;
        final isPremium = songProvider.isPremium;
        final hasAudio = song.hasAudio;

        return Card(
          elevation: isCurrentSong ? 4 : 2,
          color: isCurrentSong
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.cardColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ HEADER ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Song number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentSong
                              ? theme.colorScheme.primary.withOpacity(0.2)
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          song.number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrentSong
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),

                      // Favorite button
                      IconButton(
                        icon: Icon(
                          song.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: song.isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onFavoritePressed,
                        tooltip: song.isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ✅ SONG TITLE
                  Expanded(
                    child: Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrentSong ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentSong
                            ? theme.colorScheme.primary
                            : theme.textTheme.titleMedium?.color,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ BOTTOM CONTROLS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status indicator
                      if (isPlayingCurrent) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.graphic_eq,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Playing',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else if (hasAudio) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.headphones,
                              size: 14,
                              color: isPremium ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPremium ? 'Audio' : 'Premium',
                              style: TextStyle(
                                fontSize: 10,
                                color: isPremium ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Lyrics',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],

                      // Play button
                      if (hasAudio) ...[
                        if (isPremium) ...[
                          IconButton(
                            icon: Icon(
                              isPlayingCurrent
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: isCurrentSong
                                  ? theme.colorScheme.primary
                                  : Colors.green,
                              size: 28,
                            ),
                            onPressed: () {
                              if (onPlayPressed != null) {
                                onPlayPressed!();
                              } else {
                                songProvider.selectSong(song);
                              }
                            },
                            tooltip: isPlayingCurrent ? 'Pause' : 'Play',
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(
                              Icons.star_outline,
                              color: Colors.orange,
                              size: 24,
                            ),
                            onPressed: () => _showPremiumUpgradeDialog(context),
                            tooltip: 'Upgrade to Premium',
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPremiumUpgradeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_playback',
      ),
    );
  }
}
