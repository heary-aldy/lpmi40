import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Constants
  static const Duration _debounceTime = Duration(milliseconds: 300);
  static const String _prefsIsDarkMode = 'isDarkMode';
  static const String _prefsFontSize = 'fontSize';
  static const String _prefsFontStyle = 'fontStyle';
  static const String _prefsTextAlign = 'textAlign';
  static const String _prefsFavoriteSongs = 'favoriteSongs';

  // State variables
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSortedAlphabetically = true;
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _fontStyle = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  
  // Category filters
  String _currentCategory = 'All Songs';

  String get _currentDate {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fontSize = widget.fontSize;
    _fontStyle = widget.fontStyle;
    _textAlign = widget.textAlign;
    
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
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isDarkMode = prefs.getBool(_prefsIsDarkMode) ?? widget.isDarkMode;
        _fontSize = prefs.getDouble(_prefsFontSize) ?? widget.fontSize;
        _fontStyle = prefs.getString(_prefsFontStyle) ?? widget.fontStyle;
        _textAlign = TextAlign.values[prefs.getInt(_prefsTextAlign) ?? widget.textAlign.index];
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      // Fallback to default values from widget parameters
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsIsDarkMode, _isDarkMode);
      await prefs.setDouble(_prefsFontSize, _fontSize);
      await prefs.setString(_prefsFontStyle, _fontStyle);
      await prefs.setInt(_prefsTextAlign, _textAlign.index);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      if (mounted) {
        _showSnackBar('Failed to save preferences');
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lpmi.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);

      if (!mounted) return;

      setState(() {
        _songs = jsonResponse.map((data) => Song.fromJson(data)).toList();
      });
      
      await _loadFavoriteSongs();
      
      if (mounted) {
        setState(() {
          _filteredSongs = _songs;
          _applySorting();
        });
      }
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (mounted) {
        _showSnackBar('Failed to load songs. Please try again.');
      }
    }
  }

  Future<void> _loadFavoriteSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteSongs = prefs.getStringList(_prefsFavoriteSongs) ?? [];

      setState(() {
        for (var song in _songs) {
          song.isFavorite = favoriteSongs.contains(song.number);
        }
      });
    } catch (e) {
      debugPrint('Error loading favorite songs: $e');
    }
  }

  Future<void> _saveFavoriteSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteSongs = _songs
          .where((song) => song.isFavorite)
          .map((song) => song.number)
          .toList();
      await prefs.setStringList(_prefsFavoriteSongs, favoriteSongs);
    } catch (e) {
      debugPrint('Error saving favorite songs: $e');
      if (mounted) {
        _showSnackBar('Failed to save favorites');
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(_debounceTime, () {
      _filterSongs();
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    
    // Return all songs if query is empty
    if (query.isEmpty) {
      setState(() {
        _applyCurrentFilters();
      });
      return;
    }

    setState(() {
      List<Song> baseList = _currentCategory == 'Favorites' 
          ? _songs.where((song) => song.isFavorite).toList()
          : _songs;
          
      _filteredSongs = baseList.where((song) {
        final numberMatches = song.number.contains(query);
        final titleMatches = song.title.toLowerCase().contains(query);
        final lyricsMatches = song.verses.any((verse) =>
            verse.lyrics.toLowerCase().contains(query));
        return numberMatches || titleMatches || lyricsMatches;
      }).toList();
      
      _applySorting();
    });
  }

  void _toggleSort() {
    setState(() {
      _isSortedAlphabetically = !_isSortedAlphabetically;
      _applySorting();
    });
  }
  
  void _applySorting() {
    _filteredSongs.sort((a, b) {
      if (_isSortedAlphabetically) {
        return a.title.compareTo(b.title);
      } else {
        // Handle potential non-numeric song numbers
        try {
          return int.parse(a.number).compareTo(int.parse(b.number));
        } catch (e) {
          // Fallback to string comparison if parsing fails
          return a.number.compareTo(b.number);
        }
      }
    });
  }

  void _toggleFavorite(Song song) {
    setState(() {
      song.isFavorite = !song.isFavorite;
      
      // If in favorites category, update filtered list immediately
      if (_currentCategory == 'Favorites' && !song.isFavorite) {
        _filteredSongs.remove(song);
      }
    });
    
    _saveFavoriteSongs();
  }

  void _updateThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _savePreferences();
    widget.onToggleTheme();
  }

  void _debouncedUpdatePreferences(void Function() updateFunction) {
    _debounce?.cancel();
    _debounce = Timer(_debounceTime, () {
      setState(updateFunction);
      _savePreferences();
    });
  }

  void _updateFontSize(double? size) {
    if (size != null) {
      _debouncedUpdatePreferences(() {
        _fontSize = size;
        widget.onFontSizeChange(size);
      });
    }
  }

  void _updateFontStyle(String? style) {
    if (style != null) {
      _debouncedUpdatePreferences(() {
        _fontStyle = style;
        widget.onFontStyleChange(style);
      });
    }
  }

  void _updateTextAlign(TextAlign? align) {
    if (align != null) {
      _debouncedUpdatePreferences(() {
        _textAlign = align;
        widget.onTextAlignChange(align);
      });
    }
  }

  Future<void> _launchUpgradeUrl() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.haweeinc.lpmi_premium');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnackBar('Opening premium upgrade page...');
        }
      } else if (mounted) {
        _showSnackBar('Could not launch the URL');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        _showSnackBar('Failed to open premium page');
      }
    }
  }

  Future<void> _launchAlkitabApp() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.haweeinc.alkitab');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnackBar('Opening Alkitab 1.0 app page...');
        }
      } else if (mounted) {
        _showSnackBar('Could not launch the URL');
      }
    } catch (e) {
      debugPrint('Error launching Alkitab URL: $e');
      if (mounted) {
        _showSnackBar('Failed to open Alkitab app page');
      }
    }
  }

  void _filterSongsByCategory(String category) {
    setState(() {
      _currentCategory = category;
      _applyCurrentFilters();
    });
  }
  
  void _applyCurrentFilters() {
    final query = _searchController.text.toLowerCase();
    
    if (_currentCategory == 'Favorites') {
      _filteredSongs = _songs.where((song) => song.isFavorite).toList();
    } else {
      _filteredSongs = _songs;
    }
    
    // Apply search filter if there's a query
    if (query.isNotEmpty) {
      _filteredSongs = _filteredSongs.where((song) {
        final numberMatches = song.number.contains(query);
        final titleMatches = song.title.toLowerCase().contains(query);
        final lyricsMatches = song.verses.any((verse) =>
            verse.lyrics.toLowerCase().contains(query));
        return numberMatches || titleMatches || lyricsMatches;
      }).toList();
    }
    
    _applySorting();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SettingsPage(
        currentFontSize: _fontSize,
        currentFontStyle: _fontStyle,
        currentTextAlign: _textAlign,
        isDarkMode: _isDarkMode,
        onFontSizeChange: _updateFontSize,
        onFontStyleChange: _updateFontStyle,
        onTextAlignChange: _updateTextAlign,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildSongList(),
          ),
        ],
      ),
      floatingActionButton: _buildFilterButton(),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
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
                    _currentDate,
                    style: const TextStyle(
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterSongs();
                      },
                    )
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _isSortedAlphabetically ? 'Sort by Number' : 'Sort Alphabetically',
            icon: Icon(_isSortedAlphabetically
                ? Icons.sort_by_alpha
                : Icons.format_list_numbered),
            onPressed: _toggleSort,
          ),
        ],
      ),
    );
  }

 Widget _buildSongList() {
    if (_filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No songs found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (_currentCategory == 'Favorites' && _songs.isNotEmpty)
              ElevatedButton(
                onPressed: () => _filterSongsByCategory('All Songs'),
                child: const Text('View All Songs'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: song.isFavorite ? Colors.red : Colors.blue.shade200, 
                width: 4.0
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: song.isFavorite ? Colors.red.shade700 : Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${song.number}. ${song.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: song.isFavorite ? Colors.red.shade700 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    fontSize: _fontSize,
                    fontStyle: _fontStyle,
                    textAlign: _textAlign,
                    isDarkMode: _isDarkMode,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  SpeedDial _buildFilterButton() {
    return SpeedDial(
      icon: Icons.filter_list,
      activeIcon: Icons.close,
      backgroundColor: const Color.fromARGB(255, 243, 187, 33),
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'More Options',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.library_music),
          label: 'All Songs',
          onTap: () => _filterSongsByCategory('All Songs'),
          backgroundColor: _currentCategory == 'All Songs' ? Colors.blue.shade200 : null,
        ),
        SpeedDialChild(
          child: const Icon(Icons.favorite),
          label: 'Favorites',
          onTap: () => _filterSongsByCategory('Favorites'),
          backgroundColor: _currentCategory == 'Favorites' ? Colors.pink.shade200 : null,
        ),
        SpeedDialChild(
          child: const Icon(Icons.star),
          label: 'Upgrade to Premium',
          onTap: _launchUpgradeUrl,
          backgroundColor: Colors.amber,
        ),
        SpeedDialChild(
          child: const Icon(Icons.book),
          label: 'Alkitab 1.0',
          onTap: _launchAlkitabApp,
          backgroundColor: Colors.green.shade400,
        ),
        SpeedDialChild(
          child: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          label: _isDarkMode ? 'Light Mode' : 'Dark Mode',
          onTap: _updateThemeMode,
          backgroundColor: Colors.purple.shade300,
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'Settings',
          onTap: () => _showSettings(context),
          backgroundColor: Colors.teal.shade300,
        ),
      ],
    );
  }
}