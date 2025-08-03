// lib/src/features/songbook/presentation/widgets/song_list_widget.dart
// ✅ NEW: Extracted song list functionality from main_page.dart
// ✅ ENHANCED: Updated padding logic for desktop/large desktop to use 85% width

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_item.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/core/services/audio_download_service.dart'; // ✅ NEW: Audio download service
import 'package:lpmi40/src/core/services/premium_service.dart'; // ✅ NEW: Premium service for permissions
import 'package:lpmi40/utils/constants.dart';

class SongListWidget extends StatefulWidget {
  final MainPageController controller;
  final Function(Song) onSongTap;
  final Function(Song) onFavoritePressed;
  final Function() onRefresh;
  final ScrollController? scrollController;

  const SongListWidget({
    super.key,
    required this.controller,
    required this.onSongTap,
    required this.onFavoritePressed,
    required this.onRefresh,
    this.scrollController,
  });

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  final PremiumService _premiumService = PremiumService();
  bool _canAccessAudio = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkAudioPermissions();
  }

  Future<void> _checkAudioPermissions() async {
    try {
      final canAccess = await _premiumService.canAccessAudio();
      if (mounted) {
        setState(() {
          _canAccessAudio = canAccess;
          _isCheckingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canAccessAudio = false;
          _isCheckingPermissions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading || _isCheckingPermissions) {
      return _buildLoadingState(context);
    }

    if (widget.controller.errorMessage != null) {
      return _buildErrorState(context);
    }

    if (!widget.controller.canAccessCurrentCollection) {
      return _buildAccessDeniedState(context);
    }

    if (widget.controller.filteredSongs.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildSongsList(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading songs...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.errorMessage ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedState(BuildContext context) {
    return _buildEmptyState(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    String title, subtitle;
    IconData icon;

    if (!widget.controller.canAccessCurrentCollection) {
      if (widget.controller.accessDeniedReason == 'login_required') {
        title = 'Login Required';
        subtitle = 'Please log in to access this collection and save favorites';
        icon = Icons.login;
      } else if (widget.controller.accessDeniedReason == 'premium_required') {
        title = 'Premium Required';
        subtitle = 'Upgrade to Premium to access this collection';
        icon = Icons.star;
      } else {
        title = 'Access Denied';
        subtitle = 'You don\'t have permission to access this collection';
        icon = Icons.lock;
      }
    } else if (widget.controller.activeFilter == 'Favorites' &&
        widget.controller.collectionSongs['Favorites']!.isEmpty) {
      title = 'No favorite songs yet';
      subtitle = 'Tap the heart icon on songs to add them here';
      icon = Icons.favorite_border;
    } else if (widget.controller.searchQuery.isNotEmpty &&
        widget.controller.filteredSongs.isEmpty) {
      title = 'No songs found';
      subtitle =
          'Try adjusting your search for "${widget.controller.searchQuery}" or select a different collection';
      icon = Icons.search_off;
    } else if (widget.controller.filteredSongs.isEmpty) {
      title =
          'No songs in ${widget.controller.currentCollection?.name ?? widget.controller.activeFilter}';
      subtitle = 'This collection appears to be empty or still loading';
      icon = Icons.folder_open;
    } else {
      title = 'No songs found';
      subtitle =
          'Try adjusting your search or selecting a different collection';
      icon = Icons.search_off;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.titleLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.controller.searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // This would be handled by the parent to clear search
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ ENHANCED: Updated padding logic to eliminate double padding on all devices
  Widget _buildSongsList(BuildContext context) {
    // ✅ FIX: Remove all horizontal padding since SongListContainer now handles it
    // Let SongListContainer manage the optimal horizontal spacing for each device

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
      },
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(
          0, // No horizontal padding - managed by SongListContainer
          0,
          0, // No horizontal padding - managed by SongListContainer
          120, // ✅ Extra bottom padding for floating audio player
        ),
        itemCount: widget.controller.filteredSongs.length,
        itemBuilder: (context, index) {
          final song = widget.controller.filteredSongs[index];
          return _buildSongListItem(context, song, index);
        },
      ),
    );
  }

  Widget _buildSongListItem(BuildContext context, Song song, int index) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        return SongListItem(
          song: song,
          onTap: () => _handleSongTap(context, song),
          onFavoritePressed: () => _handleFavoritePressed(song),
          onPlayPressed: () => _handlePlayPressed(songProvider, song),
          onDownloadPressed: () =>
              _handleDownloadPressed(context, song), // ✅ NEW: Download callback
          isPlaying: songProvider.isCurrentSong(song) && songProvider.isPlaying,
          canPlay: songProvider.canPlaySong(song),
          canAccessAudio: _canAccessAudio, // ✅ NEW: Pass audio permission
          currentCollection:
              widget.controller.activeFilter, // ✅ NEW: Collection context
          showDivider: index < widget.controller.filteredSongs.length - 1,
        );
      },
    );
  }

  void _handleSongTap(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongLyricsPage(
          songNumber: song.number,
          initialCollection: widget.controller.activeFilter,
          songObject: song,
        ),
      ),
    ).then((_) {
      // Refresh when returning from song lyrics page
      widget.onRefresh();
    });
  }

  void _handleFavoritePressed(Song song) {
    widget.onFavoritePressed(song);
  }

  void _handlePlayPressed(SongProvider songProvider, Song song) {
    // Check audio permission before allowing play
    if (!_canAccessAudio) {
      // This shouldn't normally happen since the play button should be hidden,
      // but add this as a safety check
      return;
    }

    // ✅ FIX: Ensure song has collection context for proper display in audio player
    final songWithCollection =
        song.collectionId != null && song.collectionId!.isNotEmpty
            ? song // Song already has collection ID
            : Song(
                number: song.number,
                title: song.title,
                verses: song.verses,
                audioUrl: song.audioUrl,
                isFavorite: song.isFavorite,
                collectionId:
                    widget.controller.activeFilter, // Set from current filter
                accessLevel: song.accessLevel,
                collectionIndex: song.collectionIndex,
                collectionMetadata: song.collectionMetadata,
                createdAt: song.createdAt,
                updatedAt: song.updatedAt,
              );

    debugPrint(
        '🎵 [SongListWidget] Playing song with collection: "${songWithCollection.collectionId}"');
    songProvider.selectSong(songWithCollection);
  }

  // ✅ NEW: Handle download button press with proper permission checking
  Future<void> _handleDownloadPressed(BuildContext context, Song song) async {
    try {
      // First check if user has audio access permission
      if (!_canAccessAudio) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Audio features require Premium, Admin, or Super Admin access'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final downloadService = AudioDownloadService();

      // Initialize download service if needed
      await downloadService.initialize();

      // Check if song has audio URL
      if (song.audioUrl == null || song.audioUrl!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio not available for "${song.title}"'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if already downloaded
      if (downloadService.isDownloaded(song.number)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${song.title}" is already downloaded'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Start download
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading "${song.title}"...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await downloadService.downloadSongAudio(
        song: song,
        audioUrl: song.audioUrl!,
        quality: 'medium', // Default to medium quality
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${song.title}" downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SongListStats extends StatelessWidget {
  final MainPageController controller;

  const SongListStats({
    super.key,
    required this.controller,
  });

  // ✅ ENHANCED: Updated for desktop/large desktop full width utilization
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    // Use minimal horizontal margin for larger screens to maximize width utilization
    final useFullWidth = deviceType == DeviceType.tablet ||
        deviceType == DeviceType.desktop ||
        deviceType == DeviceType.largeDesktop;

    final horizontalMargin = useFullWidth ? 0.0 : 16.0;
    final totalSongs = controller.songs.length;
    final filteredCount = controller.filteredSongs.length;
    final isFiltered =
        controller.searchQuery.isNotEmpty || controller.activeFilter != 'All';

    if (totalSongs == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isFiltered
                  ? 'Showing $filteredCount of $totalSongs songs'
                  : '$totalSongs songs available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (controller.activeFilter == 'Favorites') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 12,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Favorites',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SongListHeader extends StatelessWidget {
  final MainPageController controller;
  final VoidCallback? onHeaderTap;

  const SongListHeader({
    super.key,
    required this.controller,
    this.onHeaderTap,
  });

  // ✅ ENHANCED: Updated for desktop/large desktop full width utilization
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    // Use minimal horizontal margin for larger screens to maximize width utilization
    final useFullWidth = deviceType == DeviceType.tablet ||
        deviceType == DeviceType.desktop ||
        deviceType == DeviceType.largeDesktop;

    final horizontalMargin = useFullWidth ? 0.0 : 16.0;

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 8, horizontalMargin, 0),
      child: InkWell(
        onTap: onHeaderTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(
                controller.getCollectionIcon(),
                color: controller.getCollectionColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentDisplayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.filteredSongCount} songs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.storage,
                color: Colors.blue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
