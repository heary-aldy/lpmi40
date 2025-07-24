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

  // Cache validity duration (adjust as needed)
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const Duration forceRefreshInterval = Duration(days: 7);

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
      'cache_validity': cacheValidityDuration.inHours,
    };
  }

  // ============================================================================
  // PRIVATE IMPLEMENTATION
  // ============================================================================

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    // Load any existing cache metadata
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_cacheMetadataKey);

    if (metadata != null) {
      try {
        final data = jsonDecode(metadata) as Map<String, dynamic>;
        debugPrint('📋 [CollectionCache] Loaded cache metadata: ${data.keys}');
      } catch (e) {
        debugPrint('⚠️ [CollectionCache] Error loading metadata: $e');
      }
    }

    _isInitialized = true;
    debugPrint('✅ [CollectionCache] Initialized');
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
          '⏰ [CollectionCache] Cache expired (${timeSinceSync.inHours}h old)');
      return true;
    }

    return false;
  }

  Future<bool> _shouldBackgroundRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);

    if (lastSync == null) return false;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final timeSinceSync = DateTime.now().difference(lastSyncTime);

    return timeSinceSync >
        (cacheValidityDuration * 0.8); // Refresh at 80% of validity
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
    final collectionRef = database.ref('song_collection/$collectionId');

    try {
      final snapshot = await collectionRef.get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final songs = <Song>[];

      for (final entry in data.entries) {
        try {
          final songData = entry.value as Map<dynamic, dynamic>;
          final song = Song.fromJson(Map<String, dynamic>.from(songData));
          songs.add(song);
        } catch (e) {
          debugPrint('⚠️ [CollectionCache] Error parsing song: $e');
        }
      }

      songs.sort((a, b) => _compareSongNumbers(a.number, b.number));
      debugPrint(
          '📥 [CollectionCache] Fetched $collectionId (${songs.length} songs)');

      return songs;
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error fetching $collectionId: $e');
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
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'songs': songsJson,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ [CollectionCache] Error caching $collectionId: $e');
    }
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
        return [];
      }

      final songsJson = cacheData['songs'] as List<dynamic>;
      final songs = songsJson
          .map((json) => Song.fromJson(Map<String, dynamic>.from(json)))
          .toList();

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

  void _backgroundRefreshCollections() {
    // Run refresh in background without waiting
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        debugPrint('🔄 [CollectionCache] Background refresh started');
        await _refreshAllCollections();
        debugPrint('✅ [CollectionCache] Background refresh completed');
      } catch (e) {
        debugPrint('❌ [CollectionCache] Background refresh failed: $e');
      }
    });
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
}
