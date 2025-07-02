import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/utils/sharing_utils.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/reports/presentation/report_song_bottom_sheet.dart';

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
  late PreferencesService _prefsService;

  // ✅ NEW: Changed to support status tracking
  Future<SongWithStatusResult?>? _songWithStatusFuture;

  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;

  bool _isAppBarCollapsed = false;
  // ✅ NEW: Track online status
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadSettings().then((_) {
      if (mounted) {
        setState(() {
          // ✅ UPDATED: Use new method with status
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

  // ✅ UPDATED: New method using getSongByNumberWithStatus
  Future<SongWithStatusResult?> _findSongWithStatus() async {
    try {
      debugPrint(
          '[SongLyricsPage] 🔍 Finding song ${widget.songNumber} with status...');

      final songWithStatus =
          await _songRepo.getSongByNumberWithStatus(widget.songNumber);

      if (songWithStatus.song == null) {
        throw Exception('Song #${widget.songNumber} not found.');
      }

      // ✅ NEW: Update online status
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

      debugPrint(
          '[SongLyricsPage] ✅ Song found: ${songWithStatus.song!.title} (${songWithStatus.isOnline ? "ONLINE" : "OFFLINE"})');
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
      context: context,
      text: textToCopy,
      message: 'Lyrics copied to clipboard!',
    );
  }

  void _shareSong(Song song) {
    final lyrics = song.verses.map((v) => v.lyrics).join('\n\n');
    final textToShare =
        'Check out this song from LPMI!\n\nLPMI #${song.number}: ${song.title}\n\n$lyrics';

    SharingUtils.showShareOptions(
      context: context,
      text: textToShare,
      title: song.title,
      subtitle: 'LPMI #${song.number}',
    );
  }

  void _showReportDialog(Song song) {
    // ✅ NEW: Show offline message if trying to report while offline
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Reporting requires internet connection. Please connect and try again.'),
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

  // ✅ NEW: Build status indicator widget (matches main page style)
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: _isOnline
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Local',
            style: TextStyle(
              fontSize: 11,
              color: _isOnline
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                ),
              ));
        }

        // ✅ UPDATED: Extract song from SongWithStatusResult
        final songWithStatus = snapshot.data!;
        final song = songWithStatus.song!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, song),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verse = song.verses[index];
                      final theme = Theme.of(context);
                      final isKorus = verse.number.toLowerCase() == 'korus';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (song.verses.length > 1) ...[
                              Text(
                                verse.number,
                                style: TextStyle(
                                  fontSize: _fontSize + 4,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: isKorus
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SelectableText(
                              verse.lyrics,
                              textAlign: _textAlign,
                              style: TextStyle(
                                fontSize: _fontSize,
                                fontFamily: _fontFamily,
                                height: 1.6,
                                fontStyle: isKorus
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: song.verses.length,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(context, song),
        );
      },
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
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _toggleFavorite(song),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(isFavorite ? 'Favorited' : 'Favorite'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isFavorite ? Colors.red : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                    : theme.colorScheme.onPrimaryContainer,
              ),
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
                    : theme.colorScheme.onPrimaryContainer,
              ),
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
                    isDark ? Colors.red.shade300 : Colors.red.shade700,
              ),
              child: Icon(Icons.report_problem,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Song song) {
    final theme = Theme.of(context);
    final double collapsedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: theme.colorScheme.primary,
      title: _isAppBarCollapsed
          ? Row(
              children: [
                Expanded(
                  child: Text(song.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                // ✅ NEW: Status indicator in collapsed app bar
                _buildStatusIndicator(),
              ],
            )
          : null,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isCollapsed = constraints.maxHeight <= collapsedHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isAppBarCollapsed != isCollapsed) {
              setState(() {
                _isAppBarCollapsed = isCollapsed;
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
                Image.asset('assets/images/header_image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: theme.colorScheme.primary)),
                Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('LPMI #${song.number}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          // ✅ NEW: Status indicator in expanded app bar
                          _buildStatusIndicator(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(song.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black54)
                              ])),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      actions: [
        PopupMenuButton<String>(
          iconColor: Colors.white,
          color: theme.popupMenuTheme.color,
          shape: theme.popupMenuTheme.shape,
          onSelected: (value) {
            if (value == 'increase_font') _changeFontSize(2.0);
            if (value == 'decrease_font') _changeFontSize(-2.0);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
                value: 'decrease_font',
                child: ListTile(
                    leading:
                        Icon(Icons.text_decrease, color: theme.iconTheme.color),
                    title: Text('Decrease Font',
                        style: theme.popupMenuTheme.textStyle))),
            PopupMenuItem(
                value: 'increase_font',
                child: ListTile(
                    leading:
                        Icon(Icons.text_increase, color: theme.iconTheme.color),
                    title: Text('Increase Font',
                        style: theme.popupMenuTheme.textStyle))),
          ],
        )
      ],
    );
  }
}
