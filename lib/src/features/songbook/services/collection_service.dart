// lib/src/features/songbook/services/collection_service.dart
// Collection Service - Business logic layer for song collections
// Provides high-level operations and coordinates between repositories

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/collection_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/enhanced_song_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

// Service result classes
class CollectionServiceResult {
  final bool success;
  final String? errorMessage;
  final String? data;

  CollectionServiceResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory CollectionServiceResult.success([String? data]) {
    return CollectionServiceResult(success: true, data: data);
  }

  factory CollectionServiceResult.failure(String errorMessage) {
    return CollectionServiceResult(success: false, errorMessage: errorMessage);
  }
}

class UserCollectionContext {
  final String? userRole;
  final bool isAuthenticated;
  final bool canCreateCollections;
  final bool canManageAllCollections;
  final List<CollectionAccessLevel> accessibleLevels;

  UserCollectionContext({
    required this.userRole,
    required this.isAuthenticated,
    required this.canCreateCollections,
    required this.canManageAllCollections,
    required this.accessibleLevels,
  });
}

class CollectionMigrationResult {
  final bool success;
  final int songsProcessed;
  final int songsSuccessful;
  final int songsSkipped;
  final List<String> errors;
  final String? errorMessage;

  CollectionMigrationResult({
    required this.success,
    required this.songsProcessed,
    required this.songsSuccessful,
    required this.songsSkipped,
    required this.errors,
    this.errorMessage,
  });

  int get songsFailed => songsProcessed - songsSuccessful - songsSkipped;
  double get successRate =>
      songsProcessed > 0 ? songsSuccessful / songsProcessed : 0.0;
}

class CollectionAnalytics {
  final int totalCollections;
  final int activeCollections;
  final int totalSongs;
  final int legacySongs;
  final int collectionSongs;
  final Map<CollectionAccessLevel, int> accessLevelDistribution;
  final Map<String, int> collectionSongCounts;
  final DateTime lastUpdated;

  CollectionAnalytics({
    required this.totalCollections,
    required this.activeCollections,
    required this.totalSongs,
    required this.legacySongs,
    required this.collectionSongs,
    required this.accessLevelDistribution,
    required this.collectionSongCounts,
    required this.lastUpdated,
  });

  double get collectionCoverage =>
      totalSongs > 0 ? collectionSongs / totalSongs : 0.0;
  bool get isHybridMode => legacySongs > 0 && collectionSongs > 0;
}

class CollectionService {
  // Repository dependencies
  final CollectionRepository _collectionRepo = CollectionRepository();
  final EnhancedSongRepository _songRepo = EnhancedSongRepository();
  final AuthorizationService _authService = AuthorizationService();

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // Operation logging
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint(
          '[CollectionService] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[CollectionService] 📊 Details: $details');
      }
    }
  }

  // ============================================================================
  // USER CONTEXT & PERMISSIONS
  // ============================================================================

  /// Get user's collection context and permissions
  Future<UserCollectionContext> getUserCollectionContext() async {
    _logOperation('getUserCollectionContext');

    try {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthenticated = user != null;

      String? userRole;
      bool canCreateCollections = false;
      bool canManageAllCollections = false;

      if (isAuthenticated) {
        final authResult = await _authService.checkAdminStatus();
        final isAdmin = authResult['isAdmin'] ?? false;
        final isSuperAdmin = authResult['isSuperAdmin'] ?? false;

        if (isSuperAdmin) {
          userRole = 'superadmin';
          canCreateCollections = true;
          canManageAllCollections = true;
        } else if (isAdmin) {
          userRole = 'admin';
          canCreateCollections = true;
          canManageAllCollections = true;
        } else {
          // Check if user has premium role (implement based on your premium system)
          userRole = 'user'; // Default to regular user
          canCreateCollections = false;
          canManageAllCollections = false;
        }
      }

      final accessibleLevels = _getAccessibleLevels(userRole);

      return UserCollectionContext(
        userRole: userRole,
        isAuthenticated: isAuthenticated,
        canCreateCollections: canCreateCollections,
        canManageAllCollections: canManageAllCollections,
        accessibleLevels: accessibleLevels,
      );
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to get user context: $e');
      return UserCollectionContext(
        userRole: null,
        isAuthenticated: false,
        canCreateCollections: false,
        canManageAllCollections: false,
        accessibleLevels: [CollectionAccessLevel.public],
      );
    }
  }

  /// Get accessible levels for user role
  List<CollectionAccessLevel> _getAccessibleLevels(String? userRole) {
    if (userRole == null) {
      return [CollectionAccessLevel.public];
    }

    switch (userRole.toLowerCase()) {
      case 'superadmin':
        return CollectionAccessLevel.values;
      case 'admin':
        return [
          CollectionAccessLevel.public,
          CollectionAccessLevel.registered,
          CollectionAccessLevel.premium,
          CollectionAccessLevel.admin,
        ];
      case 'premium':
        return [
          CollectionAccessLevel.public,
          CollectionAccessLevel.registered,
          CollectionAccessLevel.premium,
        ];
      case 'user':
        return [
          CollectionAccessLevel.public,
          CollectionAccessLevel.registered,
        ];
      default:
        return [CollectionAccessLevel.public];
    }
  }

  // ============================================================================
  // COLLECTION MANAGEMENT
  // ============================================================================

  /// Create new collection with validation
  Future<CollectionServiceResult> createCollection({
    required String name,
    required String description,
    required CollectionAccessLevel accessLevel,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('createCollection', {
      'name': name,
      'accessLevel': accessLevel.value,
    });

    try {
      // Check user permissions
      final userContext = await getUserCollectionContext();
      if (!userContext.canCreateCollections) {
        return CollectionServiceResult.failure(
            'Insufficient permissions to create collections');
      }

      // Validate input
      if (name.trim().isEmpty) {
        return CollectionServiceResult.failure(
            'Collection name cannot be empty');
      }

      if (name.length > 100) {
        return CollectionServiceResult.failure(
            'Collection name is too long (max 100 characters)');
      }

      if (description.length > 500) {
        return CollectionServiceResult.failure(
            'Collection description is too long (max 500 characters)');
      }

      // Check if user can create collection with this access level
      if (!userContext.accessibleLevels.contains(accessLevel)) {
        return CollectionServiceResult.failure(
            'Cannot create collection with this access level');
      }

      // Generate unique ID
      final collectionId = _generateCollectionId(name);

      // Check if collection with this ID already exists
      final existingCollection =
          await _collectionRepo.getCollectionById(collectionId);
      if (existingCollection != null) {
        return CollectionServiceResult.failure(
            'Collection with similar name already exists');
      }

      // Create collection
      final collection = SongCollection(
        id: collectionId,
        name: name.trim(),
        description: description.trim(),
        accessLevel: accessLevel,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        metadata: metadata,
      );

      final result = await _collectionRepo.createCollection(collection);

      if (result.success) {
        return CollectionServiceResult.success(collectionId);
      } else {
        return CollectionServiceResult.failure(
            result.errorMessage ?? 'Failed to create collection');
      }
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to create collection: $e');
      return CollectionServiceResult.failure(
          'Unexpected error: ${e.toString()}');
    }
  }

  /// Update existing collection
  Future<CollectionServiceResult> updateCollection(
      SongCollection collection) async {
    _logOperation('updateCollection', {'collectionId': collection.id});

    try {
      final userContext = await getUserCollectionContext();

      // Check permissions
      if (!userContext.canManageAllCollections) {
        // Check if user is the creator
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (collection.createdBy != currentUserId) {
          return CollectionServiceResult.failure(
              'Cannot update collection created by another user');
        }
      }

      final result = await _collectionRepo.updateCollection(collection);

      if (result.success) {
        return CollectionServiceResult.success();
      } else {
        return CollectionServiceResult.failure(
            result.errorMessage ?? 'Failed to update collection');
      }
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to update collection: $e');
      return CollectionServiceResult.failure(
          'Unexpected error: ${e.toString()}');
    }
  }

  /// Delete collection with validation
  Future<CollectionServiceResult> deleteCollection(String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});

    try {
      final userContext = await getUserCollectionContext();

      if (!userContext.canManageAllCollections) {
        return CollectionServiceResult.failure(
            'Insufficient permissions to delete collections');
      }

      // Get collection to verify it exists
      final collection = await _collectionRepo.getCollectionById(collectionId,
          userRole: userContext.userRole);
      if (collection == null) {
        return CollectionServiceResult.failure('Collection not found');
      }

      // Get collection songs to see if it has content
      final songsResult = await _collectionRepo.getCollectionSongs(collectionId,
          userRole: userContext.userRole);
      if (songsResult.songs.isNotEmpty) {
        debugPrint(
            '[CollectionService] ⚠️ Deleting collection with ${songsResult.songs.length} songs');
      }

      final result = await _collectionRepo.deleteCollection(collectionId);

      if (result.success) {
        return CollectionServiceResult.success();
      } else {
        return CollectionServiceResult.failure(
            result.errorMessage ?? 'Failed to delete collection');
      }
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to delete collection: $e');
      return CollectionServiceResult.failure(
          'Unexpected error: ${e.toString()}');
    }
  }

  // ============================================================================
  // SONG COLLECTION MANAGEMENT
  // ============================================================================

  /// Add song to collection with validation
  Future<CollectionServiceResult> addSongToCollection({
    required String collectionId,
    required Song song,
    int? position,
  }) async {
    _logOperation('addSongToCollection', {
      'collectionId': collectionId,
      'songNumber': song.number,
      'position': position,
    });

    try {
      final userContext = await getUserCollectionContext();

      // Check permissions
      if (!userContext.canManageAllCollections) {
        return CollectionServiceResult.failure(
            'Insufficient permissions to modify collections');
      }

      // Verify collection exists and is accessible
      final collection = await _collectionRepo.getCollectionById(collectionId,
          userRole: userContext.userRole);
      if (collection == null) {
        return CollectionServiceResult.failure(
            'Collection not found or not accessible');
      }

      // Check if song already exists in this collection
      final existingSongs = await _collectionRepo
          .getCollectionSongs(collectionId, userRole: userContext.userRole);
      final songExists =
          existingSongs.songs.any((s) => s.number == song.number);

      if (songExists) {
        return CollectionServiceResult.failure(
            'Song already exists in this collection');
      }

      // Add song to collection
      final result = await _collectionRepo
          .addSongToCollection(collectionId, song, index: position);

      if (result.success) {
        return CollectionServiceResult.success();
      } else {
        return CollectionServiceResult.failure(
            result.errorMessage ?? 'Failed to add song to collection');
      }
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to add song to collection: $e');
      return CollectionServiceResult.failure(
          'Unexpected error: ${e.toString()}');
    }
  }

  /// Remove song from collection
  Future<CollectionServiceResult> removeSongFromCollection({
    required String collectionId,
    required String songNumber,
  }) async {
    _logOperation('removeSongFromCollection', {
      'collectionId': collectionId,
      'songNumber': songNumber,
    });

    try {
      final userContext = await getUserCollectionContext();

      if (!userContext.canManageAllCollections) {
        return CollectionServiceResult.failure(
            'Insufficient permissions to modify collections');
      }

      final result = await _collectionRepo.removeSongFromCollection(
          collectionId, songNumber);

      if (result.success) {
        return CollectionServiceResult.success();
      } else {
        return CollectionServiceResult.failure(
            result.errorMessage ?? 'Failed to remove song from collection');
      }
    } catch (e) {
      debugPrint(
          '[CollectionService] ❌ Failed to remove song from collection: $e');
      return CollectionServiceResult.failure(
          'Unexpected error: ${e.toString()}');
    }
  }

  // ============================================================================
  // MIGRATION & BULK OPERATIONS
  // ============================================================================

  /// Migrate songs from legacy to collection
  Future<CollectionMigrationResult> migrateSongsToCollection({
    required String collectionId,
    required List<String> songNumbers,
    bool removeFromLegacy = false,
  }) async {
    _logOperation('migrateSongsToCollection', {
      'collectionId': collectionId,
      'songCount': songNumbers.length,
      'removeFromLegacy': removeFromLegacy,
    });

    int processed = 0;
    int successful = 0;
    int skipped = 0;
    final List<String> errors = [];

    try {
      final userContext = await getUserCollectionContext();

      if (!userContext.canManageAllCollections) {
        return CollectionMigrationResult(
          success: false,
          songsProcessed: 0,
          songsSuccessful: 0,
          songsSkipped: 0,
          errors: [],
          errorMessage: 'Insufficient permissions for migration',
        );
      }

      debugPrint(
          '[CollectionService] 🔄 Starting migration of ${songNumbers.length} songs to collection $collectionId');

      for (final songNumber in songNumbers) {
        processed++;

        try {
          // Get song from legacy
          final songResult = await _songRepo.getSongByNumber(songNumber,
              userRole: userContext.userRole);

          if (songResult.song == null) {
            skipped++;
            errors.add('Song $songNumber not found');
            continue;
          }

          final song = songResult.song!;

          // Skip if already in a collection
          if (song.belongsToCollection()) {
            skipped++;
            errors.add(
                'Song $songNumber already in collection ${song.collectionId}');
            continue;
          }

          // Add to collection
          final addResult = await addSongToCollection(
            collectionId: collectionId,
            song: song,
          );

          if (addResult.success) {
            successful++;

            // Remove from legacy if requested
            if (removeFromLegacy) {
              try {
                await _songRepo.deleteSongFromLegacy(songNumber);
              } catch (e) {
                errors.add('Failed to remove $songNumber from legacy: $e');
              }
            }
          } else {
            errors.add('Failed to add $songNumber: ${addResult.errorMessage}');
          }
        } catch (e) {
          errors.add('Error processing $songNumber: $e');
        }
      }

      final success = successful > 0;
      debugPrint(
          '[CollectionService] ✅ Migration completed: $successful/$processed successful');

      return CollectionMigrationResult(
        success: success,
        songsProcessed: processed,
        songsSuccessful: successful,
        songsSkipped: skipped,
        errors: errors,
      );
    } catch (e) {
      debugPrint('[CollectionService] ❌ Migration failed: $e');
      return CollectionMigrationResult(
        success: false,
        songsProcessed: processed,
        songsSuccessful: successful,
        songsSkipped: skipped,
        errors: errors,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================================================
  // ANALYTICS & REPORTING
  // ============================================================================

  /// Get collection analytics
  Future<CollectionAnalytics> getCollectionAnalytics() async {
    _logOperation('getCollectionAnalytics');

    try {
      final userContext = await getUserCollectionContext();

      // Get all collections
      final collectionsResult = await _collectionRepo.getAllCollections(
          userRole: userContext.userRole);
      final collections = collectionsResult.collections;

      // Get all songs
      final songsResult =
          await _songRepo.getAllSongs(userRole: userContext.userRole);

      // Calculate access level distribution
      final accessLevelDistribution = <CollectionAccessLevel, int>{};
      for (final level in CollectionAccessLevel.values) {
        accessLevelDistribution[level] =
            collections.where((c) => c.accessLevel == level).length;
      }

      // Calculate collection song counts
      final collectionSongCounts = <String, int>{};
      for (final collection in collections) {
        collectionSongCounts[collection.id] = collection.songCount;
      }

      return CollectionAnalytics(
        totalCollections: collections.length,
        activeCollections: collections.where((c) => c.isActive).length,
        totalSongs: songsResult.totalSongs,
        legacySongs: songsResult.legacySongs,
        collectionSongs: songsResult.collectionSongs,
        accessLevelDistribution: accessLevelDistribution,
        collectionSongCounts: collectionSongCounts,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[CollectionService] ❌ Failed to get analytics: $e');
      return CollectionAnalytics(
        totalCollections: 0,
        activeCollections: 0,
        totalSongs: 0,
        legacySongs: 0,
        collectionSongs: 0,
        accessLevelDistribution: {},
        collectionSongCounts: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate unique collection ID from name
  String _generateCollectionId(String name) {
    final cleanName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cleanName}_$timestamp';
  }

  /// Get service performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'collectionRepoMetrics': _collectionRepo.getPerformanceMetrics(),
      'songRepoMetrics': _songRepo.getPerformanceMetrics(),
    };
  }

  /// Get service summary
  Map<String, dynamic> getServiceSummary() {
    return {
      'lastCheck': DateTime.now().toIso8601String(),
      'supportedOperations': [
        'createCollection',
        'updateCollection',
        'deleteCollection',
        'addSongToCollection',
        'removeSongFromCollection',
        'migrateSongsToCollection',
        'getCollectionAnalytics',
        'getUserCollectionContext',
      ],
      'dependencies': [
        'CollectionRepository',
        'EnhancedSongRepository',
        'AuthorizationService',
      ],
    };
  }
}
