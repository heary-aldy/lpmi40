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

  // Initialize controller
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

  // Load collections and songs with access control
  Future<void> loadCollectionsAndSongs({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final separatedCollections = await _songRepository
          .getCollectionsSeparated(forceRefresh: forceRefresh);

      // ✅ FIX: Check for a critical data failure.
      if ((separatedCollections['LPMI'] ?? []).isEmpty) {
        throw Exception(
            "Core 'LPMI' song collection could not be loaded. App cannot continue.");
      }

      _isOnline = separatedCollections.values.any((songs) => songs.isNotEmpty);

      final favoriteSongNumbers = await _favoritesRepository.getFavorites();
      final allSongs = separatedCollections['All'] ?? [];

      for (var song in allSongs) {
        song.isFavorite = favoriteSongNumbers.contains(song.number);
      }

      // Dynamically add all collections found in separatedCollections
      _availableCollections = [];
      _collectionSongs = {
        'All': allSongs,
        'Favorites': allSongs.where((s) => s.isFavorite).toList(),
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
          accessLevel = 'registered';
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

      debugPrint('[MainPageController] ✅ Collections loaded successfully');
    } catch (e) {
      _errorMessage = 'Failed to load collections: $e';
      debugPrint('[MainPageController] ❌ Error loading collections: $e');
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

  Future<void> toggleFavorite(Song song) async {
    try {
      if (song.isFavorite) {
        await _favoritesRepository.removeFavorite(song.number);
      } else {
        await _favoritesRepository.addFavorite(song.number);
      }
      song.isFavorite = !song.isFavorite;
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
