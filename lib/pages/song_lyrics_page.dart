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
  late double fontSize;
  late String fontStyle;
  late TextAlign textAlign;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Initialize the settings with values passed from the widget
    fontSize = widget.fontSize;
    fontStyle = widget.fontStyle;
    textAlign = widget.textAlign;
  }

  String get currentDate {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Added to Favorites' : 'Removed from Favorites'),
      ),
    );
  }

  void _shareLyrics() {
    final lyrics = widget.song.verses.map((verse) => '${verse.number}. ${verse.lyrics}').join('\n\n');
    Share.share('${widget.song.title}\n\n$lyrics');
  }

  void _copyLyrics() {
    final lyrics = widget.song.verses.map((verse) => '${verse.number}. ${verse.lyrics}').join('\n\n');
    Clipboard.setData(ClipboardData(text: lyrics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lyrics copied to clipboard')),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsPage(
        currentFontSize: fontSize,
        currentFontStyle: fontStyle,
        currentTextAlign: textAlign,
        onFontSizeChange: (newFontSize) {
          setState(() {
            fontSize = newFontSize ?? fontSize;
          });
        },
        onFontStyleChange: (newFontStyle) {
          setState(() {
            fontStyle = newFontStyle ?? fontStyle;
          });
        },
        onTextAlignChange: (newTextAlign) {
          setState(() {
            textAlign = newTextAlign ?? textAlign;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140.0),
        child: AppBar(
          automaticallyImplyLeading: true,
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
                      widget.song.title,
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
                    Text(
                      currentDate,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: widget.song.verses.length,
          itemBuilder: (context, index) {
            final verse = widget.song.verses[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verse.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueAccent, // Dark blue color for verse number
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    verse.lyrics,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: fontStyle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.share),
            label: 'Share Lyrics',
            onTap: _shareLyrics,
          ),
          SpeedDialChild(
            child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            label: isFavorite ? 'Unfavorite' : 'Favorite',
            onTap: _toggleFavorite,
          ),
          SpeedDialChild(
            child: const Icon(Icons.copy),
            label: 'Copy Lyrics',
            onTap: _copyLyrics,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.pop(context);
              break;
            case 2:
              _showSettings(context);
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            label: 'Toggle Theme',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
