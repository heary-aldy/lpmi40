// lib/src/features/songbook/presentation/pages/main_page.dart
// ✅ FIXED: Resolved the "Build scheduled during frame" error.
// ✅ NEW: Added complete collection support with floating action button
// ✅ COMPATIBILITY: Updated to use older Dart syntax for broader compatibility

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';

// ✅ NEW: Collection support imports
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';

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

  Timer? _connectivityTimer;
  bool _wasOnline = true;

  final TextEditingController _searchController = TextEditingController();

  // ✅ NEW: Collection support
  final CollectionService _collectionService = CollectionService();
  List<SongCollection> _availableCollections = [];
  SongCollection? _currentCollection;
  bool _collectionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _initialize();
    _searchController.addListener(_applyFilters);
    _startConnectivityMonitoring();
  }

  Future<void> _initialize() async {
    _prefsService = await PreferencesService.init();
    await _loadCollections();
    await _loadSongs();
  }

  // ✅ NEW: Load available collections
  Future<void> _loadCollections() async {
    try {
      final collections = await _collectionService.getAccessibleCollections();
      if (mounted) {
        setState(() {
          _availableCollections = collections;
          _collectionsLoaded = true;

          // Set LPMI as default collection if available and no specific filter
          if (widget.initialFilter == 'All' && collections.isNotEmpty) {
            _currentCollection = collections.firstWhere(
              (c) => c.id == 'LPMI',
              orElse: () => collections.first,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading collections: $e');
      if (mounted) {
        setState(() => _collectionsLoaded = true);
      }
    }
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(
      Duration(seconds: _isOnline ? 30 : 10),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        try {
          final songDataResult = await _songRepository.getAllSongs();
          final currentOnlineStatus = songDataResult.isOnline;
          if (currentOnlineStatus != _isOnline) {
            _wasOnline = _isOnline;
            await _loadSongs();
            if (mounted) {
              final message = currentOnlineStatus
                  ? '🌐 Back online! Songs synced.'
                  : '📱 Switched to offline mode.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                  backgroundColor:
                      currentOnlineStatus ? Colors.green : Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('📡 Connectivity check error: $e');
        }
      },
    );
  }

  // ✅ UPDATED: Load songs with collection support
  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<Song> songs;
      bool isOnline;

      if (_activeFilter == 'All') {
        // Load all songs from all collections
        songs = await _collectionService.getAllSongsFromCollections();
        isOnline = true; // Assume online if we got results from collections

        // Fallback to original repository if no collections or empty
        if (songs.isEmpty) {
          final songDataResult = await _songRepository.getAllSongs();
          songs = songDataResult.songs;
          isOnline = songDataResult.isOnline;
        }
      } else if (_currentCollection != null) {
        // Load songs from specific collection
        final result = await _collectionService
            .getSongsFromCollection(_currentCollection!.id);
        songs = result.songs;
        isOnline = result.isOnline;
      } else {
        // Fallback to original repository for favorites/other filters
        final songDataResult = await _songRepository.getAllSongs();
        songs = songDataResult.songs;
        isOnline = songDataResult.isOnline;
      }

      final favoriteSongNumbers = await _favoritesRepository.getFavorites();

      for (var song in songs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      if (mounted) {
        // This ensures the state is only updated after the build is complete
        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _songs = songs;
            _isOnline = isOnline;
            _applyFilters();
            _isLoading = false;
          });
          _connectivityTimer?.cancel();
          _startConnectivityMonitoring();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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

  // ✅ UPDATED: Handle collection selection with backward compatibility
  void _onFilterChanged(String filter) {
    setState(() {
      if (filter == 'All' || filter == 'Favorites') {
        _activeFilter = filter;
        _currentCollection = null;
        if (filter == 'All' && _availableCollections.isNotEmpty) {
          // Set LPMI as default when "All" is selected
          _currentCollection = _availableCollections.firstWhere(
            (c) => c.id == 'LPMI',
            orElse: () => _availableCollections.first,
          );
        }
      } else if (filter == 'Alphabet' || filter == 'Number') {
        _sortOrder = filter;
      } else {
        // It's a collection name/id
        _activeFilter = 'Collection';
        SongCollection? collection;
        try {
          collection = _availableCollections.firstWhere(
            (c) => c.id == filter || c.name == filter,
          );
        } catch (e) {
          collection = _availableCollections.isNotEmpty
              ? _availableCollections.first
              : null;
        }
        _currentCollection = collection;
      }
    });
    if (_activeFilter == 'Collection' || filter == 'All') {
      _loadSongs(); // Reload songs when collection changes
    } else {
      _applyFilters(); // Just refilter existing songs
    }
  }

  // ✅ NEW: Show collection selection dialog
  void _showCollectionPicker() {
    if (!_collectionsLoaded || _availableCollections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No collections available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // All Songs option
            ListTile(
              leading: const Icon(Icons.library_music, color: Colors.blue),
              title: const Text('All Songs'),
              subtitle: const Text('Songs from all collections'),
              selected: _activeFilter == 'All',
              onTap: () {
                Navigator.pop(context);
                _onFilterChanged('All');
              },
            ),
            const Divider(),
            // Individual collections
            ..._availableCollections
                .map((collection) => ListTile(
                      leading: Icon(
                        Icons.folder_special,
                        color: _getCollectionColor(collection.id),
                      ),
                      title: Text(collection.name),
                      subtitle: Text('${collection.songCount} songs'),
                      selected: _currentCollection?.id == collection.id,
                      onTap: () {
                        Navigator.pop(context);
                        _onFilterChanged(collection.id);
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Get color for collection
  Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Colors.blue;
      case 'Lagu_belia':
        return Colors.green;
      case 'SRD':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  // ✅ NEW: Get current display title
  String get _currentDisplayTitle {
    if (_activeFilter == 'Favorites') {
      return 'Favorite Songs';
    } else if (_currentCollection != null) {
      return _currentCollection!.name;
    } else if (_activeFilter == 'All') {
      return 'All Collections';
    }
    return 'Full Songbook';
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
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildLargeScreenLayout(),
        desktop: _buildLargeScreenLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: MainDashboardDrawer(
        isFromDashboard: false,
        onFilterSelected: _onFilterChanged,
        onShowSettings: _navigateToSettingsPage,
      ),
      floatingActionButton:
          _collectionsLoaded && _availableCollections.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _showCollectionPicker,
                  tooltip: 'Select Collection',
                  child: const Icon(Icons.folder_special),
                )
              : null,
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

  Widget _buildLargeScreenLayout() {
    return ResponsiveScaffold(
      sidebar: MainDashboardDrawer(
        isFromDashboard: false,
        onFilterSelected: _onFilterChanged,
        onShowSettings: _navigateToSettingsPage,
      ),
      floatingActionButton:
          _collectionsLoaded && _availableCollections.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _showCollectionPicker,
                  tooltip: 'Select Collection',
                  child: const Icon(Icons.folder_special),
                )
              : null,
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildResponsiveHeader(),
            _buildResponsiveCollectionInfo(),
            _buildResponsiveSearchAndFilter(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_filteredSongs.isEmpty
                      ? _buildEmptyState()
                      : _buildSongsList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveHeader() {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final headerHeight = AppConstants.getHeaderHeight(deviceType);

    return SizedBox(
      height: headerHeight,
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
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.getContentPadding(deviceType),
                vertical: AppConstants.getSpacing(deviceType),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lagu Pujian Masa Ini',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      )),
                  SizedBox(height: AppConstants.getSpacing(deviceType) / 4),
                  Text(_currentDisplayTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCollectionInfo() {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.getContentPadding(deviceType),
        vertical: spacing / 2,
      ),
      child: Row(
        children: [
          Icon(
            Icons.library_music,
            color: theme.colorScheme.primary,
            size: 20 * AppConstants.getTypographyScale(deviceType),
          ),
          SizedBox(width: spacing / 2),
          Expanded(
              child: Text(_currentDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.titleMedium?.color,
                  ))),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing / 2,
              vertical: spacing / 4,
            ),
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Text('${_filteredSongs.length} songs',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(width: spacing / 2),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildResponsiveSearchAndFilter() {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.getContentPadding(deviceType),
        vertical: spacing / 2,
      ),
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
                contentPadding: EdgeInsets.symmetric(vertical: spacing),
              ),
            ),
          ),
          SizedBox(width: spacing),
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(spacing),
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
                        Text(_currentDisplayTitle,
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
    return GestureDetector(
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Checking connectivity...'),
            duration: Duration(seconds: 1),
          ),
        );
        await _loadSongs();
      },
      child: Container(
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
          border: Border.all(
            color: _isOnline
                ? (isDark ? Colors.green.shade600 : Colors.green.shade300)
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            width: 0.5,
          ),
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
            const SizedBox(width: 4),
            Icon(
              Icons.refresh,
              size: 10,
              color: _isOnline
                  ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
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

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return SongListItem(
          song: song,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SongLyricsPage(songNumber: song.number)),
          ).then((_) => _loadSongs()),
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
                  : 'No songs found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
              )),
        ]),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      // ✅ FIX: Use a post-frame callback to avoid the layout error
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stackTrace = details.stack;
          });
        }
      });
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('An unexpected error occurred.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
