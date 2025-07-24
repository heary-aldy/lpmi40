// lib/src/features/songbook/services/collection_integration_helper.dart
// 🔄 COLLECTION INTEGRATION HELPER
// Helper class to gradually integrate the new caching system with existing code
// Provides drop-in replacements for common collection operations

import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/services/smart_collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_migration_service.dart';

class CollectionIntegrationHelper {
  static CollectionIntegrationHelper? _instance;
  static CollectionIntegrationHelper get instance =>
      _instance ??= CollectionIntegrationHelper._();

  CollectionIntegrationHelper._();

  final SmartCollectionService _smartService = SmartCollectionService.instance;
  bool _isInitialized = false;

  /// 🚀 Initialize the helper (call this in your app startup)
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔄 [IntegrationHelper] Initializing...');

    // Run migration if needed
    await CollectionMigrationService.runMigrationIfNeeded();

    // Ensure Christmas collection persistence
    await _smartService.ensureChristmasCollectionPersistence();

    _isInitialized = true;
    debugPrint('✅ [IntegrationHelper] Ready');
  }

  // ============================================================================
  // DROP-IN REPLACEMENTS FOR EXISTING METHODS
  // Use these to replace existing collection loading calls
  // ============================================================================

  /// 📚 NEW: Get all collections (replaces multiple individual collection calls)
  Future<Map<String, List<Song>>> getAllCollectionsStable() async {
    await initialize();

    return await _smartService.getAllCollections(
      prioritizePersistent:
          true, // Ensures Christmas and other important collections are first
    );
  }

  /// 🎄 IMPROVED: Get Christmas collection with auto-detection and persistence
  /// Use this instead of your current Christmas collection loading
  Future<List<Song>> getChristmasCollectionStable() async {
    await initialize();

    // Get all collections
    final allCollections = await _smartService.getAllCollections();

    // Find Christmas collection automatically
    for (final entry in allCollections.entries) {
      final collectionId = entry.key.toLowerCase();
      if (collectionId.contains('christmas') ||
          collectionId.contains('krismas') ||
          collectionId == 'lagu_krismas_26346') {
        final songs = entry.value;
        if (songs.isNotEmpty) {
          // Mark as persistent to prevent "coming and going"
          await _smartService.markCollectionAsPersistent(entry.key);

          debugPrint(
              '🎄 [IntegrationHelper] Found stable Christmas collection: ${entry.key} (${songs.length} songs)');
          return songs;
        }
      }
    }

    debugPrint('🎄 [IntegrationHelper] No Christmas collection available');
    return [];
  }

  /// 📖 STABLE: Get any specific collection with caching
  Future<List<Song>> getCollectionStable(String collectionId) async {
    await initialize();

    return await _smartService.getCollection(collectionId);
  }

  /// 🔍 ENHANCED: Search with better performance
  Future<List<Song>> searchSongsStable(String query) async {
    await initialize();

    return await _smartService.searchSongs(query);
  }

  /// 📋 Get list of available collections
  Future<List<String>> getAvailableCollectionsStable() async {
    await initialize();

    return await _smartService.getAvailableCollections();
  }

  // ============================================================================
  // COMPATIBILITY WRAPPERS
  // These match your existing method signatures
  // ============================================================================

  /// 🔄 Wrapper for LPMI collection
  Future<List<Song>> getLPMIStable() async {
    return await getCollectionStable('LPMI');
  }

  /// 🔄 Wrapper for SRD collection
  Future<List<Song>> getSRDStable() async {
    return await getCollectionStable('SRD');
  }

  /// 🔄 Wrapper for Lagu Belia collection
  Future<List<Song>> getLaguBeliaStable() async {
    return await getCollectionStable('Lagu_belia');
  }

  // ============================================================================
  // MAINTENANCE & DIAGNOSTICS
  // ============================================================================

  /// 🔧 Fix collection issues (call this if users report problems)
  Future<Map<String, dynamic>> fixCollectionIssues() async {
    await initialize();

    debugPrint('🔧 [IntegrationHelper] Running collection fixes...');

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'actions_taken': <String>[],
      'collections_fixed': <String>[],
      'success': false,
    };

    try {
      // 1. Ensure Christmas collection persistence
      await _smartService.ensureChristmasCollectionPersistence();
      results['actions_taken']
          .add('✅ Christmas collection persistence ensured');

      // 2. Force refresh all collections
      final collections = await _smartService.forceRefreshAllCollections();
      results['actions_taken']
          .add('✅ All collections refreshed (${collections.length} found)');

      // 3. Mark important collections as persistent
      final importantCollections = ['LPMI', 'SRD', 'Lagu_belia'];
      for (final collection in importantCollections) {
        if (collections.containsKey(collection)) {
          await _smartService.markCollectionAsPersistent(collection);
          results['collections_fixed'].add(collection);
        }
      }

      // 4. Find and fix Christmas collections
      for (final collectionId in collections.keys) {
        final id = collectionId.toLowerCase();
        if (id.contains('christmas') || id.contains('krismas')) {
          await _smartService.markCollectionAsPersistent(collectionId);
          results['collections_fixed'].add(collectionId);
          results['actions_taken']
              .add('🎄 Fixed Christmas collection: $collectionId');
        }
      }

      results['success'] = true;
      results['actions_taken'].add('✅ Collection fixes completed successfully');

      debugPrint('✅ [IntegrationHelper] Collection fixes completed');
      return results;
    } catch (e) {
      results['actions_taken'].add('❌ Error during fixes: $e');
      debugPrint('❌ [IntegrationHelper] Fix failed: $e');
      return results;
    }
  }

  /// 📊 Get system health report
  Future<Map<String, dynamic>> getSystemHealthReport() async {
    await initialize();

    return await _smartService.getServiceStats();
  }

  /// 🧹 Emergency reset (clears cache and refreshes everything)
  Future<void> emergencyReset() async {
    await initialize();

    debugPrint('🧹 [IntegrationHelper] Running emergency reset...');
    await _smartService.clearCacheAndRefresh();
    debugPrint('✅ [IntegrationHelper] Emergency reset completed');
  }

  // ============================================================================
  // USAGE EXAMPLES (FOR DOCUMENTATION)
  // ============================================================================

  /// 📝 Example of how to replace existing collection loading
  Future<void> _usageExamples() async {
    // OLD WAY (problematic):
    // final christmasCollection = await someRepository.getChristmasCollection();

    // NEW WAY (stable):
    final christmasCollection = await getChristmasCollectionStable();

    // OLD WAY (multiple calls):
    // final lpmi = await repo.getLPMI();
    // final srd = await repo.getSRD();
    // final christmas = await repo.getChristmas();

    // NEW WAY (single call, all collections):
    final allCollections = await getAllCollectionsStable();
    final lpmi = allCollections['LPMI'] ?? [];
    final srd = allCollections['SRD'] ?? [];
    final christmas = await getChristmasCollectionStable();

    // SEARCH (enhanced):
    final searchResults = await searchSongsStable('Yesus');

    // TROUBLESHOOTING:
    if (christmasCollection.isEmpty) {
      debugPrint('🔧 Christmas collection empty, running fixes...');
      await fixCollectionIssues();
    }
  }
}
