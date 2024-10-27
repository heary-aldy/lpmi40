import 'package:flutter/material.dart';
import 'package:lpmi_24/models/song.dart';
import 'settings_page.dart';

class SongLyricsPage extends StatelessWidget {
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

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsPage(
        currentFontSize: fontSize,
        currentFontStyle: fontStyle,
        currentTextAlign: textAlign,
        onFontSizeChange: (value) {
          if (value != null) Navigator.pop(context);
        },
        onFontStyleChange: (value) {
          if (value != null) Navigator.pop(context);
        },
        onTextAlignChange: (value) {
          if (value != null) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: song.verses.map((verse) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${verse.number}. ${verse.lyrics}',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: fontStyle,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              // Add functionality for theme toggle if desired on this page
              break;
            case 2:
              _showSettings(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.light_mode), // Adjust for theme if needed
            label: 'Toggle Theme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
