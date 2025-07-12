// lib/src/features/songbook/presentation/pages/song_lyrics_page.dart
// ✅ UPDATED: Implemented the new floating vertical audio player.

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
import 'package:lpmi40/src/widgets/floating_audio_player.dart'; // ✅ NEW: Import floating player
import 'package:lpmi40/utils/constants.dart';

class SongLyricsPage extends StatefulWidget {
  final String songNumber;

  const SongLyricsPage({
    super.key,
    required this.songNumber,
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

  Future<SongWithStatusResult?> _findSongWithStatus() async {
    try {
      final songWithStatus =
          await _songRepo.getSongByNumberWithStatus(widget.songNumber);
      if (songWithStatus.song == null) {
        throw Exception('Song #${widget.songNumber} not found.');
      }
      if (mounted) {
        setState(() {
          _isOnline = songWithStatus.isOnline;
        });
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        songWithStatus.song!.isFavorite =
            await _favRepo.isSongFavorite(songWithStatus.song!.number);
      }
      return songWithStatus;
    } catch (e) {
      debugPrint('[SongLyricsPage] ❌ Error finding song: $e');
      rethrow;
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
    final lyrics = song.verses.map((v) => v.lyrics).join('\n\n');
    final textToCopy = 'LPMI #${song.number}: ${song.title}\n\n$lyrics';
    SharingUtils.copyToClipboard(
        context: context, text: textToCopy, message: 'Lyrics copied!');
  }

  void _shareSong(Song song) {
    final lyrics = song.verses.map((v) => v.lyrics).join('\n\n');
    final textToShare = 'LPMI #${song.number}: ${song.title}\n\n$lyrics';
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

  // ✅ UPDATED: This now triggers the SongProvider to handle playback
  Future<void> _handlePlayAction(Song song) async {
    if (!_isPremium) {
      await _showPremiumUpgradeDialog('audio_playback');
      return;
    }
    // Let the provider handle the logic of playing, pausing, and premium checks
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
                child: Text(snapshot.error?.toString() ?? 'Song not found.'),
              )));
        }

        final song = snapshot.data!.song!;

        // ✅ NEW: Wrapped the UI in a Stack to accommodate the floating player
        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final deviceType =
                    AppConstants.getDeviceType(constraints.maxWidth);
                switch (deviceType) {
                  case DeviceType.mobile:
                    return _buildMobileLayout(song);
                  case DeviceType.tablet:
                    return _buildTabletLayout(song);
                  case DeviceType.desktop:
                    return _buildDesktopLayout(song);
                  case DeviceType.largeDesktop:
                    return _buildLargeDesktopLayout(song);
                }
              },
            ),
            // ✅ NEW: The floating player is now part of the UI
            const FloatingAudioPlayer(),
          ],
        );
      },
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(Song song) {
    final deviceType = DeviceType.mobile;
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildResponsiveAppBar(context, song, deviceType),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                contentPadding, spacing, contentPadding, spacing),
            sliver: _buildLyricsSliver(song, deviceType),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: contentPadding),
              child: _buildFooter(context, deviceType),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: spacing * 6),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context, song),
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(Song song) {
    final deviceType = DeviceType.tablet;
    final headerHeight = AppConstants.getHeaderHeight(deviceType);

    final controlsWidth = MediaQuery.of(context).size.width * 0.35;
    final minControlsWidth = 320.0;
    final maxControlsWidth = 450.0;
    final finalControlsWidth =
        controlsWidth.clamp(minControlsWidth, maxControlsWidth);

    return Scaffold(
      body: Stack(
        children: [
          _buildFullWidthHeader(context, song, headerHeight, deviceType),
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
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
          _buildFloatingBackButton(deviceType),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(Song song) {
    final deviceType = DeviceType.desktop;
    final headerHeight = AppConstants.getHeaderHeight(deviceType);

    final controlsWidth = MediaQuery.of(context).size.width * 0.28;
    final minControlsWidth = 380.0;
    final maxControlsWidth = 500.0;
    final finalControlsWidth =
        controlsWidth.clamp(minControlsWidth, maxControlsWidth);

    return Scaffold(
      body: Stack(
        children: [
          _buildFullWidthHeader(context, song, headerHeight, deviceType),
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
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
          _buildFloatingBackButton(deviceType),
        ],
      ),
    );
  }

  // Large Desktop Layout
  Widget _buildLargeDesktopLayout(Song song) {
    final deviceType = DeviceType.largeDesktop;
    final headerHeight = AppConstants.getHeaderHeight(deviceType);

    final controlsWidth = MediaQuery.of(context).size.width * 0.25;
    final minControlsWidth = 400.0;
    final maxControlsWidth = 550.0;
    final finalControlsWidth =
        controlsWidth.clamp(minControlsWidth, maxControlsWidth);

    return Scaffold(
      body: Stack(
        children: [
          _buildFullWidthHeader(context, song, headerHeight, deviceType),
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
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
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: _buildLyricsColumn(song, deviceType),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFloatingBackButton(deviceType),
        ],
      ),
    );
  }

  Widget _buildFullWidthHeader(
      BuildContext context, Song song, double height, DeviceType deviceType) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Stack(
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
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ REMOVED: The old `_buildAudioControlsSection` is no longer needed.
  // The floating player handles this now.

  Widget _buildControlsColumn(Song song, DeviceType deviceType) {
    final theme = Theme.of(context);
    final isFavorite = song.isFavorite;
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);
    final scale = AppConstants.getTypographyScale(deviceType);

    return SingleChildScrollView(
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LPMI #${song.number}',
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

          // ✅ NEW: Play button that triggers the SongProvider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handlePlayAction(song),
              icon: const Icon(Icons.play_circle_fill),
              label: Text(
                'Play Audio',
                style: TextStyle(fontSize: 14 * scale),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              contentPadding, spacing, contentPadding, spacing),
          sliver: _buildLyricsSliver(song, deviceType),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            child: _buildFooter(context, deviceType),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: spacing * 2),
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

  Widget _buildFloatingBackButton(DeviceType deviceType) {
    final spacing = AppConstants.getSpacing(deviceType);
    final scale = AppConstants.getTypographyScale(deviceType);

    return Positioned(
      top: 40 + (spacing * 0.5),
      left: spacing,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24 * scale,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                              'LPMI #${song.number}',
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

  // ✅ UPDATED: Removed the redundant play button from the bottom bar
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
