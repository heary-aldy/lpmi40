// lib/src/features/songbook/repository/song_repository.dart
// ✅ PERFORMANCE OPTIMIZED: Auto-migration removed from startup
// 🚀 MIGRATION: Moved to manual admin function + background operations
// 🔧 DATABASE: Optimized access patterns and connection management

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

// ============================================================================
// RESULT WRAPPER CLASSES (Unchanged - maintaining backward compatibility)
// ============================================================================

class SongDataResult {
  final List<Song> songs;
  final bool isOnline;

  SongDataResult({required this.songs, required this.isOnline});
}

class PaginatedSongDataResult {
  final List<Song> songs;
  final bool isOnline;
  final String? lastKey;
  final bool hasMore;

  PaginatedSongDataResult({
    required this.songs,
    required this.isOnline,
    required this.hasMore,
    this.lastKey,
  });
}

class SongWithStatusResult {
  final Song? song;
  final bool isOnline;

  SongWithStatusResult({required this.song, required this.isOnline});
}

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
  final Map<String, int> collectionMatches;

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

/// ✅ ENHANCED: Migration result with progress tracking
class CollectionMigrationResult {
  final bool success;
  final String collectionId;
  final String originalPath;
  final String newPath;
  final int songsMigrated;
  final String? errorMessage;
  final Duration? executionTime;
  final DateTime timestamp;

  CollectionMigrationResult({
    required this.success,
    required this.collectionId,
    required this.originalPath,
    required this.newPath,
    required this.songsMigrated,
    this.errorMessage,
    this.executionTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// ✅ NEW: Migration status for admin monitoring
class MigrationStatus {
  final bool isRequired;
  final bool isRunning;
  final List<String> problematicCollections;
  final DateTime? lastCheck;
  final DateTime? lastMigration;

  MigrationStatus({
    required this.isRequired,
    required this.isRunning,
    required this.problematicCollections,
    this.lastCheck,
    this.lastMigration,
  });
}

// ============================================================================
// OPTIMIZED PARSING FUNCTIONS (Unchanged for compatibility)
// ============================================================================

List<Song> _parseSongsFromFirebaseMap(String jsonString) {
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
        debugPrint('❌ Error parsing song ${entry.key}: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing Firebase map: $e');
    return [];
  }
}

List<Song> _parseSongsFromList(String jsonString) {
  try {
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Song> songs = [];
    for (int i = 0; i < jsonList.length; i++) {
      try {
        final songData = Map<String, dynamic>.from(jsonList[i] as Map);
        final song = Song.fromJson(songData);
        songs.add(song);
      } catch (e) {
        debugPrint('❌ Error parsing song at index $i: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing list: $e');
    return [];
  }
}

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
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Song> songs = [];
    for (int i = 0; i < jsonList.length; i++) {
      try {
        final songData = Map<String, dynamic>.from(jsonList[i] as Map);
        final song = Song.fromJson(songData);
        songs.add(song);
      } catch (e) {
        debugPrint('❌ Error parsing asset song at index $i: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing assets: $e');
    return [];
  }
}

// ============================================================================
// OPTIMIZED SONG REPOSITORY CLASS
// ============================================================================

class SongRepository {
  // Firebase configuration
  static const String _firebaseUrl =
      'https://lmpi-c5c5c-default-rtdb.firebaseio.com/';
  static const String _legacySongsPath = 'songs';
  static const String _songCollectionPath = 'song_collection';

  // Services
  final FirebaseService _firebaseService = FirebaseService();

  // ✅ OPTIMIZED: Lightweight performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ✅ NEW: Connection management
  static FirebaseDatabase? _dbInstance;
  static bool _dbInitialized = false;
  static DateTime? _lastConnectionCheck;
  static bool? _lastConnectionResult;

  // ✅ NEW: Migration tracking (moved from startup)
  final Map<String, String> _collectionIdMapping = {};
  static DateTime? _lastMigrationCheck;
  static MigrationStatus? _cachedMigrationStatus;

  // ============================================================================
  // CORE INITIALIZATION (OPTIMIZED)
  // ============================================================================

  bool get _isFirebaseInitialized {
    try {
      final app = Firebase.app();
      return app.options.databaseURL?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  /// ✅ OPTIMIZED: Lazy database initialization with caching
  Future<FirebaseDatabase?> get _database async {
    // Return cached instance if available and valid
    if (_dbInstance != null && _dbInitialized) {
      return _dbInstance;
    }

    // Initialize if needed
    if (_isFirebaseInitialized) {
      try {
        final app = Firebase.app();
        _dbInstance = FirebaseDatabase.instanceFor(
          app: app,
          databaseURL: app.options.databaseURL!,
        );

        // ✅ PERFORMANCE: Configure database settings once
        if (!_dbInitialized) {
          _dbInstance!.setPersistenceEnabled(true);
          _dbInstance!.setPersistenceCacheSizeBytes(10 * 1024 * 1024);

          if (kDebugMode) {
            _dbInstance!.setLoggingEnabled(true);
          }

          _dbInitialized = true;
          debugPrint('[SongRepository] ✅ Database initialized and configured');
        }

        return _dbInstance;
      } catch (e) {
        debugPrint('[SongRepository] ❌ Database initialization failed: $e');
        return null;
      }
    }

    return null;
  }

  // ============================================================================
  // OPTIMIZED CONNECTION MANAGEMENT
  // ============================================================================

  /// ✅ OPTIMIZED: Smart connectivity check with caching
  Future<bool> _checkConnectivity() async {
    // Use cached result if recent (within 30 seconds)
    if (_lastConnectionCheck != null && _lastConnectionResult != null) {
      final timeSinceCheck = DateTime.now().difference(_lastConnectionCheck!);
      if (timeSinceCheck.inSeconds < 30) {
        return _lastConnectionResult!;
      }
    }

    try {
      final database = await _database;
      if (database == null) {
        _lastConnectionResult = false;
        _lastConnectionCheck = DateTime.now();
        return false;
      }

      // Quick connection test with timeout
      final completer = Completer<bool>();
      late StreamSubscription subscription;

      subscription = database.ref('.info/connected').onValue.listen(
        (event) {
          if (!completer.isCompleted) {
            final connected = event.snapshot.value == true;
            completer.complete(connected);
          }
          subscription.cancel();
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          subscription.cancel();
        },
      );

      final isConnected = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          subscription.cancel();
          return false;
        },
      );

      _lastConnectionResult = isConnected;
      _lastConnectionCheck = DateTime.now();

      _logConnectivityAttempt('checkConnectivity', isConnected);
      return isConnected;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Connectivity check failed: $e');
      _lastConnectionResult = false;
      _lastConnectionCheck = DateTime.now();
      return false;
    }
  }

  // ============================================================================
  // FIREBASE PATH SAFETY (UNCHANGED - MAINTAINING COMPATIBILITY)
  // ============================================================================

  String _sanitizeCollectionId(String collectionId) {
    final sanitized = collectionId
        .replaceAll(' ', '_')
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\-]'), '_');

    if (collectionId != sanitized) {
      _collectionIdMapping[collectionId] = sanitized;
    }

    return sanitized;
  }

  bool _needsSanitization(String collectionId) {
    return collectionId != _sanitizeCollectionId(collectionId);
  }

  // ============================================================================
  // MIGRATION METHODS (MOVED TO MANUAL/ADMIN ONLY)
  // ============================================================================

  /// ✅ NEW: Check if migration is needed (for admin pages)
  Future<MigrationStatus> checkMigrationStatus() async {
    _logOperation('checkMigrationStatus');

    // Use cached status if recent (within 5 minutes)
    if (_lastMigrationCheck != null && _cachedMigrationStatus != null) {
      final timeSinceCheck = DateTime.now().difference(_lastMigrationCheck!);
      if (timeSinceCheck.inMinutes < 5) {
        return _cachedMigrationStatus!;
      }
    }

    if (!_isFirebaseInitialized) {
      final status = MigrationStatus(
        isRequired: false,
        isRunning: false,
        problematicCollections: [],
        lastCheck: DateTime.now(),
      );
      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();
      return status;
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      final status = MigrationStatus(
        isRequired: false,
        isRunning: false,
        problematicCollections: [],
        lastCheck: DateTime.now(),
      );
      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();
      return status;
    }

    try {
      final database = await _database;
      if (database == null) {
        throw Exception('Database not available');
      }

      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot = await collectionsRef.get().timeout(
            const Duration(seconds: 10),
          );

      final problematicCollections = <String>[];

      if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
        final collectionsData =
            Map<String, dynamic>.from(collectionsSnapshot.value as Map);

        for (final collectionId in collectionsData.keys) {
          if (_needsSanitization(collectionId)) {
            problematicCollections.add(collectionId);
          }
        }
      }

      final status = MigrationStatus(
        isRequired: problematicCollections.isNotEmpty,
        isRunning: false,
        problematicCollections: problematicCollections,
        lastCheck: DateTime.now(),
      );

      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();

      debugPrint(
          '[SongRepository] ✅ Migration status checked: ${problematicCollections.length} collections need migration');
      return status;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Migration status check failed: $e');
      final status = MigrationStatus(
        isRequired: false,
        isRunning: false,
        problematicCollections: [],
        lastCheck: DateTime.now(),
      );
      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();
      return status;
    }
  }

  /// ✅ MANUAL: Migration function for admin use only
  Future<List<CollectionMigrationResult>> runManualMigration() async {
    _logOperation('runManualMigration');

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    final database = await _database;
    if (database == null) {
      throw Exception('Database not available');
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      throw Exception('No internet connection');
    }

    final results = <CollectionMigrationResult>[];

    try {
      debugPrint('[SongRepository] 🔄 Starting MANUAL migration...');
      final migrationStartTime = DateTime.now();

      // Get migration status first
      final status = await checkMigrationStatus();
      if (!status.isRequired) {
        debugPrint('[SongRepository] ✅ No migration needed');
        return results;
      }

      // Migrate each problematic collection
      for (final collectionId in status.problematicCollections) {
        final safeId = _sanitizeCollectionId(collectionId);
        debugPrint('[SongRepository] 🔄 Migrating "$collectionId" → "$safeId"');

        final migrationResult =
            await _migrateCollectionSongs(database, collectionId, safeId);
        results.add(migrationResult);
      }

      // Clear migration status cache
      _cachedMigrationStatus = null;
      _lastMigrationCheck = null;

      final migrationDuration = DateTime.now().difference(migrationStartTime);
      debugPrint(
          '[SongRepository] 🎉 Manual migration completed in ${migrationDuration.inSeconds}s');

      return results;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Manual migration failed: $e');
      rethrow;
    }
  }

  /// ✅ BACKGROUND: Optional background migration (admin-triggered)
  void startBackgroundMigration(
      Function(List<CollectionMigrationResult>) onComplete) {
    debugPrint('[SongRepository] 🔄 Starting background migration...');

    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final results = await runManualMigration();
        onComplete(results);
      } catch (e) {
        debugPrint('[SongRepository] ❌ Background migration failed: $e');
        onComplete([]);
      }
    });
  }

  /// ✅ PRIVATE: Migrate collection songs implementation
  Future<CollectionMigrationResult> _migrateCollectionSongs(
      FirebaseDatabase database, String originalId, String safeId) async {
    final startTime = DateTime.now();

    try {
      final originalPath = '$_songCollectionPath/$originalId';
      final newPath = '$_songCollectionPath/$safeId';

      // Check if old path exists
      final oldRef = database.ref(originalPath);
      final oldSnapshot = await oldRef.get();

      if (!oldSnapshot.exists || oldSnapshot.value == null) {
        return CollectionMigrationResult(
          success: true,
          collectionId: originalId,
          originalPath: originalPath,
          newPath: newPath,
          songsMigrated: 0,
          executionTime: DateTime.now().difference(startTime),
        );
      }

      // Get the songs data
      final songsData = oldSnapshot.value;
      final songCount = (songsData as Map?)?.length ?? 0;

      // Copy to new path
      final newRef = database.ref(newPath);
      await newRef.set(songsData);

      // Verify the copy worked
      final verifySnapshot = await newRef.get();
      if (!verifySnapshot.exists) {
        throw Exception('Migration verification failed');
      }

      // Remove old path
      await oldRef.remove();

      return CollectionMigrationResult(
        success: true,
        collectionId: originalId,
        originalPath: originalPath,
        newPath: newPath,
        songsMigrated: songCount,
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return CollectionMigrationResult(
        success: false,
        collectionId: originalId,
        originalPath: '$_songCollectionPath/$originalId',
        newPath: '$_songCollectionPath/$safeId',
        songsMigrated: 0,
        errorMessage: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  // ============================================================================
  // MAIN API METHODS (OPTIMIZED - NO AUTO-MIGRATION)
  // ============================================================================

  /// ✅ OPTIMIZED: Get all songs WITHOUT auto-migration
  Future<SongDataResult> getAllSongs() async {
    _logOperation('getAllSongs');

    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading from assets');
      return await _loadAllFromLocalAssets();
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      debugPrint('[SongRepository] No connectivity, loading from assets');
      return await _loadAllFromLocalAssets();
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      debugPrint(
          '[SongRepository] 🔄 Fetching unified songs data (NO auto-migration)...');

      // Fetch both legacy and collection songs in parallel
      final futures = await Future.wait([
        _fetchLegacySongs(database),
        _fetchCollectionSongs(database),
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

      debugPrint(
          '[SongRepository] ✅ Loaded ${songs.length} total songs (ONLINE)');
      return SongDataResult(songs: songs, isOnline: true);
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Unified fetch failed: $e. Falling back to assets');
      return await _loadAllFromLocalAssets();
    }
  }

  /// Get song by number
  Future<Song?> getSongByNumber(String songNumber) async {
    _logOperation('getSongByNumber', {'songNumber': songNumber});

    try {
      final songData = await getAllSongs();
      return songData.songs.firstWhere(
        (song) => song.number == songNumber,
        orElse: () => throw Exception('Song not found'),
      );
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      return null;
    }
  }

  /// Get song by number with status
  Future<SongWithStatusResult> getSongByNumberWithStatus(
      String songNumber) async {
    _logOperation('getSongByNumberWithStatus', {'songNumber': songNumber});

    try {
      final songData = await getAllSongs();
      final song = songData.songs.firstWhere(
        (song) => song.number == songNumber,
        orElse: () => throw Exception('Song not found'),
      );

      return SongWithStatusResult(song: song, isOnline: songData.isOnline);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      final songData = await getAllSongs();
      return SongWithStatusResult(song: null, isOnline: songData.isOnline);
    }
  }

  /// Add song to legacy collection
  Future<void> addSong(Song song) async {
    _logOperation('addSong', {'songNumber': song.number});

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    final database = await _database;
    if (database == null) {
      throw Exception('Database not available');
    }

    try {
      final songData = song.toJson();
      final ref = database.ref('$_legacySongsPath/${song.number}');
      await ref.set(songData);
      debugPrint('[SongRepository] ✅ Song added: ${song.number}');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to add song: $e');
      rethrow;
    }
  }

  /// Update song
  Future<void> updateSong(String originalSongNumber, Song updatedSong) async {
    _logOperation('updateSong', {
      'originalNumber': originalSongNumber,
      'newNumber': updatedSong.number,
    });

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    final database = await _database;
    if (database == null) {
      throw Exception('Database not available');
    }

    try {
      if (originalSongNumber != updatedSong.number) {
        await deleteSong(originalSongNumber);
        await addSong(updatedSong);
      } else {
        final songData = updatedSong.toJson();
        final ref = database.ref('$_legacySongsPath/${updatedSong.number}');
        await ref.update(songData);
      }
      debugPrint('[SongRepository] ✅ Song updated: ${updatedSong.number}');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to update song: $e');
      rethrow;
    }
  }

  /// Delete song
  Future<void> deleteSong(String songNumber) async {
    _logOperation('deleteSong', {'songNumber': songNumber});

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    final database = await _database;
    if (database == null) {
      throw Exception('Database not available');
    }

    try {
      final ref = database.ref('$_legacySongsPath/$songNumber');
      await ref.remove();
      debugPrint('[SongRepository] ✅ Song deleted: $songNumber');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to delete song: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS (OPTIMIZED)
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
      debugPrint('[SongRepository] ❌ Failed to fetch legacy songs: $e');
      return null;
    }
  }

  /// ✅ OPTIMIZED: Fetch collection songs with smart path handling
  Future<Map<String, dynamic>?> _fetchCollectionSongs(
      FirebaseDatabase database) async {
    try {
      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot = await collectionsRef.get().timeout(
            const Duration(seconds: 10),
          );

      if (!collectionsSnapshot.exists || collectionsSnapshot.value == null) {
        return null;
      }

      final collectionsData =
          Map<String, dynamic>.from(collectionsSnapshot.value as Map);
      final collectionSongs = <String, dynamic>{};

      for (final entry in collectionsData.entries) {
        try {
          final collectionId = entry.key;
          final safeCollectionId = _sanitizeCollectionId(collectionId);

          // Try safe path first, then original path
          DatabaseReference songsRef;
          if (collectionId != safeCollectionId) {
            songsRef = database.ref('$_songCollectionPath/$safeCollectionId');
          } else {
            songsRef = database.ref('$_songCollectionPath/$collectionId');
          }

          final songsSnapshot = await songsRef.get().timeout(
                const Duration(seconds: 8),
              );

          if (songsSnapshot.exists && songsSnapshot.value != null) {
            collectionSongs[collectionId] = songsSnapshot.value;
          }
        } catch (e) {
          debugPrint(
              '[SongRepository] ⚠️ Failed to fetch collection ${entry.key}: $e');
          continue;
        }
      }

      return collectionSongs.isNotEmpty ? collectionSongs : null;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to fetch collection songs: $e');
      return null;
    }
  }

  /// Load songs from local assets (fallback)
  Future<SongDataResult> _loadAllFromLocalAssets() async {
    try {
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final songs = await compute(_parseSongsFromList, localJsonString);
      debugPrint(
          '[SongRepository] ✅ Loaded ${songs.length} songs from assets (OFFLINE)');
      return SongDataResult(songs: songs, isOnline: false);
    } catch (assetError) {
      debugPrint('[SongRepository] ❌ Asset loading failed: $assetError');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('[SongRepository] 🔧 $operation (count: $count)');
      if (details != null) {
        debugPrint('[SongRepository] 📊 Details: $details');
      }
    }
  }

  void _logConnectivityAttempt(String method, bool success, [String? details]) {
    if (kDebugMode) {
      final status = success ? '✅ CONNECTED' : '❌ FAILED';
      debugPrint('[SongRepository] 🌐 $method: $status');
      if (details != null) {
        debugPrint('[SongRepository] 📄 Details: $details');
      }
    }
  }

  /// Get repository performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'firebaseInitialized': _isFirebaseInitialized,
      'databaseInitialized': _dbInitialized,
      'lastConnectionCheck': _lastConnectionCheck?.toIso8601String(),
      'lastConnectionResult': _lastConnectionResult,
      'migrationMappings': Map.from(_collectionIdMapping),
      'lastMigrationCheck': _lastMigrationCheck?.toIso8601String(),
      'cachedMigrationStatus': _cachedMigrationStatus != null,
    };
  }

  /// Get repository status summary
  Map<String, dynamic> getRepositorySummary() {
    return {
      'isFirebaseInitialized': _isFirebaseInitialized,
      'databaseAvailable': _dbInstance != null,
      'lastConnectionResult': _lastConnectionResult,
      'optimizations': [
        'lazyDatabaseInit',
        'connectionCaching',
        'noAutoMigration',
        'manualMigrationOnly',
        'backgroundMigrationSupport',
        'optimizedFetching',
      ],
    };
  }
}
