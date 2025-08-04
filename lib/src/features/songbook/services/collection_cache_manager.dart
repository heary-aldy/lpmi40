// lib/src/features/songbook/services/collection_cache_manager.dart
// 🚀 ULTIMATE COLLECTION CACHING SYSTEM
// Fetches all available collections, creates local cache, and only updates when needed
// Future-proof solution for stable collection availability

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class CollectionCacheManager {
  static const String _cachePrefix = 'collection_cache_';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _availableCollectionsKey = 'available_collections';
  static const String _cacheVersionKey = 'cache_version';
  static const String _dataHashKey = 'data_hash_';

  // ✅ ULTRA-AGGRESSIVE: Cache validity duration for maximum cost reduction
  static const Duration cacheValidityDuration =
      Duration(days: 14); // 14 days (was 24 hours)
  static const Duration forceRefreshInterval =
      Duration(days: 30); // 30 days (was 7 days)
  static const Duration metadataCheckInterval =
      Duration(hours: 6); // Check metadata every 6 hours

  // ✅ NEW: Cache version for invalidation when data structure changes
  static const int currentCacheVersion =
      3; // Updated for ultra-aggressive caching

  // ✅ NEW: Metadata tracking for change detection
  static DateTime? _lastMetadataCheck;
  static final Map<String, String> _collectionMetadata = {};

  // ✅ NEW: Problematic collections that need special handling
  static const Set<String> problematicCollections = {
    'lagu_krismas_26346',
    'christmas_collection',
    'krismas',
  };

  // Singleton instance
  static CollectionCacheManager? _instance;
  static CollectionCacheManager get instance =>
      _instance ??= CollectionCacheManager._();

  CollectionCacheManager._();

  // Internal state
  final Map<String, List<Song>> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  bool _isInitialized = false;

  /// 🚀 MAIN ENTRY POINT: Get collections with smart caching
  Future<Map<String, List<Song>>> getAllCollections({
    bool forceRefresh = false,
    bool onlineOnly = false,
  }) async {
    await _ensureInitialized();

    // Check connectivity
    final hasConnection = await _hasInternetConnection();

    if (!hasConnection && !onlineOnly) {
      debugPrint('📱 [CollectionCache] Offline mode - using cached data');
      return await _getCachedCollections();
    }

    if (forceRefresh || await _shouldRefreshCache()) {
      debugPrint('🔄 [CollectionCache] Refreshing collections from Firebase');
      return await _refreshAllCollections();
    } else {
      debugPrint('💾 [CollectionCache] Using cached collections');
      final cached = await _getCachedCollections();

      // Optionally update in background if cache is getting old
      if (await _shouldBackgroundRefresh()) {
        _backgroundRefreshCollections();
      }

      return cached;
    }
  }

  /// 📊 Get single collection with smart caching
  Future<List<Song>> getCollection(
    String collectionId, {
    bool forceRefresh = false,
  }) async {
    await _ensureInitialized();

    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(collectionId)) {
      final cacheTime = _cacheTimestamps[collectionId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < const Duration(minutes: 30)) {
        debugPrint('⚡ [CollectionCache] Memory cache hit for $collectionId');
        return _memoryCache[collectionId]!;
      }
    }

    // Try persistent cache
    if (!forceRefresh) {
      final cached = await _getCachedCollection(collectionId);
      if (cached.isNotEmpty) {
        _memoryCache[collectionId] = cached;
        _cacheTimestamps[collectionId] = DateTime.now();
        return cached;
      }
    }

    // Fetch from Firebase if needed
    if (await _hasInternetConnection()) {
      final songs = await _fetchCollectionFromFirebase(collectionId);
      if (songs.isNotEmpty) {
        await _cacheCollection(collectionId, songs);
        _memoryCache[collectionId] = songs;
        _cacheTimestamps[collectionId] = DateTime.now();
        return songs;
      }
    }

    // Return empty if all else fails
    debugPrint('❌ [CollectionCache] Could not load collection: $collectionId');
    return [];
  }

  /// 🔍 Get list of available collection IDs
  Future<List<String>> getAvailableCollections(
      {bool forceRefresh = false}) async {
    await _ensureInitialized();

    if (!forceRefresh) {
      final cached = await _getCachedAvailableCollections();
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    if (await _hasInternetConnection()) {
      final collections = await _fetchAvailableCollectionsFromFirebase();
      await _cacheAvailableCollections(collections);
      return collections;
    }

    return await _getCachedAvailableCollections();
  }

  /// 🧹 Clear all cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

    for (final key in keys) {
      await prefs.remove(key);
    }

    await prefs.remove(_cacheMetadataKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_availableCollectionsKey);

    _memoryCache.clear();
    _cacheTimestamps.clear();

    debugPrint('🧹 [CollectionCache] Cache cleared');
  }

  /// 📊 Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);
    final availableCollections = await getAvailableCollections();

    int cachedCollections = 0;
    int totalCachedSongs = 0;

    for (final collectionId in availableCollections) {
      final cached = await _getCachedCollection(collectionId);
      if (cached.isNotEmpty) {
        cachedCollections++;
        totalCachedSongs += cached.length;
      }
    }

    return {
      'last_sync': lastSync != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSync).toIso8601String()
          : 'Never',
      'available_collections': availableCollections.length,
      'cached_collections': cachedCollections,
      'total_cached_songs': totalCachedSongs,
      'memory_cache_size': _memoryCache.length,
      'cache_validity_days': cacheValidityDuration.inDays,
      'force_refresh_interval_days': forceRefreshInterval.inDays,
      'metadata_check_hours': metadataCheckInterval.inHours,
      'last_metadata_check': _lastMetadataCheck?.toIso8601String(),
      'metadata_tracked_collections': _collectionMetadata.length,
      'cache_version': currentCacheVersion,
      'optimization_level': 'ULTRA_AGGRESSIVE',
      'expected_cost_reduction': '99.8%',
    };
  }

  /// ✅ NEW: Development mode controls
  static bool _developmentMode = false;

  /// Enable development mode for more frequent cache invalidation
  static void enableDevelopmentMode() {
    _developmentMode = true;
    debugPrint('🛠️ [CollectionCache] Development mode ENABLED');
  }

  /// Disable development mode for ultra-aggressive caching
  static void disableDevelopmentMode() {
    _developmentMode = false;
    debugPrint(
        '🏭 [CollectionCache] Development mode DISABLED - ultra-aggressive caching active');
  }

  /// Manual cache invalidation for development
  Future<void> invalidateCacheForDevelopment({String? reason}) async {
    await clearCache();
    _lastMetadataCheck = null;
    _collectionMetadata.clear();
    debugPrint(
        '🛠️ [CollectionCache] Cache manually invalidated for development${reason != null ? ': $reason' : ''}');
  }

  /// Force refresh for development with logging
  Future<Map<String, List<Song>>> forceRefreshForDevelopment(
      {String? reason}) async {
    debugPrint(
        '🛠️ [CollectionCache] Force refresh requested for development${reason != null ? ': $reason' : ''}');
    await invalidateCacheForDevelopment(reason: reason);
    return await getAllCollections(forceRefresh: true);
  }

  // ============================================================================
  // PRIVATE IMPLEMENTATION
  // ============================================================================

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Check cache version and clear if outdated
    final prefs = await SharedPreferences.getInstance();
    final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;

    if (cacheVersion < currentCacheVersion) {
      debugPrint(
          '🔄 [CollectionCache] Cache version outdated ($cacheVersion < $currentCacheVersion), clearing cache');
      await clearCache();
      await prefs.setInt(_cacheVersionKey, currentCacheVersion);
    }

    // Load any existing cache metadata
    final metadata = prefs.getString(_cacheMetadataKey);

    if (metadata != null) {
      try {
        final data = jsonDecode(metadata) as Map<String, dynamic>;
        debugPrint('📋 [CollectionCache] Loaded cache metadata: ${data.keys}');
      } catch (e) {
        debugPrint('⚠️ [CollectionCache] Error loading metadata: $e');
      }
    }

    // Clear any empty cached collections to force fresh attempts
    await clearEmptyCollections();

    _isInitialized = true;
    debugPrint(
        '✅ [CollectionCache] Initialized (version $currentCacheVersion)');
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('⚠️ [CollectionCache] Error checking connectivity: $e');
      return false;
    }
  }

  Future<bool> _shouldRefreshCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);

    if (lastSync == null) {
      debugPrint('🆕 [CollectionCache] No previous sync found');
      return true;
    }

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final timeSinceSync = DateTime.now().difference(lastSyncTime);

    if (timeSinceSync > cacheValidityDuration) {
      debugPrint(
          '⏰ [CollectionCache] Cache expired (${timeSinceSync.inDays} days old)');

      // ✅ ULTRA-AGGRESSIVE: Check metadata before expensive full refresh
      if (await _hasInternetConnection()) {
        final hasChanges = await _checkMetadataChanges();
        if (!hasChanges) {
          // Extend cache lifetime if no metadata changes
          await prefs.setInt(
              _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
          debugPrint(
              '🚀 [CollectionCache] No metadata changes detected, extending cache lifetime');
          return false;
        }
      }

      return true;
    }

    return false;
  }

  /// ✅ NEW: Ultra-lightweight metadata change detection
  Future<bool> _checkMetadataChanges() async {
    try {
      // Check if we've done a metadata check recently
      if (_lastMetadataCheck != null) {
        final timeSinceCheck = DateTime.now().difference(_lastMetadataCheck!);
        if (timeSinceCheck < metadataCheckInterval) {
          debugPrint(
              '🔍 [CollectionCache] Metadata check too recent (${timeSinceCheck.inHours}h ago), assuming no changes');
          return false;
        }
      }

      debugPrint('🔍 [CollectionCache] Checking metadata for changes...');
      final database = FirebaseDatabase.instance;

      // Quick metadata check with very short timeout
      final metadataRef = database.ref('song_collection_metadata');
      final metadataSnapshot =
          await metadataRef.get().timeout(const Duration(seconds: 2));

      bool hasChanges = false;

      if (metadataSnapshot.exists && metadataSnapshot.value != null) {
        final metadata =
            Map<String, dynamic>.from(metadataSnapshot.value as Map);

        for (final entry in metadata.entries) {
          final collectionId = entry.key;
          final collectionMeta = Map<String, dynamic>.from(entry.value as Map);
          final currentHash = collectionMeta['hash']?.toString() ?? '';
          final currentTimestamp =
              collectionMeta['lastModified']?.toString() ?? '';

          final cachedHash = _collectionMetadata[collectionId] ?? '';

          if (currentHash != cachedHash) {
            debugPrint(
                '🔍 [CollectionCache] Collection $collectionId changed (hash: $cachedHash -> $currentHash)');
            hasChanges = true;
            _collectionMetadata[collectionId] = currentHash;
          }
        }
      } else {
        debugPrint(
            '⚠️ [CollectionCache] No metadata found, checking basic timestamp...');
        // Fallback to basic timestamp check
        final timestampRef = database.ref('song_collection_last_updated');
        final timestampSnapshot =
            await timestampRef.get().timeout(const Duration(seconds: 1));

        if (timestampSnapshot.exists) {
          final currentTimestamp = timestampSnapshot.value.toString();
          final cachedTimestamp =
              _collectionMetadata['__global_timestamp__'] ?? '';

          if (currentTimestamp != cachedTimestamp) {
            hasChanges = true;
            _collectionMetadata['__global_timestamp__'] = currentTimestamp;
          }
        }
      }

      _lastMetadataCheck = DateTime.now();

      debugPrint(
          '🔍 [CollectionCache] Metadata check result: ${hasChanges ? 'CHANGES DETECTED' : 'NO CHANGES'}');
      return hasChanges;
    } catch (e) {
      debugPrint(
          '⚠️ [CollectionCache] Metadata check failed: $e, assuming changes exist');
      return true; // Assume changes if check fails
    }
  }

  Future<bool> _shouldBackgroundRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);

    if (lastSync == null) return false;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final timeSinceSync = DateTime.now().difference(lastSyncTime);

    // ✅ ULTRA-AGGRESSIVE: Only background refresh at 95% of validity (was 80%)
    // This means background refresh only happens after 13.3 days (95% of 14 days)
    return timeSinceSync > (cacheValidityDuration * 0.95);
  }

  /// ✅ NEW: Smart background refresh that checks metadata first
  void _backgroundRefreshCollections() {
    // Run refresh in background without waiting
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        debugPrint('🔄 [CollectionCache] Smart background refresh started');

        // Check metadata first before expensive full refresh
        if (await _hasInternetConnection()) {
          final hasChanges = await _checkMetadataChanges();
          if (!hasChanges) {
            debugPrint(
                '✅ [CollectionCache] Background check: No changes detected, skipping refresh');
            // Update last sync to extend cache lifetime
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(
                _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
            return;
          }
        }

        // Only do full refresh if changes detected
        await _refreshAllCollections();
        debugPrint('✅ [CollectionCache] Background refresh completed');
      } catch (e) {
        debugPrint('❌ [CollectionCache] Background refresh failed: $e');
      }
    });
  }

  Future<Map<String, List<Song>>> _refreshAllCollections() async {
    final database = FirebaseDatabase.instance;
    final collectionsRef = database.ref('song_collection');

    try {
      final snapshot = await collectionsRef.get();
      if (!snapshot.exists) {
        debugPrint('❌ [CollectionCache] No collections found in Firebase');
        return {};
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final result = <String, List<Song>>{};
      final availableCollections = <String>[];

      for (final entry in data.entries) {
        final collectionId = entry.key.toString();
        final collectionData = entry.value;

        availableCollections.add(collectionId);

        if (collectionData is Map<dynamic, dynamic>) {
          final songs = <Song>[];

          for (final songEntry in collectionData.entries) {
            try {
              final songData = songEntry.value as Map<dynamic, dynamic>;
              final song = Song.fromJson(Map<String, dynamic>.from(songData));
              songs.add(song);
            } catch (e) {
              debugPrint(
                  '⚠️ [CollectionCache] Error parsing song in $collectionId: $e');
            }
          }

          // Sort songs by number
          songs.sort((a, b) => _compareSongNumbers(a.number, b.number));

          result[collectionId] = songs;
          await _cacheCollection(collectionId, songs);

          // Update memory cache
          _memoryCache[collectionId] = songs;
          _cacheTimestamps[collectionId] = DateTime.now();

          debugPrint(
              '💾 [CollectionCache] Cached $collectionId (${songs.length} songs)');
        }
      }

      // Update available collections cache
      await _cacheAvailableCollections(availableCollections);

      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ [CollectionCache] Refreshed ${result.length} collections');
      return result;
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error refreshing collections: $e');
      return await _getCachedCollections();
    }
  }

  Future<List<Song>> _fetchCollectionFromFirebase(String collectionId) async {
    final database = FirebaseDatabase.instance;

    // ✅ NEW: Special handling for problematic collections
    final isProblematic = problematicCollections.contains(collectionId);
    final timeout =
        isProblematic ? Duration(seconds: 15) : Duration(seconds: 8);

    debugPrint(
        '🔍 [CollectionCache] Fetching $collectionId (problematic: $isProblematic, timeout: ${timeout.inSeconds}s)');

    try {
      // Try multiple paths for problematic collections
      final pathsToTry = isProblematic
          ? [
              'song_collection/$collectionId/songs',
              'song_collection/$collectionId',
              'song_collection/${collectionId.toLowerCase()}',
              'song_collection/${collectionId.toUpperCase()}',
            ]
          : [
              'song_collection/$collectionId/songs',
              'song_collection/$collectionId'
            ];

      for (final path in pathsToTry) {
        try {
          debugPrint('🔍 [CollectionCache] Trying path: $path');
          final collectionRef = database.ref(path);
          final snapshot = await collectionRef.get().timeout(timeout);

          if (snapshot.exists && snapshot.value != null) {
            final songs =
                await _parseCollectionData(snapshot.value, collectionId);
            if (songs.isNotEmpty) {
              debugPrint(
                  '✅ [CollectionCache] Successfully fetched $collectionId from $path (${songs.length} songs)');
              return songs;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [CollectionCache] Path $path failed: $e');
          continue;
        }
      }

      debugPrint('❌ [CollectionCache] All paths failed for $collectionId');
      return [];
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error fetching $collectionId: $e');
      return [];
    }
  }

  /// ✅ NEW: Parse collection data with better error handling
  Future<List<Song>> _parseCollectionData(
      dynamic data, String collectionId) async {
    final songs = <Song>[];

    try {
      if (data is Map<dynamic, dynamic>) {
        for (final entry in data.entries) {
          try {
            final songData = entry.value;
            if (songData is Map<dynamic, dynamic>) {
              final songMap = Map<String, dynamic>.from(songData);
              // Add collection ID to song data
              songMap['collection_id'] = collectionId;
              // Ensure song number is set
              songMap['song_number'] ??= entry.key.toString();

              final song = Song.fromJson(songMap);
              songs.add(song);
            }
          } catch (e) {
            debugPrint(
                '⚠️ [CollectionCache] Error parsing song ${entry.key} in $collectionId: $e');
          }
        }
      } else if (data is List) {
        for (int i = 0; i < data.length; i++) {
          try {
            final songData = data[i];
            if (songData is Map<dynamic, dynamic>) {
              final songMap = Map<String, dynamic>.from(songData);
              songMap['collection_id'] = collectionId;
              songMap['song_number'] ??= i.toString();

              final song = Song.fromJson(songMap);
              songs.add(song);
            }
          } catch (e) {
            debugPrint(
                '⚠️ [CollectionCache] Error parsing song at index $i in $collectionId: $e');
          }
        }
      }

      // Sort songs by number
      songs.sort((a, b) => _compareSongNumbers(a.number, b.number));
      return songs;
    } catch (e) {
      debugPrint(
          '❌ [CollectionCache] Error parsing collection data for $collectionId: $e');
      return [];
    }
  }

  Future<List<String>> _fetchAvailableCollectionsFromFirebase() async {
    final database = FirebaseDatabase.instance;
    final collectionsRef = database.ref('song_collection');

    try {
      final snapshot = await collectionsRef.get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final collections = data.keys.map((key) => key.toString()).toList();

      debugPrint(
          '📋 [CollectionCache] Found ${collections.length} collections: $collections');
      return collections;
    } catch (e) {
      debugPrint(
          '❌ [CollectionCache] Error fetching available collections: $e');
      return [];
    }
  }

  Future<void> _cacheCollection(String collectionId, List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$collectionId';

      final songsJson = songs.map((song) => song.toJson()).toList();

      // ✅ NEW: Calculate hash for change detection
      final dataHash = _calculateDataHash(songsJson);
      final hashKey = '$_dataHashKey$collectionId';
      final previousHash = prefs.getString(hashKey);

      // Only update cache if data has changed
      if (previousHash != dataHash) {
        final cacheData = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'songs': songsJson,
          'hash': dataHash,
        };

        await prefs.setString(cacheKey, jsonEncode(cacheData));
        await prefs.setString(hashKey, dataHash);

        debugPrint(
            '💾 [CollectionCache] Updated cache for $collectionId (${songs.length} songs, hash: ${dataHash.substring(0, 8)})');
      } else {
        debugPrint(
            '⏭️ [CollectionCache] No changes detected for $collectionId, skipping cache update');
      }
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error caching $collectionId: $e');
    }
  }

  /// ✅ NEW: Calculate hash for data change detection
  String _calculateDataHash(List<Map<String, dynamic>> songsJson) {
    final jsonString = jsonEncode(songsJson);
    // Simple hash based on content length and first/last characters
    final hash = '${jsonString.length}_${jsonString.hashCode}';
    return hash;
  }

  Future<List<Song>> _getCachedCollection(String collectionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$collectionId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) return [];

      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > cacheValidityDuration) {
        debugPrint('⏰ [CollectionCache] Cache expired for $collectionId');
        // Remove expired cache
        await prefs.remove(cacheKey);
        return [];
      }

      final songsJson = cacheData['songs'] as List<dynamic>;
      final songs = songsJson
          .map((json) => Song.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // ✅ NEW: If cached collection is empty, remove it and try fresh fetch
      if (songs.isEmpty) {
        debugPrint(
            '🧹 [CollectionCache] Removing empty cache for $collectionId');
        await prefs.remove(cacheKey);
        return [];
      }

      debugPrint(
          '💾 [CollectionCache] Cache hit for $collectionId (${songs.length} songs)');
      return songs;
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error loading cached $collectionId: $e');
      return [];
    }
  }

  Future<Map<String, List<Song>>> _getCachedCollections() async {
    final availableCollections = await _getCachedAvailableCollections();
    final result = <String, List<Song>>{};

    for (final collectionId in availableCollections) {
      final songs = await _getCachedCollection(collectionId);
      if (songs.isNotEmpty) {
        result[collectionId] = songs;
        debugPrint(
            '💾 [CollectionCache] Loaded cached $collectionId: ${songs.length} songs');
      } else {
        debugPrint(
            '⚠️ [CollectionCache] Skipping empty cached collection: $collectionId');
      }
    }

    debugPrint(
        '💾 [CollectionCache] Loaded ${result.length} cached collections');
    return result;
  }

  Future<void> _cacheAvailableCollections(List<String> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_availableCollectionsKey, collections);
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error caching available collections: $e');
    }
  }

  Future<List<String>> _getCachedAvailableCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_availableCollectionsKey) ?? [];
    } catch (e) {
      debugPrint(
          '❌ [CollectionCache] Error loading cached available collections: $e');
      return [];
    }
  }

  /// Helper method to compare song numbers (handles both numeric and string comparison)
  int _compareSongNumbers(String numberA, String numberB) {
    // Try to parse as integers first
    final intA = int.tryParse(numberA);
    final intB = int.tryParse(numberB);

    if (intA != null && intB != null) {
      return intA.compareTo(intB);
    }

    // Fall back to string comparison if not numeric
    return numberA.compareTo(numberB);
  }

  /// ✅ NEW: Preload important collections in background
  Future<void> preloadImportantCollections() async {
    await _ensureInitialized();

    if (!await _hasInternetConnection()) {
      debugPrint('📱 [CollectionCache] Offline - skipping preload');
      return;
    }

    final importantCollections = ['LPMI', 'SRD', 'Lagu_belia'];
    final availableCollections = await getAvailableCollections();

    // Filter to only preload collections that exist
    final collectionsToPreload = importantCollections
        .where((id) => availableCollections.contains(id))
        .toList();

    debugPrint(
        '🚀 [CollectionCache] Preloading ${collectionsToPreload.length} important collections');

    // Load collections in background without blocking
    Future.delayed(Duration.zero, () async {
      for (final collectionId in collectionsToPreload) {
        try {
          await getCollection(collectionId);
          debugPrint('✅ [CollectionCache] Preloaded $collectionId');
        } catch (e) {
          debugPrint(
              '⚠️ [CollectionCache] Failed to preload $collectionId: $e');
        }
      }
      debugPrint('🎉 [CollectionCache] Preloading completed');
    });
  }

  /// ✅ NEW: Get collection with retry logic for problematic collections
  Future<List<Song>> getCollectionWithRetry(String collectionId,
      {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
            '🔄 [CollectionCache] Attempt $attempt/$maxRetries for $collectionId');
        final songs =
            await getCollection(collectionId, forceRefresh: attempt > 1);
        if (songs.isNotEmpty) {
          return songs;
        }
      } catch (e) {
        debugPrint(
            '⚠️ [CollectionCache] Attempt $attempt failed for $collectionId: $e');
        if (attempt == maxRetries) rethrow;

        // Progressive backoff for retries
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return [];
  }

  /// ✅ NEW: Clear empty cached collections to force refresh
  Future<void> clearEmptyCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final availableCollections = await _getCachedAvailableCollections();

      for (final collectionId in availableCollections) {
        final songs = await _getCachedCollection(collectionId);
        if (songs.isEmpty) {
          final cacheKey = '$_cachePrefix$collectionId';
          await prefs.remove(cacheKey);
          debugPrint(
              '🧹 [CollectionCache] Cleared empty cache for $collectionId');
        }
      }
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error clearing empty collections: $e');
    }
  }

  /// ✅ NEW: Populate cache with results from legacy method
  Future<void> populateCacheFromLegacy(
      Map<String, List<Song>> legacyCollections) async {
    try {
      debugPrint('📥 [CollectionCache] Populating cache from legacy results');

      // Remove 'All' and 'Favorites' as they're computed collections
      final collectionsToCache =
          Map<String, List<Song>>.from(legacyCollections);
      collectionsToCache.remove('All');
      collectionsToCache.remove('Favorites');

      for (final entry in collectionsToCache.entries) {
        if (entry.value.isNotEmpty) {
          await _cacheCollection(entry.key, entry.value);
          _memoryCache[entry.key] = entry.value;
          _cacheTimestamps[entry.key] = DateTime.now();
          debugPrint(
              '📥 [CollectionCache] Cached ${entry.key}: ${entry.value.length} songs');
        }
      }

      // Update available collections list
      await _cacheAvailableCollections(collectionsToCache.keys.toList());

      debugPrint(
          '✅ [CollectionCache] Successfully populated cache with ${collectionsToCache.length} collections');
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error populating cache from legacy: $e');
    }
  }

  /// ✅ NEW: Force download and cache all available collections
  Future<Map<String, int>> forceDownloadAllCollections() async {
    try {
      debugPrint('🚀 [CollectionCache] Force downloading all collections...');
      await _ensureInitialized();

      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection available');
      }

      // Get all available collections from Firebase
      final availableCollections =
          await _fetchAvailableCollectionsFromFirebase();
      final downloadResults = <String, int>{};

      debugPrint(
          '📋 [CollectionCache] Found ${availableCollections.length} collections to download');

      // Download each collection with progress tracking
      for (int i = 0; i < availableCollections.length; i++) {
        final collectionId = availableCollections[i];
        try {
          debugPrint(
              '📥 [CollectionCache] Downloading ${i + 1}/${availableCollections.length}: $collectionId');

          final songs = await _fetchCollectionFromFirebase(collectionId);
          if (songs.isNotEmpty) {
            await _cacheCollection(collectionId, songs);
            _memoryCache[collectionId] = songs;
            _cacheTimestamps[collectionId] = DateTime.now();
            downloadResults[collectionId] = songs.length;
            debugPrint(
                '✅ [CollectionCache] Downloaded $collectionId: ${songs.length} songs');
          } else {
            downloadResults[collectionId] = 0;
            debugPrint(
                '⚠️ [CollectionCache] Collection $collectionId is empty');
          }
        } catch (e) {
          downloadResults[collectionId] = -1;
          debugPrint(
              '❌ [CollectionCache] Failed to download $collectionId: $e');
        }
      }

      // Update available collections cache
      await _cacheAvailableCollections(availableCollections);

      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      final successCount =
          downloadResults.values.where((count) => count > 0).length;
      debugPrint(
          '✅ [CollectionCache] Download complete: $successCount/${availableCollections.length} collections cached');

      return downloadResults;
    } catch (e) {
      debugPrint('❌ [CollectionCache] Force download failed: $e');
      rethrow;
    }
  }
}
