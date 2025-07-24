// TODO Implement this library.
// lib/src/features/songbook/repository/enhanced_song_repository.dart
// Enhanced Song Repository with collection support and dual-read capability
// Maintains 100% backward compatibility while adding collection features

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_collection_repository.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

// Extended result classes for collection-aware operations
class UnifiedSongDataResult {
  final List<Song> songs;
  final bool isOnline;
  final int legacySongs;
  final int collectionSongs;
  final List<String> activeCollections;

  UnifiedSongDataResult({
    required this.songs,
    required this.isOnline,
    required this.legacySongs,
    required this.collectionSongs,
    required this.activeCollections,
  });

  int get totalSongs => songs.length;
  bool get hasCollectionSongs => collectionSongs > 0;
  bool get hasLegacySongs => legacySongs > 0;
  bool get isHybridMode => hasCollectionSongs && hasLegacySongs;
}

class SongSearchResult {
  final List<Song> songs;
  final bool isOnline;
  final String searchTerm;
  final int totalMatches;
  final Map<String, int> collectionMatches; // collectionId -> match count

  SongSearchResult({
    required this.songs,
    required this.isOnline,
    required this.searchTerm,
    required this.totalMatches,
    required this.collectionMatches,
  });
}

class SongAvailabilityResult {
  final Song? song;
  final bool isOnline;
  final bool foundInLegacy;
  final bool foundInCollections;
  final List<String> availableInCollections;

  SongAvailabilityResult({
    required this.song,
    required this.isOnline,
    required this.foundInLegacy,
    required this.foundInCollections,
    required this.availableInCollections,
  });

  bool get isAvailable => song != null;
  bool get isInMultipleCollections => availableInCollections.length > 1;
}

// Parsing functions for compute isolation
Map<String, dynamic> _parseUnifiedSongsData(String jsonString) {
  try {
    final Map<String, dynamic> input = json.decode(jsonString);
    final Map<String, dynamic>? legacySongs = input['legacySongs'];
    final Map<String, dynamic>? collectionSongs = input['collectionSongs'];

    final List<Song> allSongs = [];
    final Set<String> processedSongNumbers = {};
    int legacyCount = 0;
    int collectionCount = 0;
    final List<String> activeCollections = [];

    // Process collection songs first (they take precedence)
    if (collectionSongs != null) {
      for (final collectionEntry in collectionSongs.entries) {
        final collectionId = collectionEntry.key;
        activeCollections.add(collectionId);

        if (collectionEntry.value is Map) {
          final songMap =
              Map<String, dynamic>.from(collectionEntry.value as Map);
          for (final songEntry in songMap.entries) {
            try {
              final songData =
                  Map<String, dynamic>.from(songEntry.value as Map);
              final song = Song.fromJson(songData);

              if (!processedSongNumbers.contains(song.number)) {
                allSongs.add(song);
                processedSongNumbers.add(song.number);
                collectionCount++;
              }
            } catch (e) {
              debugPrint(
                  '❌ Error parsing collection song ${songEntry.key}: $e');
            }
          }
        }
      }
    }

    // Process legacy songs (only if not already in collections)
    if (legacySongs != null) {
      for (final entry in legacySongs.entries) {
        try {
          final songData = Map<String, dynamic>.from(entry.value as Map);
          final song = Song.fromJson(songData);

          if (!processedSongNumbers.contains(song.number)) {
            allSongs.add(song);
            processedSongNumbers.add(song.number);
            legacyCount++;
          }
        } catch (e) {
          debugPrint('❌ Error parsing legacy song ${entry.key}: $e');
        }
      }
    }

    // Sort by song number
    allSongs.sort((a, b) =>
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

    return {
      'songs': allSongs,
      'legacyCount': legacyCount,
      'collectionCount': collectionCount,
      'activeCollections': activeCollections,
    };
  } catch (e) {
    debugPrint('❌ Error parsing unified songs data: $e');
    return {
      'songs': <Song>[],
      'legacyCount': 0,
      'collectionCount': 0,
      'activeCollections': <String>[],
    };
  }
}

List<Song> _parseSongsFromAssets(String jsonString) {
  try {
    final dynamic jsonData = json.decode(jsonString);
    final List<Song> songs = [];

    // Handle both array and object formats for backward compatibility
    if (jsonData is List) {
      // Old array format
      for (int i = 0; i < jsonData.length; i++) {
        try {
          final songData = Map<String, dynamic>.from(jsonData[i] as Map);
          final song = Song.fromJson(songData);
          songs.add(song);
        } catch (e) {
          debugPrint('❌ Error parsing asset song at index $i: $e');
          continue;
        }
      }
    } else if (jsonData is Map) {
      // New object format with numeric string keys
      final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonData);
      for (final entry in songMap.entries) {
        try {
          final songData = Map<String, dynamic>.from(entry.value as Map);
          final song = Song.fromJson(songData);
          songs.add(song);
        } catch (e) {
          debugPrint('❌ Error parsing asset song with key ${entry.key}: $e');
          continue;
        }
      }
    } else {
      debugPrint('❌ Unexpected JSON format in assets: ${jsonData.runtimeType}');
      return [];
    }

    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing assets: $e');
    return [];
  }
}

class EnhancedSongRepository {
  // Firebase paths
  static const String _legacySongsPath = 'songs';
  static const String _collectionSongsPath = 'collection_songs';
  static const String _collectionsPath = 'song_collections';

  // Repository dependencies
  final CollectionRepository _collectionRepo = CollectionRepository();
  final FirebaseService _firebaseService = FirebaseService();

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database {
    if (!_isFirebaseInitialized) return null;
    try {
      return FirebaseDatabase.instance;
    } catch (e) {
      debugPrint(
          '[EnhancedSongRepository] Error getting database instance: $e');
      return null;
    }
  }

  // Operation logging
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint(
          '[EnhancedSongRepository] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[EnhancedSongRepository] 📊 Details: $details');
      }
    }
  }

  // Check connectivity
  Future<bool> _checkRealConnectivity() async {
    try {
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      final snapshot = await connectedRef.get().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connectivity check timeout'),
          );
      return snapshot.value == true;
    } catch (e) {
      debugPrint('[EnhancedSongRepository] Connectivity check failed: $e');
      return false;
    }
  }

  // ============================================================================
  // UNIFIED SONG RETRIEVAL (Collection-aware + Legacy)
  // ============================================================================

  /// Get all songs from both collections and legacy sources
  Future<UnifiedSongDataResult> getAllSongs({String? userRole}) async {
    _logOperation('getAllSongs', {'userRole': userRole});

    if (!_isFirebaseInitialized) {
      debugPrint(
          '[EnhancedSongRepository] Firebase not initialized, loading from assets');
      return await _loadAllFromLocalAssets();
    }

    final isOnline = await _checkRealConnectivity();
    if (!isOnline) {
      debugPrint(
          '[EnhancedSongRepository] No connectivity, loading from assets');
      return await _loadAllFromLocalAssets();
    }

    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');

      debugPrint('[EnhancedSongRepository] 🔄 Fetching unified songs data...');

      // Fetch both legacy songs and collection songs in parallel
      final futures = await Future.wait([
        _fetchLegacySongs(database),
        _fetchCollectionSongs(database, userRole),
      ]);

      final legacySongs = futures[0];
      final collectionSongs = futures[1];

      // Parse unified data
      final inputData = {
        'legacySongs': legacySongs,
        'collectionSongs': collectionSongs,
      };

      final result =
          await compute(_parseUnifiedSongsData, json.encode(inputData));

      final songs = List<Song>.from(result['songs'] as List);
      final legacyCount = result['legacyCount'] as int;
      final collectionCount = result['collectionCount'] as int;
      final activeCollections =
          List<String>.from(result['activeCollections'] as List);

      debugPrint(
          '[EnhancedSongRepository] ✅ Loaded ${songs.length} total songs');
      debugPrint(
          '[EnhancedSongRepository] 📊 Legacy: $legacyCount, Collections: $collectionCount');

      return UnifiedSongDataResult(
        songs: songs,
        isOnline: true,
        legacySongs: legacyCount,
        collectionSongs: collectionCount,
        activeCollections: activeCollections,
      );
    } catch (e) {
      debugPrint(
          '[EnhancedSongRepository] ❌ Unified fetch failed: $e. Falling back to assets');
      return await _loadAllFromLocalAssets();
    }
  }

  /// Get songs from specific collection
  Future<UnifiedSongDataResult> getSongsFromCollection(String collectionId,
      {String? userRole}) async {
    _logOperation('getSongsFromCollection',
        {'collectionId': collectionId, 'userRole': userRole});

    final collectionSongs = await _fetchCollectionSongs(_database!, userRole);
    final result = collectionSongs?[collectionId];

    final songs = result != null
        ? await compute(_parseSongsFromCollectionMap, json.encode(result))
        : <Song>[];

    return UnifiedSongDataResult(
      songs: songs,
      isOnline: await _checkRealConnectivity(),
      legacySongs: 0,
      collectionSongs: songs.length,
      activeCollections: songs.isNotEmpty ? [collectionId] : [],
    );
  }

  /// Get only legacy songs (non-collection)
  Future<UnifiedSongDataResult> getLegacySongsOnly() async {
    _logOperation('getLegacySongsOnly');

    if (!_isFirebaseInitialized) {
      return await _loadAllFromLocalAssets();
    }

    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');

      final legacySongs = await _fetchLegacySongs(database);

      if (legacySongs != null) {
        final songs =
            await compute(_parseSongsFromLegacyMap, json.encode(legacySongs));

        return UnifiedSongDataResult(
          songs: songs,
          isOnline: true,
          legacySongs: songs.length,
          collectionSongs: 0,
          activeCollections: [],
        );
      } else {
        return await _loadAllFromLocalAssets();
      }
    } catch (e) {
      debugPrint('[EnhancedSongRepository] ❌ Legacy songs fetch failed: $e');
      return await _loadAllFromLocalAssets();
    }
  }

  // ============================================================================
  // SONG SEARCH & RETRIEVAL
  // ============================================================================

  /// Search songs across all sources with collection context
  Future<SongSearchResult> searchSongs(String searchTerm,
      {String? userRole}) async {
    _logOperation(
        'searchSongs', {'searchTerm': searchTerm, 'userRole': userRole});

    final allSongs = await getAllSongs(userRole: userRole);
    final searchTermLower = searchTerm.toLowerCase();

    final matchingSongs = allSongs.songs.where((song) {
      return song.title.toLowerCase().contains(searchTermLower) ||
          song.number.contains(searchTerm) ||
          song.verses.any(
              (verse) => verse.lyrics.toLowerCase().contains(searchTermLower));
    }).toList();

    // Count matches by collection
    final Map<String, int> collectionMatches = {};
    for (final song in matchingSongs) {
      if (song.belongsToCollection()) {
        final collectionId = song.collectionId!;
        collectionMatches[collectionId] =
            (collectionMatches[collectionId] ?? 0) + 1;
      }
    }

    return SongSearchResult(
      songs: matchingSongs,
      isOnline: allSongs.isOnline,
      searchTerm: searchTerm,
      totalMatches: matchingSongs.length,
      collectionMatches: collectionMatches,
    );
  }

  /// Get song by number with availability context
  Future<SongAvailabilityResult> getSongByNumber(String songNumber,
      {String? userRole}) async {
    _logOperation(
        'getSongByNumber', {'songNumber': songNumber, 'userRole': userRole});

    final allSongs = await getAllSongs(userRole: userRole);

    final song = allSongs.songs.firstWhere(
      (s) => s.number == songNumber,
      orElse: () => Song(
          number: '', title: '', verses: []), // Return empty song as marker
    );

    if (song.number.isEmpty) {
      // Song not found
      return SongAvailabilityResult(
        song: null,
        isOnline: allSongs.isOnline,
        foundInLegacy: false,
        foundInCollections: false,
        availableInCollections: [],
      );
    }

    // Determine where the song was found
    final isFromCollection = song.belongsToCollection();
    final availableCollections = <String>[];

    if (isFromCollection) {
      availableCollections.add(song.collectionId!);
    }

    return SongAvailabilityResult(
      song: song,
      isOnline: allSongs.isOnline,
      foundInLegacy: !isFromCollection,
      foundInCollections: isFromCollection,
      availableInCollections: availableCollections,
    );
  }

  // ============================================================================
  // SONG MANAGEMENT (Admin Functions)
  // ============================================================================

  /// Add song to legacy collection (backward compatibility)
  Future<void> addSongToLegacy(Song song) async {
    _logOperation('addSongToLegacy', {'songNumber': song.number});

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot add song');
    }

    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    try {
      // Ensure it's a legacy song (no collection context)
      final legacySong = song.toLegacySong();
      final songData = legacySong.toJson();

      final DatabaseReference ref =
          database.ref('$_legacySongsPath/${song.number}');
      await ref.set(songData);

      debugPrint(
          '[EnhancedSongRepository] ✅ Song added to legacy collection: ${song.number}');
    } catch (e) {
      debugPrint('[EnhancedSongRepository] ❌ Failed to add song to legacy: $e');
      rethrow;
    }
  }

  /// Update song (handles both legacy and collection songs)
  Future<void> updateSong(String originalSongNumber, Song updatedSong) async {
    _logOperation('updateSong', {
      'originalNumber': originalSongNumber,
      'newNumber': updatedSong.number,
      'hasCollection': updatedSong.belongsToCollection(),
    });

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot update song');
    }

    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    try {
      // If song belongs to a collection, update in collection
      if (updatedSong.belongsToCollection()) {
        final collectionId = updatedSong.collectionId!;

        // Remove old version if number changed
        if (originalSongNumber != updatedSong.number) {
          await _collectionRepo.removeSongFromCollection(
              collectionId, originalSongNumber);
        }

        // Add/update new version
        await _collectionRepo.addSongToCollection(collectionId, updatedSong);
      } else {
        // Update in legacy collection
        if (originalSongNumber != updatedSong.number) {
          await deleteSongFromLegacy(originalSongNumber);
          await addSongToLegacy(updatedSong);
        } else {
          final songData = updatedSong.toJson();
          final DatabaseReference ref =
              database.ref('$_legacySongsPath/${updatedSong.number}');
          await ref.update(songData);
        }
      }

      debugPrint(
          '[EnhancedSongRepository] ✅ Song updated successfully: ${updatedSong.number}');
    } catch (e) {
      debugPrint('[EnhancedSongRepository] ❌ Failed to update song: $e');
      rethrow;
    }
  }

  /// Delete song from legacy collection
  Future<void> deleteSongFromLegacy(String songNumber) async {
    _logOperation('deleteSongFromLegacy', {'songNumber': songNumber});

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot delete song');
    }

    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    try {
      final DatabaseReference ref =
          database.ref('$_legacySongsPath/$songNumber');
      await ref.remove();

      debugPrint(
          '[EnhancedSongRepository] ✅ Song deleted from legacy: $songNumber');
    } catch (e) {
      debugPrint(
          '[EnhancedSongRepository] ❌ Failed to delete song from legacy: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Fetch legacy songs from Firebase
  Future<Map<String, dynamic>?> _fetchLegacySongs(
      FirebaseDatabase database) async {
    try {
      final ref = database.ref(_legacySongsPath);
      final event = await ref.once().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Legacy songs fetch timeout'),
          );

      if (event.snapshot.exists && event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[EnhancedSongRepository] ❌ Failed to fetch legacy songs: $e');
      return null;
    }
  }

  /// Fetch collection songs with access control
  Future<Map<String, dynamic>?> _fetchCollectionSongs(
      FirebaseDatabase database, String? userRole) async {
    try {
      // First get accessible collections
      final collectionsRef = database.ref(_collectionsPath);
      final collectionsSnapshot = await collectionsRef.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Collections fetch timeout'),
          );

      if (!collectionsSnapshot.exists || collectionsSnapshot.value == null) {
        return null;
      }

      final collectionsData =
          Map<String, dynamic>.from(collectionsSnapshot.value as Map);
      final collectionSongs = <String, dynamic>{};

      // Fetch songs from each accessible collection
      for (final entry in collectionsData.entries) {
        final collectionId = entry.key;
        final collectionData = Map<String, dynamic>.from(entry.value as Map);

        // Check access level
        final accessLevel = collectionData['access_level'] ?? 'public';
        if (!_canUserAccessLevel(accessLevel, userRole)) {
          continue;
        }
        try {
          final ref = database.ref('$_collectionSongsPath/$collectionId');
          final snapshot = await ref.get().timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw Exception('Collection songs timeout'),
              );

          if (snapshot.exists && snapshot.value != null) {
            collectionSongs[collectionId] = snapshot.value;
          }
        } catch (e) {
          debugPrint(
              '[EnhancedSongRepository] ❌ Failed to fetch songs from collection $collectionId: $e');
          continue;
        }
      }

      return collectionSongs.isNotEmpty ? collectionSongs : null;
    } catch (e) {
      debugPrint(
          '[EnhancedSongRepository] ❌ Failed to fetch collection songs: $e');
      return null;
    }
  }

  /// Load songs from local assets (fallback)
  Future<UnifiedSongDataResult> _loadAllFromLocalAssets() async {
    try {
      debugPrint(
          '[EnhancedSongRepository] 📁 Loading songs from local assets...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final songs = await compute(_parseSongsFromAssets, localJsonString);

      debugPrint(
          '[EnhancedSongRepository] ✅ Loaded ${songs.length} songs from assets (OFFLINE)');
      return UnifiedSongDataResult(
        songs: songs,
        isOnline: false,
        legacySongs: songs.length,
        collectionSongs: 0,
        activeCollections: [],
      );
    } catch (assetError) {
      debugPrint(
          '[EnhancedSongRepository] ❌ Local asset loading failed: $assetError');
      return UnifiedSongDataResult(
        songs: [],
        isOnline: false,
        legacySongs: 0,
        collectionSongs: 0,
        activeCollections: [],
      );
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get repository performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'legacySongsPath': _legacySongsPath,
      'collectionSongsPath': _collectionSongsPath,
      'collectionsPath': _collectionsPath,
    };
  }

  /// Check if user can access a specific access level
  bool _canUserAccessLevel(String accessLevel, String? userRole) {
    final role = userRole?.toLowerCase() ?? 'guest';
    const hierarchy = {
      'guest': 0,
      'user': 1,
      'registered': 1,
      'premium': 2,
      'admin': 3,
      'superadmin': 4,
    };

    const levelHierarchy = {
      'public': 0,
      'registered': 1,
      'premium': 2,
      'admin': 3,
      'superadmin': 4,
    };

    final userLevel = hierarchy[role] ?? 0;
    final requiredLevel = levelHierarchy[accessLevel.toLowerCase()] ?? 0;

    return userLevel >= requiredLevel;
  }

  /// Get repository summary
  Map<String, dynamic> getRepositorySummary() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return {
      'isFirebaseInitialized': _isFirebaseInitialized,
      'hasDatabaseInstance': _database != null,
      'userType': currentUser?.isAnonymous == true
          ? 'guest'
          : currentUser != null
              ? 'registered'
              : 'none',
      'userEmail': currentUser?.email,
      'lastCheck': DateTime.now().toIso8601String(),
      'supportedFeatures': [
        'unifiedSongRetrieval',
        'collectionAwareness',
        'legacyCompatibility',
        'accessControl',
        'searchWithContext',
        'dualWriteSupport',
      ],
    };
  }
}

// Additional parsing function for legacy songs
List<Song> _parseSongsFromLegacyMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<Song> songs = [];
    for (final entry in jsonMap.entries) {
      try {
        final songData = Map<String, dynamic>.from(entry.value as Map);
        final song = Song.fromJson(songData);
        songs.add(song);
      } catch (e) {
        debugPrint('❌ Error parsing legacy song ${entry.key}: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing legacy songs map: $e');
    return [];
  }
}

List<Song> _parseSongsFromCollectionMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<Song> songs = [];
    for (final entry in jsonMap.entries) {
      try {
        final songData = Map<String, dynamic>.from(entry.value as Map);
        final song = Song.fromJson(songData);
        songs.add(song);
      } catch (e) {
        debugPrint('❌ Error parsing collection song ${entry.key}: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing collection songs map: $e');
    return [];
  }
}
