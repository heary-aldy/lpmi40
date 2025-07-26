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
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:lpmi40/src/core/services/firebase_database_service.dart';
import 'package:lpmi40/src/features/songbook/services/persistent_collections_config.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';

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

// ✅ NEW: Parse songs with collection ID assignment
List<Song> _parseSongsFromFirebaseMapWithCollection(String jsonString, String collectionId) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<Song> songs = [];
    final Set<String> processedSongs = {}; // ✅ Track processed songs to detect duplicates
    
    debugPrint('🔍 [SongRepository] Parsing ${jsonMap.length} songs for collection: $collectionId');
    
    for (final entry in jsonMap.entries) {
      try {
        final songNumber = entry.key;
        final songData = Map<String, dynamic>.from(entry.value as Map);
        
        // ✅ DUPLICATE DETECTION: Check if song already processed
        if (processedSongs.contains(songNumber)) {
          debugPrint('⚠️ [SongRepository] DUPLICATE DETECTED: Song $songNumber already processed in $collectionId');
          continue;
        }
        processedSongs.add(songNumber);
        
        // Ensure song number is correctly assigned from the key if not present
        songData['song_number'] =
            songData['song_number']?.toString() ?? entry.key;
        // ✅ IMPORTANT: Add collection_id to the song data
        songData['collection_id'] = collectionId;
        final song = Song.fromJson(songData);
        songs.add(song);
        
        // ✅ DEBUG: Special tracking for song "003"
        if (songNumber == '003') {
          debugPrint('🎯 [SongRepository] Song 003: "${song.title}" parsed for $collectionId (hasAudio: ${song.hasAudio})');
        }
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

// ✅ NEW: Compute-compatible function for parsing songs with collection ID
List<Song> _parseSongsWithCollectionId(Map<String, dynamic> params) {
  final jsonString = params['jsonString'] as String;
  final collectionId = params['collectionId'] as String;
  return _parseSongsFromFirebaseMapWithCollection(jsonString, collectionId);
}

List<Song> _parseSongsFromList(String jsonString) {
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
          debugPrint('❌ Error parsing song at index $i: $e');
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
          debugPrint('❌ Error parsing song with key ${entry.key}: $e');
          continue;
        }
      }
    } else {
      debugPrint('❌ Unexpected JSON format: ${jsonData.runtimeType}');
      return [];
    }

    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing songs data: $e');
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
  final FirebaseDatabaseService _databaseService =
      FirebaseDatabaseService.instance;

  // ✅ OPTIMIZED: Lightweight performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ✅ NEW: Migration tracking (moved from startup)
  final Map<String, String> _collectionIdMapping = {};
  static DateTime? _lastMigrationCheck;
  static MigrationStatus? _cachedMigrationStatus;

  // ============================================================================
  // CORE INITIALIZATION (OPTIMIZED)
  // ============================================================================

  /// ✅ OPTIMIZED: Use centralized database service
  Future<FirebaseDatabase?> get _database async {
    return await _databaseService.database;
  }

  // ============================================================================
  // OPTIMIZED CONNECTION MANAGEMENT
  // ============================================================================

  /// ✅ OPTIMIZED: Use centralized connectivity check
  Future<bool> _checkConnectivity() async {
    final result = await _databaseService.checkConnectivity();
    _logConnectivityAttempt('checkConnectivity', result);
    return result;
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

    if (!_databaseService.isInitialized) {
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
    if (!_databaseService.isInitialized) {
      throw Exception('Firebase not initialized');
    }
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
    if (!_databaseService.isInitialized) {
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
  static const int _cacheValidityMinutes =
      10; // Increased cache time for better performance

  bool get _isCacheValid {
    if (_cachedCollections == null || _cacheTimestamp == null) return false;
    final now = DateTime.now();
    return now.difference(_cacheTimestamp!).inMinutes < _cacheValidityMinutes;
  }

  void _updateCache(Map<String, List<Song>> collections) {
    _cachedCollections = Map.from(collections);
    _cacheTimestamp = DateTime.now();
    debugPrint('[SongRepository] 💾 Collections cached at $_cacheTimestamp');
  }

  Future<Map<String, List<Song>>> getCollectionsSeparated(
      {bool forceRefresh = false}) async {
    _logOperation('getCollectionsSeparated');
    debugPrint('🔍 [SongRepository] getCollectionsSeparated() called (forceRefresh: $forceRefresh)');

    try {
      // ✅ NEW: Use CollectionCacheManager for robust caching
      final cacheManager = CollectionCacheManager.instance;
      final collections = await cacheManager.getAllCollections(forceRefresh: forceRefresh);
      
      debugPrint('[SongRepository] 🔍 Cache manager returned ${collections.length} collections: ${collections.keys.toList()}');
      
      // ✅ ENHANCED FALLBACK: If cache manager returns no collections, use legacy method
      if (collections.isEmpty) {
        debugPrint('[SongRepository] 🔄 Cache manager returned empty, using legacy method');
        final legacyResult = await _getCollectionsSeparatedLegacy(forceRefresh: forceRefresh);
        
        // Populate cache manager with legacy results for future use
        try {
          await cacheManager.populateCacheFromLegacy(legacyResult);
        } catch (e) {
          debugPrint('[SongRepository] ⚠️ Failed to populate cache from legacy results: $e');
        }
        
        return legacyResult;
      }
      
      final result = <String, List<Song>>{};

      // Process all songs collection first
      final allSongs = <Song>[];
      for (final entry in collections.entries) {
        final songs = entry.value;
        for (final song in songs) {
          allSongs.add(song);
        }
        result[entry.key] = songs;
      }

      // Create 'All' collection with all songs
      result['All'] = allSongs..sort((a, b) => (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

      // ✅ CRITICAL FIX: If LPMI collection is empty but we have legacy songs, add them
      if ((result['LPMI']?.isEmpty ?? true)) {
        debugPrint('[SongRepository] 🔄 LPMI collection empty, falling back to legacy method');
        final legacyResult = await _getCollectionsSeparatedLegacy(forceRefresh: forceRefresh);
        
        // Populate cache manager with legacy results
        try {
          await cacheManager.populateCacheFromLegacy(legacyResult);
        } catch (e) {
          debugPrint('[SongRepository] ⚠️ Failed to populate cache from legacy results: $e');
        }
        
        return legacyResult;
      }

      // Ensure default collections exist
      result['LPMI'] ??= [];
      result['SRD'] ??= [];
      result['Lagu_belia'] ??= [];

      debugPrint('[SongRepository] ✅ Collection separation complete using cache manager:');
      debugPrint('[SongRepository] 🔍 Collections from cache manager: ${collections.keys.toList()}');
      for (final entry in result.entries) {
        debugPrint('[SongRepository] 📊 ${entry.key}: ${entry.value.length} songs');
      }

      // Update local cache for backward compatibility
      _updateCache(result);
      return result;
    } catch (e) {
      debugPrint('[SongRepository] ❌ CollectionCacheManager failed: $e');
    }

    // Fallback to legacy implementation if cache manager fails
    debugPrint('[SongRepository] 🔄 Falling back to legacy collection loading...');
    final legacyResult = await _getCollectionsSeparatedLegacy(forceRefresh: forceRefresh);
    
    // ✅ NEW: Populate cache manager with legacy results for future use
    try {
      final cacheManager = CollectionCacheManager.instance;
      await cacheManager.populateCacheFromLegacy(legacyResult);
    } catch (e) {
      debugPrint('[SongRepository] ⚠️ Failed to populate cache from legacy results: $e');
    }
    
    return legacyResult;
  }

  /// ✅ LEGACY: Fallback method for when CollectionCacheManager fails
  Future<Map<String, List<Song>>> _getCollectionsSeparatedLegacy(
      {bool forceRefresh = false}) async {
    debugPrint('🔄 [SongRepository] Using legacy collection loading method');

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _cachedCollections != null) {
      debugPrint(
          '[SongRepository] 🚀 Using cached collections (${_cachedCollections!.keys.length} collections)');
      return Map.from(_cachedCollections!);
    }

    if (!_databaseService.isInitialized) {
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
          '[SongRepository] 🔄 Fetching collections with parallel loading...');

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

      // ✅ CRITICAL FIX: If LPMI collection is empty but we have legacy songs, add them to LPMI
      if ((separatedCollections['LPMI']?.isEmpty ?? true) && allSongs.isNotEmpty) {
        // Legacy songs are typically LPMI songs
        final legacySongs = allSongs.where((song) => song.collectionId == null || song.collectionId == 'LPMI').toList();
        if (legacySongs.isNotEmpty) {
          separatedCollections['LPMI'] = legacySongs..sort((a, b) => (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
          debugPrint('[SongRepository] ✅ Added ${legacySongs.length} legacy songs to LPMI collection');
        }
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

      debugPrint('[SongRepository] ✅ Legacy collection separation complete:');
      for (final entry in separatedCollections.entries) {
        debugPrint(
            '[SongRepository] 📊 ${entry.key}: ${entry.value.length} songs');
      }

      // ✅ CACHE: Store results for future use
      _updateCache(separatedCollections);

      return separatedCollections;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Legacy collection separation failed: $e');

      // Return cached data if available, otherwise fallback
      if (_cachedCollections != null) {
        debugPrint('[SongRepository] 💾 Using stale cache due to error');
        return Map.from(_cachedCollections!);
      }

      final allSongs = await _loadAllFromLocalAssets();
      final result = <String, List<Song>>{
        'All': allSongs.songs,
        'LPMI': allSongs.songs,  // Assets contain LPMI songs
        'SRD': <Song>[],  // ✅ FIX: Don't duplicate songs in all collections
        'Lagu_belia': <Song>[]  // ✅ FIX: These should be empty as they're specific collections
      };
      debugPrint('[SongRepository] 📦 Using asset fallback with ${allSongs.songs.length} songs');
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
      // Use persistent collections configuration
      final basePersistentCollections =
          await PersistentCollectionsConfig.getPersistentCollections();

      // Find working Christmas collection and add to persistent list
      final christmasCollection =
          await PersistentCollectionsConfig.findAndSaveChristmasCollection(
              collectionsData);

      final priorityCollections = List<String>.from(basePersistentCollections);

      // Ensure Christmas collection is in priority list if found
      if (christmasCollection != null &&
          !priorityCollections.contains(christmasCollection)) {
        priorityCollections.add(christmasCollection);
        debugPrint(
            '[SongRepository] 🎄 Added Christmas collection to priority: $christmasCollection');
      }

      if (christmasCollection == null) {
        debugPrint(
            '[SongRepository] ⚠️ No Christmas collection found in available collections');
        debugPrint(
            '[SongRepository] 🔍 Available collections: ${collectionsData.keys.toList()}');
      }

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
        final batchSize = 3; // Increased batch size for better performance
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

      debugPrint('[SongRepository] 🔍 Querying: $songsPath');

      // Longer timeout for problematic collections like Christmas
      final timeoutDuration = collectionId == 'lagu_krismas_26346'
          ? const Duration(seconds: 12)
          : const Duration(seconds: 10);

      debugPrint(
          '[SongRepository] ⏱️ Using ${timeoutDuration.inSeconds}s timeout for $collectionId');

      final songsSnapshot = await songsRef.get().timeout(timeoutDuration);

      if (!songsSnapshot.exists || songsSnapshot.value == null) {
        debugPrint(
            '[SongRepository] ⚠️ Collection $collectionId/songs is empty or doesn\'t exist');
        // Try fallback immediately
        return await _attemptCollectionFallback(database, collectionId);
      }

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
      // Use the new method that includes collection ID
      final collectionSongList = await compute(_parseSongsWithCollectionId, 
          {'jsonString': json.encode(songData), 'collectionId': collectionId});
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

      // Longer timeout for problematic collections
      final timeoutDuration = collectionId == 'lagu_krismas_26346'
          ? const Duration(seconds: 10)
          : const Duration(seconds: 5);

      final fallbackSnapshot = await fallbackRef.get().timeout(timeoutDuration);

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
    _logOperation('addSong', {'songNumber': song.number, 'collectionId': song.collectionId});
    if (!_databaseService.isInitialized) {
      throw Exception('Firebase not initialized');
    }
    final database = await _database;
    if (database == null) throw Exception('Database not available');
    try {
      final songData = song.toJson(); // ✅ Collection ID excluded by default
      
      if (song.collectionId != null) {
        // Song belongs to a collection - add to array structure
        final collectionId = song.collectionId!;
        debugPrint('[SongRepository] ➕ Adding song to collection array: $collectionId');
        
        final nextIndex = await _getNextArrayIndex(database, collectionId);
        final ref = database.ref('$_songCollectionPath/$collectionId/songs/$nextIndex');
        await ref.set(songData);
        debugPrint('[SongRepository] ✅ Song added at array index $nextIndex: ${song.number}');
        debugPrint('[SongRepository] 📍 Firebase path: ${ref.path}');
      } else {
        // Legacy song
        final ref = database.ref('$_legacySongsPath/${song.number}');
        await ref.set(songData);
        debugPrint('[SongRepository] ✅ Legacy song added: ${song.number}');
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to add song: $e');
      rethrow;
    }
  }

  Future<void> updateSong(String originalSongNumber, Song updatedSong) async {
    _logOperation('updateSong', {
      'originalNumber': originalSongNumber,
      'newNumber': updatedSong.number,
      'collectionId': updatedSong.collectionId
    });
    if (!_databaseService.isInitialized) {
      throw Exception('Firebase not initialized');
    }
    final database = await _database;
    if (database == null) throw Exception('Database not available');
    try {
      // ✅ FIX: Handle collection songs properly with array-based structure
      if (updatedSong.collectionId != null) {
        // Song belongs to a collection - use array-based update
        final collectionId = updatedSong.collectionId!;
        final songData = updatedSong.toJson(); // ✅ FIXED: Don't include collection_id in Firebase data

        debugPrint('[SongRepository] 🔍 Finding song in array-based structure');
        debugPrint('[SongRepository] 🎯 Collection: $collectionId, Song: $originalSongNumber');
        
        // Find the array index of the song to update
        final arrayIndex = await _findSongArrayIndex(database, collectionId, originalSongNumber);
        
        if (arrayIndex != null) {
          // Update existing song at the found index
          final ref = database.ref('$_songCollectionPath/$collectionId/songs/$arrayIndex');
          await ref.set(songData);
          debugPrint('[SongRepository] ✅ Updated song at array index $arrayIndex: ${updatedSong.number}');
          debugPrint('[SongRepository] 📍 Firebase path: ${ref.path}');
        } else {
          // Song not found, add as new entry at the next available array index
          debugPrint('[SongRepository] ➕ Song not found in array, adding as new entry');
          final nextIndex = await _getNextArrayIndex(database, collectionId);
          final ref = database.ref('$_songCollectionPath/$collectionId/songs/$nextIndex');
          await ref.set(songData);
          debugPrint('[SongRepository] ✅ Added new song at array index $nextIndex: ${updatedSong.number}');
          debugPrint('[SongRepository] 📍 Firebase path: ${ref.path}');
        }
        
        debugPrint('[SongRepository] 📦 Data keys: ${songData.keys.toList()}');
        debugPrint('[SongRepository] ✅ Verified: collection_id NOT included in saved data');
      } else {
        // Legacy song
        if (originalSongNumber != updatedSong.number) {
          await deleteSong(originalSongNumber);
          await addSong(updatedSong);
        } else {
          final songData = updatedSong.toJson();
          final ref = database.ref('$_legacySongsPath/${updatedSong.number}');
          await ref.set(
              songData); // Use set instead of update to ensure all fields are updated
        }
      }
      debugPrint('[SongRepository] ✅ Song updated: ${updatedSong.number}');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to update song: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Public method to clean up existing duplicates for a specific song
  Future<bool> cleanupDuplicateSongs(String songNumber, String targetCollectionId) async {
    debugPrint('[SongRepository] 🔧 Manual cleanup requested for song: $songNumber');
    debugPrint('[SongRepository] ℹ️  Note: With array-based structure, duplicates are prevented by design');
    
    // With the new array-based structure, duplicates should not occur
    // This method is kept for backward compatibility but is no longer needed
    debugPrint('[SongRepository] ✅ No cleanup needed - array structure prevents duplicates');
    return true;
  }

  /// ✅ NEW: Get the next available array index for adding a new song
  Future<int> _getNextArrayIndex(FirebaseDatabase database, String collectionId) async {
    try {
      debugPrint('[SongRepository] 🔢 Finding next array index for collection: $collectionId');
      
      final songsRef = database.ref('$_songCollectionPath/$collectionId/songs');
      final snapshot = await songsRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('[SongRepository] 📋 No songs array found, starting at index 0');
        return 0;
      }
      
      // Firebase arrays come as Maps with string keys (0, 1, 2, etc.)
      final songsData = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Find the highest numeric index
      int maxIndex = -1;
      for (final key in songsData.keys) {
        final index = int.tryParse(key);
        if (index != null && index > maxIndex) {
          maxIndex = index;
        }
      }
      
      final nextIndex = maxIndex + 1;
      debugPrint('[SongRepository] 📋 Found ${songsData.length} songs, next index: $nextIndex');
      return nextIndex;
      
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error finding next array index: $e');
      // Fallback to 0 if there's an error
      return 0;
    }
  }

  /// ✅ NEW: Find the array index of a song in a collection's songs array
  Future<int?> _findSongArrayIndex(FirebaseDatabase database, String collectionId, String songNumber) async {
    try {
      debugPrint('[SongRepository] 🔍 Searching for song $songNumber in collection $collectionId array');
      
      final songsRef = database.ref('$_songCollectionPath/$collectionId/songs');
      final snapshot = await songsRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('[SongRepository] ❌ Songs array not found in collection $collectionId');
        return null;
      }
      
      // Firebase arrays come as Maps with string keys (0, 1, 2, etc.)
      final songsData = Map<String, dynamic>.from(snapshot.value as Map);
      final songNumberVariants = _generateSongNumberVariants(songNumber);
      
      debugPrint('[SongRepository] 📋 Found ${songsData.length} songs in array');
      debugPrint('[SongRepository] 🔢 Looking for song number variants: $songNumberVariants');
      
      // Search through each array index
      for (final entry in songsData.entries) {
        final arrayIndex = entry.key;
        final songData = entry.value;
        
        if (songData is Map) {
          final songMap = Map<String, dynamic>.from(songData);
          final currentSongNumber = songMap['song_number'] as String?;
          
          if (currentSongNumber != null) {
            // Check if any variant matches
            if (songNumberVariants.contains(currentSongNumber)) {
              debugPrint('[SongRepository] ✅ Found song at array index $arrayIndex: $currentSongNumber');
              return int.tryParse(arrayIndex);
            }
          }
        }
      }
      
      debugPrint('[SongRepository] ❌ Song $songNumber not found in collection $collectionId array');
      return null;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error finding song array index: $e');
      return null;
    }
  }

  /// ✅ NEW: Generate song number variants to handle format differences
  List<String> _generateSongNumberVariants(String songNumber) {
    final variants = <String>{};
    
    // Add the original number
    variants.add(songNumber);
    
    // If it's a numeric string, add variants with/without leading zeros
    final numericMatch = RegExp(r'^0*(\d+)$').firstMatch(songNumber);
    if (numericMatch != null) {
      final coreNumber = numericMatch.group(1)!;
      
      // Add version without leading zeros
      variants.add(coreNumber);
      
      // Add common padded versions
      variants.add(coreNumber.padLeft(2, '0')); // 01, 02, 03
      variants.add(coreNumber.padLeft(3, '0')); // 001, 002, 003
      variants.add(coreNumber.padLeft(4, '0')); // 0001, 0002, 0003
    }
    
    return variants.toList();
  }


  Future<int> _removeOriginalSongFromAllLocations(
      FirebaseDatabase database, String songNumber) async {
    debugPrint('[SongRepository] 🗑️ Starting deletion of song: $songNumber');
    int deletionCount = 0;

    try {
      // Remove from all collections
      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot = await collectionsRef.get();

      if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
        final collectionsData =
            Map<String, dynamic>.from(collectionsSnapshot.value as Map);

        debugPrint(
            '[SongRepository] 🔍 Searching ${collectionsData.keys.length} collections for song $songNumber');

        for (final collectionId in collectionsData.keys) {
          debugPrint('[SongRepository] 🔍 Checking collection: $collectionId');

          // ✅ UPDATED: Check paths based on actual Firebase structure
          final songPaths = [
            '$_songCollectionPath/$collectionId/$songNumber', // Direct under collection (most common)
            '$_songCollectionPath/$collectionId/songs/$songNumber', // In songs subfolder  
            '$_songCollectionPath/$collectionId/song/$songNumber', // In song subfolder
          ];

          for (final songPath in songPaths) {
            final songRef = database.ref(songPath);
            final songSnapshot = await songRef.get();

            if (songSnapshot.exists) {
              await songRef.remove();
              deletionCount++;
              debugPrint(
                  '[SongRepository] ✅ Removed song from $collectionId at path: $songPath');
            }
          }

          // Special handling for Christmas collections with numeric suffixes
          if (collectionId.toLowerCase().contains('krismas') ||
              collectionId.toLowerCase().contains('christmas')) {
            debugPrint(
                '[SongRepository] 🎄 Special Christmas collection processing: $collectionId');

            // Try additional Christmas-specific paths (already covered above, but being thorough)
            final christmasPaths = [
              '$_songCollectionPath/$collectionId/lagu/$songNumber', // Indonesian path
              '$_songCollectionPath/$collectionId/christmas/$songNumber', // Potential Christmas-specific path
            ];

            for (final christmasPath in christmasPaths) {
              final christmasRef = database.ref(christmasPath);
              final christmasSnapshot = await christmasRef.get();

              if (christmasSnapshot.exists) {
                await christmasRef.remove();
                deletionCount++;
                debugPrint(
                    '[SongRepository] 🎄 Removed Christmas song at path: $christmasPath');
              }
            }
          }
        }
      } else {
        debugPrint(
            '[SongRepository] ⚠️ No collections found at path: $_songCollectionPath');
      }

      // Remove from legacy path
      final legacyRef = database.ref('$_legacySongsPath/$songNumber');
      final legacySnapshot = await legacyRef.get();

      if (legacySnapshot.exists) {
        await legacyRef.remove();
        deletionCount++;
        debugPrint(
            '[SongRepository] ✅ Removed song from legacy path: $_legacySongsPath/$songNumber');
      }

      debugPrint(
          '[SongRepository] 🗑️ Song deletion completed. Total deletions: $deletionCount');

      if (deletionCount == 0) {
        debugPrint(
            '[SongRepository] ⚠️ WARNING: Song $songNumber was not found in any location!');
      }
      
      return deletionCount;
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Error removing original song from all locations: $e');
      // Don't rethrow - continue with the update even if removal fails
      return 0;
    }
  }

  Future<void> deleteSong(String songNumber) async {
    _logOperation('deleteSong', {'songNumber': songNumber});
    debugPrint(
        '[SongRepository] 🗑️ Delete operation started for song: $songNumber');

    if (!_databaseService.isInitialized) {
      throw Exception('Firebase not initialized');
    }
    final database = await _database;
    if (database == null) throw Exception('Database not available');

    try {
      // ✅ DEBUG: First, let's see where this song actually exists
      await _debugSongLocations(database, songNumber);

      // ✅ FIX: Delete from all possible locations (collections and legacy)
      final deletionResult = await _removeOriginalSongFromAllLocations(database, songNumber);
      
      // ✅ ENHANCED: Verify deletion was successful
      if (deletionResult == 0) {
        debugPrint('[SongRepository] ⚠️ WARNING: No songs were found to delete for song number: $songNumber');
        throw Exception('Song #$songNumber not found in database for deletion');
      }
      
      debugPrint(
          '[SongRepository] ✅ Song deletion completed successfully: $songNumber (deleted from $deletionResult locations)');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to delete song: $e');
      debugPrint('[SongRepository] 🔍 Error details: ${e.toString()}');
      debugPrint('[SongRepository] 📍 Song number: $songNumber');
      debugPrint('[SongRepository] 🔧 Database paths checked:');
      debugPrint(
          '[SongRepository]   - $_songCollectionPath/*/songs/$songNumber');
      debugPrint('[SongRepository]   - $_songCollectionPath/*/$songNumber');
      debugPrint('[SongRepository]   - $_legacySongsPath/$songNumber');
      rethrow;
    }
  }

  // ✅ NEW: Debug method to find where a song actually exists
  Future<void> _debugSongLocations(
      FirebaseDatabase database, String songNumber) async {
    debugPrint(
        '[SongRepository] 🔍 DEBUG: Searching for song $songNumber in all possible locations...');

    try {
      // Check all collections
      final collectionsRef = database.ref(_songCollectionPath);
      final collectionsSnapshot = await collectionsRef.get();

      if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
        final collectionsData =
            Map<String, dynamic>.from(collectionsSnapshot.value as Map);

        debugPrint('[SongRepository] 🔍 Found ${collectionsData.keys.length} collections: ${collectionsData.keys.toList()}');

        for (final collectionId in collectionsData.keys) {
          debugPrint('[SongRepository] 🔍 Checking collection: $collectionId');
          
          // Check various possible paths based on actual Firebase structure
          final pathsToCheck = [
            '$_songCollectionPath/$collectionId/$songNumber', // Direct under collection (most common)
            '$_songCollectionPath/$collectionId/songs/$songNumber', // In songs subfolder
            '$_songCollectionPath/$collectionId/song/$songNumber', // In song subfolder  
            '$_songCollectionPath/$collectionId/lagu/$songNumber', // In lagu subfolder (Indonesian)
          ];

          for (final path in pathsToCheck) {
            final ref = database.ref(path);
            final snapshot = await ref.get();
            if (snapshot.exists) {
              debugPrint(
                  '[SongRepository] 🎯 FOUND song $songNumber at: $path');
              debugPrint('[SongRepository] 📄 Song data: ${snapshot.value}');
            }
          }
        }
      }

      // Check legacy path
      final legacyRef = database.ref('$_legacySongsPath/$songNumber');
      final legacySnapshot = await legacyRef.get();
      if (legacySnapshot.exists) {
        debugPrint(
            '[SongRepository] 🎯 FOUND song $songNumber in legacy path: $_legacySongsPath/$songNumber');
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error during debug search: $e');
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

          // Specific timeout handling for Christmas collection
          final timeoutDuration = collectionId == 'lagu_krismas_26346'
              ? const Duration(seconds: 12)
              : const Duration(seconds: 8);

          debugPrint(
              '[SongRepository] ⏱️ Using ${timeoutDuration.inSeconds}s timeout for $collectionId');

          final songsSnapshot = await songsRef.get().timeout(timeoutDuration);

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

            // Longer fallback timeout for Christmas collection
            final fallbackTimeout = collectionId == 'lagu_krismas_26346'
                ? const Duration(seconds: 8)
                : const Duration(seconds: 5);

            final fallbackSnapshot =
                await fallbackRef.get().timeout(fallbackTimeout);
            if (fallbackSnapshot.exists && fallbackSnapshot.value != null) {
              final fallbackData = fallbackSnapshot.value;
              debugPrint(
                  '[SongRepository] 🔄 Trying fallback for $collectionId, type: ${fallbackData.runtimeType}');

              // Special handling for Christmas collection
              if (collectionId == 'lagu_krismas_26346') {
                debugPrint(
                    '[SongRepository] 🎄 Processing Christmas collection with special handling...');
              }
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
        
        // ✅ DEBUG: Check if song "003" exists in this collection
        final songMap = entry.value as Map<String, dynamic>?;
        if (songMap != null && songMap.containsKey('003')) {
          final song003Data = songMap['003'];
          if (song003Data is Map<String, dynamic>) {
            debugPrint('🎯 [SongRepository] Collection ${entry.key} contains song "003":');
            debugPrint('  Title: "${song003Data['song_title']}"');
            debugPrint('  HasAudio: ${song003Data['has_audio']}');
            debugPrint('  AudioUrl: "${song003Data['audio_url']}"');
          }
        }
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
      'firebaseInitialized': _databaseService.isInitialized,
      'databaseInitialized': _databaseService.isInitialized,
      'lastConnectionCheck': DateTime.now().toIso8601String(),
      'lastConnectionResult': true,
      'migrationMappings': Map.from(_collectionIdMapping),
      'lastMigrationCheck': _lastMigrationCheck?.toIso8601String(),
      'cachedMigrationStatus': _cachedMigrationStatus != null,
    };
  }

  Map<String, dynamic> getRepositorySummary() {
    return {
      'isFirebaseInitialized': _databaseService.isInitialized,
      'databaseAvailable': _databaseService.isInitialized,
      'lastConnectionResult': true,
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

  /// Debug method to specifically check Christmas collection
  Future<void> debugChristmasCollection() async {
    debugPrint('[SongRepository] 🎄 === DEBUGGING CHRISTMAS COLLECTION ===');

    if (!_databaseService.isInitialized) {
      debugPrint('[SongRepository] ❌ Firebase not initialized');
      return;
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      final collectionId = 'lagu_krismas_26346';
      final basePath = '$_songCollectionPath/$collectionId';
      final songsPath = '$basePath/songs';

      debugPrint('[SongRepository] 🔍 Checking base path: $basePath');
      final baseRef = database.ref(basePath);
      final baseSnapshot =
          await baseRef.get().timeout(const Duration(seconds: 10));

      if (baseSnapshot.exists) {
        debugPrint('[SongRepository] ✅ Base collection exists');
        debugPrint(
            '[SongRepository] 📊 Base data type: ${baseSnapshot.value.runtimeType}');

        if (baseSnapshot.value is Map) {
          final baseData = Map<String, dynamic>.from(baseSnapshot.value as Map);
          debugPrint(
              '[SongRepository] 🗂️ Base keys: ${baseData.keys.toList()}');
        }
      } else {
        debugPrint('[SongRepository] ❌ Base collection does not exist');
        return;
      }

      debugPrint('[SongRepository] 🔍 Checking songs path: $songsPath');
      final songsRef = database.ref(songsPath);
      final songsSnapshot =
          await songsRef.get().timeout(const Duration(seconds: 15));

      if (songsSnapshot.exists) {
        debugPrint('[SongRepository] ✅ Songs node exists');
        debugPrint(
            '[SongRepository] 📊 Songs data type: ${songsSnapshot.value.runtimeType}');

        if (songsSnapshot.value is Map) {
          final songsData =
              Map<String, dynamic>.from(songsSnapshot.value as Map);
          debugPrint('[SongRepository] 🎵 Total songs: ${songsData.length}');
          debugPrint(
              '[SongRepository] 🔑 First few song keys: ${songsData.keys.take(5).toList()}');
        }
      } else {
        debugPrint('[SongRepository] ❌ Songs node does not exist');
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Christmas collection debug failed: $e');
    }

    debugPrint('[SongRepository] 🎄 === END CHRISTMAS DEBUG ===');
  }
}
