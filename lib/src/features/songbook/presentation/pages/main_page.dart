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
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class MainPage extends StatefulWidget {
  final String initialFilter;
  const MainPage({super.key, this.initialFilter = 'All'});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  late PreferencesService _prefsService;

  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  late String _activeFilter;
  String _sortOrder = 'Number';
  bool _isOnline = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _initialize();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _initialize() async {
    _prefsService = await PreferencesService.init();
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final songDataResult = await _songRepository.getSongs();
      final songs = songDataResult.songs;
      final isOnline = songDataResult.isOnline;

      final favoriteSongNumbers = await _favoritesRepository.getFavorites();
      for (var song in songs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }
      if (mounted) {
        setState(() {
          _songs = songs;
          _isOnline = isOnline;
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
    if (_sortOrder == 'Alphabet') {
      tempSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      tempSongs.sort((a, b) =>
          (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
    }
    if (mounted) setState(() => _filteredSongs = tempSongs);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      if (filter == 'All' || filter == 'Favorites') {
        _activeFilter = filter;
      } else if (filter == 'Alphabet' || filter == 'Number')
        _sortOrder = filter;
    });
    _applyFilters();
  }

  void _toggleFavorite(Song song) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please log in to save favorites.'),
        action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()))),
      ));
      return;
    }
    final isCurrentlyFavorite = song.isFavorite;
    setState(() => song.isFavorite = !isCurrentlyFavorite);
    _favoritesRepository.toggleFavoriteStatus(song.number, isCurrentlyFavorite);
    _applyFilters();
  }

  void _navigateToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  String get _currentDate =>
      DateFormat('EEEE | MMMM d, y').format(DateTime.now());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MainDashboardDrawer(
          isFromDashboard: false,
          onFilterSelected: _onFilterChanged,
          onShowSettings: _navigateToSettingsPage),
      body: Column(
        children: [
          _buildHeader(),
          _buildCollectionInfo(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_filteredSongs.isEmpty
                    ? _buildEmptyState()
                    : _buildSongsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/images/header_image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Theme.of(context).primaryColor))),
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.6)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 4.0,
                  right: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                      builder: (context) => IconButton(
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          tooltip: 'Open Menu')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lagu Pujian Masa Ini',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            _activeFilter == 'Favorites'
                                ? 'Favorite Songs'
                                : 'Full Songbook',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.library_music, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_currentDate,
                  style: Theme.of(context).textTheme.titleMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12)),
            child: Text('${_filteredSongs.length} songs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            _isOnline ? Colors.green.withAlpha(30) : Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: _isOnline ? Colors.green.shade700 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Local',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      _isOnline ? Colors.green.shade800 : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.sort, color: Theme.of(context).primaryColor),
            ),
            tooltip: 'Sort options',
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'Number',
                  child: Text('Sort by Number',
                      style: TextStyle(
                          fontWeight: _sortOrder == 'Number'
                              ? FontWeight.bold
                              : null))),
              PopupMenuItem(
                  value: 'Alphabet',
                  child: Text('Sort A-Z',
                      style: TextStyle(
                          fontWeight: _sortOrder == 'Alphabet'
                              ? FontWeight.bold
                              : null))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredSongs.length,
        itemBuilder: (context, index) {
          final song = _filteredSongs[index];
          return SongListItem(
            song: song,
            onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SongLyricsPage(songNumber: song.number)))
                .then((_) => _loadSongs()),
            onFavoritePressed: () => _toggleFavorite(song),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
              _activeFilter == 'Favorites'
                  ? Icons.favorite_border
                  : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(70)),
          const SizedBox(height: 16),
          Text(
              _activeFilter == 'Favorites'
                  ? 'No favorite songs yet'
                  : 'No songs found',
              style: Theme.of(context).textTheme.titleMedium),
        ]),
      )),
    );
  }
}
