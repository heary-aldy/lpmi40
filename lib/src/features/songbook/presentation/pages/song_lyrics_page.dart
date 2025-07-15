// lib/src/features/songbook/presentation/pages/song_lyrics_page.dart
// ✅ UPDATED: Added collection context support to fix navigation issues
// ✅ FIXED: Now properly loads songs from correct collections instead of defaulting to LPMI
// ✅ PREMIUM: All premium features preserved

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/utils/sharing_utils.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/reports/presentation/report_song_bottom_sheet.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/widgets/floating_audio_player.dart';
import 'package:lpmi40/utils/constants.dart';

class SongLyricsPage extends StatefulWidget {
  final String songNumber;
  final String? initialCollection; // ✅ NEW: Collection context
  final Song? songObject; // ✅ NEW: Direct song object

  const SongLyricsPage({
    super.key,
    required this.songNumber,
    this.initialCollection, // ✅ NEW: Optional collection context
    this.songObject, // ✅ NEW: Optional direct song object
  });

  @override
  State<SongLyricsPage> createState() => _SongLyricsPageState();
}

class _SongLyricsPageState extends State<SongLyricsPage> {
  final SongRepository _songRepo = SongRepository();
  final FavoritesRepository _favRepo = FavoritesRepository();
  final PremiumService _premiumService = PremiumService();
  late PreferencesService _prefsService;

  Future<SongWithStatusResult?>? _songWithStatusFuture;

  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;

  bool _isAppBarCollapsed = false;
  bool _isOnline = true;
  bool _isPremium = false;
  bool _isLoadingPremium = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadPremiumStatus();
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

  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoadingPremium = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPremium = false;
        });
      }
    }
  }

  // ✅ UPDATED: Enhanced song finding with collection context support
  Future<SongWithStatusResult?> _findSongWithStatus() async {
    try {
      debugPrint(
          '🔍 [SongLyricsPage] Loading song ${widget.songNumber} from collection: ${widget.initialCollection}');

      // ✅ OPTIMIZATION: If song object is provided directly, use it
      if (widget.songObject != null) {
        debugPrint('✅ [SongLyricsPage] Using provided song object');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          widget.songObject!.isFavorite =
              await _favRepo.isSongFavorite(widget.songObject!.number);
        }

        return SongWithStatusResult(
          song: widget.songObject!,
          isOnline: true, // Assume online if song object is provided
        );
      }

      // ✅ NEW: Collection-aware song loading
      SongWithStatusResult? songResult;

      if (widget.initialCollection != null &&
          widget.initialCollection != 'All') {
        // Try to load from specific collection first
        songResult = await _loadSongFromCollection(widget.initialCollection!);
      }

      // ✅ FALLBACK: If collection-specific loading fails, try general lookup
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
        });
      }

      // Load favorite status
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

  // ✅ NEW: Collection-specific song loading
  Future<SongWithStatusResult?> _loadSongFromCollection(
      String collectionId) async {
    try {
      debugPrint('🎯 [SongLyricsPage] Loading from collection: $collectionId');

      if (collectionId == 'Favorites') {
        // For favorites, use the general lookup but ensure it's marked as favorite
        final result =
            await _songRepo.getSongByNumberWithStatus(widget.songNumber);
        if (result.song != null) {
          result.song!.isFavorite = true;
        }
        return result;
      }

      // ✅ ENHANCED: Try to get collection-separated songs
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
        return SongWithStatusResult(
          song: song,
          isOnline: true,
        );
      }

      return null;
    } catch (e) {
      debugPrint('⚠️  [SongLyricsPage] Collection-specific loading failed: $e');
      return null;
    }
  }

  void _toggleFavorite(Song song) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to save favorites.")));
      return;
    }
    final isCurrentlyFavorite = song.isFavorite;
    setState(() {
      song.isFavorite = !isCurrentlyFavorite;
    });
    _favRepo.toggleFavoriteStatus(song.number, isCurrentlyFavorite);
  }

  void _changeFontSize(double delta) {
    final newSize = (_fontSize + delta).clamp(12.0, 30.0);
    setState(() {
      _fontSize = newSize;
    });
    _prefsService.saveFontSize(newSize);
  }

  void _copyToClipboard(Song song) {
    final lyrics = song.verses.map((verse) => verse.lyrics).join('\n\n');
    // ✅ ENHANCED: Include collection context in copied text
    final collectionText = widget.initialCollection != null &&
            widget.initialCollection != 'All' &&
            widget.initialCollection != 'Favorites'
        ? ' (${widget.initialCollection})'
        : '';
    final textToCopy =
        'LPMI #${song.number}$collectionText: ${song.title}\n\n$lyrics';
    SharingUtils.copyToClipboard(
        context: context, text: textToCopy, message: 'Lyrics copied!');
  }

  void _shareSong(Song song) {
    final lyrics = song.verses.map((verse) => verse.lyrics).join('\n\n');
    // ✅ ENHANCED: Include collection context in shared text
    final collectionText = widget.initialCollection != null &&
            widget.initialCollection != 'All' &&
            widget.initialCollection != 'Favorites'
        ? ' (${widget.initialCollection})'
        : '';
    final textToShare =
        'LPMI #${song.number}$collectionText: ${song.title}\n\n$lyrics';
    SharingUtils.showShareOptions(
        context: context, text: textToShare, title: song.title);
  }

  void _showReportDialog(Song song) {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reporting requires an internet connection.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportSongBottomSheet(song: song),
    );
  }

  Future<void> _handlePlayAction(Song song) async {
    if (!_isPremium) {
      await _showPremiumUpgradeDialog('audio_playback');
      return;
    }
    context.read<SongProvider>().selectSong(song);
  }

  Future<void> _showPremiumUpgradeDialog(String feature) async {
    await showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: feature,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongWithStatusResult?>(
      future: _songWithStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
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
              )));
        }

        final song = snapshot.data!.song!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = AppConstants.getDeviceType(constraints.maxWidth);
            if (deviceType == DeviceType.mobile) {
              return _buildMobileLayout(song);
            } else {
              return _buildTabletDesktopLayout(song, deviceType);
            }
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(Song song) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildResponsiveAppBar(context, song, DeviceType.mobile),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: _buildLyricsSliver(song, DeviceType.mobile),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFooter(context, DeviceType.mobile),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Space for bottom action bar
              ),
            ],
          ),
          // ✅ PREMIUM: Floating audio player restored
          const FloatingAudioPlayer(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context, song),
    );
  }

  Widget _buildTabletDesktopLayout(Song song, DeviceType deviceType) {
    final controlsWidth = MediaQuery.of(context).size.width * 0.35;
    double finalControlsWidth;
    double minControlsWidth;
    double maxControlsWidth;

    // ✅ FIXED: Use conditional statements instead of switch expressions
    if (deviceType == DeviceType.tablet) {
      minControlsWidth = 320.0;
      maxControlsWidth = 450.0;
    } else if (deviceType == DeviceType.desktop) {
      minControlsWidth = 380.0;
      maxControlsWidth = 500.0;
    } else {
      // largeDesktop
      minControlsWidth = 400.0;
      maxControlsWidth = 550.0;
    }

    finalControlsWidth =
        controlsWidth.clamp(minControlsWidth, maxControlsWidth);

    return Scaffold(
      // ✅ FIXED: Proper body structure to prevent layout errors
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildResponsiveAppBar(context, song, deviceType),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: finalControlsWidth,
                        child: _buildControlsColumn(song, deviceType),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildLyricsColumn(song, deviceType),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ✅ PREMIUM: Floating audio player restored
          const FloatingAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildControlsColumn(Song song, DeviceType deviceType) {
    final theme = Theme.of(context);
    final isFavorite = song.isFavorite;
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // ✅ ENHANCED: Show collection context in controls
    final collectionDisplay = widget.initialCollection != null &&
            widget.initialCollection != 'All' &&
            widget.initialCollection != 'Favorites'
        ? ' • ${widget.initialCollection}'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LPMI #${song.number}$collectionDisplay',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * scale,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          Text(
            song.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 20) * scale,
            ),
          ),
          SizedBox(height: spacing * 0.75),
          _buildStatusIndicator(),
          SizedBox(height: spacing * 1.5),

          // ✅ PREMIUM: Audio button with premium gate restored
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handlePlayAction(song),
              icon: const Icon(Icons.play_circle_fill),
              label: Text(
                _isPremium ? 'Play Audio' : 'Premium Audio',
                style: TextStyle(fontSize: 14 * scale),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPremium ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
              ),
            ),
          ),
          SizedBox(height: spacing * 1.5),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _toggleFavorite(song),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18 * scale,
              ),
              label: Text(
                isFavorite ? 'Favorited' : 'Favorite',
                style: TextStyle(fontSize: 14 * scale),
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isFavorite ? Colors.red : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
              ),
            ),
          ),
          SizedBox(height: spacing * 0.75),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _copyToClipboard(song),
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
                  onPressed: () => _shareSong(song),
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
                  onPressed: () => _showReportDialog(song),
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
                    icon: Icon(Icons.remove_circle_outline, size: 20 * scale),
                    onPressed: () => _changeFontSize(-2.0),
                    tooltip: 'Decrease font size',
                  ),
                  Container(
                    constraints: BoxConstraints(minWidth: 30 * scale),
                    child: Text(
                      _fontSize.toStringAsFixed(0),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize:
                            (theme.textTheme.bodyLarge?.fontSize ?? 14) * scale,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, size: 20 * scale),
                    onPressed: () => _changeFontSize(2.0),
                    tooltip: 'Increase font size',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsColumn(Song song, DeviceType deviceType) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: _buildLyricsSliver(song, deviceType),
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

  Widget _buildLyricsSliver(Song song, DeviceType deviceType) {
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final verse = song.verses[index];
          final theme = Theme.of(context);
          final isKorus = verse.number.toLowerCase() == 'korus';

          return Padding(
            padding: EdgeInsets.only(bottom: spacing * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (song.verses.length > 1) ...[
                  Text(
                    verse.number,
                    style: TextStyle(
                      fontSize: (_fontSize + 4) * scale,
                      fontWeight: FontWeight.bold,
                      fontStyle: isKorus ? FontStyle.italic : FontStyle.normal,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                ],
                SelectableText(
                  verse.lyrics,
                  textAlign: _textAlign,
                  style: TextStyle(
                    fontSize: _fontSize * scale,
                    fontFamily: _fontFamily,
                    height: 1.6,
                    fontStyle: isKorus ? FontStyle.italic : FontStyle.normal,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: song.verses.length,
      ),
    );
  }

  SliverAppBar _buildResponsiveAppBar(
      BuildContext context, Song song, DeviceType deviceType) {
    final theme = Theme.of(context);
    final double collapsedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final headerHeight = AppConstants.getHeaderHeight(deviceType);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SliverAppBar(
      expandedHeight: headerHeight,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: theme.colorScheme.primary,
      title: _isAppBarCollapsed
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing * 0.5),
                _buildStatusIndicator(),
              ],
            )
          : null,
      actions: [
        // ✅ PREMIUM: Audio button in app bar for premium users
        if (_isPremium)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Play Audio',
            onPressed: () => _handlePlayAction(song),
            iconSize: 24 * scale,
          ),
        PopupMenuButton<String>(
          iconColor: Colors.white,
          icon: Icon(Icons.more_vert, size: 24 * scale),
          color: theme.popupMenuTheme.color,
          shape: theme.popupMenuTheme.shape,
          onSelected: (value) {
            if (value == 'increase_font') _changeFontSize(2.0);
            if (value == 'decrease_font') _changeFontSize(-2.0);
            if (value == 'upgrade_premium') {
              _showPremiumUpgradeDialog('audio_playback');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'decrease_font',
              child: ListTile(
                leading: Icon(
                  Icons.text_decrease,
                  color: theme.iconTheme.color,
                  size: 20 * scale,
                ),
                title: Text(
                  'Decrease Font',
                  style: theme.popupMenuTheme.textStyle?.copyWith(
                    fontSize: (theme.popupMenuTheme.textStyle?.fontSize ?? 14) *
                        scale,
                  ),
                ),
              ),
            ),
            PopupMenuItem(
              value: 'increase_font',
              child: ListTile(
                leading: Icon(
                  Icons.text_increase,
                  color: theme.iconTheme.color,
                  size: 20 * scale,
                ),
                title: Text(
                  'Increase Font',
                  style: theme.popupMenuTheme.textStyle?.copyWith(
                    fontSize: (theme.popupMenuTheme.textStyle?.fontSize ?? 14) *
                        scale,
                  ),
                ),
              ),
            ),
            // ✅ PREMIUM: Upgrade option for non-premium users
            if (!_isPremium) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'upgrade_premium',
                child: ListTile(
                  leading: Icon(
                    Icons.star,
                    color: Colors.purple,
                    size: 20 * scale,
                  ),
                  title: Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var isCollapsed = constraints.maxHeight <= collapsedHeight;
          if (isCollapsed != _isAppBarCollapsed) {
            Future.microtask(() {
              if (mounted) setState(() => _isAppBarCollapsed = isCollapsed);
            });
          }
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
            title: const Text(''),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/header_image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: theme.colorScheme.primary),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: spacing,
                  left: spacing,
                  right: 72 * scale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LPMI #${song.number}${widget.initialCollection != null && widget.initialCollection != 'All' && widget.initialCollection != 'Favorites' ? ' • ${widget.initialCollection}' : ''}',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing * 0.5),
                          _buildStatusIndicator(),
                        ],
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        song.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 2, color: Colors.black54)
                          ],
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
    );
  }

  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: _isOnline
              ? (isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green.withOpacity(0.1))
              : (isDark
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: _isOnline
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
        const SizedBox(width: 4),
        Text(_isOnline ? 'Online' : 'Local',
            style: TextStyle(
                fontSize: 11,
                color: _isOnline
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, Song song) {
    final isFavorite = song.isFavorite;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            top: BorderSide(
                color: theme.dividerColor.withOpacity(0.3), width: 1)),
        boxShadow: isDark
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2))
              ]
            : null,
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _toggleFavorite(song),
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              label: Text(isFavorite ? 'Favorited' : 'Favorite'),
              style: FilledButton.styleFrom(
                  backgroundColor:
                      isFavorite ? Colors.red : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _copyToClipboard(song),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: isDark
                    ? theme.colorScheme.surface.withOpacity(0.8)
                    : theme.colorScheme.primaryContainer,
                foregroundColor: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer),
            child: const Icon(Icons.copy),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _shareSong(song),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: isDark
                    ? theme.colorScheme.surface.withOpacity(0.8)
                    : theme.colorScheme.primaryContainer,
                foregroundColor: isDark
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer),
            child: const Icon(Icons.share),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _showReportDialog(song),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: isDark
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.withOpacity(0.1),
                foregroundColor:
                    isDark ? Colors.red.shade300 : Colors.red.shade700),
            child: Icon(Icons.report_problem,
                color: isDark ? Colors.red.shade300 : Colors.red.shade700),
          ),
        ]),
      ),
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
