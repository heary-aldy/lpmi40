// lib/src/features/songbook/repository/collection_repository.dart
// ✅ FIX: Corrected the import path for song_model.dart to resolve the URI error.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
// ✅ FIX: Corrected the import path below
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// (The rest of your existing code remains unchanged)

class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;

  CollectionDataResult({
    required this.collections,
    required this.isOnline,
  });
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

List<SongCollection> _parseCollectionsFromData(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];

    final List<SongCollection> collections = [];
    jsonMap.forEach((collectionId, collectionValue) {
      try {
        final collectionData =
            Map<String, dynamic>.from(collectionValue as Map);
        collections.add(SongCollection.fromJson(collectionData, collectionId));
      } catch (e) {
        debugPrint('❌ Error parsing collection $collectionId: $e');
      }
    });

    return collections;
  } catch (e) {
    debugPrint('❌ Error parsing collections data: $e');
    return [];
  }
}

List<Song> _parseSongsFromCollectionMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<Song> songs = [];
    jsonMap.forEach((key, value) {
      try {
        final data = Map<String, dynamic>.from(value as Map);
        data['number'] = data['song_number']?.toString() ?? key;
        songs.add(Song.fromJson(data));
      } catch (e) {
        debugPrint('❌ Error parsing collection song $key: $e');
      }
    });
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing collection songs map: $e');
    return [];
  }
}

class CollectionRepository {
  static const String _collectionsPath = 'song_collection';

  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  static CollectionDataResult? _cachedCollections;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static Future<CollectionDataResult>? _pendingRequest;

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://lmpi-c5c5c-default-rtdb.firebaseio.com");

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
    try {
      final testRef = _database.ref('song_collection/LPMI/songs/1');
      await testRef.get().timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('[CollectionRepository] Quick connectivity test failed: $e');
      return false;
    }
  }

  bool _isCacheValid() {
    if (_cachedCollections == null || _cacheTimestamp == null) return false;
    final age = DateTime.now().difference(_cacheTimestamp!);
    return age < _cacheValidDuration;
  }

  Future<CollectionDataResult> getAllCollections({String? userRole}) async {
    _logOperation('getAllCollections', {'userRole': userRole});

    if (_isCacheValid()) {
      debugPrint(
          '[CollectionRepository] 📋 Using cached collections (age: ${DateTime.now().difference(_cacheTimestamp!).inSeconds}s)');
      final filtered =
          _filterCollectionsByAccess(_cachedCollections!.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: _cachedCollections!.isOnline);
    }

    if (_pendingRequest != null) {
      debugPrint('[CollectionRepository] 🔄 Waiting for pending request...');
      final result = await _pendingRequest!;
      final filtered = _filterCollectionsByAccess(result.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: result.isOnline);
    }

    _pendingRequest = _fetchCollectionsFromFirebase();

    try {
      final result = await _pendingRequest!;
      _cachedCollections = result;
      _cacheTimestamp = DateTime.now();
      final filtered = _filterCollectionsByAccess(result.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: result.isOnline);
    } finally {
      _pendingRequest = null;
    }
  }

  Future<CollectionDataResult> _fetchCollectionsFromFirebase() async {
    if (!await _checkRealConnectivity()) {
      debugPrint(
          '[CollectionRepository] 📱 Offline - returning empty collections');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      debugPrint(
          '[CollectionRepository] 🌐 Fetching collections from path: $_collectionsPath');

      final event = await _database.ref(_collectionsPath).once();

      if (!event.snapshot.exists || event.snapshot.value == null) {
        debugPrint(
            '[CollectionRepository] ✅ No data found at path: $_collectionsPath');
        return CollectionDataResult(collections: [], isOnline: true);
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      debugPrint(
          '[CollectionRepository] 📊 Found collection keys: ${data.keys.toList()}');

      final collections =
          await compute(_parseCollectionsFromData, json.encode(data));

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
      for (final collection in collections) {
        debugPrint(
            '[CollectionRepository] 📁 Collection: ${collection.id} - ${collection.name} (${collection.songCount} songs)');
      }

      return CollectionDataResult(collections: collections, isOnline: true);
    } catch (e) {
      debugPrint('[CollectionRepository] ❌ Failed to fetch collections: $e');
      return CollectionDataResult(collections: [], isOnline: false);
    }
  }

  Future<SongCollection?> getCollectionById(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionById', {'collectionId': collectionId});
    final result = await getAllCollections(userRole: userRole);
    try {
      return result.collections.firstWhere((c) => c.id == collectionId);
    } catch (e) {
      return null;
    }
  }

  Future<CollectionWithSongsResult> getSongsFromCollection(String collectionId,
      {String? userRole}) async {
    _logOperation('getSongsFromCollection', {'collectionId': collectionId});

    if (!await _checkRealConnectivity()) {
      return CollectionWithSongsResult(
          collection: null, songs: [], isOnline: false);
    }

    try {
      final collectionPath = '$_collectionsPath/$collectionId';
      final collectionEvent = await _database.ref(collectionPath).once();
      if (!collectionEvent.snapshot.exists ||
          collectionEvent.snapshot.value == null) {
        debugPrint(
            '[CollectionRepository] ❌ Collection $collectionId not found');
        return CollectionWithSongsResult(
            collection: null, songs: [], isOnline: true);
      }

      final collectionData =
          Map<String, dynamic>.from(collectionEvent.snapshot.value as Map);
      final collection = SongCollection.fromJson(collectionData, collectionId);

      if (!_canUserAccessCollection(collection, userRole)) {
        debugPrint(
            '[CollectionRepository] 🚫 Access denied for user to collection $collectionId');
        return CollectionWithSongsResult(
            collection: null, songs: [], isOnline: true);
      }

      final songsData = collectionData['songs'] as Map<dynamic, dynamic>? ?? {};
      final songs =
          await compute(_parseSongsFromCollectionMap, json.encode(songsData));

      songs.sort((a, b) =>
          (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

      debugPrint(
          '[CollectionRepository] ✅ Loaded ${songs.length} songs from collection $collectionId');

      return CollectionWithSongsResult(
          collection: collection, songs: songs, isOnline: true);
    } catch (e) {
      debugPrint(
          '[CollectionRepository] ❌ Failed to fetch collection songs: $e');
      return CollectionWithSongsResult(
          collection: null, songs: [], isOnline: false);
    }
  }

  Future<CollectionOperationResult> createCollection(
      SongCollection collection) async {
    _logOperation('createCollection', {'name': collection.name});
    return CollectionOperationResult(
        success: false, errorMessage: 'Create operation not yet implemented.');
  }

  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    _logOperation('updateCollection', {'id': collection.id});
    return CollectionOperationResult(
        success: false, errorMessage: 'Update operation not yet implemented.');
  }

  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    _logOperation('deleteCollection', {'collectionId': collectionId});
    return CollectionOperationResult(
        success: false, errorMessage: 'Delete operation not yet implemented.');
  }

  Future<CollectionWithSongsResult> getCollectionSongs(String collectionId,
      {String? userRole}) async {
    _logOperation('getCollectionSongs', {'collectionId': collectionId});
    return await getSongsFromCollection(collectionId, userRole: userRole);
  }

  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song) async {
    _logOperation('addSongToCollection',
        {'collectionId': collectionId, 'songNumber': song.number});
    return CollectionOperationResult(
        success: false,
        errorMessage: 'Add song operation not yet implemented.');
  }

  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    _logOperation('removeSongFromCollection',
        {'collectionId': collectionId, 'songNumber': songNumber});
    return CollectionOperationResult(
        success: false,
        errorMessage: 'Remove song operation not yet implemented.');
  }

  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'cacheInfo': {
        'hasCachedData': _cachedCollections != null,
        'cacheAge': _cacheTimestamp != null
            ? DateTime.now().difference(_cacheTimestamp!).inSeconds
            : null,
        'cacheValid': _isCacheValid(),
      }
    };
  }

  static void invalidateCache() {
    _cachedCollections = null;
    _cacheTimestamp = null;
    debugPrint('[CollectionRepository] 🗑️ Cache invalidated');
  }

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
      'super_admin': 4,
    };
    final userLevel = hierarchy[role] ?? 0;
    final requiredLevel = collection.accessLevel.index;
    return userLevel >= requiredLevel;
  }
}
