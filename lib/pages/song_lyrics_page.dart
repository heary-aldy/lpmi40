import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lpmi40/models/song.dart';
import 'package:lpmi40/pages/settings_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class SongLyricsPage extends StatefulWidget {
  final Song song;
  final double fontSize;
  final String fontStyle;
  final TextAlign textAlign;
  final bool isDarkMode;

  const SongLyricsPage({
    super.key,
    required this.song,
    required this.fontSize,
    required this.fontStyle,
    required this.textAlign,
    required this.isDarkMode,
  });

  @override
  SongLyricsPageState createState() => SongLyricsPageState();
}

class SongLyricsPageState extends State<SongLyricsPage> {
  // Constants
  static const Duration _snackBarDuration = Duration(seconds: 2);
  
  // State variables
  late double _fontSize;
  late String _fontStyle;
  late TextAlign _textAlign;
  late bool _isFavorite;
  late ScrollController _scrollController;
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    // Initialize the settings with values passed from the widget
    _fontSize = widget.fontSize;
    _fontStyle = widget.fontStyle;
    _textAlign = widget.textAlign;
    _isFavorite = widget.song.isFavorite;
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    // Show scroll-to-top button when user scrolls down
    if (_scrollController.offset >= 300 && !_showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = true;
      });
    } else if (_scrollController.offset < 300 && _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = false;
      });
    }
  }
  
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  String get _currentDate {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      widget.song.isFavorite = _isFavorite; // Update the song model
    });
    
    _showSnackBar(_isFavorite ? 'Added to Favorites' : 'Removed from Favorites');
  }

  void _shareLyrics() async {
    try {
      final lyrics = '${widget.song.title}\n\n${_formatLyricsForSharing()}';
      await Share.share(lyrics, subject: 'Lyrics for ${widget.song.title}');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to share lyrics: ${e.toString()}');
      }
    }
  }

  String _formatLyricsForSharing() {
    return widget.song.verses.map((verse) => 
      '${verse.number}. ${verse.lyrics}'
    ).join('\n\n');
  }

  void _copyLyrics() {
    try {
      Clipboard.setData(ClipboardData(text: _formatLyricsForSharing()));
      _showSnackBar('Lyrics copied to clipboard');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to copy lyrics');
      }
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: _snackBarDuration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) => SettingsPage(
        currentFontSize: _fontSize,
        currentFontStyle: _fontStyle,
        currentTextAlign: _textAlign,
        isDarkMode: widget.isDarkMode,
        onFontSizeChange: (newFontSize) {
          if (newFontSize != null) {
            setState(() {
              _fontSize = newFontSize;
            });
          }
        },
        onFontStyleChange: (newFontStyle) {
          if (newFontStyle != null) {
            setState(() {
              _fontStyle = newFontStyle;
            });
          }
        },
        onTextAlignChange: (newTextAlign) {
          if (newTextAlign != null) {
            setState(() {
              _textAlign = newTextAlign;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildLyricsContent(),
      floatingActionButton: _buildSpeedDial(),
    );
  }
  
  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(140.0),
      child: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox(), // Remove default title
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.song.number} | ${widget.song.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(2.0, 2.0),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        _currentDate,
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 20,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: _shareLyrics,
                        tooltip: 'Share lyrics',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLyricsContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: widget.song.verses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final verse = widget.song.verses[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: widget.isDarkMode 
                    ? Colors.grey.withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verse.number,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      verse.lyrics,
                      textAlign: _textAlign,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontFamily: _fontStyle,
                        height: 1.5,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_showScrollToTopButton)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton.small(
              heroTag: 'scrollToTop',
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }
  
  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.more_vert,
      activeIcon: Icons.close,
      backgroundColor: Colors.blue,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'More options',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.text_format),
          label: 'Text Settings',
          onTap: () => _showSettings(context),
          backgroundColor: Colors.purple,
        ),
        SpeedDialChild(
          child: const Icon(Icons.copy),
          label: 'Copy Lyrics',
          onTap: _copyLyrics,
          backgroundColor: Colors.teal,
        ),
        SpeedDialChild(
          child: const Icon(Icons.share),
          label: 'Share Lyrics',
          onTap: _shareLyrics,
          backgroundColor: Colors.green,
        ),
        SpeedDialChild(
          child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          label: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
          onTap: _toggleFavorite,
          backgroundColor: _isFavorite ? Colors.red : Colors.pink,
        ),
      ],
    );
  }
}