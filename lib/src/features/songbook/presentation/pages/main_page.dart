import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/pages/auth_page.dart';
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

  // ✅ NEW: State variables for lazy loading
  final _scrollController = ScrollController();
  String? _lastKey;
  bool _hasMoreSongs = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _initialize();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll); // Listener for lazy loading
  }

  Future<void> _initialize() async {
    _prefsService = await PreferencesService.init();
    await _loadSongs();
  }

  // ✅ UPDATED: For initial paginated fetch
  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _songs = []; // Clear previous songs
      _filteredSongs = [];
      _hasMoreSongs = true;
      _lastKey = null;
    });
    try {
      // Use the new paginated method
      final songDataResult = await _songRepository.getPaginatedSongs();

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
          _lastKey = songDataResult.lastKey;
          _hasMoreSongs = songDataResult.hasMore;
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

  // ✅ NEW: Method to fetch subsequent pages
  Future<void> _loadMoreSongs() async {
    if (!mounted || _isLoadingMore || !_hasMoreSongs) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final songDataResult =
          await _songRepository.getPaginatedSongs(startAfterKey: _lastKey);
      final newSongs = songDataResult.songs;

      if (newSongs.isNotEmpty) {
        final favoriteSongNumbers = await _favoritesRepository.getFavorites();
        for (var song in newSongs) {
          song.isFavorite = favoriteSongNumbers.contains(song.number);
        }
      }

      if (mounted) {
        setState(() {
          _songs.addAll(newSongs);
          _lastKey = songDataResult.lastKey;
          _hasMoreSongs = songDataResult.hasMore;
          _applyFilters();
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more songs: ${e.toString()}')));
    }
  }

  // ✅ NEW: Scroll listener to trigger fetching more songs
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMoreSongs &&
        !_isLoadingMore &&
        _searchController.text.isEmpty && // Only lazy load when not searching
        _activeFilter != 'Favorites') {
      // and not in favorites
      _loadMoreSongs();
    }
  }

  void _applyFilters() {
    List<Song> tempSongs;

    // When filtering by Favorites or searching, use the currently loaded songs.
    // Lazy loading is disabled in these modes.
    if (_activeFilter == 'Favorites') {
      tempSongs = _songs.where((s) => s.isFavorite).toList();
    } else {
      tempSongs = List.from(_songs);
    }

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
    // When changing main filter, reload everything from scratch
    if (filter == 'All' || filter == 'Favorites') {
      setState(() {
        _activeFilter = filter;
      });
      // Favorites filter is applied locally, "All" requires a fresh load
      // to reset pagination.
      _loadSongs();
    } else if (filter == 'Alphabet' || filter == 'Number') {
      setState(() {
        _sortOrder = filter;
      });
      _applyFilters(); // Just re-sort the existing list
    }
  }

  void _toggleFavorite(Song song) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please log in to save favorites.'),
        action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AuthPage(
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      onToggleTheme: () {},
                    )))),
      ));
      return;
    }
    final isCurrentlyFavorite = song.isFavorite;
    setState(() => song.isFavorite = !isCurrentlyFavorite);
    // Corrected logic: pass the original favorite status to the repository
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
    _scrollController.dispose();
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
                : (_filteredSongs.isEmpty && _searchController.text.isNotEmpty
                    ? _buildEmptyState()
                    : _buildSongsList()),
          ),
        ],
      ),
    );
  }

  // Header and other build methods remain the same...
  Widget _buildHeader() {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/images/header_image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                        color: theme.colorScheme.primary,
                      ))),
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7)
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.library_music,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_currentDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.titleMedium?.color,
                  ))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Text('${_filteredSongs.length} songs',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOnline
            ? (isDark
                ? Colors.green.withOpacity(0.2)
                : Colors.green.withOpacity(0.1))
            : (isDark
                ? Colors.grey.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: _isOnline
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Local',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _isOnline
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by title or number...',
                hintStyle: theme.inputDecorationTheme.hintStyle,
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.iconTheme.color,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                Icons.sort,
                color: theme.colorScheme.primary,
              ),
            ),
            tooltip: 'Sort options',
            onSelected: _onFilterChanged,
            color: theme.popupMenuTheme.color,
            shape: theme.popupMenuTheme.shape,
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'Number',
                  child: Text('Sort by Number',
                      style: TextStyle(
                        fontWeight:
                            _sortOrder == 'Number' ? FontWeight.bold : null,
                        color: theme.textTheme.bodyMedium?.color,
                      ))),
              PopupMenuItem(
                  value: 'Alphabet',
                  child: Text('Sort A-Z',
                      style: TextStyle(
                        fontWeight:
                            _sortOrder == 'Alphabet' ? FontWeight.bold : null,
                        color: theme.textTheme.bodyMedium?.color,
                      ))),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: ListView now supports showing a loading indicator at the bottom
  Widget _buildSongsList() {
    return ListView.builder(
      controller: _scrollController, // Attach controller
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSongs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredSongs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final song = _filteredSongs[index];
        return SongListItem(
          song: song,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongLyricsPage(songNumber: song.number),
            ),
          ).then((_) {
            // After returning from lyrics page, a full reload is simple but
            // loses scroll position. For a better UX, you could pass back
            // the favorite status and update only that song in the list.
            _loadSongs();
          }),
          onFavoritePressed: () => _toggleFavorite(song),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            _activeFilter == 'Favorites'
                ? Icons.favorite_border
                : Icons.search_off,
            size: 64,
            color: theme.iconTheme.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'Favorites'
                ? 'No favorite songs yet'
                : 'No songs found for your search',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
