// lib/src/features/songbook/services/collection_migration_service.dart
// 🔄 COLLECTION MIGRATION SERVICE
// Handles smooth transition from old system to new caching system
// Ensures existing data is preserved and migrated properly

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/features/songbook/services/smart_collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/persistent_collections_config.dart';

class CollectionMigrationService {
  static const String _migrationVersionKey = 'collection_migration_version';
  static const int currentMigrationVersion = 1;

  /// 🚀 Run migration if needed
  static Future<bool> runMigrationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;

      if (currentVersion >= currentMigrationVersion) {
        debugPrint('✅ [Migration] Already up to date (v$currentVersion)');
        return true;
      }

      debugPrint(
          '🔄 [Migration] Starting migration from v$currentVersion to v$currentMigrationVersion');

      // Run migrations in sequence
      bool success = true;

      if (currentVersion < 1) {
        success &= await _migrateToV1();
      }

      if (success) {
        await prefs.setInt(_migrationVersionKey, currentMigrationVersion);
        debugPrint(
            '✅ [Migration] Successfully migrated to v$currentMigrationVersion');
      } else {
        debugPrint('❌ [Migration] Migration failed');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [Migration] Migration error: $e');
      return false;
    }
  }

  /// 🔄 Migration to V1: Initial cache setup and data preservation
  static Future<bool> _migrateToV1() async {
    debugPrint('🔄 [Migration] Running V1 migration...');

    try {
      // 1. Initialize the smart collection service
      final smartService = SmartCollectionService.instance;

      // 2. Check if user has any existing preferred collections
      await _migrateExistingPreferences();

      // 3. Ensure Christmas collections are detected and persisted
      await smartService.ensureChristmasCollectionPersistence();

      // 4. Initial cache warmup - fetch all collections to establish baseline
      debugPrint('🔄 [Migration] Warming up cache...');
      await smartService.getAllCollections(forceRefresh: true);

      // 5. Set up monitoring for future stability
      await _setupInitialMonitoring();

      debugPrint('✅ [Migration] V1 migration completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [Migration] V1 migration failed: $e');
      return false;
    }
  }

  /// 📋 Migrate any existing user preferences
  static Future<void> _migrateExistingPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for any old collection preferences
      // (This would be customized based on your existing preference keys)
      final oldFavorites = prefs.getStringList('favorite_collections');

      if (oldFavorites != null && oldFavorites.isNotEmpty) {
        debugPrint('📋 [Migration] Found existing favorites: $oldFavorites');

        // Add them to persistent collections
        for (final favorite in oldFavorites) {
          await PersistentCollectionsConfig.addPersistentCollection(favorite);
        }

        // Clean up old key
        await prefs.remove('favorite_collections');
        debugPrint('✅ [Migration] Migrated favorite collections');
      }

      // Migrate any other collection-related preferences here
      // For example, last selected collection, custom ordering, etc.
    } catch (e) {
      debugPrint('⚠️ [Migration] Error migrating preferences: $e');
    }
  }

  /// 📊 Set up initial monitoring
  static Future<void> _setupInitialMonitoring() async {
    try {
      final smartService = SmartCollectionService.instance;
      final stats = await smartService.getServiceStats();

      debugPrint('📊 [Migration] Initial system stats:');
      debugPrint('   - Cache status: ${stats['cache_stats']['last_sync']}');
      debugPrint(
          '   - Persistent collections: ${stats['persistent_collections']}');
      debugPrint(
          '   - Available collections: ${stats['available_collections_count']}');

      // Log any recommendations
      final recommendations = stats['recommendations'] as List<String>;
      if (recommendations.isNotEmpty) {
        debugPrint('💡 [Migration] System recommendations:');
        for (final rec in recommendations) {
          debugPrint('   - $rec');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Migration] Error setting up monitoring: $e');
    }
  }

  /// 🧹 Clean up old cache data (if any)
  static Future<void> cleanupOldCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove any old cache keys that might conflict
      final oldKeys = keys
          .where((key) =>
              key.startsWith('old_collection_cache_') ||
              key.startsWith('legacy_song_data_') ||
              key == 'outdated_collections_list')
          .toList();

      for (final key in oldKeys) {
        await prefs.remove(key);
        debugPrint('🧹 [Migration] Removed old cache key: $key');
      }

      if (oldKeys.isNotEmpty) {
        debugPrint(
            '✅ [Migration] Cleaned up ${oldKeys.length} old cache entries');
      }
    } catch (e) {
      debugPrint('⚠️ [Migration] Error cleaning up old data: $e');
    }
  }

  /// 📊 Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_migrationVersionKey) ?? 0;
      final isUpToDate = currentVersion >= currentMigrationVersion;

      return {
        'current_version': currentVersion,
        'target_version': currentMigrationVersion,
        'is_up_to_date': isUpToDate,
        'needs_migration': !isUpToDate,
        'last_migration': currentVersion > 0
            ? 'Completed V$currentVersion'
            : 'Never migrated',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'current_version': 0,
        'target_version': currentMigrationVersion,
        'is_up_to_date': false,
        'needs_migration': true,
      };
    }
  }

  /// 🔄 Force re-run migration (for testing or troubleshooting)
  static Future<bool> forceMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationVersionKey);

      debugPrint('🔄 [Migration] Forcing migration re-run...');
      return await runMigrationIfNeeded();
    } catch (e) {
      debugPrint('❌ [Migration] Error forcing migration: $e');
      return false;
    }
  }
}
