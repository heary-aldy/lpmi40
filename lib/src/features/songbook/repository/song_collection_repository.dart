// lib/src/features/songbook/repository/collection_repository.dart
// Collection repository with access control and Firebase integration for LPMI40
// Follows the same patterns as song_repository.dart for consistency

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

// Result wrapper classes following song_repository pattern
class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;

  CollectionDataResult({required this.collections, required this.isOnline});
}

class CollectionWithSongsResult {
  final SongCollection? collection;
  final List<Song> songs;
  final bool isOnline;

  CollectionWithSongsResult({
    required this.collection,
    required this.songs,
    required this.isOnline,
  });
}

class CollectionOperationResult {
  final bool success;
  final String? errorMessage;
  final String? collectionId;

  CollectionOperationResult({
    required this.success,
    this.errorMessage,
    this.collectionId,
  });
}

// Parsing functions for compute isolation
List<SongCollection> _parseCollectionsFromFirebaseMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];

    final List<SongCollection> collections = [];
    for (final entry in jsonMap.entries) {
      try {
        final collectionData = Map<String, dynamic>.from(entry.value as Map);
        final collection = SongCollection.fromJson(collectionData, entry.key);
        collections.add(collection);
      } catch (e) {
        debugPrint('❌ Error parsing collection ${entry.key}: $e');
        continue;
      }
    }
    return collections;
  } catch (e) {
    debugPrint('❌ Error parsing Firebase collections map: $e');
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

class CollectionRepository {
  // Firebase paths
  static const String _collectionsPath = 'song_collections';
  static const String _collectionSongsPath = 'collection_songs';

  // Firebase service for connectivity checking
  final FirebaseService _firebaseService = FirebaseService();

  // Performance tracking (following song_repository pattern)
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
      debugPrint('[CollectionRepository] Error getting database instance: $e');
      return null;
    }
  }

  // Operation logging helper (following song_repository pattern)
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint(
          '[CollectionRepository] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[CollectionRepository] 📊 Details: $details');
      }
    }
  }

  // Check real connectivity (following song_repository pattern)
  Future<bool> _checkRealConnectivity() async {
    try {
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      final snapshot = await connectedRef.get().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connectivity check timeout'),
          );
      return snapshot.value == true;
    } catch (e) {
      debugPrint('[CollectionRepository] Connectivity check failed: $e');
      return false;
    }
  }

  // ============================================================================
  // COLLECTION CRUD OPERATIONS
  // ============================================================================

  /// Get all collections with access control
  Future<CollectionDataResult> getAllCollections({String? userRole}) async {
    _logOperation('getAllCollections', {'userRole': userRole});

    if (!_isFirebaseInitialized) {
      debugPrint(
          '[CollectionRepository] Firebase not initialized, returning empty collections');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    final isOnline = await _checkRealConnectivity();
    if (!isOnline) {
      debugPrint(
          '[CollectionRepository] No connectivity, returning empty collections');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      debugPrint('[CollectionRepository] 🔄 Fetching all collections...');

      final ref = database.ref(_collectionsPath);
      final event = await ref.once().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Collections fetch timeout'),
          );

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        final collections =
            await compute(_parseCollectionsFromFirebaseMap, json.encode(data));

        // Apply access control filtering
        final filteredCollections =
            _filterCollectionsByAccess(collections, userRole);

        // Sort by creation date (newest first)
        filteredCollections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        debugPrint(
            '[CollectionRepository] ✅ Successfully loaded ${filteredCollections.length} collections (ONLINE)');
        return CollectionDataResult(
            collections: filteredCollections, isOnline: true);
      } else {
        debugPrint('[CollectionRepository] 📭 No collections found');
        return CollectionDataResult(collections: [], isOnline: true);
      }
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to fetch collections: $e');
      return CollectionDataResult(collections: [], isOnline: false);
    }
  }

  /// Get active collections only
  Future<CollectionDataResult> getActiveCollections({String? userRole}) async {
    final result = await getAllCollections(userRole: userRole);
    final activeCollections = result.collections
        .where((collection) => collection.status == CollectionStatus.active)
        .toList();

    return CollectionDataResult(
      collections: activeCollections,
      isOnline: result.isOnline,
    );
  }

  /// Get single collection by ID
  Future<SongCollection?> getCollectionById(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionById',
        {'collectionId': collectionId, 'userRole': userRole});

    if (!_isFirebaseInitialized) return null;

    try {
      final database = _database;
      if (database == null) return null;

      final ref = database.ref('$_collectionsPath/$collectionId');
      final snapshot = await ref.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Collection fetch timeout'),
          );

      if (snapshot.exists && snapshot.value != null) {
        final collectionData = Map<String, dynamic>.from(snapshot.value as Map);
        final collection =
            SongCollection.fromJson(collectionData, collectionId);

        // Check access control
        if (_canUserAccessCollection(collection, userRole)) {
          return collection;
        } else {
          debugPrint(
              '[CollectionRepository] ❌ User does not have access to collection $collectionId');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Failed to get collection $collectionId: $e');
      return null;
    }
  }

  /// Create new collection
  Future<CollectionOperationResult> createCollection(
      SongCollection collection) async {
    _logOperation('createCollection', {'collectionId': collection.id});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'User not authenticated',
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      // Create collection with current user as creator
      final collectionWithCreator = collection.copyWith(
        createdBy: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final ref = database.ref('$_collectionsPath/${collection.id}');
      await ref.set(collectionWithCreator.toJson());

      debugPrint(
          '[CollectionRepository] ✅ Collection created successfully: ${collection.id}');
      return CollectionOperationResult(
        success: true,
        collectionId: collection.id,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to create collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update existing collection
  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    _logOperation('updateCollection', {'collectionId': collection.id});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      final user = FirebaseAuth.instance.currentUser;
      final updatedCollection = collection.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: () => user!.uid,
      );

      final ref = database.ref('$_collectionsPath/${collection.id}');
      await ref.update(updatedCollection.toJson());

      debugPrint(
          '[CollectionRepository] ✅ Collection updated successfully: ${collection.id}');
      return CollectionOperationResult(
        success: true,
        collectionId: collection.id,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to update collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Delete collection
  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      // Delete collection
      final collectionRef = database.ref('$_collectionsPath/$collectionId');
      await collectionRef.remove();

      // Also delete collection songs
      final songsRef = database.ref('$_collectionSongsPath/$collectionId');
      await songsRef.remove();

      debugPrint(
          '[CollectionRepository] ✅ Collection deleted successfully: $collectionId');
      return CollectionOperationResult(
        success: true,
        collectionId: collectionId,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to delete collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================================================
  // COLLECTION SONGS MANAGEMENT
  // ============================================================================

  /// Get songs from a specific collection
  Future<CollectionWithSongsResult> getCollectionSongs(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionSongs', {'collectionId': collectionId});

    // First get the collection info
    final collection =
        await getCollectionById(collectionId, userRole: userRole);

    if (collection == null) {
      return CollectionWithSongsResult(
        collection: null,
        songs: [],
        isOnline: false,
      );
    }

    if (!_isFirebaseInitialized) {
      return CollectionWithSongsResult(
        collection: collection,
        songs: [],
        isOnline: false,
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      final ref = database.ref('$_collectionSongsPath/$collectionId');
      final snapshot = await ref.get().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Collection songs fetch timeout'),
          );

      List<Song> songs = [];
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        songs = await compute(_parseSongsFromCollectionMap, json.encode(data));

        // Sort by collection index if available
        songs.sort((a, b) {
          final aIndex = a.collectionIndex ?? 999999;
          final bIndex = b.collectionIndex ?? 999999;
          return aIndex.compareTo(bIndex);
        });
      }

      debugPrint(
          '[CollectionRepository] ✅ Loaded ${songs.length} songs from collection $collectionId');
      return CollectionWithSongsResult(
        collection: collection,
        songs: songs,
        isOnline: true,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to get collection songs: $e');
      return CollectionWithSongsResult(
        collection: collection,
        songs: [],
        isOnline: false,
      );
    }
  }

  /// Add song to collection
  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song,
      {int? index}) async {
    _logOperation('addSongToCollection', {
      'collectionId': collectionId,
      'songNumber': song.number,
      'index': index,
    });

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      // Create collection-aware song
      final collectionSong = song.withCollectionContext(
        collectionId: collectionId,
        collectionIndex: index,
      );

      // Add song to collection
      final ref =
          database.ref('$_collectionSongsPath/$collectionId/${song.number}');
      await ref.set(collectionSong.toJson());

      // Update collection song count
      await _updateCollectionSongCount(collectionId);

      debugPrint(
          '[CollectionRepository] ✅ Song ${song.number} added to collection $collectionId');
      return CollectionOperationResult(success: true);
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Failed to add song to collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Remove song from collection
  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    _logOperation('removeSongFromCollection', {
      'collectionId': collectionId,
      'songNumber': songNumber,
    });

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    try {
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      final ref =
          database.ref('$_collectionSongsPath/$collectionId/$songNumber');
      await ref.remove();

      // Update collection song count
      await _updateCollectionSongCount(collectionId);

      debugPrint(
          '[CollectionRepository] ✅ Song $songNumber removed from collection $collectionId');
      return CollectionOperationResult(success: true);
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Failed to remove song from collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================================================
  // ACCESS CONTROL METHODS
  // ============================================================================

  /// Filter collections based on user access level
  List<SongCollection> _filterCollectionsByAccess(
      List<SongCollection> collections, String? userRole) {
    if (userRole == null) {
      // Guest users only see public collections
      return collections
          .where((c) => c.accessLevel == CollectionAccessLevel.public)
          .toList();
    }

    final role = userRole.toLowerCase();
    return collections.where((collection) {
      switch (role) {
        case 'superadmin':
          return true; // SuperAdmin sees everything
        case 'admin':
          return collection.accessLevel.index <=
              CollectionAccessLevel.admin.index;
        case 'premium':
          return collection.accessLevel.index <=
              CollectionAccessLevel.premium.index;
        case 'user':
          return collection.accessLevel.index <=
              CollectionAccessLevel.registered.index;
        default:
          return collection.accessLevel == CollectionAccessLevel.public;
      }
    }).toList();
  }

  /// Check if user can access specific collection
  bool _canUserAccessCollection(SongCollection collection, String? userRole) {
    final filtered = _filterCollectionsByAccess([collection], userRole);
    return filtered.isNotEmpty;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Update collection song count
  Future<void> _updateCollectionSongCount(String collectionId) async {
    try {
      final database = _database;
      if (database == null) return;

      final songsRef = database.ref('$_collectionSongsPath/$collectionId');
      final snapshot = await songsRef.get();

      int songCount = 0;
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        songCount = data.length;
      }

      final collectionRef = database.ref('$_collectionsPath/$collectionId');
      await collectionRef.update({
        'song_count': songCount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to update song count: $e');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'collectionsPath': _collectionsPath,
      'collectionSongsPath': _collectionSongsPath,
    };
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
      'supportedOperations': [
        'getAllCollections',
        'getActiveCollections',
        'getCollectionById',
        'createCollection',
        'updateCollection',
        'deleteCollection',
        'getCollectionSongs',
        'addSongToCollection',
        'removeSongFromCollection',
      ],
    };
  }
}
