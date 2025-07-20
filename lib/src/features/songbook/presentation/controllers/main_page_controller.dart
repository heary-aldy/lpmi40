// lib/src/features/songbook/presentation/controllers/main_page_controller.dart
// ✅ NEW: Extracted business logic and state management from main_page.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
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
  // ✅ Dependencies
  final SongRepository _songRepository = SongRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  late PreferencesService _prefsService;

  // ✅ Core state
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String _activeFilter = 'LPMI';
  String _sortOrder = 'Number';
  bool _isOnline = true;
  String _searchQuery = '';

  // ✅ Collection state
  List<SimpleCollection> _availableCollections = [];
  SimpleCollection? _currentCollection;
  bool _collectionsLoaded = false;
  Map<String, List<Song>> _collectionSongs = {};

  // ✅ Access control state
  bool _canAccessCurrentCollection = true;
  String _accessDeniedReason = '';

  // ✅ Connectivity monitoring
  Timer? _connectivityTimer;

  // ✅ Error state
  String? _errorMessage;

  // ✅ Getters
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

  // ✅ Computed properties
  String get currentDisplayTitle {
    if (_activeFilter == 'Favorites') {
      return 'Favorite Songs';
    } else if (_activeFilter == 'All') {
      return 'All Collections';
    } else if (_currentCollection != null) {
      return _currentCollection!.name;
    }
    return 'LPMI Collection';
  }

  int get filteredSongCount => _filteredSongs.length;

  // ✅ Initialize controller
  Future<void> initialize({String initialFilter = 'LPMI'}) async {
    try {
      _activeFilter = initialFilter;
      _prefsService = await PreferencesService.init();
      await loadCollectionsAndSongs();
      _startConnectivityMonitoring();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      debugPrint('[MainPageController] ❌ Initialization failed: $e');
      notifyListeners();
    }
  }

  // ✅ Load collections and songs with access control
  Future<void> loadCollectionsAndSongs() async {
    try {
      _setLoading(true);
      _errorMessage = null;

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

      // Update favorite status
      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      // Create collections with access control
      _availableCollections = [
        SimpleCollection(
          id: 'LPMI',
          name: 'LPMI Collection',
          songCount: separatedCollections['LPMI']?.length ?? 0,
          color: const Color(0xFF2196F3), // Blue
          accessLevel: 'public',
        ),
        SimpleCollection(
          id: 'SRD',
          name: 'SRD Collection',
          songCount: separatedCollections['SRD']?.length ?? 0,
          color: const Color(0xFF9C27B0), // Purple
          accessLevel: 'registered',
        ),
        SimpleCollection(
          id: 'Lagu_belia',
          name: 'Lagu Belia',
          songCount: separatedCollections['Lagu_belia']?.length ?? 0,
          color: const Color(0xFF4CAF50), // Green
          accessLevel: 'premium',
        ),
      ];

      // Store collection songs
      _collectionSongs = {
        'All': allSongs,
        'LPMI': separatedCollections['LPMI'] ?? [],
        'SRD': separatedCollections['SRD'] ?? [],
        'Lagu_belia': separatedCollections['Lagu_belia'] ?? [],
        'Favorites': allSongs.where((s) => s.isFavorite).toList(),
      };

      // Check access and set current collection
      _checkCollectionAccess();
      _collectionsLoaded = true;
      _applyFilters();

      debugPrint('[MainPageController] ✅ Collections loaded successfully');
      debugPrint(
          '[MainPageController] 📊 Active filter: $_activeFilter, Access: $_canAccessCurrentCollection');
    } catch (e) {
      _errorMessage = 'Failed to load collections: $e';
      debugPrint('[MainPageController] ❌ Error loading collections: $e');
    } finally {
      _setLoading(false);
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

  // ✅ Apply filters and sorting
  void _applyFilters() {
    if (!_canAccessCurrentCollection) {
      _filteredSongs = [];
      notifyListeners();
      return;
    }

    List<Song> tempSongs = _activeFilter == 'Favorites'
        ? List.from(_collectionSongs['Favorites'] ?? [])
        : List.from(_songs);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tempSongs = tempSongs
          .where((song) =>
              song.number.toLowerCase().contains(query) ||
              song.title.toLowerCase().contains(query))
          .toList();
    }

    // Apply sorting
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

  // ✅ Update search query
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  // ✅ Change filter/collection
  void changeFilter(String filter) {
    if (_activeFilter == filter) return;

    // Handle sorting changes
    if (filter == 'Alphabet' || filter == 'Number') {
      _sortOrder = filter;
      _applyFilters();
      return;
    }

    _activeFilter = filter;
    _checkCollectionAccess();
    _applyFilters();

    debugPrint(
        '[MainPageController] 🔄 Filter changed to: $filter, Access: $_canAccessCurrentCollection');
  }

  // ✅ Toggle favorite status
  Future<void> toggleFavorite(Song song) async {
    try {
      // Check what methods are available in your FavoritesRepository
      // Common method names: addFavorite/removeFavorite, setFavorite, toggleFavorite

      if (song.isFavorite) {
        // Remove from favorites - adjust method name as needed
        await _favoritesRepository.removeFavorite(song.number);
      } else {
        // Add to favorites - adjust method name as needed
        await _favoritesRepository.addFavorite(song.number);
      }

      // Update local state
      song.isFavorite = !song.isFavorite;

      // Update favorites collection
      if (song.isFavorite) {
        _collectionSongs['Favorites']?.add(song);
      } else {
        _collectionSongs['Favorites']
            ?.removeWhere((s) => s.number == song.number);
      }

      _applyFilters();
    } catch (e) {
      debugPrint('[MainPageController] ❌ Failed to toggle favorite: $e');
      rethrow;
    }
  }

  // ✅ Refresh data
  Future<void> refresh() async {
    await loadCollectionsAndSongs();
  }

  // ✅ Start connectivity monitoring
  void _startConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      Duration(seconds: _isOnline ? 30 : 10),
      (timer) async {
        try {
          final currentOnlineStatus = _isOnline;
          await loadCollectionsAndSongs();

          if (_isOnline != currentOnlineStatus) {
            // Connectivity status changed - notify listeners will be called by loadCollectionsAndSongs
            debugPrint(
                '[MainPageController] 📡 Connectivity changed: online=$_isOnline');
          }
        } catch (e) {
          debugPrint('[MainPageController] 📡 Connectivity check error: $e');
        }
      },
    );
  }

  // ✅ Stop connectivity monitoring
  void stopConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  // ✅ Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // ✅ Get collection icon
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

  // ✅ Get collection color
  Color getCollectionColor() {
    if (_activeFilter == 'Favorites') return const Color(0xFFF44336); // Red
    return _currentCollection?.color ?? const Color(0xFF2196F3); // Blue
  }

  // ✅ Clean up resources
  @override
  void dispose() {
    stopConnectivityMonitoring();
    super.dispose();
  }
}
