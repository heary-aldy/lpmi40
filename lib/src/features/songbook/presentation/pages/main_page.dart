import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/features/authentication/presentation/login_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_item.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SongRepository _songRepository = SongRepository();
  late PreferencesService _prefsService;

  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String _activeFilter = 'All'; // Can be 'All' or 'Favorites'

  final TextEditingController _searchController = TextEditingController();

  // Settings state variables
  double _fontSize = 16.0;
  String _fontStyle = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _initialize() async {
    // This ensures that the context is available before checking brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isDarkMode =
            MediaQuery.of(context).platformBrightness == Brightness.dark;
      }
    });
    _prefsService = await PreferencesService.init();
    if (mounted) {
      setState(() {
        _fontSize = _prefsService.fontSize;
        _fontStyle = _prefsService.fontStyle;
        _textAlign = _prefsService.textAlign;
        _isDarkMode = _prefsService.isDarkMode;
      });
    }
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final songs = await _songRepository.getSongs();
      // TODO: Load user's favorites from Firebase and merge isFavorite status.
      if (mounted) {
        setState(() {
          _songs = songs;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading songs: ${e.toString()}')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Song> tempSongs = _activeFilter == 'Favorites'
        ? _songs.where((s) => s.isFavorite).toList()
        : List.from(_songs);

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempSongs = tempSongs.where((song) {
        return song.number.toLowerCase().contains(query) ||
            song.title.toLowerCase().contains(query);
      }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredSongs = tempSongs;
      });
    }
  }

  void _filterSongsByCategory(String filter) {
    setState(() {
      _activeFilter = filter;
    });
    _applyFilters();
  }

  /// This is the updated method that handles guest users.
  void _toggleFavorite(Song song) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is a guest (not logged in)
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save favorites.'),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ));
            },
          ),
        ),
      );
      return; // Stop the function here for guests
    }

    // If the user is logged in, proceed to toggle the favorite status
    setState(() {
      song.isFavorite = !song.isFavorite;
    });
    _applyFilters();

    // TODO: Add logic here to save the favorite status to Firebase for the logged-in user.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(song.isFavorite
          ? '"${song.title}" added to favorites.'
          : '"${song.title}" removed from favorites.'),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SettingsPage(
        initialFontSize: _fontSize,
        initialFontStyle: _fontStyle,
        initialTextAlign: _textAlign,
        onFontSizeChange: (size) {
          if (size != null) {
            setState(() => _fontSize = size);
            _prefsService.saveFontSize(size);
          }
        },
        onFontStyleChange: (style) {
          if (style != null) {
            setState(() => _fontStyle = style);
            _prefsService.saveFontStyle(style);
          }
        },
        onTextAlignChange: (align) {
          if (align != null) {
            setState(() => _textAlign = align);
            _prefsService.saveTextAlign(align);
          }
        },
      ),
    );
  }

  String get _currentDate =>
      DateFormat('EEEE, MMMM d, y').format(DateTime.now());

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: MainDashboardDrawer(
        onFilterSelected: _filterSongsByCategory,
        onShowSettings: _showSettingsModal,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 180.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              centerTitle: true,
              title: const Text('Lagu Pujian Masa Ini',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              background: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Lagu by Number or Title...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear())
                      : null,
                ),
              ),
            ),
          ),
          _buildSongList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/header_image.png', fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              stops: const [0.0, 0.7],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            _currentDate,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSongList() {
    if (_isLoading) {
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    }
    if (_filteredSongs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(_searchController.text.isNotEmpty
              ? 'No songs match your search.'
              : 'No songs in "$_activeFilter".'),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _filteredSongs[index];
          return SongListItem(
            song: song,
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
            onFavoritePressed: () => _toggleFavorite(song),
          );
        },
        childCount: _filteredSongs.length,
      ),
    );
  }
}
