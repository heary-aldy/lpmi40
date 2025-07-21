// lib/src/features/songbook/repository/song_repository.dart
// ✅ FIREBASE STRUCTURE FIX: Corrected case sensitivity and path structure issues
// 🔧 COLLECTION PATHS: Fixed to query /song_collection/LPMI/songs (with correct case)
// 🚀 NO DATABASE CHANGES NEEDED: Works with existing Firebase structure
// ✅ NEW: Added getCollectionsSeparated() method for collection-specific song display
// ✅ FIX: Removed verbose debugPrint statement from parsing function.

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
        // Ensure song number is correctly assigned from the key if not present
        songData['song_number'] =
            songData['song_number']?.toString() ?? entry.key;
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
            _dbInstance!.setLoggingEnabled(
                false); // Set to false to reduce console noise
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
  // FIREBASE PATH SAFETY (FIXED - PRESERVES ORIGINAL CASE)
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

  Future<MigrationStatus> checkMigrationStatus() async {
    _logOperation('checkMigrationStatus');
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
          lastCheck: DateTime.now());
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
          lastCheck: DateTime.now());
      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();
      return status;
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot =
          await collectionsRef.get().timeout(const Duration(seconds: 10));

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
          lastCheck: DateTime.now());
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
          lastCheck: DateTime.now());
      _cachedMigrationStatus = status;
      _lastMigrationCheck = DateTime.now();
      return status;
    }
  }

  Future<List<CollectionMigrationResult>> runManualMigration() async {
    _logOperation('runManualMigration');
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = await _database;
    if (database == null) throw Exception('Database not available');
    final isOnline = await _checkConnectivity();
    if (!isOnline) throw Exception('No internet connection');

    final results = <CollectionMigrationResult>[];
    try {
      debugPrint('[SongRepository] 🔄 Starting MANUAL migration...');
      final migrationStartTime = DateTime.now();
      final status = await checkMigrationStatus();
      if (!status.isRequired) {
        debugPrint('[SongRepository] ✅ No migration needed');
        return results;
      }
      for (final collectionId in status.problematicCollections) {
        final safeId = _sanitizeCollectionId(collectionId);
        debugPrint('[SongRepository] 🔄 Migrating "$collectionId" → "$safeId"');
        final migrationResult =
            await _migrateCollectionSongs(database, collectionId, safeId);
        results.add(migrationResult);
      }
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

  Future<CollectionMigrationResult> _migrateCollectionSongs(
      FirebaseDatabase database, String originalId, String safeId) async {
    final startTime = DateTime.now();
    try {
      final originalPath = '$_songCollectionPath/$originalId';
      final newPath = '$_songCollectionPath/$safeId';
      final oldRef = database.ref(originalPath);
      final oldSnapshot = await oldRef.get();

      if (!oldSnapshot.exists || oldSnapshot.value == null) {
        return CollectionMigrationResult(
            success: true,
            collectionId: originalId,
            originalPath: originalPath,
            newPath: newPath,
            songsMigrated: 0,
            executionTime: DateTime.now().difference(startTime));
      }

      final songsData = oldSnapshot.value;
      final songCount = (songsData as Map?)?.length ?? 0;
      final newRef = database.ref(newPath);
      await newRef.set(songsData);
      final verifySnapshot = await newRef.get();
      if (!verifySnapshot.exists) {
        throw Exception('Migration verification failed');
      }
      await oldRef.remove();
      return CollectionMigrationResult(
          success: true,
          collectionId: originalId,
          originalPath: originalPath,
          newPath: newPath,
          songsMigrated: songCount,
          executionTime: DateTime.now().difference(startTime));
    } catch (e) {
      return CollectionMigrationResult(
          success: false,
          collectionId: originalId,
          originalPath: '$_songCollectionPath/$originalId',
          newPath: '$_songCollectionPath/$safeId',
          songsMigrated: 0,
          errorMessage: e.toString(),
          executionTime: DateTime.now().difference(startTime));
    }
  }

  // ============================================================================
  // MAIN API METHODS (OPTIMIZED - NO AUTO-MIGRATION)
  // ============================================================================

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
          '[SongRepository] 🔄 Fetching unified songs data (FIXED PATHS)...');
      final futures = await Future.wait([
        _fetchLegacySongs(database),
        _fetchCollectionSongs(database),
      ]);
      final legacySongs = futures[0];
      final collectionSongs = futures[1];
      final inputData = {
        'legacySongs': legacySongs,
        'collectionSongs': collectionSongs
      };

      // ✅ FIX: Removed the verbose debugPrint that caused the long lines of checking
      // debugPrint(inputData.toString());

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

  // ============================================================================
  // COLLECTION DATA CACHING
  // ============================================================================

  static Map<String, List<Song>>? _cachedCollections;
  static DateTime? _cacheTimestamp;
  static const int _cacheValidityMinutes = 5; // Cache for 5 minutes

  bool get _isCacheValid {
    if (_cachedCollections == null || _cacheTimestamp == null) return false;
    final now = DateTime.now();
    return now.difference(_cacheTimestamp!).inMinutes < _cacheValidityMinutes;
  }

  void _updateCache(Map<String, List<Song>> collections) {
    _cachedCollections = Map.from(collections);
    _cacheTimestamp = DateTime.now();
    debugPrint('[SongRepository] 💾 Collections cached at ${_cacheTimestamp}');
  }

  Future<Map<String, List<Song>>> getCollectionsSeparated(
      {bool forceRefresh = false}) async {
    _logOperation('getCollectionsSeparated');

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _cachedCollections != null) {
      debugPrint(
          '[SongRepository] 🚀 Using cached collections (${_cachedCollections!.keys.length} collections)');
      return Map.from(_cachedCollections!);
    }

    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, using assets fallback');
      final allSongs = await _loadAllFromLocalAssets();
      final result = {
        'All': allSongs.songs,
        'LPMI': allSongs.songs,
        'SRD': allSongs.songs,
        'Lagu_belia': allSongs.songs
      };
      _updateCache(result);
      return result;
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      debugPrint('[SongRepository] No connectivity, using assets fallback');
      final allSongs = await _loadAllFromLocalAssets();
      final result = {
        'All': allSongs.songs,
        'LPMI': allSongs.songs,
        'SRD': allSongs.songs,
        'Lagu_belia': allSongs.songs
      };
      _updateCache(result);
      return result;
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      debugPrint(
          '[SongRepository] � Fetching collections with parallel loading...');

      // ✅ PERFORMANCE: Parallel fetching with priority loading
      final legacySongsFuture = _fetchLegacySongs(database);
      final collectionSongsFuture = _fetchCollectionSongsOptimized(database);

      // Start both operations in parallel
      final futures =
          await Future.wait([legacySongsFuture, collectionSongsFuture]);
      final legacySongs = futures[0];
      final collectionSongs = futures[1];

      List<Song> allSongs = [];
      if (legacySongs != null) {
        allSongs =
            await compute(_parseSongsFromFirebaseMap, json.encode(legacySongs));
        debugPrint('[SongRepository] ✅ Parsed ${allSongs.length} legacy songs');
      }

      final separatedCollections = <String, List<Song>>{
        'All': List.from(allSongs)
      };

      if (collectionSongs != null) {
        // ✅ PERFORMANCE: Process collections in parallel
        final processingFutures = <Future<void>>[];

        for (final entry in collectionSongs.entries) {
          final collectionId = entry.key;
          final songData = entry.value as Map<String, dynamic>;

          // Process each collection in parallel
          processingFutures.add(_processCollectionData(
            collectionId,
            songData,
            separatedCollections,
          ));
        }

        // Wait for all collections to be processed
        await Future.wait(processingFutures);
      }

      // Ensure default collections exist
      separatedCollections['LPMI'] ??= [];
      separatedCollections['SRD'] ??= [];
      separatedCollections['Lagu_belia'] ??= [];

      // Sort all collections
      for (final entry in separatedCollections.entries) {
        entry.value.sort((a, b) => (int.tryParse(a.number) ?? 0)
            .compareTo(int.tryParse(b.number) ?? 0));
      }

      debugPrint('[SongRepository] ✅ Collection separation complete:');
      for (final entry in separatedCollections.entries) {
        debugPrint(
            '[SongRepository] 📊 ${entry.key}: ${entry.value.length} songs');
      }

      // ✅ CACHE: Store results for future use
      _updateCache(separatedCollections);

      return separatedCollections;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Collection separation failed: $e');

      // Return cached data if available, otherwise fallback
      if (_cachedCollections != null) {
        debugPrint('[SongRepository] 💾 Using stale cache due to error');
        return Map.from(_cachedCollections!);
      }

      final allSongs = await _loadAllFromLocalAssets();
      final result = {
        'All': allSongs.songs,
        'LPMI': allSongs.songs,
        'SRD': allSongs.songs,
        'Lagu_belia': allSongs.songs
      };
      _updateCache(result);
      return result;
    }
  }

  // ✅ NEW: Optimized collection fetching with batch operations
  Future<Map<String, dynamic>?> _fetchCollectionSongsOptimized(
      FirebaseDatabase database) async {
    try {
      debugPrint('[SongRepository] 🚀 Optimized collection fetching...');
      final collectionsRef = database.ref(_songCollectionPath);

      // Single query to get all collection metadata
      final collectionsSnapshot =
          await collectionsRef.get().timeout(const Duration(seconds: 12));

      if (!collectionsSnapshot.exists || collectionsSnapshot.value == null) {
        debugPrint(
            '[SongRepository] ❌ No collections found at $_songCollectionPath');
        return null;
      }

      final collectionsData =
          Map<String, dynamic>.from(collectionsSnapshot.value as Map);
      debugPrint(
          '[SongRepository] 📂 Found ${collectionsData.keys.length} collections: ${collectionsData.keys.toList()}');

      // ✅ PERFORMANCE: Priority loading - load important collections first
      final priorityCollections = ['LPMI', 'SRD', 'Lagu_belia'];
      final otherCollections = collectionsData.keys
          .where((k) => !priorityCollections.contains(k))
          .toList();

      final collectionSongs = <String, dynamic>{};

      // Load priority collections first (in parallel)
      final priorityFutures = priorityCollections
          .map((collectionId) => _fetchSingleCollection(
              database, collectionId, collectionsData[collectionId]))
          .toList();

      final priorityResults = await Future.wait(priorityFutures);
      for (int i = 0; i < priorityCollections.length; i++) {
        final result = priorityResults[i];
        if (result != null) {
          collectionSongs[priorityCollections[i]] = result;
        }
      }

      // Load other collections in background (in smaller batches)
      if (otherCollections.isNotEmpty) {
        final batchSize = 2; // Process 2 collections at a time
        for (int i = 0; i < otherCollections.length; i += batchSize) {
          final batch = otherCollections.skip(i).take(batchSize);
          final batchFutures = batch
              .map((collectionId) => _fetchSingleCollection(
                  database, collectionId, collectionsData[collectionId]))
              .toList();

          final batchResults = await Future.wait(batchFutures);
          for (int j = 0; j < batch.length; j++) {
            final collectionId = batch.elementAt(j);
            final result = batchResults[j];
            if (result != null) {
              collectionSongs[collectionId] = result;
            }
          }
        }
      }

      return collectionSongs;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Optimized collection fetch failed: $e');
      return null;
    }
  }

  // ✅ NEW: Single collection fetcher with improved error handling
  Future<Map<String, dynamic>?> _fetchSingleCollection(
      FirebaseDatabase database,
      String collectionId,
      dynamic collectionData) async {
    try {
      final songsPath = '$_songCollectionPath/$collectionId/songs';
      final songsRef = database.ref(songsPath);

      final songsSnapshot =
          await songsRef.get().timeout(const Duration(seconds: 10));

      if (songsSnapshot.exists && songsSnapshot.value != null) {
        final rawData = songsSnapshot.value;
        Map<String, dynamic>? processedData;

        if (rawData is Map) {
          processedData = Map<String, dynamic>.from(rawData);
        } else if (rawData is List) {
          processedData = <String, dynamic>{};
          for (int i = 0; i < rawData.length; i++) {
            final songData = rawData[i];
            if (songData is Map) {
              final songMap = Map<String, dynamic>.from(songData);
              final songNumber =
                  songMap['song_number']?.toString() ?? i.toString();
              processedData[songNumber] = songMap;
            }
          }
        }

        if (processedData != null && processedData.isNotEmpty) {
          debugPrint(
              '[SongRepository] ✅ Loaded $collectionId: ${processedData.length} songs');
          return processedData;
        }
      }

      // Fallback attempt
      return await _attemptCollectionFallback(database, collectionId);
    } catch (e) {
      debugPrint(
          '[SongRepository] ⚠️ Failed to fetch collection $collectionId: $e');
      return null;
    }
  }

  // ✅ NEW: Parallel collection processing
  Future<void> _processCollectionData(
    String collectionId,
    Map<String, dynamic> songData,
    Map<String, List<Song>> separatedCollections,
  ) async {
    try {
      final collectionSongList =
          await compute(_parseSongsFromFirebaseMap, json.encode(songData));
      separatedCollections[collectionId] = collectionSongList;

      debugPrint(
          '[SongRepository] ✅ Processed $collectionId: ${collectionSongList.length} songs');

      // Add to 'All' collection (avoiding duplicates)
      for (final song in collectionSongList) {
        final existingIndex = separatedCollections['All']!
            .indexWhere((s) => s.number == song.number);
        if (existingIndex == -1) {
          separatedCollections['All']!.add(song);
        } else {
          separatedCollections['All']![existingIndex] = song;
        }
      }
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Failed to process collection $collectionId: $e');
      separatedCollections[collectionId] = [];
    }
  }

  Future<Map<String, dynamic>?> _attemptCollectionFallback(
    FirebaseDatabase database,
    String collectionId,
  ) async {
    try {
      final fallbackPath = '$_songCollectionPath/$collectionId';
      final fallbackRef = database.ref(fallbackPath);
      final fallbackSnapshot =
          await fallbackRef.get().timeout(const Duration(seconds: 5));

      if (fallbackSnapshot.exists && fallbackSnapshot.value != null) {
        final fallbackData = fallbackSnapshot.value;
        if (fallbackData is Map) {
          final mapData = Map<String, dynamic>.from(fallbackData);
          if (mapData.containsKey('songs')) {
            final songsData = mapData['songs'];
            if (songsData is Map && songsData.isNotEmpty) {
              debugPrint(
                  '[SongRepository] ✅ Loaded $collectionId (fallback/songs): ${songsData.length} songs');
              return Map<String, dynamic>.from(songsData);
            }
          } else {
            final firstValue = mapData.values.firstOrNull;
            if (firstValue is Map && firstValue.containsKey('song_title')) {
              debugPrint(
                  '[SongRepository] ✅ Loaded $collectionId (fallback/direct): ${mapData.length} songs');
              return mapData;
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Fallback failed for $collectionId: $e');
      return null;
    }
  }

  Future<Song?> getSongByNumber(String songNumber) async {
    _logOperation('getSongByNumber', {'songNumber': songNumber});
    try {
      final songData = await getAllSongs();
      return songData.songs.firstWhere((song) => song.number == songNumber,
          orElse: () => throw Exception('Song not found'));
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      return null;
    }
  }

  Future<SongWithStatusResult> getSongByNumberWithStatus(
      String songNumber) async {
    _logOperation('getSongByNumberWithStatus', {'songNumber': songNumber});
    try {
      final songData = await getAllSongs();
      final song = songData.songs.firstWhere(
          (song) => song.number == songNumber,
          orElse: () => throw Exception('Song not found'));
      return SongWithStatusResult(song: song, isOnline: songData.isOnline);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      final songData = await getAllSongs();
      return SongWithStatusResult(song: null, isOnline: songData.isOnline);
    }
  }

  Future<List<Song>> getRecentlyAddedSongs({int limit = 5}) async {
    _logOperation('getRecentlyAddedSongs', {'limit': limit});
    try {
      final songData = await getAllSongs();
      final songs = List<Song>.from(songData.songs);

      // Sort by song number (assuming higher numbers = more recent)
      // or you could add a timestamp field to songs for more accurate sorting
      songs.sort((a, b) {
        try {
          final aNum = int.tryParse(a.number) ?? 0;
          final bNum = int.tryParse(b.number) ?? 0;
          return bNum.compareTo(aNum); // Descending order (newest first)
        } catch (e) {
          return b.number.compareTo(a.number); // Fallback to string comparison
        }
      });

      return songs.take(limit).toList();
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get recent songs: $e');
      return [];
    }
  }

  Future<void> addSong(Song song) async {
    _logOperation('addSong', {'songNumber': song.number});
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = await _database;
    if (database == null) throw Exception('Database not available');
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

  Future<void> updateSong(String originalSongNumber, Song updatedSong) async {
    _logOperation('updateSong', {
      'originalNumber': originalSongNumber,
      'newNumber': updatedSong.number
    });
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = await _database;
    if (database == null) throw Exception('Database not available');
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

  Future<void> deleteSong(String songNumber) async {
    _logOperation('deleteSong', {'songNumber': songNumber});
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = await _database;
    if (database == null) throw Exception('Database not available');
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

  Future<Map<String, dynamic>?> _fetchLegacySongs(
      FirebaseDatabase database) async {
    try {
      final ref = database.ref(_legacySongsPath);
      final event = await ref.once().timeout(const Duration(seconds: 15),
          onTimeout: () => throw Exception('Legacy songs fetch timeout'));
      if (event.snapshot.exists && event.snapshot.value != null) {
        final songCount = (event.snapshot.value as Map?)?.length ?? 0;
        debugPrint('[SongRepository] ✅ Fetched $songCount legacy songs');
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      debugPrint('[SongRepository] ⚠️ No legacy songs found');
      return null;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to fetch legacy songs: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchCollectionSongs(
      FirebaseDatabase database) async {
    try {
      debugPrint(
          '[SongRepository] 🔍 Checking collections at: $_songCollectionPath');
      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot =
          await collectionsRef.get().timeout(const Duration(seconds: 10));

      if (!collectionsSnapshot.exists || collectionsSnapshot.value == null) {
        debugPrint(
            '[SongRepository] ❌ No collections found at $_songCollectionPath');
        return null;
      }

      final collectionsData =
          Map<String, dynamic>.from(collectionsSnapshot.value as Map);
      final collectionSongs = <String, dynamic>{};
      debugPrint(
          '[SongRepository] 📂 Found ${collectionsData.keys.length} collections: ${collectionsData.keys.toList()}');

      for (final entry in collectionsData.entries) {
        try {
          final collectionId = entry.key;
          final songsPath = '$_songCollectionPath/$collectionId/songs';
          final songsRef = database.ref(songsPath);
          debugPrint('[SongRepository] 🔍 Querying: $songsPath');
          final songsSnapshot =
              await songsRef.get().timeout(const Duration(seconds: 8));

          if (songsSnapshot.exists && songsSnapshot.value != null) {
            final rawData = songsSnapshot.value;
            debugPrint(
                '[SongRepository] 📊 Raw data type for $collectionId: ${rawData.runtimeType}');
            Map<String, dynamic>? processedData;

            if (rawData is Map) {
              processedData = Map<String, dynamic>.from(rawData);
              debugPrint(
                  '[SongRepository] ✅ Processing $collectionId as Map: ${processedData.length} songs');
            } else if (rawData is List) {
              debugPrint(
                  '[SongRepository] 🔄 Converting $collectionId from List to Map...');
              processedData = <String, dynamic>{};
              for (int i = 0; i < (rawData).length; i++) {
                final songData = rawData[i];
                if (songData is Map) {
                  final songMap = Map<String, dynamic>.from(songData);
                  final songNumber =
                      songMap['song_number']?.toString() ?? i.toString();
                  processedData[songNumber] = songMap;
                }
              }
              debugPrint(
                  '[SongRepository] ✅ Converted $collectionId List to Map: ${processedData.length} songs');
            } else if (rawData is String) {
              debugPrint(
                  '[SongRepository] ⚠️ Collection $collectionId contains string: "$rawData"');
              if (rawData.trim().isEmpty) {
                debugPrint(
                    '[SongRepository] ⚠️ Collection $collectionId is empty');
                continue;
              }
            } else {
              debugPrint(
                  '[SongRepository] ❌ Unknown data type for $collectionId: ${rawData.runtimeType}');
              continue;
            }

            if (processedData != null && processedData.isNotEmpty) {
              collectionSongs[collectionId] = processedData;
              debugPrint(
                  '[SongRepository] ✅ Successfully loaded collection $collectionId: ${processedData.length} songs');
            }
          } else {
            debugPrint(
                '[SongRepository] ⚠️ Collection $collectionId/songs is empty or doesn\'t exist');
            final fallbackPath = '$_songCollectionPath/$collectionId';
            final fallbackRef = database.ref(fallbackPath);
            final fallbackSnapshot =
                await fallbackRef.get().timeout(const Duration(seconds: 5));
            if (fallbackSnapshot.exists && fallbackSnapshot.value != null) {
              final fallbackData = fallbackSnapshot.value;
              debugPrint(
                  '[SongRepository] 🔄 Trying fallback for $collectionId, type: ${fallbackData.runtimeType}');
              if (fallbackData is Map) {
                final mapData = Map<String, dynamic>.from(fallbackData);
                if (mapData.containsKey('songs')) {
                  final songsData = mapData['songs'];
                  if (songsData is Map && songsData.isNotEmpty) {
                    collectionSongs[collectionId] =
                        Map<String, dynamic>.from(songsData);
                    debugPrint(
                        '[SongRepository] ✅ Loaded collection $collectionId (from metadata/songs): ${songsData.length} songs');
                  }
                } else {
                  final firstValue = mapData.values.firstOrNull;
                  if (firstValue is Map &&
                      firstValue.containsKey('song_title')) {
                    collectionSongs[collectionId] = mapData;
                    debugPrint(
                        '[SongRepository] ✅ Loaded collection $collectionId (direct): ${mapData.length} songs');
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
              '[SongRepository] ⚠️ Failed to fetch collection ${entry.key}: $e');
          debugPrint('[SongRepository] 🔍 Stack trace: ${StackTrace.current}');
          continue;
        }
      }

      if (collectionSongs.isEmpty) {
        debugPrint('[SongRepository] ❌ No songs found in any collections');
        return null;
      }

      debugPrint(
          '[SongRepository] ✅ Successfully fetched ${collectionSongs.length} collections with songs');
      for (final entry in collectionSongs.entries) {
        final count = (entry.value as Map?)?.length ?? 0;
        debugPrint('[SongRepository] 📊 Final: ${entry.key} = $count songs');
      }
      return collectionSongs;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to fetch collection songs: $e');
      return null;
    }
  }

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

  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'firebaseInitialized': _isFirebaseInitialized,
      'databaseInitialized': _dbInitialized,
      'lastConnectionCheck': _lastConnectionCheck?.toIso8601String(),
      'lastConnectionResult': _lastConnectionResult,
      'migrationMappings': Map.from(_collectionIdMapping),
      'lastMigrationCheck': _lastMigrationCheck?.toIso8601String(),
      'cachedMigrationStatus': _cachedMigrationStatus != null,
    };
  }

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
        'fixedCollectionPaths',
        'casePreservation',
        'collectionSeparation',
      ],
    };
  }
}
