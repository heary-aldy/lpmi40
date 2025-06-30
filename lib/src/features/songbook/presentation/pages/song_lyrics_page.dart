// lib/src/features/songbook/presentation/pages/song_lyrics_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
// ✅ NEW IMPORT - Report functionality
import 'package:lpmi40/src/features/reports/presentation/widgets/report_song_dialog.dart';

class SongLyricsPage extends StatefulWidget {
  final String songNumber;
  const SongLyricsPage({super.key, required this.songNumber});

  @override
  State<SongLyricsPage> createState() => _SongLyricsPageState();
}

class _SongLyricsPageState extends State<SongLyricsPage> {
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  Song? _song;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  Future<void> _loadSong() async {
    try {
      // Load song and check if it's in favorites
      final songResult =
          await _songRepository.getSongByNumber(widget.songNumber);
      final favorites = await _favoritesRepository.getFavorites();

      if (mounted) {
        setState(() {
          _song = songResult;
          _isFavorite = favorites.contains(widget.songNumber);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading song: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ USING YOUR ACTUAL METHOD: toggleFavoriteStatus
  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite || _song == null) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      // Use your existing toggleFavoriteStatus method
      await _favoritesRepository.toggleFavoriteStatus(
          widget.songNumber, _isFavorite);

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite; // Toggle the state
        });

        _showFavoriteMessage(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          _isFavorite ? Colors.green : Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _showFavoriteMessage('Error updating favorites', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  void _showFavoriteMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ✅ NEW METHOD - Report functionality
  void _showReportDialog() {
    if (_song == null) return;

    showDialog(
      context: context,
      builder: (context) => ReportSongDialog(
        songNumber: widget.songNumber,
        songTitle: _song!.title,
        verses: _song!.verses
            .map((v) => v.number)
            .where((n) => n.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_song?.title ?? 'Song ${widget.songNumber}'),
        actions: [
          // Favorite button
          if (!_isLoading) ...[
            IconButton(
              onPressed: _isTogglingFavorite ? null : _toggleFavorite,
              icon: _isTogglingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isFavorite),
                        color: _isFavorite ? Colors.red : null,
                      ),
                    ),
              tooltip:
                  _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ],

          // ✅ NEW: Report button
          IconButton(
            onPressed: () => _showReportDialog(),
            icon: const Icon(Icons.report_problem),
            tooltip: 'Report Issue',
          ),

          // Optional: Menu for other actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareSong();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Song'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _song != null
              ? _buildSongContent()
              : _buildErrorContent(),
    );
  }

  void _shareSong() {
    if (_song == null) return;

    // Simple share implementation
    final songText = '🎵 ${_song!.title}\nSong #${_song!.number}\n\n'
        '${_song!.verses.map((v) => '${v.number.isNotEmpty ? '${v.number}:\n' : ''}${v.lyrics}').join('\n\n')}\n\n'
        'Shared from Lagu Pujian Masa Ini app';

    // You can implement actual sharing here if you have share_plus package
    debugPrint('Share: $songText');
  }

  Widget _buildSongContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _song!.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _song!.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_song!.verses.length} verse${_song!.verses.length != 1 ? 's' : ''}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (_isFavorite)
                    const Icon(Icons.favorite, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Song verses
          ...List.generate(_song!.verses.length, (index) {
            final verse = _song!.verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (verse.number.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        verse.number,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SelectableText(
                    verse.lyrics,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontSize: 16.0,
                        ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Song #${_song!.number}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lagu Pujian Masa Ini',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Song not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Song #${widget.songNumber} could not be loaded.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadSong,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
