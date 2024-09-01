import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as root_bundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:auto_size_text/auto_size_text.dart'; // Make sure to include this package in your pubspec.yaml

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  double fontSize = 16.0;
  String fontStyle = 'Roboto';
  TextAlign textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isDarkMode = prefs.getBool('isDarkMode') ?? false;
        fontSize = prefs.getDouble('fontSize') ?? 16.0;
        fontStyle = prefs.getString('fontStyle') ?? 'Roboto';
        textAlign = TextAlign.values[prefs.getInt('textAlign') ?? 0];
      });
    } catch (error) {
      debugPrint('Error loading preferences: $error');
    }
  }

  void _updateThemeMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      _savePreferences();
    });
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
      await prefs.setDouble('fontSize', fontSize);
      await prefs.setString('fontStyle', fontStyle);
      await prefs.setInt('textAlign', textAlign.index);
    } catch (error) {
      debugPrint('Error saving preferences: $error');
    }
  }

  void _updateFontSize(double? size) {
    if (size != null) {
      setState(() {
        fontSize = size;
        _savePreferences();
      });
    }
  }

  void _updateFontStyle(String? style) {
    if (style != null) {
      setState(() {
        fontStyle = style;
        _savePreferences();
      });
    }
  }

  void _updateTextAlign(TextAlign? align) {
    if (align != null) {
      setState(() {
        textAlign = align;
        _savePreferences();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lagu Pujian Masa Ini',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: fontSize, fontFamily: fontStyle),
        ),
      ),
      home: MainPage(
        isDarkMode: isDarkMode,
        fontSize: fontSize,
        fontStyle: fontStyle,
        textAlign: textAlign,
        onToggleTheme: _updateThemeMode,
        onFontSizeChange: _updateFontSize,
        onFontStyleChange: _updateFontStyle,
        onTextAlignChange: _updateTextAlign,
      ),
    );
  }
}

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_filterSongs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSongs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final jsonString = await root_bundle.rootBundle.loadString('assets/lpmi.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      final prefs = await SharedPreferences.getInstance();
      final favoriteSongs = prefs.getStringList('favoriteSongs') ?? [];

      setState(() {
        songs = jsonResponse.map((data) {
          final song = Song.fromJson(data);
          song.isFavorite = favoriteSongs.contains(song.number);
          return song;
        }).toList();
        filteredSongs = songs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error in _loadSongs: $e');
    }
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSongs = songs.where((song) => song.title.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _toggleFavorite(Song song) async {
    setState(() {
      song.isFavorite = !song.isFavorite;
    });

    final prefs = await SharedPreferences.getInstance();
    final favoriteSongs = prefs.getStringList('favoriteSongs') ?? [];

    if (song.isFavorite) {
      favoriteSongs.add(song.number);
    } else {
      favoriteSongs.remove(song.number);
    }

    await prefs.setStringList('favoriteSongs', favoriteSongs);
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SettingsPage(
        currentFontSize: widget.fontSize,
        currentFontStyle: widget.fontStyle,
        currentTextAlign: widget.textAlign,
        onFontSizeChange: widget.onFontSizeChange,
        onFontStyleChange: widget.onFontStyleChange,
        onTextAlignChange: widget.onTextAlignChange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: AppBar(
          flexibleSpace: Stack(
            children: [
              Image.asset(
                'assets/header_image.png',
                width: double.infinity,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              Center(
                child: Text(
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
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                  ),
                  onPressed: widget.onToggleTheme,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Carian Lagu',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Semua Lagu', () => setState(() => filteredSongs = songs)),
                _buildFilterButton('Favorites', () {
                  setState(() => filteredSongs = songs.where((song) => song.isFavorite).toList());
                }),
                _buildFilterButton('Filter', () {
                  // Add custom filter logic here if needed
                }),
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
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(
                      '${song.number}. ${song.title}',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontFamily: widget.fontStyle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        song.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: song.isFavorite
                            ? (widget.isDarkMode ? Colors.white : Colors.black)
                            : (widget.isDarkMode ? Colors.white : Colors.black),
                      ),
                      onPressed: () => _toggleFavorite(song),
                    ),
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
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            widget.onToggleTheme();
          } else if (index == 2) {
            _showSettings(context);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            label: 'Toggle Mode',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

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
  // ignore: library_private_types_in_public_api
  _SongLyricsPageState createState() => _SongLyricsPageState();
}

class _SongLyricsPageState extends State<SongLyricsPage> {
  late double fontSize;
  late String fontStyle;
  late TextAlign textAlign;

  @override
  void initState() {
    super.initState();
    fontSize = widget.fontSize;
    fontStyle = widget.fontStyle;
    textAlign = widget.textAlign;
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SettingsPage(
        currentFontSize: fontSize,
        currentFontStyle: fontStyle,
        currentTextAlign: textAlign,
        onFontSizeChange: (value) {
          if (value != null) {
            setState(() {
              fontSize = value;
            });
            Navigator.pop(context);
          }
        },
        onFontStyleChange: (value) {
          if (value != null) {
            setState(() {
              fontStyle = value;
            });
            Navigator.pop(context);
          }
        },
        onTextAlignChange: (value) {
          if (value != null) {
            setState(() {
              textAlign = value;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _shareLyrics() {
    final lyrics = widget.song.verses
        .map((verse) => '${verse.number}. ${verse.lyrics}')
        .join('\n\n');
    Share.share('${widget.song.title}\n\n$lyrics');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(240.0), // Increased header size
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Removes the back arrow
          flexibleSpace: Stack(
            children: [
              Image.asset(
                'assets/header_image.png',
                width: double.infinity,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AutoSizeText(
                    widget.song.title,
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.0,
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
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.song.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          widget.song.isFavorite = !widget.song.isFavorite;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: _shareLyrics,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
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
                    ),
                  ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            _showSettings(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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

class SettingsPage extends StatelessWidget {
  final double currentFontSize;
  final String currentFontStyle;
  final TextAlign currentTextAlign;
  final ValueChanged<double?> onFontSizeChange;
  final ValueChanged<String?> onFontStyleChange;
  final ValueChanged<TextAlign?> onTextAlignChange;

  const SettingsPage({
    super.key,
    required this.currentFontSize,
    required this.currentFontStyle,
    required this.currentTextAlign,
    required this.onFontSizeChange,
    required this.onFontStyleChange,
    required this.onTextAlignChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('Font Size'),
          trailing: DropdownButton<double>(
            value: currentFontSize,
            items: [12.0, 14.0, 16.0, 18.0, 20.0]
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text(size.toString()),
                    ))
                .toList(),
            onChanged: onFontSizeChange,
          ),
        ),
        ListTile(
          title: const Text('Font Style'),
          trailing: DropdownButton<String>(
            value: currentFontStyle,
            items: ['Roboto', 'Arial', 'Times New Roman']
                .map((style) => DropdownMenuItem(
                      value: style,
                      child: Text(style),
                    ))
                .toList(),
            onChanged: onFontStyleChange,
          ),
        ),
        ListTile(
          title: const Text('Text Alignment'),
          trailing: DropdownButton<TextAlign>(
            value: currentTextAlign,
            items: TextAlign.values
                .map((align) => DropdownMenuItem(
                      value: align,
                      child: Text(align.toString().split('.').last),
                    ))
                .toList(),
            onChanged: onTextAlignChange,
          ),
        ),
      ],
    );
  }
}

class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  bool isFavorite;

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.isFavorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    var versesJson = json['verses'] as List;
    List<Verse> versesList = versesJson.map((verse) => Verse.fromJson(verse)).toList();
    return Song(
      number: json['song_number'],
      title: json['song_title'],
      verses: versesList,
    );
  }
}

class Verse {
  final String number;
  final String lyrics;

  Verse({required this.number, required this.lyrics});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'],
      lyrics: json['lyrics'],
    );
  }
}
