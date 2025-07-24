// lib/src/features/songbook/presentation/pages/song_lyrics_page.dart
// ✅ REFACTORED: Using extracted components for better maintainability
// ✅ REDUCED: From 800+ lines to ~400 lines
// ✅ INCLUDES: Mobile emergency play button via SongControlsWidget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/widgets/floating_audio_player.dart';

// ✅ NEW: Extracted components
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_controls_widget.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/lyrics_display_widget.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_header_widget.dart';

import 'package:lpmi40/utils/constants.dart';

class SongLyricsPage extends StatefulWidget {
  final String songNumber;
  final String? initialCollection;
  final Song? songObject;

  const SongLyricsPage({
    super.key,
    required this.songNumber,
    this.initialCollection,
    this.songObject,
  });

  @override
  State<SongLyricsPage> createState() => _SongLyricsPageState();
}

class _SongLyricsPageState extends State<SongLyricsPage> {
  final SongRepository _songRepo = SongRepository();
  final FavoritesRepository _favRepo = FavoritesRepository();
  late PreferencesService _prefsService;

  Future<SongWithStatusResult?>? _songWithStatusFuture;

  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  bool _isOnline = true;
  
  // ✅ NEW: Track favorites state for real-time updates
  Song? _currentSong;

  @override
  void initState() {
    super.initState();
    // ✅ NEW: Listen to favorites changes for real-time UI updates
    _favRepo.addListener(_onFavoritesChanged);
    _loadInitialData();
  }
  
  @override
  void dispose() {
    // ✅ NEW: Clean up listeners
    _favRepo.removeListener(_onFavoritesChanged);
    super.dispose();
  }
  
  // ✅ NEW: Handle favorites state changes
  void _onFavoritesChanged() {
    if (mounted && _currentSong != null) {
      setState(() {
        // UI will rebuild with updated favorite status from cache
      });
    }
  }

  void _loadInitialData() {
    _loadSettings().then((_) {
      if (mounted) {
        setState(() {
          _songWithStatusFuture = _findSongWithStatus();
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    _prefsService = await PreferencesService.init();
    if (mounted) {
      setState(() {
        _fontSize = _prefsService.fontSize;
        _fontFamily = _prefsService.fontStyle;
        _textAlign = _prefsService.textAlign;
      });
    }
  }

  Future<SongWithStatusResult?> _findSongWithStatus() async {
    try {
      debugPrint(
          '🔍 [SongLyricsPage] Loading song ${widget.songNumber} from collection: ${widget.initialCollection}');

      if (widget.songObject != null) {
        debugPrint('✅ [SongLyricsPage] Using provided song object');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          widget.songObject!.isFavorite =
              await _favRepo.isSongFavorite(widget.songObject!.number);
        }
        return SongWithStatusResult(song: widget.songObject!, isOnline: true);
      }

      SongWithStatusResult? songResult;

      if (widget.initialCollection != null &&
          widget.initialCollection != 'All') {
        songResult = await _loadSongFromCollection(widget.initialCollection!);
      }

      if (songResult == null || songResult.song == null) {
        debugPrint('🔄 [SongLyricsPage] Falling back to general song lookup');
        songResult =
            await _songRepo.getSongByNumberWithStatus(widget.songNumber);
      }

      if (songResult.song == null) {
        throw Exception('Song #${widget.songNumber} not found.');
      }

      if (mounted) {
        setState(() {
          _isOnline = songResult!.isOnline;
          // ✅ NEW: Store current song for tracking
          _currentSong = songResult.song;
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        songResult.song!.isFavorite =
            await _favRepo.isSongFavorite(songResult.song!.number);
      }

      debugPrint('✅ [SongLyricsPage] Song loaded: ${songResult.song!.title}');
      return songResult;
    } catch (e) {
      debugPrint('❌ [SongLyricsPage] Error finding song: $e');
      rethrow;
    }
  }

  Future<SongWithStatusResult?> _loadSongFromCollection(
      String collectionId) async {
    try {
      debugPrint('🎯 [SongLyricsPage] Loading from collection: $collectionId');

      if (collectionId == 'Favorites') {
        final result =
            await _songRepo.getSongByNumberWithStatus(widget.songNumber);
        if (result.song != null) {
          result.song!.isFavorite = true;
        }
        return result;
      }

      final separatedCollections = await _songRepo.getCollectionsSeparated();
      final collectionSongs = separatedCollections[collectionId];

      if (collectionSongs != null) {
        final song = collectionSongs.firstWhere(
          (s) => s.number == widget.songNumber,
          orElse: () =>
              throw Exception('Song not found in collection $collectionId'),
        );

        debugPrint(
            '✅ [SongLyricsPage] Found song in collection $collectionId: ${song.title}');
        return SongWithStatusResult(song: song, isOnline: true);
      }

      return null;
    } catch (e) {
      debugPrint('⚠️  [SongLyricsPage] Collection-specific loading failed: $e');
      return null;
    }
  }

  void _toggleFavorite(Song song) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save favorites.")),
      );
      return;
    }
    
    // Get current status from cache
    final isCurrentlyFavorite = await _favRepo.isSongFavorite(song.number);
    
    // Toggle favorite status - the cache will update immediately
    await _favRepo.toggleFavoriteStatus(song.number, isCurrentlyFavorite);
    
    // The UI will update automatically via the listener
  }

  void _changeFontSize(double delta) {
    final newSize = (_fontSize + delta).clamp(12.0, 30.0);
    setState(() {
      _fontSize = newSize;
    });
    _prefsService.saveFontSize(newSize);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongWithStatusResult?>(
      future: _songWithStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data?.song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Song Not Found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error?.toString() ??
                          'Song #${widget.songNumber} could not be found${widget.initialCollection != null ? " in ${widget.initialCollection}" : ""}.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final song = snapshot.data!.song!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = AppConstants.getDeviceType(constraints.maxWidth);
            if (deviceType == DeviceType.mobile) {
              return _buildMobileLayout(song, deviceType);
            } else {
              return _buildTabletDesktopLayout(song, deviceType);
            }
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(Song song, DeviceType deviceType) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ✅ EXTRACTED: Header component
                  SongHeaderWidget(
                    song: song,
                    initialCollection: widget.initialCollection,
                    isOnline: _isOnline,
                    deviceType: deviceType,
                    onFontSizeIncrease: () => _changeFontSize(2.0),
                    onFontSizeDecrease: () => _changeFontSize(-2.0),
                  ),

                  // ✅ EXTRACTED: Lyrics component
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: LyricsDisplayWidget(
                      song: song,
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                      textAlign: _textAlign,
                      deviceType: deviceType,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child:
                        SizedBox(height: 120), // Extra space for bottom player
                  ),
                ],
              ),

              // ✅ FIXED: Floating player with improved visibility
              const FloatingAudioPlayer(),
            ],
          ),

          // ✅ EXTRACTED: Mobile controls with emergency play button
          bottomNavigationBar: SongControlsWidget(
            song: song,
            initialCollection: widget.initialCollection,
            isOnline: _isOnline,
            fontSize: _fontSize,
            onFontSizeIncrease: () => _changeFontSize(2.0),
            onFontSizeDecrease: () => _changeFontSize(-2.0),
            onToggleFavorite: () => _toggleFavorite(song),
            deviceType: DeviceType.mobile,
            isMobileBottomBar: true,
          ),
        );
      },
    );
  }

  Widget _buildTabletDesktopLayout(Song song, DeviceType deviceType) {
    final controlsWidth = MediaQuery.of(context).size.width * 0.35;
    double finalControlsWidth;
    double minControlsWidth;
    double maxControlsWidth;

    if (deviceType == DeviceType.tablet) {
      minControlsWidth = 320.0;
      maxControlsWidth = 450.0;
    } else if (deviceType == DeviceType.desktop) {
      minControlsWidth = 380.0;
      maxControlsWidth = 500.0;
    } else if (deviceType == DeviceType.largeDesktop) {
      minControlsWidth = 400.0;
      maxControlsWidth = 600.0;
    } else {
      minControlsWidth = 400.0;
      maxControlsWidth = 550.0;
    }

    finalControlsWidth =
        controlsWidth.clamp(minControlsWidth, maxControlsWidth);

    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ✅ EXTRACTED: Header component
                  SongHeaderWidget(
                    song: song,
                    initialCollection: widget.initialCollection,
                    isOnline: _isOnline,
                    deviceType: deviceType,
                    onFontSizeIncrease: () => _changeFontSize(2.0),
                    onFontSizeDecrease: () => _changeFontSize(-2.0),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ EXTRACTED: Desktop controls component
                          SizedBox(
                            width: finalControlsWidth,
                            child: SongControlsWidget(
                              song: song,
                              initialCollection: widget.initialCollection,
                              isOnline: _isOnline,
                              fontSize: _fontSize,
                              onFontSizeIncrease: () => _changeFontSize(2.0),
                              onFontSizeDecrease: () => _changeFontSize(-2.0),
                              onToggleFavorite: () => _toggleFavorite(song),
                              deviceType: deviceType,
                            ),
                          ),

                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.3),
                          ),

                          // ✅ EXTRACTED: Lyrics column
                          Expanded(
                            child: _buildLyricsColumn(song, deviceType),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ FIXED: Floating player with improved visibility
              const FloatingAudioPlayer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricsColumn(Song song, DeviceType deviceType) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: LyricsDisplayWidget(
            song: song,
            fontSize: _fontSize,
            fontFamily: _fontFamily,
            textAlign: _textAlign,
            deviceType: deviceType,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFooter(context, deviceType),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, DeviceType deviceType) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);
    final theme = Theme.of(context);

    return Column(
      children: [
        const Divider(),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red,
              size: 16 * scale,
            ),
            SizedBox(width: spacing * 0.5),
            Text(
              'Made With Love: HaweeInc',
              style: TextStyle(
                fontSize: 14 * scale,
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.5),
        Text(
          'Lagu Pujian Masa Ini © ${DateTime.now().year}',
          style: TextStyle(
            fontSize: 12 * scale,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
