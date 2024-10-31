import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as root_bundle;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lpmi40/models/song.dart';
import 'package:lpmi40/pages/song_lyrics_page.dart';
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
  bool isSortedAlphabetically = true;
  bool isDarkMode = false;
  double fontSize = 16.0;
  String fontStyle = 'Roboto';
  TextAlign textAlign = TextAlign.left;

  String get currentDate {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? widget.isDarkMode;
      fontSize = prefs.getDouble('fontSize') ?? widget.fontSize;
      fontStyle = prefs.getString('fontStyle') ?? widget.fontStyle;
      textAlign = TextAlign.values[prefs.getInt('textAlign') ?? widget.textAlign.index];
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setString('fontStyle', fontStyle);
    await prefs.setInt('textAlign', textAlign.index);
  }

  Future<void> _loadSongs() async {
    try {
      final jsonString = await root_bundle.rootBundle.loadString('assets/lpmi.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);

      if (!mounted) return;

      setState(() {
        songs = jsonResponse.map((data) => Song.fromJson(data)).toList();
      });
      await _loadFavoriteSongs();
      if (mounted) {
        setState(() {
          filteredSongs = songs;
        });
      }
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load songs. Please try again.')),
        );
      }
    }
  }

  Future<void> _loadFavoriteSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteSongs = prefs.getStringList('favoriteSongs') ?? [];

    setState(() {
      for (var song in songs) {
        song.isFavorite = favoriteSongs.contains(song.number);
      }
    });
  }

  Future<void> _saveFavoriteSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteSongs = songs
          .where((song) => song.isFavorite)
          .map((song) => song.number)
          .toList();
      await prefs.setStringList('favoriteSongs', favoriteSongs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save favorites.')),
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

  void _toggleSort() {
    setState(() {
      isSortedAlphabetically = !isSortedAlphabetically;
      filteredSongs.sort((a, b) {
        if (isSortedAlphabetically) {
          return a.title.compareTo(b.title);
        } else {
          return int.parse(a.number).compareTo(int.parse(b.number));
        }
      });
    });
  }

  void _toggleFavorite(Song song) {
    setState(() {
      song.isFavorite = !song.isFavorite;
    });
    _saveFavoriteSongs();
  }

  void _updateThemeMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _savePreferences();
    widget.onToggleTheme();
  }

  void _debouncedUpdatePreferences(void Function() updateFunction) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(updateFunction);
      _savePreferences();
    });
  }

  void _updateFontSize(double? size) {
    if (size != null) {
      _debouncedUpdatePreferences(() {
        fontSize = size;
        widget.onFontSizeChange(size);
      });
    }
  }

  void _updateFontStyle(String? style) {
    if (style != null) {
      _debouncedUpdatePreferences(() {
        fontStyle = style;
        widget.onFontStyleChange(style);
      });
    }
  }

  void _updateTextAlign(TextAlign? align) {
    if (align != null) {
      _debouncedUpdatePreferences(() {
        textAlign = align;
        widget.onTextAlignChange(align);
      });
    }
  }

  Future<void> _launchUpgradeUrl() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.haweeinc.lpmi_premium');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening premium upgrade page...')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the URL.')),
      );
    }
  }

  void _filterSongsByCategory(String category) {
    setState(() {
      if (category == 'Favorites') {
        filteredSongs = songs.where((song) => song.isFavorite).toList();
      } else {
        filteredSongs = songs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140.0),
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
            child: Row(
              children: [
                Expanded(
                  flex: 8,
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
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isSortedAlphabetically
                      ? Icons.sort_by_alpha
                      : Icons.format_list_numbered),
                  onPressed: _toggleSort,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${song.number}. ${song.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Klik Untuk Melihat Lirik',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        song.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: song.isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(song),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SongLyricsPage(
                            song: song,
                            fontSize: fontSize,
                            fontStyle: fontStyle,
                            textAlign: textAlign,
                            isDarkMode: isDarkMode,
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
      floatingActionButton: SpeedDial(
        icon: Icons.filter_list,
        activeIcon: Icons.close,
        backgroundColor: const Color.fromARGB(255, 243, 187, 33),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.library_music),
            label: 'All Songs',
            onTap: () => _filterSongsByCategory('All Songs'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.favorite),
            label: 'Favorites',
            onTap: () => _filterSongsByCategory('Favorites'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.star),
            label: 'Upgrade to Premium',
            onTap: _launchUpgradeUrl,
            backgroundColor: Colors.amber,
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
              _updateThemeMode();
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
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
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
        currentFontSize: fontSize,
        currentFontStyle: fontStyle,
        currentTextAlign: textAlign,
        onFontSizeChange: _updateFontSize,
        onFontStyleChange: _updateFontStyle,
        onTextAlignChange: _updateTextAlign,
      ),
    );
  }
}
