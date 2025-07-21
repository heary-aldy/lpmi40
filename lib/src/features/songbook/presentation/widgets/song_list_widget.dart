// lib/src/features/songbook/presentation/widgets/song_list_widget.dart
// ✅ NEW: Extracted song list functionality from main_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_item.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/utils/constants.dart';

class SongListWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return _buildLoadingState(context);
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(context);
    }

    if (!controller.canAccessCurrentCollection) {
      return _buildAccessDeniedState(context);
    }

    if (controller.filteredSongs.isEmpty) {
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
              controller.errorMessage ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
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

    if (!controller.canAccessCurrentCollection) {
      if (controller.accessDeniedReason == 'login_required') {
        title = 'Login Required';
        subtitle = 'Please log in to access this collection and save favorites';
        icon = Icons.login;
      } else if (controller.accessDeniedReason == 'premium_required') {
        title = 'Premium Required';
        subtitle = 'Upgrade to Premium to access this collection';
        icon = Icons.star;
      } else {
        title = 'Access Denied';
        subtitle = 'You don\'t have permission to access this collection';
        icon = Icons.lock;
      }
    } else if (controller.activeFilter == 'Favorites' &&
        controller.collectionSongs['Favorites']!.isEmpty) {
      title = 'No favorite songs yet';
      subtitle = 'Tap the heart icon on songs to add them here';
      icon = Icons.favorite_border;
    } else if (controller.searchQuery.isNotEmpty &&
        controller.filteredSongs.isEmpty) {
      title = 'No songs found';
      subtitle =
          'Try adjusting your search for "${controller.searchQuery}" or select a different collection';
      icon = Icons.search_off;
    } else if (controller.filteredSongs.isEmpty) {
      title =
          'No songs in ${controller.currentCollection?.name ?? controller.activeFilter}';
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
            if (controller.searchQuery.isNotEmpty)
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

  Widget _buildSongsList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          120, // ✅ Extra bottom padding for floating audio player
        ),
        itemCount: controller.filteredSongs.length,
        itemBuilder: (context, index) {
          final song = controller.filteredSongs[index];
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
          isPlaying: songProvider.isCurrentSong(song) && songProvider.isPlaying,
          canPlay: songProvider.canPlaySong(song),
          showDivider: index < controller.filteredSongs.length - 1,
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
          initialCollection: controller.activeFilter,
          songObject: song,
        ),
      ),
    ).then((_) {
      // Refresh when returning from song lyrics page
      onRefresh();
    });
  }

  void _handleFavoritePressed(Song song) {
    onFavoritePressed(song);
  }

  void _handlePlayPressed(SongProvider songProvider, Song song) {
    songProvider.selectSong(song);
  }
}

class SongListStats extends StatelessWidget {
  final MainPageController controller;

  const SongListStats({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSongs = controller.songs.length;
    final filteredCount = controller.filteredSongs.length;
    final isFiltered =
        controller.searchQuery.isNotEmpty || controller.activeFilter != 'All';

    if (totalSongs == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                controller.isOnline ? Icons.cloud_done : Icons.offline_bolt,
                color: controller.isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
