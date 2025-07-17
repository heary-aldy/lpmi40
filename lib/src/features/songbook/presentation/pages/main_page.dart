// lib/src/features/songbook/presentation/pages/main_page.dart
// ✅ FIXED: Removed Center() wrapper from banner calls to fix positioning

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/features/settings/presentation/settings_page.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/song_lyrics_page.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/main_dashboard_drawer.dart';
import 'package:lpmi40/src/features/songbook/presentation/widgets/song_list_item.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/widgets/floating_audio_player.dart';
import 'package:lpmi40/src/widgets/compact_premium_banner.dart';
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';

// ✅ Enhanced collection model with access control
class SimpleCollection {
  final String id;
  final String name;
  final int songCount;
  final Color color;
  final String accessLevel; // public, registered, premium, admin, superadmin

  SimpleCollection({
    required this.id,
    required this.name,
    required this.songCount,
    required this.color,
    this.accessLevel = 'public', // Default to public
  });
}

class MainPage extends StatefulWidget {
  final String initialFilter;
  const MainPage({super.key, this.initialFilter = 'LPMI'});

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
  final bool _wasOnline = true;

  final TextEditingController _searchController = TextEditingController();

  // ✅ Collection data with access control
  List<SimpleCollection> _availableCollections = [];
  SimpleCollection? _currentCollection;
  bool _collectionsLoaded = false;

  // ✅ Store collection song data
  Map<String, List<Song>> _collectionSongs = {};

  // ✅ Access control state
  bool _canAccessCurrentCollection = true;
  String _accessDeniedReason = '';

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

  // ✅ Load collections with access control
  Future<void> _loadCollectionsAndSongs() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      // Get collection-separated song data from repository
      final separatedCollections =
          await _songRepository.getCollectionsSeparated();

      // Check if we're online
      _isOnline = separatedCollections['LPMI']?.isNotEmpty == true ||
          separatedCollections['SRD']?.isNotEmpty == true ||
          separatedCollections['Lagu_belia']?.isNotEmpty == true;

      // Load favorites
      final favoriteSongNumbers = await _favoritesRepository.getFavorites();
      final allSongs = separatedCollections['All'] ?? [];

      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      // ✅ Create collections with access control
      _availableCollections = [
        SimpleCollection(
          id: 'LPMI',
          name: 'LPMI Collection',
          songCount: separatedCollections['LPMI']?.length ?? 0,
          color: Colors.blue,
          accessLevel: 'public', // Everyone can access
        ),
        SimpleCollection(
          id: 'SRD',
          name: 'SRD Collection',
          songCount: separatedCollections['SRD']?.length ?? 0,
          color: Colors.purple,
          accessLevel: 'registered', // ✅ Requires login
        ),
        SimpleCollection(
          id: 'Lagu_belia',
          name: 'Lagu Belia',
          songCount: separatedCollections['Lagu_belia']?.length ?? 0,
          color: Colors.green,
          accessLevel: 'premium', // ✅ Requires premium
        ),
      ];

      // Use separated collection data
      _collectionSongs = {
        'All': allSongs,
        'LPMI': separatedCollections['LPMI'] ?? [],
        'SRD': separatedCollections['SRD'] ?? [],
        'Lagu_belia': separatedCollections['Lagu_belia'] ?? [],
        'Favorites': allSongs.where((s) => s.isFavorite).toList(),
      };

      // ✅ Check access and set current collection
      _checkCollectionAccess();

      // ✅ SYNC WITH SONG PROVIDER
      final songProvider = context.read<SongProvider>();
      songProvider.setCollectionSongs(_collectionSongs);
      songProvider.setCurrentCollection(_activeFilter);

      if (mounted) {
        setState(() {
          _collectionsLoaded = true;
          _applyFilters();
          _isLoading = false;
        });
      }

      debugPrint('[MainPage] ✅ Collections loaded with access control');
      debugPrint(
          '[MainPage] 📊 Active filter: $_activeFilter, Access: $_canAccessCurrentCollection');
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

  // ✅ Check collection access based on user status
  void _checkCollectionAccess() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;
    final isLoggedIn = user != null && !user.isAnonymous;

    if (_activeFilter == 'LPMI' || _activeFilter == 'All') {
      // LPMI and All are always accessible
      _canAccessCurrentCollection = true;
      _currentCollection = _availableCollections.firstWhere(
        (c) => c.id == _activeFilter,
        orElse: () => _availableCollections.first,
      );
      _songs = _collectionSongs[_activeFilter] ?? [];
    } else if (_activeFilter == 'Favorites') {
      // Favorites requires login
      _canAccessCurrentCollection = isLoggedIn;
      _accessDeniedReason = isGuest ? 'login_required' : 'ok';
      _currentCollection = null;
      _songs = _canAccessCurrentCollection
          ? (_collectionSongs['Favorites'] ?? [])
          : [];
    } else {
      // Check specific collection access
      final collection = _availableCollections.firstWhere(
        (c) => c.id == _activeFilter,
        orElse: () => _availableCollections.first,
      );

      _currentCollection = collection;

      switch (collection.accessLevel) {
        case 'public':
          _canAccessCurrentCollection = true;
          _songs = _collectionSongs[_activeFilter] ?? [];
          break;
        case 'registered':
          _canAccessCurrentCollection = isLoggedIn;
          _accessDeniedReason = isGuest ? 'login_required' : 'ok';
          _songs = _canAccessCurrentCollection
              ? (_collectionSongs[_activeFilter] ?? [])
              : [];
          break;
        case 'premium':
          _canAccessCurrentCollection = isLoggedIn; // TODO: Add premium check
          _accessDeniedReason = isGuest ? 'login_required' : 'premium_required';
          _songs = _canAccessCurrentCollection
              ? (_collectionSongs[_activeFilter] ?? [])
              : [];
          break;
        default:
          _canAccessCurrentCollection = false;
          _accessDeniedReason = 'access_denied';
          _songs = [];
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
          final currentOnlineStatus = _isOnline;
          await _loadCollectionsAndSongs();

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
    if (!_canAccessCurrentCollection) {
      setState(() => _filteredSongs = []);
      return;
    }

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

  // ✅ Enhanced collection selection with access control
  void _onFilterChanged(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == 'Alphabet' || filter == 'Number') {
        _sortOrder = filter;
        _applyFilters();
        return;
      }
    });

    _checkCollectionAccess();

    // ✅ SYNC WITH SONG PROVIDER
    final songProvider = context.read<SongProvider>();
    songProvider.setCurrentCollection(_activeFilter);

    _applyFilters();

    debugPrint(
        '[MainPage] 🔄 Filter changed to: $filter, Access: $_canAccessCurrentCollection');
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

    // ✅ Use SongProvider for favorite management
    context.read<SongProvider>().toggleFavorite(song);

    // Update local collections
    if (song.isFavorite) {
      _collectionSongs['Favorites']?.add(song);
    } else {
      _collectionSongs['Favorites']
          ?.removeWhere((s) => s.number == song.number);
    }
    _applyFilters();
  }

  String get _currentDisplayTitle {
    if (_activeFilter == 'Favorites') {
      return 'Favorite Songs';
    } else if (_activeFilter == 'All') {
      return 'All Collections';
    } else if (_currentCollection != null) {
      return _currentCollection!.name;
    }
    return 'LPMI Collection';
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
        onShowSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        ),
      ),
      // ✅ PREMIUM: Add FloatingAudioPlayer to Stack
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildCollectionInfo(),
              _buildSearchAndFilter(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMainContent(),
              ),
            ],
          ),
          // ✅ PREMIUM: FloatingAudioPlayer integration
          const FloatingAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return ResponsiveScaffold(
      sidebar: MainDashboardDrawer(
        isFromDashboard: false,
        onFilterSelected: _onFilterChanged,
        onShowSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        ),
      ),
      body: Stack(
        children: [
          ResponsiveContainer(
            child: Column(
              children: [
                _buildResponsiveHeader(),
                _buildResponsiveCollectionInfo(),
                _buildResponsiveSearchAndFilter(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMainContent(),
                ),
              ],
            ),
          ),
          // ✅ PREMIUM: FloatingAudioPlayer integration
          const FloatingAudioPlayer(),
        ],
      ),
    );
  }

  // ✅ Main content with access control and banners
  Widget _buildMainContent() {
    if (!_canAccessCurrentCollection) {
      return _buildAccessDeniedState();
    }

    if (_filteredSongs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // ✅ Song list
        Expanded(
          child: _buildSongsList(),
        ),
        // ✅ Compact premium banner at bottom
        _buildBottomBanner(),
      ],
    );
  }

  // ✅ FIXED: Access denied state with proper banner positioning
  Widget _buildAccessDeniedState() {
    return Column(
      children: [
        Expanded(
          child: _buildEmptyState(),
        ),
        // Show appropriate banner based on access denial reason
        if (_accessDeniedReason == 'login_required')
          const LoginPromptBanner() // ✅ FIXED: Removed Center() wrapper
        else if (_accessDeniedReason == 'premium_required')
          const AudioUpgradeBanner(), // ✅ FIXED: Removed Center() wrapper
      ],
    );
  }

  // ✅ FIXED: Bottom banner with proper positioning
  Widget _buildBottomBanner() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    // Show different banners based on user state
    if (isGuest) {
      return const LoginPromptBanner(); // ✅ FIXED: Removed Center() wrapper
    } else {
      return const AudioUpgradeBanner(); // ✅ FIXED: Removed Center() wrapper
    }
  }

  // ✅ Build songs list without blocking UI
  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return Consumer<SongProvider>(
          builder: (context, songProvider, child) {
            return SongListItem(
              song: song,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongLyricsPage(
                    songNumber: song.number,
                    initialCollection: _activeFilter,
                    songObject: song,
                  ),
                ),
              ).then((_) => _loadCollectionsAndSongs()),
              onFavoritePressed: () => _toggleFavorite(song),
              // ✅ PREMIUM: Add play functionality
              onPlayPressed: () => songProvider.selectSong(song),
              isPlaying:
                  songProvider.isCurrentSong(song) && songProvider.isPlaying,
              canPlay: songProvider.canPlaySong(song),
            );
          },
        );
      },
    );
  }

  // ✅ Rest of the existing methods (header, collection info, search, etc.)
  Widget _buildHeader() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: theme.colorScheme.primary),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 4.0,
                right: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.white, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: 'Open Menu',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lagu Pujian Masa Ini',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentDisplayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
            _getCollectionIcon(),
            color: _getCollectionColor(theme),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentDate,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredSongs.length} songs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  IconData _getCollectionIcon() {
    switch (_activeFilter) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      case 'Favorites':
        return Icons.favorite;
      case 'All':
        return Icons.library_music;
      default:
        return Icons.folder_special;
    }
  }

  Color _getCollectionColor(ThemeData theme) {
    if (_activeFilter == 'Favorites') return Colors.red;
    return _currentCollection?.color ?? theme.colorScheme.primary;
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
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sort, color: theme.colorScheme.primary),
            ),
            tooltip: 'Sort options',
            onSelected: _onFilterChanged,
            color: theme.popupMenuTheme.color,
            shape: theme.popupMenuTheme.shape,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Number',
                child: Text(
                  'Sort by Number',
                  style: TextStyle(
                    fontWeight: _sortOrder == 'Number' ? FontWeight.bold : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Alphabet',
                child: Text(
                  'Sort A-Z',
                  style: TextStyle(
                    fontWeight:
                        _sortOrder == 'Alphabet' ? FontWeight.bold : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    String title, subtitle;
    IconData icon;

    if (!_canAccessCurrentCollection) {
      if (_accessDeniedReason == 'login_required') {
        title = 'Login Required';
        subtitle = 'Please log in to access this collection and save favorites';
        icon = Icons.login;
      } else if (_accessDeniedReason == 'premium_required') {
        title = 'Premium Required';
        subtitle = 'Upgrade to Premium to access this collection';
        icon = Icons.star;
      } else {
        title = 'Access Denied';
        subtitle = 'You don\'t have permission to access this collection';
        icon = Icons.lock;
      }
    } else if (_activeFilter == 'Favorites' &&
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Responsive versions (similar to mobile but with different spacing)
  Widget _buildResponsiveHeader() {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final headerHeight = AppConstants.getHeaderHeight(deviceType);

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: theme.colorScheme.primary),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
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
                  Text(
                    'Lagu Pujian Masa Ini',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppConstants.getSpacing(deviceType) / 4),
                  Text(
                    _currentDisplayTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
            _getCollectionIcon(),
            color: _getCollectionColor(theme),
            size: 20 * AppConstants.getTypographyScale(deviceType),
          ),
          SizedBox(width: spacing / 2),
          Expanded(
            child: Text(
              _currentDate,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing / 2,
              vertical: spacing / 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredSongs.length} songs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sort, color: theme.colorScheme.primary),
            ),
            tooltip: 'Sort options',
            onSelected: _onFilterChanged,
            color: theme.popupMenuTheme.color,
            shape: theme.popupMenuTheme.shape,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Number',
                child: Text(
                  'Sort by Number',
                  style: TextStyle(
                    fontWeight: _sortOrder == 'Number' ? FontWeight.bold : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'Alphabet',
                child: Text(
                  'Sort A-Z',
                  style: TextStyle(
                    fontWeight:
                        _sortOrder == 'Alphabet' ? FontWeight.bold : null,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ Error boundary remains the same
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
                const Text(
                  'An unexpected error occurred.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
