import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as root_bundle;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:lpmi40/models/song.dart';
import 'package:lpmi40/pages/song_lyrics_page.dart';
import 'package:lpmi40/widgets/filter_buttons.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final double fontSize;
  final String fontStyle;
  final TextAlign textAlign;
  final VoidCallback onToggleTheme;
  final ValueChanged<double?> onFontSizeChange;
  final ValueChanged<String?> onFontStyleChange;
  final ValueChanged<TextAlign?> onTextAlignChange;

  const MainPage({
    super.key,
    required this.isDarkMode,
    required this.fontSize,
    required this.fontStyle,
    required this.textAlign,
    required this.onToggleTheme,
    required this.onFontSizeChange,
    required this.onFontStyleChange,
    required this.onTextAlignChange,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Song> songs = [];
  List<Song> filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String get currentDate {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now); // e.g., "Monday, October 30, 2023"
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final jsonString = await root_bundle.rootBundle.loadString('assets/lpmi.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);

      if (!mounted) return;

      setState(() {
        songs = jsonResponse.map((data) => Song.fromJson(data)).toList();
        filteredSongs = songs;
      });
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load songs. Please try again.')),
        );
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterSongs();
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredSongs = songs.where((song) {
        final numberMatches = song.number.contains(query);
        final titleMatches = song.title.toLowerCase().contains(query);
        final lyricsMatches = song.verses.any((verse) =>
            verse.lyrics.toLowerCase().contains(query));
        return numberMatches || titleMatches || lyricsMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          automaticallyImplyLeading: false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lagu Pujian Masa Ini',
                      style: TextStyle(
                        fontSize: 24.0,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Songs',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          FilterButtons(
            onShowAll: () => setState(() => filteredSongs = songs),
            onShowFavorites: () => setState(() => filteredSongs = songs.where((s) => s.isFavorite).toList()),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return Card(
                  child: ListTile(
                    title: Text('${song.number}. ${song.title}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SongLyricsPage(
                            song: song,
                            fontSize: widget.fontSize,
                            fontStyle: widget.fontStyle,
                            textAlign: widget.textAlign,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              if (Navigator.of(context).canPop()) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
              break;
            case 1:
              widget.onToggleTheme();
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

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SettingsPage(
        currentFontSize: widget.fontSize,
        currentFontStyle: widget.fontStyle,
        currentTextAlign: widget.textAlign,
        onFontSizeChange: widget.onFontSizeChange,
        onFontStyleChange: widget.onFontStyleChange,
        onTextAlignChange: widget.onTextAlignChange,
      ),
    );
  }
}
