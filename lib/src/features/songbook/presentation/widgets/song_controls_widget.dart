// lib/src/features/songbook/presentation/widgets/song_controls_widget.dart
// ✅ EXTRACTED: Controls for both desktop column and mobile fallback
// ✅ INCLUDES: Play button, favorites, sharing, font controls
// ✅ PREMIUM: Integrated premium gates and state management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/core/utils/sharing_utils.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/reports/presentation/report_song_bottom_sheet.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/fullscreen_lyrics_page.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/utils/constants.dart';

class SongControlsWidget extends StatelessWidget {
  final Song song;
  final String? initialCollection;
  final bool isOnline;
  final double fontSize;
  final VoidCallback onFontSizeIncrease;
  final VoidCallback onFontSizeDecrease;
  final VoidCallback onToggleFavorite;
  final DeviceType deviceType;
  final bool isMobileBottomBar;

  const SongControlsWidget({
    super.key,
    required this.song,
    this.initialCollection,
    required this.isOnline,
    required this.fontSize,
    required this.onFontSizeIncrease,
    required this.onFontSizeDecrease,
    required this.onToggleFavorite,
    required this.deviceType,
    this.isMobileBottomBar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileBottomBar) {
      return _buildMobileBottomBar(context);
    }
    return _buildDesktopControls(context);
  }

  // Desktop/Tablet controls column
  Widget _buildDesktopControls(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);
    final collectionAbbr = _getCollectionAbbreviation(initialCollection);

    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        final isPremium = songProvider.isPremium;
        final shouldShowFeatures = _shouldShowPremiumFeatures();
        final hasAudio = _songHasAudio(song);
        final isCurrentSong = songProvider.isCurrentSong(song);
        final isPlaying = songProvider.isPlaying;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$collectionAbbr #${song.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize:
                      (theme.textTheme.titleMedium?.fontSize ?? 16) * scale,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                song.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize:
                      (theme.textTheme.headlineSmall?.fontSize ?? 20) * scale,
                ),
              ),
              SizedBox(height: spacing * 0.75),
              _buildStatusIndicator(context),
              SizedBox(height: spacing * 1.5),

              // Play button for desktop
              if (shouldShowFeatures && hasAudio) ...[
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePlayAction(context, song),
                      icon: Icon(
                        isPremium && isCurrentSong && isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPremium
                                ? (isCurrentSong && isPlaying
                                    ? 'Pause Audio'
                                    : 'Play Audio')
                                : 'Premium Audio',
                            style: TextStyle(fontSize: 14 * scale),
                          ),
                          if (!isPremium) ...[
                            SizedBox(width: 4 * scale),
                            Icon(Icons.star,
                                size: 16 * scale, color: Colors.white),
                          ],
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing * 0.75),

                // ✅ NEW: Full-screen button for premium users
                if (isPremium) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openFullScreenMode(context, song),
                      icon: Icon(Icons.fullscreen, size: 18 * scale),
                      label: Text(
                        'Full Screen Mode',
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing * 1.5),
                ] else ...[
                  SizedBox(height: spacing * 1.5),
                ],
              ],

              // Favorite button with real-time status
              FutureBuilder<bool>(
                future: FavoritesRepository().isSongFavorite(song.number),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18 * scale,
                      ),
                      label: Text(
                        isFavorite ? 'Favorited' : 'Favorite',
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isFavorite
                            ? FavoritesRepository.getFavoriteColorForCollection(
                                song.collectionId ?? initialCollection)
                            : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: spacing * 0.75),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _copyToClipboard(context, song),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      ),
                      child: Tooltip(
                        message: 'Copy Lyrics',
                        child: Icon(Icons.copy, size: 16 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing * 0.5),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _shareSong(context, song),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      ),
                      child: Tooltip(
                        message: 'Share Song',
                        child: Icon(Icons.share, size: 16 * scale),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing * 0.5),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _showReportDialog(context, song),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      ),
                      child: Tooltip(
                        message: 'Report Issue',
                        child: Icon(Icons.report_problem, size: 16 * scale),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: spacing * 3),

              // Font size controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Font Size',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize:
                          (theme.textTheme.titleMedium?.fontSize ?? 16) * scale,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.remove_circle_outline, size: 20 * scale),
                        onPressed: onFontSizeDecrease,
                        tooltip: 'Decrease font size',
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 30 * scale),
                        child: Text(
                          fontSize.toStringAsFixed(0),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize:
                                (theme.textTheme.bodyLarge?.fontSize ?? 14) *
                                    scale,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, size: 20 * scale),
                        onPressed: onFontSizeIncrease,
                        tooltip: 'Increase font size',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Mobile bottom action bar
  Widget _buildMobileBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasAudio = _songHasAudio(song);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.3), width: 1),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ]
            : null,
      ),
      child: SafeArea(
        child: Consumer<SongProvider>(
          builder: (context, songProvider, child) {
            final isPremium = songProvider.isPremium;
            final isCurrentSong = songProvider.isCurrentSong(song);
            final isPlaying = songProvider.isPlaying;

            return Row(
              children: [
                // ✅ Mobile emergency play button
                if (hasAudio && _shouldShowPremiumFeatures()) ...[
                  Container(
                    decoration: BoxDecoration(
                      gradient: isPremium
                          ? LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePlayAction(context, song),
                      icon: Icon(
                        isPremium && isCurrentSong && isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 18,
                      ),
                      label: Text(
                        isPremium
                            ? (isCurrentSong && isPlaying ? 'Pause' : 'Play')
                            : 'Premium',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        elevation: 0,
                        minimumSize: const Size(80, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Favorite button with real-time status
                Expanded(
                  child: FutureBuilder<bool>(
                    future: FavoritesRepository().isSongFavorite(song.number),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
                      return FilledButton.icon(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                        label: Text(
                          isFavorite ? 'Favorited' : 'Favorite',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: isFavorite
                              ? FavoritesRepository
                                  .getFavoriteColorForCollection(
                                      song.collectionId ?? initialCollection)
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          minimumSize: const Size(80, 44),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 4),

                // Action buttons
                FilledButton.tonal(
                  onPressed: () => _copyToClipboard(context, song),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(44, 44),
                    backgroundColor: isDark
                        ? theme.colorScheme.surface.withOpacity(0.8)
                        : theme.colorScheme.primaryContainer,
                    foregroundColor: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                  child: const Icon(Icons.copy, size: 18),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal(
                  onPressed: () => _shareSong(context, song),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(44, 44),
                    backgroundColor: isDark
                        ? theme.colorScheme.surface.withOpacity(0.8)
                        : theme.colorScheme.primaryContainer,
                    foregroundColor: isDark
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                  child: const Icon(Icons.share, size: 18),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal(
                  onPressed: () => _showReportDialog(context, song),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(44, 44),
                    backgroundColor: isDark
                        ? Colors.red.withOpacity(0.2)
                        : Colors.red.withOpacity(0.1),
                    foregroundColor:
                        isDark ? Colors.red.shade300 : Colors.red.shade700,
                  ),
                  child: Icon(
                    Icons.report_problem,
                    size: 18,
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper methods
  String _getCollectionAbbreviation(String? collectionName) {
    if (collectionName == null || collectionName == 'All') return 'LPMI';
    switch (collectionName) {
      case 'Lagu Pujian Masa Ini':
      case 'LPMI':
        return 'LPMI';
      case 'Syair Rindu Dendam':
        return 'SRD';
      case 'Lagu Belia':
        return 'LB';
      case 'Favorites':
        return 'FAV';
      default:
        return collectionName.length > 4
            ? collectionName.substring(0, 4).toUpperCase()
            : collectionName.toUpperCase();
    }
  }

  bool _shouldShowPremiumFeatures() {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool _songHasAudio(Song song) {
    return song.audioUrl != null && song.audioUrl!.isNotEmpty;
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? (isDark
                ? Colors.green.withOpacity(0.2)
                : Colors.green.withOpacity(0.1))
            : (isDark
                ? Colors.grey.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: isOnline
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Local',
            style: TextStyle(
              fontSize: 11,
              color: isOnline
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlayAction(BuildContext context, Song song) async {
    final songProvider = context.read<SongProvider>();
    if (!songProvider.isPremium) {
      await _showPremiumUpgradeDialog(context, 'audio_playback');
      return;
    }
    if (!_songHasAudio(song)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio not available for this song.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    songProvider.selectSong(song);
  }

  // ✅ NEW: Open full-screen mode
  void _openFullScreenMode(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenLyricsPage(song: song),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _showPremiumUpgradeDialog(
      BuildContext context, String feature) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PremiumUpgradeDialog(feature: feature),
    );
  }

  void _copyToClipboard(BuildContext context, Song song) {
    final lyrics = song.sortedVerses.map((verse) => verse.lyrics).join('\n\n');
    final collectionAbbr = _getCollectionAbbreviation(initialCollection);
    final textToCopy =
        '$collectionAbbr #${song.number}: ${song.title}\n\n$lyrics';
    SharingUtils.copyToClipboard(
      context: context,
      text: textToCopy,
      message: 'Lyrics copied!',
    );
  }

  void _shareSong(BuildContext context, Song song) {
    final lyrics = song.sortedVerses.map((verse) => verse.lyrics).join('\n\n');
    final collectionAbbr = _getCollectionAbbreviation(initialCollection);
    final textToShare =
        '$collectionAbbr #${song.number}: ${song.title}\n\n$lyrics';
    SharingUtils.showShareOptions(
      context: context,
      text: textToShare,
      title: song.title,
    );
  }

  void _showReportDialog(BuildContext context, Song song) {
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporting requires an internet connection.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportSongBottomSheet(song: song),
    );
  }
}
