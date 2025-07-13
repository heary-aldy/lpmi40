// lib/src/features/songbook/repository/collection_repository.dart
// ✅ FIXED: Read collections from root level (LPMI, Lagu_belia, SRD) instead of /song_collection

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

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

// Top-level function for parsing collections from root level
List<SongCollection> _parseCollectionsFromRoot(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];

    final List<SongCollection> collections = [];
    final knownCollections = [
      'LPMI',
      'Lagu_belia',
      'SRD'
    ]; // ✅ Your actual collection IDs

    for (final collectionId in knownCollections) {
      if (jsonMap.containsKey(collectionId)) {
        try {
          final collectionData =
              Map<String, dynamic>.from(jsonMap[collectionId] as Map);
          collections
              .add(SongCollection.fromJson(collectionData, collectionId));
        } catch (e) {
          debugPrint('❌ Error parsing collection $collectionId: $e');
        }
      }
    }

    return collections;
  } catch (e) {
    debugPrint('❌ Error parsing root collections: $e');
    return [];
  }
}

// Top-level function for parsing songs in a separate isolate.
List<Song> _parseSongsFromCollectionMap(String jsonString) {
  try {
    final Map<String, dynamic>? jsonMap = json.decode(jsonString);
    if (jsonMap == null) return [];
    final List<Song> songs = [];
    jsonMap.forEach((key, value) {
      try {
        final data = Map<String, dynamic>.from(value as Map);
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
  // ✅ FIXED: Read from root level, not /song_collection
  static const String _collectionsPath = ''; // Root level

  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ✅ OPTIMIZATION: Cache for collections to reduce API calls
  static CollectionDataResult? _cachedCollections;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // ✅ OPTIMIZATION: Prevent multiple simultaneous requests
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

  // ✅ IMPROVED: Faster, more reliable connectivity check
  Future<bool> _checkRealConnectivity() async {
    try {
      // Try a simple test read from root
      final testRef = _database.ref('LPMI/metadata'); // Test with known path
      await testRef.get().timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      debugPrint('[CollectionRepository] Quick connectivity test failed: $e');
      return false;
    }
  }

  // ✅ OPTIMIZED: Check if cache is still valid
  bool _isCacheValid() {
    if (_cachedCollections == null || _cacheTimestamp == null) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimestamp!);
    return age < _cacheValidDuration;
  }

  Future<CollectionDataResult> getAllCollections({String? userRole}) async {
    _logOperation('getAllCollections', {'userRole': userRole});

    // ✅ OPTIMIZATION: Return cached result if valid
    if (_isCacheValid()) {
      debugPrint(
          '[CollectionRepository] 📋 Using cached collections (age: ${DateTime.now().difference(_cacheTimestamp!).inSeconds}s)');
      final filtered =
          _filterCollectionsByAccess(_cachedCollections!.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: _cachedCollections!.isOnline);
    }

    // ✅ OPTIMIZATION: Prevent multiple simultaneous requests
    if (_pendingRequest != null) {
      debugPrint('[CollectionRepository] 🔄 Waiting for pending request...');
      final result = await _pendingRequest!;
      final filtered = _filterCollectionsByAccess(result.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: result.isOnline);
    }

    // ✅ IMPROVED: Create the actual request
    _pendingRequest = _fetchCollectionsFromFirebase();

    try {
      final result = await _pendingRequest!;

      // ✅ OPTIMIZATION: Cache the result
      _cachedCollections = result;
      _cacheTimestamp = DateTime.now();

      final filtered = _filterCollectionsByAccess(result.collections, userRole);
      return CollectionDataResult(
          collections: filtered, isOnline: result.isOnline);
    } finally {
      _pendingRequest = null;
    }
  }

  // ✅ FIXED: Read collections from root level
  Future<CollectionDataResult> _fetchCollectionsFromFirebase() async {
    // Quick connectivity check first
    if (!await _checkRealConnectivity()) {
      debugPrint(
          '[CollectionRepository] 📱 Offline - returning empty collections');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      debugPrint(
          '[CollectionRepository] 🌐 Fetching collections from Firebase root...');

      // ✅ FIXED: Read from root level where your collections actually are
      final event = await _database.ref().once(); // Root level

      if (!event.snapshot.exists || event.snapshot.value == null) {
        debugPrint('[CollectionRepository] ✅ No data found in Firebase root');
        return CollectionDataResult(collections: [], isOnline: true);
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      debugPrint(
          '[CollectionRepository] 📊 Found root keys: ${data.keys.toList()}');

      // ✅ FIXED: Use the new parsing function for root level
      final collections =
          await compute(_parseCollectionsFromRoot, json.encode(data));

      collections.sort((a, b) => a.name.compareTo(b.name));

      debugPrint(
          '[CollectionRepository] ✅ Loaded ${collections.length} collections from Firebase root');
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
      // ✅ FIXED: Read collection from root level (e.g., /LPMI, /Lagu_belia, /SRD)
      final collectionEvent = await _database.ref(collectionId).once();
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

      // Check if user has access to this collection
      if (!_canUserAccessCollection(collection, userRole)) {
        return CollectionWithSongsResult(
            collection: null, songs: [], isOnline: true);
      }

      // Extract songs from the collection
      final songsData = collectionData['songs'] as Map<String, dynamic>? ?? {};
      final songs =
          await compute(_parseSongsFromCollectionMap, json.encode(songsData));

      // Sort songs by number
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

  // ✅ NEW: Manual cache invalidation method
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
      'super_admin': 4, // ✅ Added alias for your super_admin format
    };
    final userLevel = hierarchy[role] ?? 0;
    final requiredLevel = collection.accessLevel.index;
    return userLevel >= requiredLevel;
  }
}
