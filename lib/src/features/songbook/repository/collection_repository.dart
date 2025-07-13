// lib/src/features/songbook/repository/collection_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// Result wrapper classes
class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;
  CollectionDataResult({required this.collections, required this.isOnline});
}

class CollectionWithSongsResult {
  final SongCollection? collection;
  final List<Song> songs;
  final bool isOnline;
  CollectionWithSongsResult(
      {required this.collection, required this.songs, required this.isOnline});
}

class CollectionOperationResult {
  final bool success;
  final String? errorMessage;
  final String? collectionId;
  CollectionOperationResult(
      {required this.success, this.errorMessage, this.collectionId});
}

// Parsing functions for compute isolation
List<SongCollection> _parseCollectionsFromFirebaseMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<SongCollection> collections = [];
    for (final entry in jsonMap.entries) {
      try {
        final data = Map<String, dynamic>.from(entry.value as Map);
        collections.add(SongCollection.fromJson(data, entry.key));
      } catch (e) {
        debugPrint('❌ Error parsing collection ${entry.key}: $e');
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
        final data = Map<String, dynamic>.from(entry.value as Map);
        songs.add(Song.fromJson(data));
      } catch (e) {
        debugPrint('❌ Error parsing collection song ${entry.key}: $e');
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing collection songs map: $e');
    return [];
  }
}

class CollectionRepository {
  static const String _collectionsPath = 'song_collections';
  static const String _collectionSongsPath = 'collection_songs';

  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  bool get _isFirebaseInitialized => Firebase.apps.isNotEmpty;
  FirebaseDatabase? get _database =>
      _isFirebaseInitialized ? FirebaseDatabase.instance : null;

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
      debugPrint(
          '[CollectionRepository] 🔧 $operation (${_operationCounts[operation]})');
      if (details != null) {
        debugPrint('[CollectionRepository] 📊 Details: $details');
      }
    }
  }

  Future<bool> _checkRealConnectivity() async {
    if (!_isFirebaseInitialized) return false;
    try {
      final connectedRef = _database!.ref('.info/connected');
      final snapshot =
          await connectedRef.get().timeout(const Duration(seconds: 5));
      return snapshot.value == true;
    } catch (e) {
      debugPrint('[CollectionRepository] Connectivity check failed: $e');
      return false;
    }
  }

  // ============================================================================
  //  COLLECTION CRUD OPERATIONS
  // ============================================================================

  Future<CollectionDataResult> getAllCollections({String? userRole}) async {
    _logOperation('getAllCollections', {'userRole': userRole});
    if (!await _checkRealConnectivity()) {
      return CollectionDataResult(collections: [], isOnline: false);
    }
    try {
      final event = await _database!
          .ref(_collectionsPath)
          .once()
          .timeout(const Duration(seconds: 15));
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return CollectionDataResult(collections: [], isOnline: true);
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final collections =
          await compute(_parseCollectionsFromFirebaseMap, json.encode(data));
      final filtered = _filterCollectionsByAccess(collections, userRole);
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return CollectionDataResult(collections: filtered, isOnline: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to fetch collections: $e');
      return CollectionDataResult(collections: [], isOnline: false);
    }
  }

  Future<CollectionOperationResult> createCollection(
      SongCollection collection) async {
    _logOperation('createCollection', {'name': collection.name});
    if (!await _checkRealConnectivity()) {
      return CollectionOperationResult(
          success: false, errorMessage: 'No internet connection.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return CollectionOperationResult(
          success: false, errorMessage: 'User not authenticated.');
    }
    try {
      // **FIXED**: Generate a new ID from Firebase using `push()`
      final newRef = _database!.ref(_collectionsPath).push();
      final newId = newRef.key!;
      final now = DateTime.now();

      final newCollection = collection.copyWith(
        id: newId, // Use the newly generated ID
        createdBy: user.uid,
        createdAt: now,
        updatedAt: now,
      );
      await newRef.set(newCollection.toJson());
      return CollectionOperationResult(success: true, collectionId: newId);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to create collection: $e');
      return CollectionOperationResult(
          success: false, errorMessage: 'An unknown error occurred.');
    }
  }

  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    _logOperation('updateCollection', {'collectionId': collection.id});
    if (!await _checkRealConnectivity()) {
      return CollectionOperationResult(
          success: false, errorMessage: 'No internet connection.');
    }
    try {
      final updatedCollection = collection.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: FirebaseAuth.instance.currentUser?.uid,
      );
      await _database!
          .ref('$_collectionsPath/${collection.id}')
          .update(updatedCollection.toJson());
      return CollectionOperationResult(
          success: true, collectionId: collection.id);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to update collection: $e');
      return CollectionOperationResult(
          success: false, errorMessage: 'An unknown error occurred.');
    }
  }

  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});
    if (!await _checkRealConnectivity()) {
      return CollectionOperationResult(
          success: false, errorMessage: 'No internet connection.');
    }
    try {
      final Map<String, dynamic> updates = {
        '/$_collectionsPath/$collectionId': null,
        '/$_collectionSongsPath/$collectionId': null,
      };
      await _database!.ref().update(updates);
      return CollectionOperationResult(success: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to delete collection: $e');
      return CollectionOperationResult(
          success: false, errorMessage: 'An unknown error occurred.');
    }
  }

  // ============================================================================
  //  COLLECTION SONGS MANAGEMENT
  // ============================================================================

  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song,
      {int? index}) async {
    _logOperation('addSongToCollection',
        {'collectionId': collectionId, 'songNumber': song.number});
    if (!await _checkRealConnectivity()) {
      return CollectionOperationResult(
          success: false, errorMessage: 'No internet connection.');
    }
    try {
      final songJson = song
          .withCollectionContext(
              collectionId: collectionId, collectionIndex: index)
          .toJson();
      await _database!
          .ref('$_collectionSongsPath/$collectionId/${song.number}')
          .set(songJson);
      await _updateCollectionSongCount(collectionId);
      return CollectionOperationResult(success: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to add song: $e');
      return CollectionOperationResult(
          success: false, errorMessage: 'An unknown error occurred.');
    }
  }

  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    _logOperation('removeSongFromCollection',
        {'collectionId': collectionId, 'songNumber': songNumber});
    if (!await _checkRealConnectivity()) {
      return CollectionOperationResult(
          success: false, errorMessage: 'No internet connection.');
    }
    try {
      await _database!
          .ref('$_collectionSongsPath/$collectionId/$songNumber')
          .remove();
      await _updateCollectionSongCount(collectionId);
      return CollectionOperationResult(success: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to remove song: $e');
      return CollectionOperationResult(
          success: false, errorMessage: 'An unknown error occurred.');
    }
  }

  // ============================================================================
  //  ACCESS CONTROL & UTILITIES
  // ============================================================================

  List<SongCollection> _filterCollectionsByAccess(
      List<SongCollection> collections, String? userRole) {
    return collections
        .where((c) => _canUserAccessCollection(c, userRole))
        .toList();
  }

  bool _canUserAccessCollection(SongCollection collection, String? userRole) {
    final role = userRole?.toLowerCase() ?? 'guest';
    const hierarchy = {
      'guest': 0,
      'user': 1,
      'registered': 1,
      'premium': 2,
      'admin': 3,
      'superadmin': 4,
    };
    final userLevel = hierarchy[role] ?? 0;
    return userLevel >= collection.accessLevel.index;
  }

  // ============================================================================
  //  NEW METHODS FOR ENHANCED INTEGRATION
  // ============================================================================

  Future<CollectionWithSongsResult> getCollectionSongs(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionSongs',
        {'collectionId': collectionId, 'userRole': userRole});
    
    if (!await _checkRealConnectivity()) {
      return CollectionWithSongsResult(
          collection: null, songs: [], isOnline: false);
    }
    
    try {
      // Get collection metadata
      final collectionSnapshot = await _database!
          .ref('$_collectionsPath/$collectionId')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (!collectionSnapshot.exists || collectionSnapshot.value == null) {
        return CollectionWithSongsResult(
            collection: null, songs: [], isOnline: true);
      }
      
      final collectionData = Map<String, dynamic>.from(collectionSnapshot.value as Map);
      final collection = SongCollection.fromJson(collectionData, collectionId);
      
      // Check access
      if (!_canUserAccessCollection(collection, userRole)) {
        return CollectionWithSongsResult(
            collection: null, songs: [], isOnline: true);
      }
      
      // Get collection songs
      final songsSnapshot = await _database!
          .ref('$_collectionSongsPath/$collectionId')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (!songsSnapshot.exists || songsSnapshot.value == null) {
        return CollectionWithSongsResult(
            collection: collection, songs: [], isOnline: true);
      }
      
      final songsData = Map<String, dynamic>.from(songsSnapshot.value as Map);
      final songs = await compute(_parseSongsFromCollectionMap, json.encode(songsData));
      
      return CollectionWithSongsResult(
          collection: collection, songs: songs, isOnline: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to get collection songs: $e');
      return CollectionWithSongsResult(
          collection: null, songs: [], isOnline: false);
    }
  }

  Future<CollectionDataResult> getActiveCollections({String? userRole}) async {
    return await getAllCollections(userRole: userRole);
  }

  Future<SongCollection?> getCollectionById(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionById',
        {'collectionId': collectionId, 'userRole': userRole});
    
    if (!await _checkRealConnectivity()) {
      return null;
    }
    
    try {
      final snapshot = await _database!
          .ref('$_collectionsPath/$collectionId')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final collection = SongCollection.fromJson(data, collectionId);
      
      // Check access
      if (!_canUserAccessCollection(collection, userRole)) {
        return null;
      }
      
      return collection;
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to get collection by ID: $e');
      return null;
    }
  }

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

  Future<void> _updateCollectionSongCount(String collectionId) async {
    if (!_isFirebaseInitialized) return;
    try {
      final snapshot =
          await _database!.ref('$_collectionSongsPath/$collectionId').get();
      final songCount = (snapshot.value as Map?)?.length ?? 0;
      await _database!.ref('$_collectionsPath/$collectionId').update({
        'song_count': songCount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Failed to update song count for $collectionId: $e');
    }
  }
}
