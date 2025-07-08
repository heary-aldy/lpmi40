import 'dart:async'; // ✅ ADDED: For Timer
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

// ✅ NEW: Import responsive layout utilities
import 'package:lpmi40/utils/constants.dart';
import 'package:lpmi40/src/widgets/responsive_layout.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';

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

  // ✅ ADDED: Enhanced connectivity monitoring
  Timer? _connectivityTimer;
  bool _wasOnline = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _initialize();
    _searchController.addListener(_applyFilters);

    // ✅ ADDED: Start connectivity monitoring
    _startConnectivityMonitoring();
  }

  Future<void> _initialize() async {
    _prefsService = await PreferencesService.init();
    await _loadSongs();
  }

  // ✅ ADDED: Smart connectivity monitoring
  void _startConnectivityMonitoring() {
    // Check connectivity every 30 seconds when online, every 10 seconds when offline
    _connectivityTimer = Timer.periodic(
      Duration(seconds: _isOnline ? 30 : 10),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Quick connectivity check without full reload
        try {
          final songDataResult = await _songRepository.getAllSongs();
          final currentOnlineStatus = songDataResult.isOnline;

          // Only reload if status changed
          if (currentOnlineStatus != _isOnline) {
            debugPrint(
                '📡 Connectivity changed: $_isOnline -> $currentOnlineStatus');
            _wasOnline = _isOnline;
            await _loadSongs();

            // Show user-friendly status message
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
          // Continue silently on connectivity check errors
          debugPrint('📡 Connectivity check error: $e');
        }
      },
    );
  }

  // ✅ ENHANCED: Updated to work with improved detection from Steps 1-2
  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Use improved detection from Steps 1-2
      final songDataResult = await _songRepository.getAllSongs();
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

        // Restart timer with appropriate interval
        _connectivityTimer?.cancel();
        _startConnectivityMonitoring();
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
      } else if (filter == 'Alphabet' || filter == 'Number') {
        _sortOrder = filter;
      }
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
    _connectivityTimer?.cancel(); // ✅ ADDED: Cancel connectivity timer
    super.dispose();
  }

  // ✅ ENHANCED: Build drawer with completely safe navigation handling
  Widget _buildSafeDrawer() {
    return Builder(
      builder: (context) {
        try {
          return MainDashboardDrawer(
            isFromDashboard: false,
            onFilterSelected: _onFilterChanged,
            onShowSettings: _navigateToSettingsPage,
          );
        } catch (e) {
          debugPrint('Drawer navigation error caught: $e');
          // Return a simplified drawer that won't cause navigation issues
          return MainDashboardDrawer(
            isFromDashboard: true, // Safe fallback
            onFilterSelected: _onFilterChanged,
            onShowSettings: _navigateToSettingsPage,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final shouldShowSidebar = AppConstants.shouldShowSidebar(deviceType);

    // ✅ NEW: Responsive layout with error handling
    return ErrorBoundary(
      child: ResponsiveLayout(
        // Mobile layout (existing behavior)
        mobile: _buildMobileLayout(),

        // Tablet and Desktop layout with sidebar
        tablet: _buildLargeScreenLayout(),
        desktop: _buildLargeScreenLayout(),
      ),
    );
  }

  // ✅ PRESERVED: Original mobile layout
  Widget _buildMobileLayout() {
    return Scaffold(
      drawer: _buildSafeDrawer(), // ✅ Use safe drawer
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

  // ✅ NEW: Large screen layout with sidebar and responsive content
  Widget _buildLargeScreenLayout() {
    return ResponsiveScaffold(
      sidebar: _buildSafeDrawer(), // ✅ Use safe drawer
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
                      : _buildResponsiveSongsList()),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Responsive header for larger screens
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
                  Text(
                      _activeFilter == 'Favorites'
                          ? 'Favorite Songs'
                          : 'Full Songbook',
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

  // ✅ NEW: Responsive collection info
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

  // ✅ NEW: Responsive search and filter
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

  // ✅ FIXED: Responsive songs list with proper height constraints to prevent overflow
  Widget _buildResponsiveSongsList() {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final columns = AppConstants.getSongColumns(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    if (columns == 1) {
      // Single column for mobile-like experience
      return _buildSongsList();
    }

    // Multi-column grid for larger screens with proper height management
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.getContentPadding(deviceType),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate item width and ensure adequate height for text
          final availableWidth =
              constraints.maxWidth - (spacing * (columns - 1));
          final itemWidth = availableWidth / columns;

          // ✅ FIXED: More generous height calculation to prevent overflow
          const baseHeight = 100.0; // Increased base height
          final scale = AppConstants.getTypographyScale(deviceType);
          final adjustedHeight = baseHeight * scale.clamp(1.0, 1.3);

          // Calculate aspect ratio - ensure it's not too tight
          final aspectRatio = (itemWidth / adjustedHeight).clamp(2.0, 4.0);

          return GridView.builder(
            padding: EdgeInsets.symmetric(vertical: spacing),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: _filteredSongs.length,
            itemBuilder: (context, index) {
              final song = _filteredSongs[index];

              // ✅ FIXED: Proper height constraints with minimum height
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: adjustedHeight,
                  minWidth: itemWidth * 0.8,
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SongLyricsPage(songNumber: song.number)),
                    ).then((_) => _loadSongs()),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(spacing * 0.75),
                      child: _buildCompactSongItem(song, itemWidth),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ FIXED: Compact song item with proper layout to prevent overflow
  Widget _buildCompactSongItem(Song song, double availableWidth) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);
    final scale = AppConstants.getTypographyScale(deviceType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ✅ FIXED: Start alignment
      children: [
        // Song number badge - fixed size
        Container(
          width: (36 * scale).clamp(32.0, 48.0),
          height: (36 * scale).clamp(32.0, 48.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              song.number,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (11 * scale).clamp(9.0, 13.0),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(width: spacing * 0.5),

        // ✅ FIXED: Song title and info - Expanded instead of Flexible + proper alignment
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment
                .start, // ✅ FIXED: Changed from center to start
            mainAxisSize: MainAxisSize.min, // ✅ FIXED: Use minimum size needed
            children: [
              Text(
                song.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: (12 * scale)
                      .clamp(10.0, 14.0), // ✅ FIXED: Clamped font size
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (song.verses.isNotEmpty) ...[
                SizedBox(height: spacing * 0.15), // ✅ FIXED: Reduced spacing
                Text(
                  '${song.verses.length} verses',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize:
                        (10 * scale).clamp(8.0, 12.0), // ✅ FIXED: Smaller font
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Favorite button - compact size
        SizedBox(
          width: (28 * scale).clamp(24.0, 36.0),
          height: (28 * scale).clamp(24.0, 36.0),
          child: IconButton(
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: song.isFavorite
                  ? Colors.red
                  : theme.iconTheme.color?.withOpacity(0.6),
              size: (14 * scale).clamp(12.0, 18.0),
            ),
            onPressed: () => _toggleFavorite(song),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  // ===== PRESERVED METHODS (existing mobile layouts) =====

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

  // ✅ ENHANCED: Updated status indicator with tap-to-refresh functionality
  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        // Manual refresh on tap
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
          // Add subtle border for tap indication
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
            // Add refresh icon hint
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

// ✅ NEW: Error boundary to catch navigation and other errors
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          debugPrint('Error caught in ErrorBoundary: $error');
          debugPrint('Stack trace: $stackTrace');

          // Return a safe fallback widget
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Something went wrong'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try to navigate to a safe state
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
