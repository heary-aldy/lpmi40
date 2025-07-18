// lib/src/features/songbook/repository/song_collection_repository.dart
// ✅ COMPLETE: Collection Repository with Firebase integration
// ✅ FIXED: Proper error handling and result types
// ✅ OPTIMIZED: Uses same patterns as working SongRepository

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// ✅ RESULT CLASSES
class CollectionOperationResult {
  final bool success;
  final String? errorMessage;
  final SongCollection? collection;
  final String? operationId;

  CollectionOperationResult({
    required this.success,
    this.errorMessage,
    this.collection,
    this.operationId,
  });
}

class CollectionWithSongsResult {
  final SongCollection? collection;
  final List<Song> songs;
  final bool isOnline;
  final String? errorMessage;

  CollectionWithSongsResult({
    this.collection,
    required this.songs,
    required this.isOnline,
    this.errorMessage,
  });
}

class CollectionRepository {
  // ✅ FIREBASE CONFIGURATION (same as SongRepository)
  static const String _firebaseUrl =
      'https://lmpi-c5c5c-default-rtdb.firebaseio.com/';
  static const String _songCollectionPath = 'song_collection';

  // ✅ CONNECTION MANAGEMENT (same as SongRepository)
  static FirebaseDatabase? _dbInstance;
  static bool _dbInitialized = false;
  static DateTime? _lastConnectionCheck;
  static bool? _lastConnectionResult;

  // ✅ PERFORMANCE TRACKING
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ============================================================================
  // CORE INITIALIZATION (same as SongRepository)
  // ============================================================================

  bool get _isFirebaseInitialized {
    try {
      final app = Firebase.app();
      return app.options.databaseURL?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<FirebaseDatabase?> get _database async {
    if (_dbInstance != null && _dbInitialized) {
      return _dbInstance;
    }

    if (_isFirebaseInitialized) {
      try {
        final app = Firebase.app();
        _dbInstance = FirebaseDatabase.instanceFor(
          app: app,
          databaseURL: app.options.databaseURL!,
        );

        if (!_dbInitialized) {
          _dbInstance!.setPersistenceEnabled(true);
          _dbInstance!.setPersistenceCacheSizeBytes(10 * 1024 * 1024);

          if (kDebugMode) {
            _dbInstance!.setLoggingEnabled(false);
          }

          _dbInitialized = true;
          debugPrint(
              '[CollectionRepository] ✅ Database initialized and configured');
        }

        return _dbInstance;
      } catch (e) {
        debugPrint(
            '[CollectionRepository] ❌ Database initialization failed: $e');
        return null;
      }
    }

    return null;
  }

  Future<bool> _checkConnectivity() async {
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
      return isConnected;
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Connectivity check failed: $e');
      _lastConnectionResult = false;
      _lastConnectionCheck = DateTime.now();
      return false;
    }
  }

  // ============================================================================
  // COLLECTION CRUD OPERATIONS
  // ============================================================================

  /// Get all collections accessible to a user role
  Future<CollectionDataResult> getAllCollections(
      {required String userRole}) async {
    _logOperation('getAllCollections', {'userRole': userRole});

    if (!_isFirebaseInitialized) {
      debugPrint('[CollectionRepository] Firebase not initialized');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      debugPrint('[CollectionRepository] No connectivity');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      final collectionsRef = database.ref(_songCollectionPath);
      final snapshot =
          await collectionsRef.get().timeout(const Duration(seconds: 15));

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint(
            '[CollectionRepository] No collections found at $_songCollectionPath');
        return CollectionDataResult(collections: [], isOnline: true);
      }

      final collectionsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<SongCollection> collections = [];

      for (final entry in collectionsData.entries) {
        try {
          final collectionId = entry.key;
          final collectionData = Map<String, dynamic>.from(entry.value as Map);

          // Create collection from metadata
          final collection =
              SongCollection.fromJson(collectionData, collectionId);

          // Check access based on user role
          if (_canUserAccessCollection(collection, userRole)) {
            collections.add(collection);
          }
        } catch (e) {
          debugPrint(
              '[CollectionRepository] Error parsing collection ${entry.key}: $e');
          continue;
        }
      }

      // Sort by display order or name
      collections.sort((a, b) {
        final aOrder = a.metadata?['display_order'] as int? ?? 999;
        final bOrder = b.metadata?['display_order'] as int? ?? 999;

        if (aOrder == bOrder) {
          return a.name.compareTo(b.name);
        }
        return aOrder.compareTo(bOrder);
      });

      debugPrint(
          '[CollectionRepository] ✅ Loaded ${collections.length} collections');
      return CollectionDataResult(collections: collections, isOnline: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Error loading collections: $e');
      return CollectionDataResult(collections: [], isOnline: isOnline);
    }
  }

  /// Get a specific collection by ID
  Future<SongCollection?> getCollectionById(String collectionId,
      {required String userRole}) async {
    _logOperation('getCollectionById',
        {'collectionId': collectionId, 'userRole': userRole});

    if (!_isFirebaseInitialized) return null;

    final isOnline = await _checkConnectivity();
    if (!isOnline) return null;

    try {
      final database = await _database;
      if (database == null) return null;

      final collectionRef = database.ref('$_songCollectionPath/$collectionId');
      final snapshot =
          await collectionRef.get().timeout(const Duration(seconds: 10));

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('[CollectionRepository] Collection $collectionId not found');
        return null;
      }

      final collectionData = Map<String, dynamic>.from(snapshot.value as Map);
      final collection = SongCollection.fromJson(collectionData, collectionId);

      if (!_canUserAccessCollection(collection, userRole)) {
        debugPrint(
            '[CollectionRepository] User $userRole cannot access collection $collectionId');
        return null;
      }

      debugPrint('[CollectionRepository] ✅ Loaded collection $collectionId');
      return collection;
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Error loading collection $collectionId: $e');
      return null;
    }
  }

  /// Get songs from a specific collection
  Future<CollectionWithSongsResult> getCollectionSongs(String collectionId,
      {required String userRole}) async {
    _logOperation('getCollectionSongs',
        {'collectionId': collectionId, 'userRole': userRole});

    if (!_isFirebaseInitialized) {
      return CollectionWithSongsResult(songs: [], isOnline: false);
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionWithSongsResult(songs: [], isOnline: false);
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      // Get collection metadata
      final collection =
          await getCollectionById(collectionId, userRole: userRole);
      if (collection == null) {
        return CollectionWithSongsResult(
            songs: [],
            isOnline: true,
            errorMessage: 'Collection not found or access denied');
      }

      // Get songs from collection
      final songsRef = database.ref('$_songCollectionPath/$collectionId/songs');
      final songsSnapshot =
          await songsRef.get().timeout(const Duration(seconds: 10));

      final List<Song> songs = [];

      if (songsSnapshot.exists && songsSnapshot.value != null) {
        final songsData = songsSnapshot.value;

        if (songsData is Map) {
          final songsMap = Map<String, dynamic>.from(songsData);
          for (final entry in songsMap.entries) {
            try {
              final songData = Map<String, dynamic>.from(entry.value as Map);
              songData['song_number'] =
                  songData['song_number']?.toString() ?? entry.key;
              songData['collectionId'] = collectionId; // Add collection context

              final song = Song.fromJson(songData);
              songs.add(song);
            } catch (e) {
              debugPrint(
                  '[CollectionRepository] Error parsing song ${entry.key}: $e');
              continue;
            }
          }
        }
      }

      // Sort songs by number
      songs.sort((a, b) =>
          (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

      debugPrint(
          '[CollectionRepository] ✅ Loaded ${songs.length} songs from collection $collectionId');
      return CollectionWithSongsResult(
        collection: collection,
        songs: songs,
        isOnline: true,
      );
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Error loading songs from collection $collectionId: $e');
      return CollectionWithSongsResult(
        songs: [],
        isOnline: isOnline,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a new collection
  Future<CollectionOperationResult> createCollection(
      SongCollection collection) async {
    _logOperation('createCollection', {'name': collection.name});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      // Generate unique ID
      final collectionId = _generateCollectionId(collection.name);

      // Check if ID already exists
      final existingRef = database.ref('$_songCollectionPath/$collectionId');
      final existingSnapshot = await existingRef.get();

      if (existingSnapshot.exists) {
        return CollectionOperationResult(
          success: false,
          errorMessage: 'Collection with similar name already exists',
        );
      }

      // Create collection with metadata and empty songs
      final collectionData = {
        'metadata': {
          'name': collection.name,
          'description': collection.description,
          'access_level': collection.accessLevel.value,
          'status': collection.status.value,
          'song_count': 0,
          'created_at': collection.createdAt.toIso8601String(),
          'updated_at': collection.updatedAt.toIso8601String(),
          'created_by': collection.createdBy,
          'display_order': 999, // Default order
        },
        'songs': {}, // Empty songs object
      };

      await existingRef.set(collectionData);

      final createdCollection = collection.copyWith(id: collectionId);

      debugPrint('[CollectionRepository] ✅ Created collection $collectionId');
      return CollectionOperationResult(
        success: true,
        collection: createdCollection,
        operationId: collectionId,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Error creating collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update an existing collection
  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    _logOperation(
        'updateCollection', {'id': collection.id, 'name': collection.name});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      final collectionRef =
          database.ref('$_songCollectionPath/${collection.id}/metadata');

      // Check if collection exists
      final existingSnapshot = await collectionRef.get();
      if (!existingSnapshot.exists) {
        return CollectionOperationResult(
          success: false,
          errorMessage: 'Collection not found',
        );
      }

      // Update metadata
      final metadataUpdate = {
        'name': collection.name,
        'description': collection.description,
        'access_level': collection.accessLevel.value,
        'status': collection.status.value,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': collection.updatedBy,
      };

      await collectionRef.update(metadataUpdate);

      debugPrint(
          '[CollectionRepository] ✅ Updated collection ${collection.id}');
      return CollectionOperationResult(
        success: true,
        collection: collection,
        operationId: collection.id,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Error updating collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Delete a collection
  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      // Prevent deletion of core collections
      if (['LPMI', 'SRD', 'Lagu_belia'].contains(collectionId)) {
        return CollectionOperationResult(
          success: false,
          errorMessage: 'Cannot delete core collections',
        );
      }

      final collectionRef = database.ref('$_songCollectionPath/$collectionId');

      // Check if collection exists
      final existingSnapshot = await collectionRef.get();
      if (!existingSnapshot.exists) {
        return CollectionOperationResult(
          success: false,
          errorMessage: 'Collection not found',
        );
      }

      // Archive instead of delete (safer)
      await collectionRef.child('metadata/status').set('archived');
      await collectionRef
          .child('metadata/updated_at')
          .set(DateTime.now().toIso8601String());

      debugPrint('[CollectionRepository] ✅ Archived collection $collectionId');
      return CollectionOperationResult(
        success: true,
        operationId: collectionId,
      );
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Error deleting collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Add a song to a collection
  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song) async {
    _logOperation('addSongToCollection',
        {'collectionId': collectionId, 'songNumber': song.number});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      // Add song to collection
      final songRef = database
          .ref('$_songCollectionPath/$collectionId/songs/${song.number}');
      final songData = song.toJson();
      songData['collectionId'] = collectionId; // Add collection context

      await songRef.set(songData);

      // Update song count
      await _updateCollectionSongCount(database, collectionId);

      debugPrint(
          '[CollectionRepository] ✅ Added song ${song.number} to collection $collectionId');
      return CollectionOperationResult(
        success: true,
        operationId: '${collectionId}_${song.number}',
      );
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Error adding song to collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Remove a song from a collection
  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    _logOperation('removeSongFromCollection',
        {'collectionId': collectionId, 'songNumber': songNumber});

    if (!_isFirebaseInitialized) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'Firebase not initialized',
      );
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      return CollectionOperationResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    try {
      final database = await _database;
      if (database == null) throw Exception('Database not available');

      // Remove song from collection
      final songRef =
          database.ref('$_songCollectionPath/$collectionId/songs/$songNumber');
      await songRef.remove();

      // Update song count
      await _updateCollectionSongCount(database, collectionId);

      debugPrint(
          '[CollectionRepository] ✅ Removed song $songNumber from collection $collectionId');
      return CollectionOperationResult(
        success: true,
        operationId: '${collectionId}_$songNumber',
      );
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Error removing song from collection: $e');
      return CollectionOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if user can access collection based on role
  bool _canUserAccessCollection(SongCollection collection, String userRole) {
    // Super admin can access everything
    if (userRole == 'super_admin') return true;

    // Admin can access everything except super admin collections
    if (userRole == 'admin') {
      return collection.accessLevel != CollectionAccessLevel.superadmin;
    }

    // Premium users can access public, registered, and premium
    if (userRole == 'premium') {
      return [
        CollectionAccessLevel.public,
        CollectionAccessLevel.registered,
        CollectionAccessLevel.premium,
      ].contains(collection.accessLevel);
    }

    // Registered users can access public and registered
    if (userRole == 'user') {
      return [
        CollectionAccessLevel.public,
        CollectionAccessLevel.registered,
      ].contains(collection.accessLevel);
    }

    // Anonymous users can only access public
    return collection.accessLevel == CollectionAccessLevel.public;
  }

  /// Generate a unique collection ID from name
  String _generateCollectionId(String name) {
    // Convert to safe ID format
    final id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    // Add timestamp to ensure uniqueness
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${id}_$timestamp';
  }

  /// Update the song count for a collection
  Future<void> _updateCollectionSongCount(
      FirebaseDatabase database, String collectionId) async {
    try {
      final songsRef = database.ref('$_songCollectionPath/$collectionId/songs');
      final songsSnapshot = await songsRef.get();

      final songCount = songsSnapshot.exists && songsSnapshot.value != null
          ? (songsSnapshot.value as Map).length
          : 0;

      await database
          .ref('$_songCollectionPath/$collectionId/metadata/song_count')
          .set(songCount);
      await database
          .ref('$_songCollectionPath/$collectionId/metadata/updated_at')
          .set(DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint(
          '[CollectionRepository] Warning: Could not update song count for $collectionId: $e');
    }
  }

  /// Log operation for debugging
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
      final count = _operationCounts[operation];
      debugPrint('[CollectionRepository] 🔧 $operation (count: $count)');
      if (details != null) {
        debugPrint('[CollectionRepository] 📊 Details: $details');
      }
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'firebaseInitialized': _isFirebaseInitialized,
      'databaseInitialized': _dbInitialized,
      'lastConnectionCheck': _lastConnectionCheck?.toIso8601String(),
      'lastConnectionResult': _lastConnectionResult,
    };
  }
}
