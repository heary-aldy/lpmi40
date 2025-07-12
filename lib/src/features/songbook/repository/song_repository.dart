// lib/src/features/songbook/repository/song_repository.dart
// 🟢 PHASE 1: Added connectivity logging, simplified error messages, performance tracking
// 🟢 PHASE 1.3: Dual-Read capability - collection-first, legacy fallback
// 🔵 ORIGINAL: All existing methods preserved exactly

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ NEW: Added Firebase Auth import
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
// import 'package:lpmi40/src/features/songbook/models/collection_model.dart'; // ✅ PHASE 1.3: Added for access control (imported via collection repository)
import 'package:lpmi40/src/features/songbook/repository/song_collection_repository.dart'; // ✅ PHASE 1.3: Added for collection support
import 'package:lpmi40/src/core/services/firebase_service.dart';

// Original wrapper class for holding a full list of songs
class SongDataResult {
  final List<Song> songs;
  final bool isOnline;

  SongDataResult({required this.songs, required this.isOnline});
}

// Wrapper class for paginated lazy-loading results
class PaginatedSongDataResult {
  final List<Song> songs;
  final bool isOnline;
  final String? lastKey;
  final bool hasMore;

  PaginatedSongDataResult({
    required this.songs,
    required this.isOnline,
    required this.hasMore,
    this.lastKey,
  });
}

// ✅ NEW: Wrapper class for single song with status
class SongWithStatusResult {
  final Song? song;
  final bool isOnline;

  SongWithStatusResult({required this.song, required this.isOnline});
}

// --- PARSING FUNCTIONS ---
List<Song> _parseSongsFromFirebaseMap(String jsonString) {
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
        debugPrint('❌ Error parsing song ${entry.key}: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing Firebase map: $e');
    return [];
  }
}

List<Song> _parseSongsFromList(String jsonString) {
  try {
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Song> songs = [];
    for (int i = 0; i < jsonList.length; i++) {
      try {
        final songData = Map<String, dynamic>.from(jsonList[i] as Map);
        final song = Song.fromJson(songData);
        songs.add(song);
      } catch (e) {
        debugPrint('❌ Error parsing song at index $i: $e');
        continue;
      }
    }
    return songs;
  } catch (e) {
    debugPrint('❌ Error parsing list: $e');
    return [];
  }
}

class SongRepository {
  static const String _firebaseUrl =
      'https://lmpi-c5c5c-default-rtdb.firebaseio.com/';

  // ✅ NEW: Firebase service for proper connectivity checking
  final FirebaseService _firebaseService = FirebaseService();

  // ✅ PHASE 1.3: Collection repository for dual-read support
  final SongCollectionRepository _collectionRepository = SongCollectionRepository();

  // 🟢 NEW: Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ✅ PHASE 1.3: Collection-based reading configuration
  bool _preferCollectionRead = true; // Feature flag for gradual switchover
  String? _currentCollectionFilter; // Optional collection filter
  String? _currentUserRole; // User role for access control

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
      debugPrint('[SongRepository] Error getting database instance: $e');
      return null;
    }
  }

  // 🟢 NEW: Operation logging helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('[SongRepository] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[SongRepository] 📊 Details: $details');
      }
    }
  }

  // 🟢 NEW: Connectivity attempt logging
  void _logConnectivityAttempt(String method, bool success, [String? error]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final currentUser = FirebaseAuth.instance.currentUser;
      final userType = currentUser?.isAnonymous == true
          ? 'GUEST'
          : currentUser != null
              ? 'REGISTERED'
              : 'NO_AUTH';

      debugPrint('🔍 [$timestamp] Connectivity Test: $method');
      debugPrint('👤 User Type: $userType');
      debugPrint('📊 Result: ${success ? "SUCCESS" : "FAILED"}');
      if (error != null) debugPrint('❌ Error: $error');
      debugPrint('─' * 50);
    }
  }

  // 🟢 NEW: User-friendly error message helper
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to access songs right now. Please try again later.';
    } else {
      return 'Unable to load songs. Please try again.';
    }
  }

  // ✅ COMPREHENSIVE FIX: Enhanced connectivity detection with guest user support
  Future<bool> _checkRealConnectivity() async {
    _logOperation('_checkRealConnectivity'); // 🟢 NEW

    if (!_isFirebaseInitialized) {
      debugPrint('[SongRepository] Firebase not initialized');
      _logConnectivityAttempt(
          'Firebase Init Check', false, 'Not initialized'); // 🟢 NEW
      return false;
    }

    try {
      debugPrint('[SongRepository] 🔍 Testing real Firebase connectivity...');

      final database = _database;
      if (database == null) {
        debugPrint('[SongRepository] ❌ Database instance is null');
        _logConnectivityAttempt(
            'Database Instance', false, 'Null database'); // 🟢 NEW
        return false;
      }

      // ✅ NEW: Check authentication state
      final currentUser = FirebaseAuth.instance.currentUser;
      final isGuestUser = currentUser?.isAnonymous ?? false;
      final userType = currentUser == null
          ? 'NO_AUTH'
          : (isGuestUser ? 'GUEST' : 'REGISTERED');

      debugPrint(
          '[SongRepository] 👤 User type: $userType (${currentUser?.email ?? 'no-email'})');

      // ✅ STRATEGY 1: For guest users, try direct data access first (more reliable)
      if (isGuestUser) {
        debugPrint(
            '[SongRepository] 🔄 Guest user detected - trying direct data access...');

        try {
          final DatabaseReference ref = database.ref('songs');
          final DatabaseEvent event =
              await ref.orderByKey().limitToFirst(1).once().timeout(
            const Duration(seconds: 8), // Longer timeout for guest users
            onTimeout: () {
              debugPrint('[SongRepository] ⏰ Guest data access timed out');
              throw Exception('Guest data access timeout');
            },
          );

          final hasData = event.snapshot.exists && event.snapshot.value != null;

          if (hasData) {
            debugPrint(
                '[SongRepository] ✅ Guest user can access Firebase data - ONLINE');
            _logConnectivityAttempt('Guest Data Access', true); // 🟢 NEW
            return true;
          } else {
            debugPrint(
                '[SongRepository] ❌ Guest user: No data available from Firebase');
            _logConnectivityAttempt(
                'Guest Data Access', false, 'No data'); // 🟢 NEW
          }
        } catch (guestError) {
          debugPrint(
              '[SongRepository] ⚠️ Guest data access failed: $guestError');
          _logConnectivityAttempt(
              'Guest Data Access', false, guestError.toString()); // 🟢 NEW
          // Continue to other methods below
        }
      }

      // ✅ STRATEGY 2: Use Firebase's .info/connected (reliable for registered users)
      try {
        debugPrint('[SongRepository] 🌐 Checking .info/connected...');

        final DatabaseReference connectedRef = database.ref('.info/connected');
        final DatabaseEvent connectedEvent = await connectedRef.once().timeout(
          Duration(seconds: isGuestUser ? 8 : 5), // More lenient for guests
          onTimeout: () {
            debugPrint('[SongRepository] ⏰ .info/connected check timed out');
            throw Exception('Connected check timeout');
          },
        );

        final isConnected = connectedEvent.snapshot.value as bool? ?? false;

        if (isConnected) {
          debugPrint(
              '[SongRepository] ✅ Firebase .info/connected reports: ONLINE');
          _logConnectivityAttempt('.info/connected', true); // 🟢 NEW
          return true;
        } else {
          debugPrint(
              '[SongRepository] ❌ Firebase .info/connected reports: OFFLINE');
          _logConnectivityAttempt(
              '.info/connected', false, 'Reports offline'); // 🟢 NEW

          // ✅ For guest users, don't immediately give up - try fallback
          if (!isGuestUser) {
            return false;
          }
        }
      } catch (e) {
        debugPrint('[SongRepository] ⚠️ .info/connected check failed: $e');
        _logConnectivityAttempt(
            '.info/connected', false, e.toString()); // 🟢 NEW
      }

      // ✅ STRATEGY 3: Fallback - Test server timestamp
      try {
        debugPrint('[SongRepository] 🔄 Fallback: Testing server timestamp...');

        final DatabaseReference timestampRef =
            database.ref('.info/serverTimeOffset');
        final DatabaseEvent timestampEvent = await timestampRef.once().timeout(
          Duration(seconds: isGuestUser ? 10 : 8), // More time for guests
          onTimeout: () {
            debugPrint('[SongRepository] ⏰ Server timestamp check timed out');
            throw Exception('Timestamp check timeout');
          },
        );

        final hasServerTime = timestampEvent.snapshot.exists;

        if (hasServerTime) {
          debugPrint('[SongRepository] ✅ Fallback connectivity test: ONLINE');
          _logConnectivityAttempt('Server Timestamp', true); // 🟢 NEW
          return true;
        } else {
          debugPrint('[SongRepository] ❌ Fallback connectivity test: OFFLINE');
          _logConnectivityAttempt(
              'Server Timestamp', false, 'No server time'); // 🟢 NEW
        }
      } catch (fallbackError) {
        debugPrint(
            '[SongRepository] ❌ Fallback connectivity test failed: $fallbackError');
        _logConnectivityAttempt(
            'Server Timestamp', false, fallbackError.toString()); // 🟢 NEW
      }

      // ✅ STRATEGY 4: Last resort - Try actual songs data (especially for guests)
      try {
        debugPrint(
            '[SongRepository] 🔄 Last resort: Testing songs data access...');

        final DatabaseReference ref = database.ref('songs');
        final DatabaseEvent event =
            await ref.orderByKey().limitToFirst(1).once().timeout(
          Duration(seconds: isGuestUser ? 12 : 3), // Much more time for guests
          onTimeout: () {
            debugPrint('[SongRepository] ⏰ Songs data test timed out');
            throw Exception('Songs data test timeout');
          },
        );

        final hasData = event.snapshot.exists && event.snapshot.value != null;

        if (hasData) {
          debugPrint(
              '[SongRepository] ✅ Last resort: Songs data accessible - likely ONLINE');
          _logConnectivityAttempt('Songs Data Test', true); // 🟢 NEW
          return true;
        } else {
          debugPrint('[SongRepository] ❌ Last resort: No songs data available');
          _logConnectivityAttempt(
              'Songs Data Test', false, 'No songs data'); // 🟢 NEW
        }
      } catch (lastResortError) {
        debugPrint(
            '[SongRepository] ❌ Last resort test failed: $lastResortError');
        _logConnectivityAttempt(
            'Songs Data Test', false, lastResortError.toString()); // 🟢 NEW
      }

      // ✅ All methods failed
      debugPrint(
          '[SongRepository] ❌ All connectivity methods failed - assuming OFFLINE');
      _logConnectivityAttempt(
          'All Methods', false, 'All strategies failed'); // 🟢 NEW
      return false;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Critical connectivity check error: $e');

      // ✅ Enhanced error handling with guest-specific logic
      String errorType = 'Unknown error';
      if (e.toString().contains('timeout')) {
        errorType = 'Network timeout';
        debugPrint(
            '[SongRepository] ⏰ Network timeout detected - assuming offline');
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorType = 'Permission denied';
        debugPrint(
            '[SongRepository] 🔒 Permission denied - check Firebase rules');
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorType = 'Network connectivity issue';
        debugPrint(
            '[SongRepository] 📡 Network connectivity issue - assuming offline');
      } else {
        errorType = 'Firebase error';
        debugPrint(
            '[SongRepository] 🔧 Unknown Firebase error - assuming offline: $e');
      }

      _logConnectivityAttempt('Critical Check', false, errorType); // 🟢 NEW
      return false;
    }
  }

  // ✅ UPDATED: Added proper connectivity detection
  Future<PaginatedSongDataResult> getPaginatedSongs(
      {int pageSize = 30, String? startAfterKey}) async {
    _logOperation('getPaginatedSongs',
        {'pageSize': pageSize, 'startAfterKey': startAfterKey}); // 🟢 NEW

    // Step 1: Check if Firebase is initialized
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[DEBUG] Firebase not initialized, loading from local assets.');
      final allSongs = await _loadAllFromLocalAssets();
      return PaginatedSongDataResult(
          songs: allSongs.songs, isOnline: false, hasMore: false);
    }

    // Step 2: Check real connectivity
    final isReallyOnline = await _checkRealConnectivity();
    if (!isReallyOnline) {
      debugPrint('[DEBUG] No real connectivity, loading from local assets.');
      final allSongs = await _loadAllFromLocalAssets();
      return PaginatedSongDataResult(
          songs: allSongs.songs, isOnline: false, hasMore: false);
    }

    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');

      debugPrint('----------- PAGINATION FETCH START -----------');
      debugPrint('[DEBUG] Fetching page with pageSize: $pageSize');
      debugPrint('[DEBUG] Starting after key: $startAfterKey');

      Query query = database.ref('songs').orderByKey();
      final fetchSize = pageSize + 1;

      if (startAfterKey != null) {
        query = query.startAt(startAfterKey);
      }

      query = query.limitToFirst(fetchSize);

      // ✅ NEW: Add timeout to Firebase call
      final event = await query.once().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[DEBUG] Firebase query timed out');
          throw Exception('Firebase query timeout');
        },
      );

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        debugPrint('[DEBUG] Firebase returned ${data.length} records.');

        final songs =
            await compute(_parseSongsFromFirebaseMap, json.encode(data));

        if (songs.isNotEmpty) {
          debugPrint(
              '[DEBUG] First song key from DB: ${songs.first.number}, Last: ${songs.last.number}');
        } else {
          debugPrint('[DEBUG] Parsing returned 0 songs.');
        }

        if (startAfterKey != null && songs.isNotEmpty) {
          debugPrint(
              '[DEBUG] Removing duplicate start key: ${songs.first.number}');
          songs.removeAt(0);
        }

        final bool hasMore = songs.length > pageSize;
        debugPrint('[DEBUG] Does it have more pages? $hasMore');

        if (hasMore) {
          final extraSong = songs.last;
          songs.removeLast();
          debugPrint(
              '[DEBUG] Removed extra song for check: ${extraSong.number}');
        }

        final String? lastKey = songs.isNotEmpty ? songs.last.number : null;
        debugPrint('[DEBUG] Last key for this page: $lastKey');
        debugPrint('----------- PAGINATION FETCH END -------------\n');

        // ✅ FIXED: Now correctly returns online status
        return PaginatedSongDataResult(
            songs: songs, isOnline: true, hasMore: hasMore, lastKey: lastKey);
      } else {
        debugPrint('[DEBUG] Firebase query returned no data.');
        debugPrint('----------- PAGINATION FETCH END -------------\n');
        return PaginatedSongDataResult(
            songs: [], isOnline: true, hasMore: false);
      }
    } catch (e) {
      debugPrint(
          '[DEBUG] ❌ Firebase pagination failed: $e. Falling back to all local songs.');
      debugPrint('----------- PAGINATION FETCH END -------------\n');
      final allSongs = await _loadAllFromLocalAssets();
      return PaginatedSongDataResult(
          songs: allSongs.songs, isOnline: false, hasMore: false);
    }
  }

  // ✅ PHASE 1.3: Dual-read capability - collection-first, legacy fallback
  Future<SongDataResult> getAllSongs() async {
    _logOperation('getAllSongs'); // 🟢 NEW

    debugPrint('[SongRepository] 🔍 Starting getAllSongs with dual-read capability...');

    // Step 1: Check if Firebase is initialized
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading all from local assets');
      return await _loadAllFromLocalAssets();
    }

    // Step 2: Check real connectivity with enhanced detection
    debugPrint('[SongRepository] 🌐 Checking real connectivity...');
    final isReallyOnline = await _checkRealConnectivity();

    if (!isReallyOnline) {
      debugPrint(
          '[SongRepository] ❌ No real connectivity detected, using local assets');
      return await _loadAllFromLocalAssets();
    }

    debugPrint(
        '[SongRepository] ✅ Real connectivity confirmed, attempting dual-read fetch...');

    // ✅ PHASE 1.3: Try collection-based read first (if enabled)
    if (_preferCollectionRead) {
      final collectionSongs = await _getAllSongsFromCollections();
      if (collectionSongs.songs.isNotEmpty) {
        debugPrint('[SongRepository] ✅ Successfully loaded ${collectionSongs.songs.length} songs from collections');
        return collectionSongs;
      } else {
        debugPrint('[SongRepository] ⚠️ No songs found in collections, falling back to legacy');
      }
    }

    // ✅ PHASE 1.3: Fallback to legacy songs endpoint
    return await _getAllSongsFromLegacy();
  }

  // ✅ PHASE 1.3: Get songs from collection-based structure
  Future<SongDataResult> _getAllSongsFromCollections() async {
    _logOperation('_getAllSongsFromCollections');

    try {
      debugPrint('[SongRepository] 🔄 Fetching songs from collections...');

      // Get user's accessible collections
      final collectionsResult = await _collectionRepository.getCollectionsForUser(
        userRole: _currentUserRole,
        includeInactive: false,
      );

      if (!collectionsResult.isOnline) {
        debugPrint('[SongRepository] ❌ Collections repository offline');
        return SongDataResult(songs: [], isOnline: false);
      }

      if (collectionsResult.collections.isEmpty) {
        debugPrint('[SongRepository] 📭 No accessible collections found');
        return SongDataResult(songs: [], isOnline: true);
      }

      // Filter collections if specific collection is requested
      final collectionsToFetch = _currentCollectionFilter != null
          ? collectionsResult.collections.where((c) => c.id == _currentCollectionFilter).toList()
          : collectionsResult.collections;

      debugPrint('[SongRepository] 📚 Fetching songs from ${collectionsToFetch.length} collections');

      final allSongs = <Song>[];
      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      // Fetch songs from each accessible collection
      for (final collection in collectionsToFetch) {
        try {
          final collectionSongs = await _getSongsFromCollection(collection.id);
          allSongs.addAll(collectionSongs);
          debugPrint('[SongRepository] ✅ Added ${collectionSongs.length} songs from collection: ${collection.name}');
        } catch (e) {
          debugPrint('[SongRepository] ⚠️ Failed to fetch songs from collection ${collection.name}: $e');
          continue;
        }
      }

      // Apply access control filtering
      final accessibleSongs = allSongs.where((song) {
        return song.canUserAccess(_currentUserRole);
      }).toList();

      // Sort songs by number
      if (accessibleSongs.isNotEmpty) {
        accessibleSongs.sort((a, b) => (int.tryParse(a.number) ?? 0)
            .compareTo(int.tryParse(b.number) ?? 0));
      }

      debugPrint('[SongRepository] ✅ Successfully loaded ${accessibleSongs.length} accessible songs from collections');
      return SongDataResult(songs: accessibleSongs, isOnline: true);

    } catch (e) {
      debugPrint('[SongRepository] ❌ Collection-based fetch failed: $e');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

  // ✅ PHASE 1.3: Get songs from a specific collection
  Future<List<Song>> _getSongsFromCollection(String collectionId) async {
    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    final collectionSongsRef = database.ref('song_collection/$collectionId');
    
    // ✅ ENHANCED: Adjust timeout based on user type
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser?.isAnonymous ?? false;
    final timeoutDuration = Duration(seconds: isGuestUser ? 20 : 15);

    final DatabaseEvent event = await collectionSongsRef.once().timeout(
      timeoutDuration,
      onTimeout: () {
        debugPrint('[SongRepository] ⏰ Collection query timed out for $collectionId');
        throw Exception('Collection query timeout');
      },
    );

    if (event.snapshot.exists && event.snapshot.value != null) {
      final data = event.snapshot.value;
      List<Song> songs;
      
      if (data is Map) {
        songs = await compute(_parseSongsFromFirebaseMap, json.encode(data));
      } else if (data is List) {
        songs = await compute(_parseSongsFromList, json.encode(data));
      } else {
        throw Exception('Unexpected data structure from collection $collectionId: ${data.runtimeType}');
      }

      // Ensure all songs have proper collection context
      return songs.map((song) => song.belongsToCollection() 
          ? song 
          : song.withCollectionContext(collectionId: collectionId)).toList();
    }

    return [];
  }

  // ✅ PHASE 1.3: Legacy method (unchanged behavior)
  Future<SongDataResult> _getAllSongsFromLegacy() async {
    _logOperation('_getAllSongsFromLegacy');

    debugPrint('[SongRepository] 🔄 Fetching songs from legacy endpoint...');

    try {
      final database = _database;
      if (database == null) {
        debugPrint('[SongRepository] ❌ Database instance is null');
        throw Exception('Could not get database instance');
      }

      final DatabaseReference ref = database.ref('songs');

      // ✅ ENHANCED: Adjust timeout based on user type
      final currentUser = FirebaseAuth.instance.currentUser;
      final isGuestUser = currentUser?.isAnonymous ?? false;
      final timeoutDuration = Duration(seconds: isGuestUser ? 20 : 15);

      final DatabaseEvent event = await ref.once().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint(
              '[SongRepository] ⏰ Firebase query timed out after ${timeoutDuration.inSeconds} seconds');
          throw Exception('Firebase query timeout');
        },
      );

      if (event.snapshot.exists && event.snapshot.value != null) {
        debugPrint('[SongRepository] ✅ Legacy Firebase data received, parsing...');

        final data = event.snapshot.value;
        List<Song> songs;
        if (data is Map) {
          songs = await compute(_parseSongsFromFirebaseMap, json.encode(data));
        } else if (data is List) {
          songs = await compute(_parseSongsFromList, json.encode(data));
        } else {
          throw Exception(
              'Unexpected data structure from Firebase: ${data.runtimeType}');
        }

        if (songs.isNotEmpty) {
          songs.sort((a, b) => (int.tryParse(a.number) ?? 0)
              .compareTo(int.tryParse(b.number) ?? 0));

          debugPrint(
              '[SongRepository] ✅ Successfully loaded ${songs.length} songs from legacy Firebase (ONLINE)');
          return SongDataResult(songs: songs, isOnline: true);
        } else {
          debugPrint(
              '[SongRepository] ⚠️ Legacy Firebase returned empty data, falling back to local assets');
        }
      } else {
        debugPrint(
            '[SongRepository] ⚠️ Legacy Firebase snapshot does not exist, falling back to local assets');
      }

      // If we get here, Firebase didn't have data, use local assets
      return await _loadAllFromLocalAssets();
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Legacy Firebase full fetch failed: $e. Falling back to local assets.');
      return await _loadAllFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadAllFromLocalAssets() async {
    try {
      debugPrint('[SongRepository] 📁 Loading songs from local assets...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lmpi.json');
      final songs = await compute(_parseSongsFromList, localJsonString);
      debugPrint(
          '[SongRepository] ✅ Successfully loaded ${songs.length} songs from local assets (OFFLINE)');
      return SongDataResult(songs: songs, isOnline: false);
    } catch (assetError) {
      debugPrint('[SongRepository] ❌ Local asset loading failed: $assetError');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

  // ✅ EXISTING: Keep original method unchanged for compatibility
  Future<Song?> getSongByNumber(String songNumber) async {
    _logOperation('getSongByNumber', {'songNumber': songNumber}); // 🟢 NEW

    try {
      final songData = await getAllSongs();
      return songData.songs.firstWhere(
        (song) => song.number == songNumber,
        orElse: () => throw Exception('Song not found'),
      );
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      return null;
    }
  }

  // ✅ NEW: Method that returns song with online status
  Future<SongWithStatusResult> getSongByNumberWithStatus(
      String songNumber) async {
    _logOperation(
        'getSongByNumberWithStatus', {'songNumber': songNumber}); // 🟢 NEW

    try {
      debugPrint('[SongRepository] 🔍 Getting song $songNumber with status...');
      final songData = await getAllSongs();

      final song = songData.songs.firstWhere(
        (song) => song.number == songNumber,
        orElse: () => throw Exception('Song not found'),
      );

      debugPrint(
          '[SongRepository] ✅ Found song $songNumber (${songData.isOnline ? "ONLINE" : "OFFLINE"})');
      return SongWithStatusResult(song: song, isOnline: songData.isOnline);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to get song $songNumber: $e');
      // If song not found, still return the online status
      final songData = await getAllSongs();
      return SongWithStatusResult(song: null, isOnline: songData.isOnline);
    }
  }

  Future<void> addSong(Song song) async {
    _logOperation('addSong', {'songNumber': song.number}); // 🟢 NEW

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot add song');
    }
    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }
    try {
      final songData = song.toJson();
      final DatabaseReference ref = database.ref('songs/${song.number}');
      await ref.set(songData);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to add song: $e');
      rethrow;
    }
  }

  Future<void> updateSong(String originalSongNumber, Song updatedSong) async {
    _logOperation('updateSong', {
      'originalNumber': originalSongNumber,
      'newNumber': updatedSong.number
    }); // 🟢 NEW

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot update song');
    }
    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }
    try {
      if (originalSongNumber != updatedSong.number) {
        await deleteSong(originalSongNumber);
        await addSong(updatedSong);
        return;
      }
      final songData = updatedSong.toJson();
      final DatabaseReference ref = database.ref('songs/${updatedSong.number}');
      await ref.update(songData);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to update song: $e');
      rethrow;
    }
  }

  Future<void> deleteSong(String songNumber) async {
    _logOperation('deleteSong', {'songNumber': songNumber}); // 🟢 NEW

    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot delete song');
    }
    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }
    try {
      final DatabaseReference ref = database.ref('songs/$songNumber');
      await ref.remove();
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to delete song: $e');
      rethrow;
    }
  }

  // 🟢 NEW: Get performance metrics (for debugging)
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'firebaseUrl': _firebaseUrl,
    };
  }

  // 🟢 NEW: Get connectivity summary
  Map<String, dynamic> getConnectivitySummary() {
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
    };
  }

  // ✅ PHASE 1.3: Collection-based reading configuration methods
  
  /// Set user role for access control
  void setUserRole(String? userRole) {
    _currentUserRole = userRole;
    debugPrint('[SongRepository] 👤 User role set to: ${userRole ?? 'null'}');
  }

  /// Set collection filter (null for all collections)
  void setCollectionFilter(String? collectionId) {
    _currentCollectionFilter = collectionId;
    debugPrint('[SongRepository] 📚 Collection filter set to: ${collectionId ?? 'all'}');
  }

  /// Enable or disable collection-first reading
  void setPreferCollectionRead(bool prefer) {
    _preferCollectionRead = prefer;
    debugPrint('[SongRepository] ⚙️ Collection-first reading: ${prefer ? 'ENABLED' : 'DISABLED'}');
  }

  /// Get songs filtered by collection with access control
  Future<SongDataResult> getSongsByCollection(String collectionId, {String? userRole}) async {
    _logOperation('getSongsByCollection', {
      'collectionId': collectionId,
      'userRole': userRole,
    });

    // Temporarily set collection filter
    final originalFilter = _currentCollectionFilter;
    final originalRole = _currentUserRole;
    
    _currentCollectionFilter = collectionId;
    if (userRole != null) _currentUserRole = userRole;

    try {
      final result = await _getAllSongsFromCollections();
      return result;
    } finally {
      // Restore original settings
      _currentCollectionFilter = originalFilter;
      _currentUserRole = originalRole;
    }
  }

  /// Get all accessible collections for current user
  Future<CollectionDataResult> getAccessibleCollections({String? userRole}) async {
    return await _collectionRepository.getCollectionsForUser(
      userRole: userRole ?? _currentUserRole,
      includeInactive: false,
    );
  }

  /// Force refresh from legacy endpoint (bypass collection-read)
  Future<SongDataResult> getAllSongsFromLegacy() async {
    return await _getAllSongsFromLegacy();
  }

  /// Force refresh from collections (bypass legacy fallback)
  Future<SongDataResult> getAllSongsFromCollections() async {
    return await _getAllSongsFromCollections();
  }

  /// Get detailed reading strategy status
  Map<String, dynamic> getReadingStrategy() {
    return {
      'preferCollectionRead': _preferCollectionRead,
      'currentCollectionFilter': _currentCollectionFilter,
      'currentUserRole': _currentUserRole,
      'collectionRepositoryAvailable': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Test both reading methods and compare results (for debugging)
  Future<Map<String, dynamic>> testDualReadComparison() async {
    _logOperation('testDualReadComparison');

    debugPrint('[SongRepository] 🔬 Testing dual-read comparison...');

    final stopwatch = Stopwatch()..start();

    try {
      // Test legacy read
      final legacyStart = stopwatch.elapsedMilliseconds;
      final legacyResult = await _getAllSongsFromLegacy();
      final legacyTime = stopwatch.elapsedMilliseconds - legacyStart;

      // Test collection read
      final collectionStart = stopwatch.elapsedMilliseconds;
      final collectionResult = await _getAllSongsFromCollections();
      final collectionTime = stopwatch.elapsedMilliseconds - collectionStart;

      stopwatch.stop();

      final comparison = {
        'legacy': {
          'songCount': legacyResult.songs.length,
          'isOnline': legacyResult.isOnline,
          'loadTimeMs': legacyTime,
          'hasData': legacyResult.songs.isNotEmpty,
        },
        'collections': {
          'songCount': collectionResult.songs.length,
          'isOnline': collectionResult.isOnline,
          'loadTimeMs': collectionTime,
          'hasData': collectionResult.songs.isNotEmpty,
        },
        'performance': {
          'totalTimeMs': stopwatch.elapsedMilliseconds,
          'fasterMethod': legacyTime < collectionTime ? 'legacy' : 'collections',
          'timeDifferenceMs': (legacyTime - collectionTime).abs(),
        },
        'recommendation': _getPerformanceRecommendation(legacyResult, collectionResult, legacyTime, collectionTime),
      };

      debugPrint('[SongRepository] 📊 Dual-read comparison completed: ${comparison['recommendation']}');
      return comparison;

    } catch (e) {
      debugPrint('[SongRepository] ❌ Dual-read comparison failed: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get performance-based recommendation
  String _getPerformanceRecommendation(
    SongDataResult legacyResult,
    SongDataResult collectionResult,
    int legacyTime,
    int collectionTime,
  ) {
    if (!legacyResult.isOnline && !collectionResult.isOnline) {
      return 'Both methods offline - use local assets';
    }

    if (collectionResult.songs.isNotEmpty && legacyResult.songs.isEmpty) {
      return 'Use collections - legacy has no data';
    }

    if (legacyResult.songs.isNotEmpty && collectionResult.songs.isEmpty) {
      return 'Use legacy - collections have no data';
    }

    if (collectionResult.songs.isNotEmpty && legacyResult.songs.isNotEmpty) {
      if (collectionTime < legacyTime * 1.2) { // Collections is significantly faster or close
        return 'Use collections - better performance and access control';
      } else {
        return 'Use legacy - significantly faster, consider optimizing collections';
      }
    }

    return 'Both methods have issues - investigate further';
  }
}
