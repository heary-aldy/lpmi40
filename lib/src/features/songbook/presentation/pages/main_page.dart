// lib/src/features/songbook/presentation/pages/main_page.dart
// ✅ FIXED: Removed missing CollectionService dependencies and using working SongRepository
// ✅ COLLECTIONS: Added working collection support with floating menu
// ✅ MODAL FIX: Fixed overflow error with DraggableScrollableSheet
// ✅ NAVIGATION FIX: Added collection context to prevent wrong lyrics showing
// ✅ DEFAULT: LPMI collection as default as requested

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

// ✅ NEW: Simple collection model to replace missing one
class SimpleCollection {
  final String id;
  final String name;
  final int songCount;
  final Color color;

  SimpleCollection({
    required this.id,
    required this.name,
    required this.songCount,
    required this.color,
  });
}

class MainPage extends StatefulWidget {
  final String initialFilter;
  const MainPage(
      {super.key, this.initialFilter = 'LPMI'}); // ✅ Changed default to LPMI

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

  // ✅ FIXED: Using simple collection data instead of missing service
  List<SimpleCollection> _availableCollections = [];
  SimpleCollection? _currentCollection;
  bool _collectionsLoaded = false;

  // ✅ NEW: Store collection song data
  Map<String, List<Song>> _collectionSongs = {};

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
    await _loadCollectionsAndSongs();
  }

  // ✅ FIXED: Load collections using separated song data
  Future<void> _loadCollectionsAndSongs() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      // ✅ NEW: Get collection-separated song data from repository
      final separatedCollections =
          await _songRepository.getCollectionsSeparated();

      // Check if we're online by seeing if collections have different song counts
      _isOnline = separatedCollections['LPMI']?.isNotEmpty == true ||
          separatedCollections['SRD']?.isNotEmpty == true ||
          separatedCollections['Lagu_belia']?.isNotEmpty == true;
      // Load favorites
      final favoriteSongNumbers = await _favoritesRepository.getFavorites();
      final allSongs = separatedCollections['All'] ?? [];

      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }
      // ✅ FIXED: Create collections with REAL separated data and counts
      _availableCollections = [
        SimpleCollection(
          id: 'LPMI',
          name: 'LPMI Collection',
          songCount: separatedCollections['LPMI']?.length ?? 0, // ✅ REAL count
          color: Colors.blue,
        ),
        SimpleCollection(
          id: 'SRD',
          name: 'SRD Collection',
          songCount: separatedCollections['SRD']?.length ?? 0, // ✅ REAL count
          color: Colors.purple,
        ),
        SimpleCollection(
          id: 'Lagu_belia',
          name: 'Lagu Belia',
          songCount:
              separatedCollections['Lagu_belia']?.length ?? 0, // ✅ REAL count
          color: Colors.green,
        ),
      ];
      // ✅ FIXED: Use separated collection data instead of allSongs for everything
      _collectionSongs = {
        'All': allSongs,
        'LPMI': separatedCollections['LPMI'] ?? [], // ✅ REAL LPMI songs
        'SRD': separatedCollections['SRD'] ?? [], // ✅ REAL SRD songs
        'Lagu_belia':
            separatedCollections['Lagu_belia'] ?? [], // ✅ REAL Lagu_belia songs
        'Favorites': allSongs.where((s) => s.isFavorite).toList(),
      };
      // ✅ FIXED: Set current collection and songs based on active filter
      if (_activeFilter == 'LPMI') {
        _currentCollection =
            _availableCollections.firstWhere((c) => c.id == 'LPMI');
        _songs = _collectionSongs['LPMI'] ?? []; // ✅ Use actual LPMI songs
      } else if (_activeFilter == 'SRD') {
        _currentCollection =
            _availableCollections.firstWhere((c) => c.id == 'SRD');
        _songs = _collectionSongs['SRD'] ?? []; // ✅ Use actual SRD songs
      } else if (_activeFilter == 'Lagu_belia') {
        _currentCollection =
            _availableCollections.firstWhere((c) => c.id == 'Lagu_belia');
        _songs = _collectionSongs['Lagu_belia'] ??
            []; // ✅ Use actual Lagu_belia songs
      } else if (_activeFilter == 'Favorites') {
        _currentCollection = null;
        _songs = _collectionSongs['Favorites'] ?? [];
      } else if (_activeFilter == 'All') {
        _currentCollection = null;
        _songs = allSongs;
      } else {
        // Default to LPMI if unknown filter
        _currentCollection = _availableCollections.first; // LPMI
        _songs = _collectionSongs['LPMI'] ?? [];
        _activeFilter = 'LPMI';
      }
      if (mounted) {
        setState(() {
          _collectionsLoaded = true;
          _applyFilters();
          _isLoading = false;
        });
      }
      // ✅ ENHANCED: More detailed logging
      debugPrint('[MainPage] ✅ Collections loaded with separated data:');
      debugPrint(
          '[MainPage] 📊 All Songs: ${_collectionSongs['All']?.length ?? 0}');
      debugPrint(
          '[MainPage] 📊 LPMI: ${_collectionSongs['LPMI']?.length ?? 0} songs');
      debugPrint(
          '[MainPage] 📊 SRD: ${_collectionSongs['SRD']?.length ?? 0} songs');
      debugPrint(
          '[MainPage] 📊 Lagu_belia: ${_collectionSongs['Lagu_belia']?.length ?? 0} songs');
      debugPrint(
          '[MainPage] 📊 Favorites: ${_collectionSongs['Favorites']?.length ?? 0} songs');
      debugPrint(
          '[MainPage] 🎯 Active filter: $_activeFilter, Songs loaded: ${_songs.length}');
    } catch (e) {
      debugPrint('[MainPage] ❌ Error loading collections: $e');
      if (mounted) {
        setState(() {
          _collectionsLoaded = true;
          _isLoading = false;
        });
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
          // This check is now implicitly handled by the logic within _loadCollectionsAndSongs
          // We just need to call it to see if the state changes.
          final currentOnlineStatus = _isOnline; // Store current state
          await _loadCollectionsAndSongs(); // This will update _isOnline

          if (_isOnline != currentOnlineStatus) {
            final message = _isOnline
                ? '🌐 Back online! Songs synced.'
                : '📱 Switched to offline mode.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
                backgroundColor: _isOnline ? Colors.green : Colors.orange,
              ),
            );
          }
        } catch (e) {
          debugPrint('📡 Connectivity check error: $e');
        }
      },
    );
  }

  void _applyFilters() {
    List<Song> tempSongs = _activeFilter == 'Favorites'
        ? _collectionSongs['Favorites'] ?? []
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

  // ✅ UPDATED: Enhanced collection selection with correct song loading
  void _onFilterChanged(String filter) {
    setState(() {
      if (filter == 'All') {
        _activeFilter = filter;
        _currentCollection = null;
        _songs = _collectionSongs['All'] ?? [];
      } else if (filter == 'Favorites') {
        _activeFilter = filter;
        _currentCollection = null;
        _songs = _collectionSongs['Favorites'] ?? [];
      } else if (filter == 'Alphabet' || filter == 'Number') {
        _sortOrder = filter;
        // Don't change songs, just re-apply filters for sorting
        _applyFilters();
        return; // Exit early since we don't need to reload songs
      } else {
        // It's a collection ID (LPMI, SRD, Lagu_belia)
        _activeFilter = filter;
        _currentCollection = _availableCollections.firstWhere(
          (c) => c.id == filter,
          orElse: () => _availableCollections.first,
        );
        _songs =
            _collectionSongs[filter] ?? []; // ✅ Use collection-specific songs
      }
    });
    _applyFilters();

    // ✅ ENHANCED: More detailed logging
    debugPrint('[MainPage] 🔄 Filter changed to: $filter');
    debugPrint('[MainPage] 📊 Songs loaded: ${_songs.length}');
    debugPrint(
        '[MainPage] 📊 Collection: ${_currentCollection?.name ?? 'None'}');

    // ✅ NEW: Log first few song titles to verify correct collection
    if (_songs.isNotEmpty) {
      final firstThreeTitles =
          _songs.take(3).map((s) => '${s.number}: ${s.title}').join(', ');
      debugPrint('[MainPage] 🎵 First songs: $firstThreeTitles');
    }
  }

  // ✅ FIXED: No more overflow - properly scrollable modal
  void _showCollectionPicker() {
    if (!_collectionsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collections are still loading...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ CRITICAL: Allow custom height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // ✅ IMPROVED: Start at 60% of screen height
        minChildSize: 0.4, // ✅ IMPROVED: Minimum 40% of screen height
        maxChildSize: 0.9, // ✅ IMPROVED: Maximum 90% of screen height
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // ✅ NEW: Drag handle for better UX
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ✅ FIXED: Header - not scrollable
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.folder_special,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Collection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // ✅ NEW: Close button for accessibility
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ✅ FIXED: Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // All Songs option
                    _buildCollectionListTile(
                      icon: Icons.library_music,
                      iconColor: Colors.blue,
                      title: 'All Songs',
                      subtitle: '${_collectionSongs['All']?.length ?? 0} songs',
                      isSelected: _activeFilter == 'All',
                      onTap: () {
                        Navigator.pop(context);
                        _onFilterChanged('All');
                      },
                    ),

                    const SizedBox(height: 8),

                    // ✅ IMPROVED: Section header for collections
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Collections',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                    // Individual collections
                    ..._availableCollections.map((collection) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildCollectionListTile(
                            icon: Icons.folder,
                            iconColor: collection.color,
                            title: collection.name,
                            subtitle: '${collection.songCount} songs',
                            isSelected: _currentCollection?.id == collection.id,
                            onTap: () {
                              Navigator.pop(context);
                              _onFilterChanged(collection.id);
                            },
                          ),
                        )),

                    const SizedBox(height: 16),

                    // ✅ IMPROVED: Section header for favorites
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Personal',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                    // Favorites option
                    _buildCollectionListTile(
                      icon: Icons.favorite,
                      iconColor: Colors.red,
                      title: 'Favorites',
                      subtitle:
                          '${_collectionSongs['Favorites']?.length ?? 0} songs',
                      isSelected: _activeFilter == 'Favorites',
                      onTap: () {
                        Navigator.pop(context);
                        _onFilterChanged('Favorites');
                      },
                    ),

                    // ✅ NEW: Bottom padding for better scrolling
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Helper method for consistent list tiles
  Widget _buildCollectionListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.7)
                : theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }

  // ✅ UPDATED: Get current display title with proper collection names
  String get _currentDisplayTitle {
    if (_activeFilter == 'Favorites') {
      return 'Favorite Songs';
    } else if (_activeFilter == 'All') {
      return 'All Collections';
    } else if (_currentCollection != null) {
      return _currentCollection!.name;
    }
    return 'LPMI Collection'; // Default
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

    // Update the master favorites list
    if (song.isFavorite) {
      _collectionSongs['Favorites']?.add(song);
    } else {
      _collectionSongs['Favorites']
          ?.removeWhere((s) => s.number == song.number);
    }
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
      floatingActionButton: _collectionsLoaded
          ? FloatingActionButton.extended(
              onPressed: _showCollectionPicker,
              tooltip: 'Select Collection',
              icon: const Icon(Icons.folder_special),
              label: Text(_activeFilter == 'All'
                  ? 'All Songs'
                  : _activeFilter == 'Favorites'
                      ? 'Favorites'
                      : _currentCollection?.name ?? 'Collections'),
              backgroundColor: _activeFilter == 'Favorites'
                  ? Colors.red
                  : _currentCollection?.color ??
                      Theme.of(context).colorScheme.primary,
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
      floatingActionButton: _collectionsLoaded
          ? FloatingActionButton.extended(
              onPressed: _showCollectionPicker,
              tooltip: 'Select Collection',
              icon: const Icon(Icons.folder_special),
              label: Text(_activeFilter == 'All'
                  ? 'All Songs'
                  : _activeFilter == 'Favorites'
                      ? 'Favorites'
                      : _currentCollection?.name ?? 'Collections'),
              backgroundColor: _activeFilter == 'Favorites'
                  ? Colors.red
                  : _currentCollection?.color ??
                      Theme.of(context).colorScheme.primary,
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
            _activeFilter == 'LPMI'
                ? Icons.library_music
                : _activeFilter == 'SRD'
                    ? Icons.auto_stories
                    : _activeFilter == 'Lagu_belia'
                        ? Icons.child_care
                        : _activeFilter == 'Favorites'
                            ? Icons.favorite
                            : _activeFilter == 'All'
                                ? Icons.library_music
                                : Icons.folder_special,
            color: _activeFilter == 'Favorites'
                ? Colors.red
                : _currentCollection?.color ?? theme.colorScheme.primary,
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
            _activeFilter == 'LPMI'
                ? Icons.library_music
                : _activeFilter == 'SRD'
                    ? Icons.auto_stories
                    : _activeFilter == 'Lagu_belia'
                        ? Icons.child_care
                        : _activeFilter == 'Favorites'
                            ? Icons.favorite
                            : _activeFilter == 'All'
                                ? Icons.library_music
                                : Icons.folder_special,
            color: _activeFilter == 'Favorites'
                ? Colors.red
                : _currentCollection?.color ?? theme.colorScheme.primary,
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
            content: Text('🔄 Refreshing collections...'),
            duration: Duration(seconds: 1),
          ),
        );
        await _loadCollectionsAndSongs();
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

  // ✅ FIXED: Now passes collection context to prevent wrong lyrics showing
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
                builder: (context) => SongLyricsPage(
                      songNumber: song.number,
                      // ✅ FIX: Pass collection context to prevent LPMI-only display
                      initialCollection:
                          _activeFilter, // Pass current collection filter
                      songObject: song, // Pass complete song object as backup
                    )),
          ).then((_) => _loadCollectionsAndSongs()),
          onFavoritePressed: () => _toggleFavorite(song),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    String title, subtitle;
    IconData icon;

    if (_activeFilter == 'Favorites' &&
        _collectionSongs['Favorites']!.isEmpty) {
      title = 'No favorite songs yet';
      subtitle = 'Tap the heart icon on songs to add them here';
      icon = Icons.favorite_border;
    } else if (_searchController.text.isNotEmpty && _filteredSongs.isEmpty) {
      title = 'No songs found';
      subtitle =
          'Try adjusting your search for "${_searchController.text}" or select a different collection';
      icon = Icons.search_off;
    } else if (_filteredSongs.isEmpty) {
      title = 'No songs in ${_currentCollection?.name ?? _activeFilter}';
      subtitle = 'This collection appears to be empty or still loading';
      icon = Icons.folder_open;
    } else {
      title = 'No songs found';
      subtitle =
          'Try adjusting your search or selecting a different collection';
      icon = Icons.search_off;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            icon,
            size: 64,
            color: theme.iconTheme.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center),
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
