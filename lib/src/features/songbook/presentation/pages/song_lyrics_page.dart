import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/utils/sharing_utils.dart'; // ✅ Import our utility
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';

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

  Future<Song?>? _songFuture;

  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadSettings().then((_) {
      if (mounted) {
        setState(() {
          _songFuture = _findSong();
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

  Future<Song?> _findSong() async {
    try {
      final songDataResult = await _songRepo.getSongs();
      final allSongs = songDataResult.songs;
      final song = allSongs.firstWhere((s) => s.number == widget.songNumber);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteNumbers = await _favRepo.getFavorites();
        song.isFavorite = favoriteNumbers.contains(song.number);
      }
      return song;
    } catch (e) {
      print("Error finding song: $e");
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
    final lyrics = song.verses.map((v) => v.lyrics).join('\n\n');
    final textToCopy = 'LPMI #${song.number}: ${song.title}\n\n$lyrics';

    // ✅ SIMPLIFIED: Using utility class
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

    // ✅ SIMPLIFIED: Using utility class
    SharingUtils.showShareOptions(
      context: context,
      text: textToShare,
      title: song.title,
      subtitle: 'LPMI #${song.number}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song?>(
      future: _songFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Error: Song not found.')));
        }

        final song = snapshot.data!;

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
                                  color: Theme.of(context).primaryColor,
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
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
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
                      isFavorite ? Colors.red : Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () => _copyToClipboard(song),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(12)),
              child: const Icon(Icons.copy),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => _shareSong(song),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(12)),
              child: const Icon(Icons.share),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Song song) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/header_image.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).primaryColor,
                    )),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('LPMI #${song.number}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
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
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'increase_font') _changeFontSize(2.0);
            if (value == 'decrease_font') _changeFontSize(-2.0);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'decrease_font',
                child: ListTile(
                    leading: Icon(Icons.text_decrease),
                    title: Text('Decrease Font'))),
            const PopupMenuItem(
                value: 'increase_font',
                child: ListTile(
                    leading: Icon(Icons.text_increase),
                    title: Text('Increase Font'))),
          ],
        )
      ],
    );
  }
}
