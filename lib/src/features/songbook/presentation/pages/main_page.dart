import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
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
  String _activeFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

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
            SnackBar(content: Text('Error loading songs: ${e.toString()}')));
      }
    }
  }

  void _applyFilters() {
    List<Song> tempSongs = _activeFilter == 'Favorites'
        ? _songs.where((s) => s.isFavorite).toList()
        : List.from(_songs);
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempSongs = tempSongs
          .where((song) =>
              song.number.toLowerCase().contains(query) ||
              song.title.toLowerCase().contains(query))
          .toList();
    }
    if (mounted) setState(() => _filteredSongs = tempSongs);
  }

  void _filterSongsByCategory(String filter) {
    setState(() => _activeFilter = filter);
    _applyFilters();
  }

  void _toggleFavorite(Song song) {
    setState(() => song.isFavorite = !song.isFavorite);
    _applyFilters();
    // TODO: Save favorite status to Firebase.
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SettingsPage(
        // Corrected: Pass initial values to the settings page
        initialFontSize: _fontSize,
        initialFontStyle: _fontStyle,
        initialTextAlign: _textAlign,
        // Callbacks to update state and save preferences
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
          onShowSettings: _showSettingsModal),
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
                  hintText: 'Cari Lagu...',
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
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/header_image.png', fit: BoxFit.cover),
      Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  stops: const [0.0, 0.7],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter))),
      Positioned(
          left: 16,
          bottom: 16,
          child: Text(_currentDate,
              style: const TextStyle(color: Colors.white70, fontSize: 12))),
    ]);
  }

  Widget _buildSongList() {
    if (_isLoading)
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    if (_filteredSongs.isEmpty)
      return SliverFillRemaining(
          child: Center(child: Text('No songs found for "$_activeFilter".')));

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
