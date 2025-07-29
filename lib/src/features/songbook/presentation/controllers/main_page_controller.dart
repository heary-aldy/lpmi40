// lib/src/features/songbook/presentation/controllers/main_page_controller.dart
// ✅ FIXED: Added checks for empty data to prevent layout crashes.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

// Enhanced collection model with access control
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
    this.accessLevel = 'public',
  });
}

class MainPageController extends ChangeNotifier {
  // Dependencies
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  late PreferencesService _prefsService;

  // Core state
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String _activeFilter = 'LPMI';
  String _sortOrder = 'Number';
  bool _isOnline = true;
  String _searchQuery = '';

  // Collection state
  List<SimpleCollection> _availableCollections = [];
  SimpleCollection? _currentCollection;
  bool _collectionsLoaded = false;
  Map<String, List<Song>> _collectionSongs = {};

  // Access control state
  bool _canAccessCurrentCollection = true;
  String _accessDeniedReason = '';

  // Connectivity monitoring
  Timer? _connectivityTimer;

  // Error state
  String? _errorMessage;

  // Getters
  List<Song> get songs => _songs;
  List<Song> get filteredSongs => _filteredSongs;
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;
  String get sortOrder => _sortOrder;
  bool get isOnline => _isOnline;
  String get searchQuery => _searchQuery;

  List<SimpleCollection> get availableCollections => _availableCollections;
  SimpleCollection? get currentCollection => _currentCollection;
  bool get collectionsLoaded => _collectionsLoaded;
  Map<String, List<Song>> get collectionSongs => _collectionSongs;

  bool get canAccessCurrentCollection => _canAccessCurrentCollection;
  String get accessDeniedReason => _accessDeniedReason;
  String? get errorMessage => _errorMessage;

  // Computed properties
  String get currentDisplayTitle {
    if (_errorMessage != null) return 'Error';
    if (_isLoading) return 'Loading...';
    if (_activeFilter == 'Favorites') return 'Favorite Songs';
    if (_activeFilter == 'All') return 'All Collections';
    if (_currentCollection != null) return _currentCollection!.name;
    return 'LPMI Collection';
  }

  int get filteredSongCount => _filteredSongs.length;

  // Private premium status getter (TODO: Implement actual premium check)
  bool get _userHasPremium =>
      false; // Default to false until premium system is implemented

  // Load collections from repository - used by initialize() and setFilter()
  Future<void> _loadCollections() async {
    await loadCollectionsAndSongs();
  }

  // Initialize controller
  Future<void> initialize(
      {String initialFilter = 'LPMI', String? collectionAccessLevel}) async {
    try {
      _activeFilter = initialFilter;
      _prefsService = await PreferencesService.init();

      // First load collections to determine access levels
      await loadCollectionsAndSongs();

      // Check if the selected collection is public before applying other access checks
      if (_activeFilter != 'Favorites' &&
          _collectionSongs.containsKey(_activeFilter)) {
        // If a specific access level was provided, override the one from the database
        if (collectionAccessLevel != null) {
          // Find the collection and update its access level
          final existingCollectionIndex =
              _availableCollections.indexWhere((c) => c.id == _activeFilter);
          if (existingCollectionIndex >= 0) {
            // Clone the collection with updated access level
            final existingCollection =
                _availableCollections[existingCollectionIndex];
            _availableCollections[existingCollectionIndex] = SimpleCollection(
              id: existingCollection.id,
              name: existingCollection.name,
              songCount: existingCollection.songCount,
              color: existingCollection.color,
              accessLevel: collectionAccessLevel,
            );
            debugPrint(
                '[MainPageController] 🔑 Access level overridden for $_activeFilter: $collectionAccessLevel');
          }
        }

        final collection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => SimpleCollection(
            id: _activeFilter,
            name: _activeFilter,
            songCount: 0,
            color: Colors.blue,
          ),
        );

        // If the collection is public, ensure access is granted without login
        if (collection.accessLevel == 'public') {
          _canAccessCurrentCollection = true;
          _accessDeniedReason = 'ok';
          debugPrint(
              '[MainPageController] 🔓 Public collection accessed: $_activeFilter');
        }
      }

      // Now apply the filter which will respect the public collection setting we just made
      await setFilter(_activeFilter);

      _startConnectivityMonitoring();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      debugPrint('[MainPageController] ❌ Initialization failed: $e');
      notifyListeners();
    }
  }

  // Load collections and songs with access control
  Future<void> loadCollectionsAndSongs({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final separatedCollections = await _songRepository
          .getCollectionsSeparated(forceRefresh: forceRefresh);

      // ✅ RESILIENT: Log warning instead of throwing exception
      if ((separatedCollections['LPMI'] ?? []).isEmpty) {
        debugPrint(
            '[MainPageController] ⚠️ WARNING: LPMI collection is empty, but continuing with available data');
      }

      _isOnline = separatedCollections.values.any((songs) => songs.isNotEmpty);

      // ✅ NEW: Load all favorites (global and collection-specific)
      final allFavoriteSongNumbers = await _favoritesRepository.getFavorites();

      // ✅ FIX: Collect ALL songs from ALL collections to find favorites
      final allSongsAcrossCollections = <Song>[];
      final songNumbersAdded = <String>{};

      // Add songs from all collections, avoiding duplicates
      for (final entry in separatedCollections.entries) {
        if (entry.key == 'All') {
          continue; // Skip 'All' to avoid potential duplicates
        }

        for (final song in entry.value) {
          if (!songNumbersAdded.contains(song.number)) {
            songNumbersAdded.add(song.number);
            // ✅ NEW: Check both global favorites and collection-specific favorites
            song.isFavorite = allFavoriteSongNumbers.contains(song.number);
            allSongsAcrossCollections.add(song);
          }
        }
      }

      // Also process the 'All' collection if it exists and has unique songs
      final allSongs = separatedCollections['All'] ?? [];
      for (var song in allSongs) {
        if (!songNumbersAdded.contains(song.number)) {
          songNumbersAdded.add(song.number);
          song.isFavorite = allFavoriteSongNumbers.contains(song.number);
          allSongsAcrossCollections.add(song);
        } else {
          // Update favorite status for existing songs
          song.isFavorite = allFavoriteSongNumbers.contains(song.number);
        }
      }

      // Dynamically add all collections found in separatedCollections
      _availableCollections = [];
      _collectionSongs = {
        'All': allSongs.isNotEmpty ? allSongs : allSongsAcrossCollections,
        'Favorites':
            allSongsAcrossCollections.where((s) => s.isFavorite).toList(),
      };
      separatedCollections.forEach((key, value) {
        if (key == 'All' || key == 'Favorites') return;
        String displayName = key;
        Color color = Colors.orange;
        String accessLevel = 'public';
        if (key == 'LPMI') {
          displayName = 'LPMI Collection';
          color = const Color(0xFF2196F3);
          accessLevel = 'public';
        } else if (key == 'SRD') {
          displayName = 'SRD Collection';
          color = const Color(0xFF9C27B0);
          accessLevel =
              'public'; // ✅ CHANGED: Made SRD public so no login required
        } else if (key == 'Lagu_belia') {
          displayName = 'Lagu Belia';
          color = const Color(0xFF4CAF50);
          accessLevel = 'premium';
        } else if (key == 'lagu_krismas_26346') {
          displayName = 'Christmas';
          color = Colors.redAccent;
          accessLevel = 'public';
        }
        _availableCollections.add(SimpleCollection(
          id: key,
          name: displayName,
          songCount: value.length,
          color: color,
          accessLevel: accessLevel,
        ));
        _collectionSongs[key] = value;
      });

      _checkCollectionAccess();
      _collectionsLoaded = true;
      _applyFilters();

      // ✅ DEBUG: Add diagnostic information
      debugPrint('[MainPageController] ✅ Collections loaded successfully');
      debugPrint(
          '[MainPageController] 📊 Available collections: ${_availableCollections.length}');
      debugPrint(
          '[MainPageController] 📊 Total songs across all collections: ${_collectionSongs.values.fold(0, (sum, songs) => sum + songs.length)}');
      debugPrint('[MainPageController] 📊 Active filter: $_activeFilter');
      debugPrint(
          '[MainPageController] 📊 Filtered songs: ${_filteredSongs.length}');
    } catch (e) {
      _errorMessage = 'Failed to load collections: $e';
      debugPrint('[MainPageController] ❌ Error loading collections: $e');

      // ✅ FALLBACK: Try to provide minimal functionality even on error
      _availableCollections = [];
      _collectionSongs = {'All': [], 'LPMI': [], 'Favorites': []};
      _collectionsLoaded = true;
      _applyFilters();
    } finally {
      _setLoading(false);
    }
  }

  void _checkCollectionAccess() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;
    final isLoggedIn = user != null && !user.isAnonymous;

    if (_activeFilter == 'LPMI' || _activeFilter == 'All') {
      _canAccessCurrentCollection = true;
      _currentCollection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => _availableCollections.first);
      _songs = _collectionSongs[_activeFilter] ?? [];
    } else if (_activeFilter == 'Favorites') {
      _canAccessCurrentCollection = isLoggedIn;
      _accessDeniedReason = isGuest ? 'login_required' : 'ok';
      _currentCollection = null;
      _songs = _canAccessCurrentCollection
          ? (_collectionSongs['Favorites'] ?? [])
          : [];
    } else {
      final collection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => _availableCollections.first);
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
          _canAccessCurrentCollection =
              isLoggedIn; // TODO: Add real premium check
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

  void _applyFilters() {
    if (!_canAccessCurrentCollection) {
      _filteredSongs = [];
      notifyListeners();
      return;
    }

    List<Song> tempSongs = _activeFilter == 'Favorites'
        ? List.from(_collectionSongs['Favorites'] ?? [])
        : List.from(_songs);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
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

    _filteredSongs = tempSongs;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  void changeFilter(String filter) {
    if (_activeFilter == filter) return;

    if (filter == 'Alphabet' || filter == 'Number') {
      _sortOrder = filter;
      _applyFilters();
      return;
    }

    _activeFilter = filter;
    _checkCollectionAccess();
    _applyFilters();
  }

  // Update filter and reload songs accordingly
  Future<void> setFilter(String filter) async {
    _activeFilter = filter;
    _isLoading = true;
    notifyListeners();

    // Load collections if not loaded
    if (!_collectionsLoaded) {
      await _loadCollections();
    }

    // Get the current auth state
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;
    final isLoggedIn = user != null && !user.isAnonymous;

    // Check if the collection is public - this ensures public collections don't need login
    bool isPublicCollection = false;
    if (_activeFilter != 'Favorites' &&
        _activeFilter != 'LPMI' &&
        _activeFilter != 'All') {
      final collection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => _availableCollections.first);
      isPublicCollection = collection.accessLevel == 'public';
    }

    if (_activeFilter == 'LPMI' || _activeFilter == 'All') {
      _canAccessCurrentCollection = true;
      _currentCollection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => _availableCollections.first);
      _songs = _collectionSongs[_activeFilter] ?? [];
    } else if (_activeFilter == 'Favorites') {
      _canAccessCurrentCollection = isLoggedIn;
      _accessDeniedReason = isGuest ? 'login_required' : 'ok';
      _currentCollection = null;
      _songs = _canAccessCurrentCollection
          ? (_collectionSongs['Favorites'] ?? [])
          : [];
    } else {
      final collection = _availableCollections.firstWhere(
          (c) => c.id == _activeFilter,
          orElse: () => _availableCollections.first);
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
          _canAccessCurrentCollection =
              isLoggedIn && _userHasPremium; // Check if user has premium
          _accessDeniedReason = !isLoggedIn
              ? 'login_required'
              : !_userHasPremium
                  ? 'premium_required'
                  : 'ok';
          _songs = _canAccessCurrentCollection
              ? (_collectionSongs[_activeFilter] ?? [])
              : [];
          break;
        default:
          _canAccessCurrentCollection = false;
          _accessDeniedReason = 'unknown';
          _songs = [];
      }
    }

    _applyFilters();
    _setLoading(false);
  }

  Future<void> toggleFavorite(Song song) async {
    try {
      // Get the collection context for this song
      final collection = song.collectionId ?? _activeFilter;

      if (song.isFavorite) {
        await _favoritesRepository.toggleFavoriteStatus(
            song.number, true, collection);
      } else {
        await _favoritesRepository.toggleFavoriteStatus(
            song.number, false, collection);
      }

      // Update favorite status across ALL collections and songs with same number
      final newFavoriteStatus = !song.isFavorite;

      for (final collectionEntry in _collectionSongs.entries) {
        for (final collectionSong in collectionEntry.value) {
          if (collectionSong.number == song.number) {
            collectionSong.isFavorite = newFavoriteStatus;
          }
        }
      }

      // Update the main song object
      song.isFavorite = newFavoriteStatus;

      // Update favorites collection
      if (newFavoriteStatus) {
        // Add to favorites if not already there
        if (!_collectionSongs['Favorites']!
            .any((s) => s.number == song.number)) {
          _collectionSongs['Favorites']?.add(song);
        }
      } else {
        // Remove from favorites
        _collectionSongs['Favorites']
            ?.removeWhere((s) => s.number == song.number);
      }

      _applyFilters();
    } catch (e) {
      debugPrint('[MainPageController] ❌ Failed to toggle favorite: $e');
      rethrow;
    }
  }

  Future<void> refresh({bool forceRefresh = false}) async {
    await loadCollectionsAndSongs(forceRefresh: forceRefresh);
  }

  // Force refresh to bypass cache
  Future<void> forceRefresh() async {
    await loadCollectionsAndSongs(forceRefresh: true);
  }

  void _startConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer =
        Timer.periodic(Duration(seconds: _isOnline ? 30 : 10), (timer) async {
      try {
        await loadCollectionsAndSongs();
      } catch (e) {
        debugPrint('[MainPageController] 📡 Connectivity check error: $e');
      }
    });
  }

  void stopConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  IconData getCollectionIcon() {
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

  Color getCollectionColor() {
    if (_activeFilter == 'Favorites') return const Color(0xFFF44336);
    return _currentCollection?.color ?? const Color(0xFF2196F3);
  }

  @override
  void dispose() {
    stopConnectivityMonitoring();
    super.dispose();
  }
}
