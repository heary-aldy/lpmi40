import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class SongLyricsPage extends StatefulWidget {
  final Song song;
  final double fontSize;
  final String fontStyle;
  final TextAlign textAlign;
  final bool isDarkMode; // This was a required parameter

  const SongLyricsPage({
    super.key,
    required this.song,
    required this.fontSize,
    required this.fontStyle,
    required this.textAlign,
    required this.isDarkMode, // Added to the constructor
  });

  @override
  SongLyricsPageState createState() => SongLyricsPageState();
}

class SongLyricsPageState extends State<SongLyricsPage> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.song.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      widget.song.isFavorite = _isFavorite;
      // TODO: Save favorite state to Firebase/SharedPreferences
    });
    _showSnackBar(
        _isFavorite ? 'Added to Favorites' : 'Removed from Favorites');
  }

  String _formatLyricsForSharing() {
    String lyrics = widget.song.verses.map((v) => v.lyrics).join('\n\n');
    return '${widget.song.title}\n\n$lyrics';
  }

  void _shareLyrics() {
    Share.share(_formatLyricsForSharing(),
        subject: 'Lyrics for ${widget.song.title}');
  }

  void _copyLyrics() {
    Clipboard.setData(ClipboardData(text: _formatLyricsForSharing()));
    _showSnackBar('Lyrics copied to clipboard');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.song.number} | ${widget.song.title}'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLyrics,
            tooltip: 'Copy Lyrics',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLyrics,
            tooltip: 'Share Lyrics',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: widget.song.verses.length,
        itemBuilder: (context, index) {
          final verse = widget.song.verses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8.0),
                SelectableText(
                  verse.lyrics,
                  textAlign: widget.textAlign,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontFamily: widget.fontStyle,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
