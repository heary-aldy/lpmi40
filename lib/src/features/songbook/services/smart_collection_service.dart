// lib/src/features/songbook/services/smart_collection_service.dart
// 🎯 SMART COLLECTION SERVICE
// High-level service that intelligently manages collections using the cache manager
// Provides a clean API for the UI while handling all caching logic internally

import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';
import 'package:lpmi40/src/features/songbook/services/persistent_collections_config.dart';

class SmartCollectionService {
  static SmartCollectionService? _instance;
  static SmartCollectionService get instance =>
      _instance ??= SmartCollectionService._();

  SmartCollectionService._();

  final CollectionCacheManager _cacheManager = CollectionCacheManager.instance;

  /// 🚀 MAIN API: Get all collections with smart prioritization
  /// This is the primary method that UI components should use
  Future<Map<String, List<Song>>> getAllCollections({
    bool forceRefresh = false,
    bool prioritizePersistent = true,
  }) async {
    debugPrint('🎯 [SmartCollectionService] Getting all collections...');

    // Get collections from cache manager
    final allCollections = await _cacheManager.getAllCollections(
      forceRefresh: forceRefresh,
    );

    if (!prioritizePersistent) {
      return allCollections;
    }

    // Get persistent collections and prioritize them
    final persistentIds =
        await PersistentCollectionsConfig.getPersistentCollections();
    final prioritized = <String, List<Song>>{};

    // Add persistent collections first (in order)
    for (final persistentId in persistentIds) {
      if (allCollections.containsKey(persistentId)) {
        prioritized[persistentId] = allCollections[persistentId]!;
        debugPrint(
            '📌 [SmartCollectionService] Prioritized persistent: $persistentId');
      }
    }

    // Add remaining collections
    for (final entry in allCollections.entries) {
      if (!prioritized.containsKey(entry.key)) {
        prioritized[entry.key] = entry.value;
      }
    }

    // Auto-detect and save Christmas collections
    await _autoDetectChristmasCollections(allCollections);

    debugPrint(
        '✅ [SmartCollectionService] Returned ${prioritized.length} collections');
    return prioritized;
  }

  /// 📊 Get a specific collection
  Future<List<Song>> getCollection(
    String collectionId, {
    bool forceRefresh = false,
  }) async {
    debugPrint('🎯 [SmartCollectionService] Getting collection: $collectionId');

    final songs = await _cacheManager.getCollection(
      collectionId,
      forceRefresh: forceRefresh,
    );

    // If this is a Christmas collection, ensure it's persistent
    if (_isChristmasCollection(collectionId) && songs.isNotEmpty) {
      await PersistentCollectionsConfig.addPersistentCollection(collectionId);
    }

    return songs;
  }

  /// 🔍 Get available collection IDs
  Future<List<String>> getAvailableCollections(
      {bool forceRefresh = false}) async {
    return await _cacheManager.getAvailableCollections(
        forceRefresh: forceRefresh);
  }

  /// 🎄 Smart Christmas collection detection and persistence
  Future<void> ensureChristmasCollectionPersistence() async {
    debugPrint(
        '🎄 [SmartCollectionService] Ensuring Christmas collection persistence...');

    final availableCollections = await getAvailableCollections();
    await _autoDetectChristmasCollections(
        {for (String collection in availableCollections) collection: <Song>[]});
  }

  /// 🔄 Force refresh all collections
  Future<Map<String, List<Song>>> forceRefreshAllCollections() async {
    debugPrint(
        '🔄 [SmartCollectionService] Force refreshing all collections...');
    return await getAllCollections(forceRefresh: true);
  }

  /// 🧹 Clear cache and start fresh
  Future<void> clearCacheAndRefresh() async {
    debugPrint('🧹 [SmartCollectionService] Clearing cache and refreshing...');
    await _cacheManager.clearCache();
    await getAllCollections(forceRefresh: true);
  }

  /// 📊 Get service statistics
  Future<Map<String, dynamic>> getServiceStats() async {
    final cacheStats = await _cacheManager.getCacheStats();
    final persistentCollections =
        await PersistentCollectionsConfig.getPersistentCollections();
    final availableCollections = await getAvailableCollections();

    return {
      'cache_stats': cacheStats,
      'persistent_collections': persistentCollections,
      'available_collections_count': availableCollections.length,
      'service_status': 'healthy',
      'recommendations':
          _generateRecommendations(cacheStats, persistentCollections),
    };
  }

  /// 🎵 Search songs across all collections
  Future<List<Song>> searchSongs(
    String query, {
    List<String>? specificCollections,
    bool includeTitle = true,
    bool includeLyrics = true,
    bool includeArtist = true,
  }) async {
    debugPrint('🔍 [SmartCollectionService] Searching for: "$query"');

    final collections = specificCollections != null
        ? await Future.wait(specificCollections.map((id) => getCollection(id)))
        : (await getAllCollections()).values.toList();

    final allSongs = collections.expand((songs) => songs).toList();
    final results = <Song>[];
    final queryLower = query.toLowerCase();

    for (final song in allSongs) {
      bool matches = false;

      if (includeTitle && song.title.toLowerCase().contains(queryLower)) {
        matches = true;
      }

      // Note: Song model doesn't have artist field, skipping artist search
      // if (!matches &&
      //     includeArtist &&
      //     (song.artist?.toLowerCase().contains(queryLower) ?? false)) {
      //   matches = true;
      // }

      if (!matches && includeLyrics) {
        for (final verse in song.verses) {
          if (verse.lyrics.toLowerCase().contains(queryLower)) {
            matches = true;
            break;
          }
        }
      }

      if (matches) {
        results.add(song);
      }
    }

    debugPrint(
        '🔍 [SmartCollectionService] Found ${results.length} songs matching "$query"');
    return results;
  }

  /// 🏷️ Add collection to persistent list
  Future<void> markCollectionAsPersistent(String collectionId) async {
    await PersistentCollectionsConfig.addPersistentCollection(collectionId);
    debugPrint(
        '📌 [SmartCollectionService] Marked $collectionId as persistent');
  }

  /// 🗑️ Remove collection from persistent list
  Future<void> unmarkCollectionAsPersistent(String collectionId) async {
    await PersistentCollectionsConfig.removePersistentCollection(collectionId);
    debugPrint(
        '📌 [SmartCollectionService] Unmarked $collectionId as persistent');
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<void> _autoDetectChristmasCollections(
      Map<String, List<Song>> collections) async {
    for (final collectionId in collections.keys) {
      if (_isChristmasCollection(collectionId)) {
        await PersistentCollectionsConfig.addPersistentCollection(collectionId);
        debugPrint(
            '🎄 [SmartCollectionService] Auto-detected Christmas collection: $collectionId');
      }
    }
  }

  bool _isChristmasCollection(String collectionId) {
    final id = collectionId.toLowerCase();
    return id.contains('christmas') ||
        id.contains('krismas') ||
        id.contains('xmas') ||
        id == 'lagu_krismas_26346';
  }

  List<String> _generateRecommendations(
    Map<String, dynamic> cacheStats,
    List<String> persistentCollections,
  ) {
    final recommendations = <String>[];

    final cachedCollections = cacheStats['cached_collections'] as int;
    final availableCollections = cacheStats['available_collections'] as int;

    if (cachedCollections < availableCollections * 0.8) {
      recommendations.add(
          'Consider refreshing cache to ensure all collections are available offline');
    }

    if (persistentCollections.length < 3) {
      recommendations.add(
          'Consider marking more collections as persistent for better user experience');
    }

    final lastSync = cacheStats['last_sync'] as String;
    if (lastSync == 'Never') {
      recommendations.add(
          'Initial sync needed - collections will be cached after first load');
    }

    return recommendations;
  }
}
