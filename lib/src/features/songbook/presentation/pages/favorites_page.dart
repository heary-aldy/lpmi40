// lib/src/features/songbook/presentation/pages/favorites_page.dart
// ✅ NEW: Dedicated favorites page with collection-grouped favorites

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_item.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/pages/auth_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final CollectionService _collectionService = CollectionService();
  final SongRepository _songRepository = SongRepository();

  Map<String, List<Song>> _collectionFavorites = {};
  List<SongCollection> _collections = [];
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to view your favorites';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load collections first
      _collections = await _collectionService.getAccessibleCollections();

      // Create a map to organize favorites by collection
      final Map<String, List<Song>> collectionFavorites = {};

      // Initialize with empty lists for each collection
      for (final collection in _collections) {
        collectionFavorites[collection.id] = [];
      }

      // Add global collection for legacy favorites
      collectionFavorites['global'] = [];

      // Load favorites for each collection
      for (final collection in _collections) {
        try {
          final favoriteNumbers =
              await _favoritesRepository.getFavorites(collection.id);

          if (favoriteNumbers.isNotEmpty) {
            // Get songs specifically from this collection
            final collectionsSeparated =
                await _songRepository.getCollectionsSeparated();
            final collectionSongs = collectionsSeparated[collection.id] ?? [];

            for (final songNumber in favoriteNumbers) {
              final foundSong = collectionSongs.firstWhere(
                (s) => s.number == songNumber,
                orElse: () => Song(
                  number: songNumber,
                  title: 'Unknown Song',
                  verses: [],
                ),
              );

              if (foundSong.number.isNotEmpty) {
                // Create a new song with favorite status and collection ID
                final song = Song(
                  number: foundSong.number,
                  title: foundSong.title,
                  verses: foundSong.verses,
                  isFavorite: true,
                  collectionId: collection.id,
                  audioUrl: foundSong.audioUrl,
                  createdAt: foundSong.createdAt,
                  updatedAt: foundSong.updatedAt,
                );
                collectionFavorites[collection.id]!.add(song);
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading favorites for ${collection.id}: $e');
        }
      }

      // Load global/legacy favorites
      try {
        final globalFavorites =
            await _favoritesRepository.getFavorites('global');
        if (globalFavorites.isNotEmpty) {
          // Try to get these songs from the main song data
          final allSongsResult = await _songRepository.getAllSongs();

          for (final songNumber in globalFavorites) {
            final foundSong = allSongsResult.songs.firstWhere(
              (s) => s.number == songNumber,
              orElse: () => Song(
                number: songNumber,
                title: 'Unknown Song',
                verses: [],
              ),
            );

            if (foundSong.number.isNotEmpty) {
              final song = Song(
                number: foundSong.number,
                title: foundSong.title,
                verses: foundSong.verses,
                isFavorite: true,
                collectionId: 'global',
                audioUrl: foundSong.audioUrl,
                createdAt: foundSong.createdAt,
                updatedAt: foundSong.updatedAt,
              );
              collectionFavorites['global']!.add(song);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error loading global favorites: $e');
      }

      // Remove empty collections
      collectionFavorites.removeWhere((key, value) => value.isEmpty);

      if (mounted) {
        setState(() {
          _collectionFavorites = collectionFavorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load favorites: $e';
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle(Song song) async {
    try {
      // Only use SongProvider - it will handle the repository call
      await context.read<SongProvider>().toggleFavorite(song);

      // Update local state to reflect the change
      final collectionId = song.collectionId ?? 'global';
      setState(() {
        if (song.isFavorite) {
          // Song was added to favorites
          _collectionFavorites[collectionId] ??= [];
          if (!_collectionFavorites[collectionId]!
              .any((s) => s.number == song.number)) {
            _collectionFavorites[collectionId]!.add(song);
          }
        } else {
          // Song was removed from favorites
          _collectionFavorites[collectionId]
              ?.removeWhere((s) => s.number == song.number);
          if (_collectionFavorites[collectionId]?.isEmpty == true) {
            _collectionFavorites.remove(collectionId);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              song.isFavorite ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongLyricsPage(
          songNumber: song.number,
          initialCollection: song.collectionId,
          songObject: song,
        ),
      ),
    );
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please log in to manage favorites.'),
        action: SnackBarAction(
          label: 'LOGIN',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AuthPage(
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                onToggleTheme: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all songs from your favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _favoritesRepository.clearAllFavorites();
        setState(() {
          _collectionFavorites.clear();
        });

        // ✅ NEW: Refresh SongProvider to update all UI
        if (mounted) {
          context.read<SongProvider>().refreshFavorites();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All favorites cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear favorites: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCollectionDisplayName(String collectionId) {
    if (collectionId == 'global') return 'General Favorites';

    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => SongCollection(
        id: collectionId,
        name: collectionId,
        description: '',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'unknown',
      ),
    );

    return collection.name.isNotEmpty ? collection.name : collectionId;
  }

  Color _getCollectionColor(String collectionId) {
    return FavoritesRepository.getFavoriteColorForCollection(collectionId);
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      case 'PPL':
        return Icons.favorite;
      case 'Advent':
        return Icons.star;
      case 'Natal':
        return Icons.celebration;
      case 'Paskah':
        return Icons.brightness_5;
      case 'global':
        return Icons.favorite;
      default:
        return Icons.library_music;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ✅ Enhanced header with background image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            title: _isHeaderCollapsed
                ? Row(
                    children: [
                      const Icon(Icons.favorite, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'My Favorites',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : null,
            actions: [
              if (_currentUser != null && _collectionFavorites.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _loadFavorites();
                        break;
                      case 'clear_all':
                        _clearAllFavorites();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: ListTile(
                        leading: Icon(Icons.clear_all, color: Colors.red),
                        title: Text('Clear All'),
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double collapsedHeight =
                    kToolbarHeight + MediaQuery.of(context).padding.top;
                final isCollapsed = constraints.maxHeight <= collapsedHeight;

                // Update collapsed state
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _isHeaderCollapsed != isCollapsed) {
                    setState(() {
                      _isHeaderCollapsed = isCollapsed;
                    });
                  }
                });

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  centerTitle: false,
                  title: const Text(''), // Set to empty
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image
                      Image.asset(
                        'assets/images/header_image.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.red,
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.7)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 72,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon and favorites badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'FAVORITES',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Title
                            const Text(
                              'My Favorites',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtitle
                            Text(
                              _collectionFavorites.isEmpty
                                  ? 'No favorite songs yet'
                                  : '${_collectionFavorites.values.fold(0, (sum, songs) => sum + songs.length)} favorite songs across ${_collectionFavorites.length} collection${_collectionFavorites.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Content
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your favorites...'),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Login Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please log in to view and manage your favorite songs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showLoginPrompt,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadFavorites,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_collectionFavorites.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Favorites Yet',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start adding songs to your favorites by tapping the heart icon on any song.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // ✅ FIX: Safe navigation - just pop if possible, otherwise stay on page
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    // If can't pop, just stay on this page (it's likely the root)
                  },
                  icon: const Icon(Icons.library_music),
                  label: const Text('Browse Songs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final collectionId = _collectionFavorites.keys.elementAt(index);
          final songs = _collectionFavorites[collectionId]!;
          final collectionName = _getCollectionDisplayName(collectionId);
          final collectionColor = _getCollectionColor(collectionId);
          final collectionIcon = _getCollectionIcon(collectionId);

          return Padding(
            padding: EdgeInsets.fromLTRB(16.0, index == 0 ? 16.0 : 8.0, 16.0,
                index == _collectionFavorites.length - 1 ? 16.0 : 8.0),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collection header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: collectionColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: collectionColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            collectionIcon,
                            color: collectionColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collectionName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: collectionColor,
                                ),
                              ),
                              Text(
                                '${songs.length} favorite song${songs.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: collectionColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Songs list
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: songs
                          .map((song) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: SongListItem(
                                  song: song,
                                  isPlaying: false,
                                  canPlay: song.audioUrl?.isNotEmpty ?? false,
                                  onTap: () => _navigateToSong(song),
                                  onFavoritePressed: () =>
                                      _handleFavoriteToggle(song),
                                  showDivider: false,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: _collectionFavorites.length,
      ),
    );
  }
}
