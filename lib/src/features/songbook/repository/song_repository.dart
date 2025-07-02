import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart'; // ✅ NEW: Import FirebaseService

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

  // ✅ FIXED: Proper connectivity detection using Firebase's .info/connected
  Future<bool> _checkRealConnectivity() async {
    if (!_isFirebaseInitialized) {
      debugPrint('[SongRepository] Firebase not initialized');
      return false;
    }

    try {
      debugPrint('[SongRepository] 🔍 Testing real Firebase connectivity...');

      final database = _database;
      if (database == null) {
        debugPrint('[SongRepository] ❌ Database instance is null');
        return false;
      }

      // ✅ Method 1: Use Firebase's .info/connected (most reliable)
      try {
        debugPrint('[SongRepository] 🌐 Checking .info/connected...');

        final DatabaseReference connectedRef = database.ref('.info/connected');
        final DatabaseEvent connectedEvent = await connectedRef.once().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[SongRepository] ⏰ .info/connected check timed out');
            throw Exception('Connected check timeout');
          },
        );

        final isConnected = connectedEvent.snapshot.value as bool? ?? false;

        if (isConnected) {
          debugPrint(
              '[SongRepository] ✅ Firebase .info/connected reports: ONLINE');
          return true;
        } else {
          debugPrint(
              '[SongRepository] ❌ Firebase .info/connected reports: OFFLINE');
          return false;
        }
      } catch (e) {
        debugPrint('[SongRepository] ⚠️ .info/connected check failed: $e');

        // ✅ Method 2: Fallback - Test actual data access without cache
        try {
          debugPrint(
              '[SongRepository] 🔄 Fallback: Testing direct data access...');

          // Use server timestamp to avoid cached data
          final DatabaseReference timestampRef =
              database.ref('.info/serverTimeOffset');
          final DatabaseEvent timestampEvent =
              await timestampRef.once().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('[SongRepository] ⏰ Server timestamp check timed out');
              throw Exception('Timestamp check timeout');
            },
          );

          // If we can read server info, we're connected
          final hasServerTime = timestampEvent.snapshot.exists;

          if (hasServerTime) {
            debugPrint('[SongRepository] ✅ Fallback connectivity test: ONLINE');
            return true;
          } else {
            debugPrint(
                '[SongRepository] ❌ Fallback connectivity test: OFFLINE');
            return false;
          }
        } catch (fallbackError) {
          debugPrint(
              '[SongRepository] ❌ Fallback connectivity test failed: $fallbackError');

          // ✅ Method 3: Last resort - Quick songs data test with stricter timeout
          try {
            debugPrint('[SongRepository] 🔄 Last resort: Quick songs test...');

            final DatabaseReference ref = database.ref('songs');
            final DatabaseEvent event =
                await ref.orderByKey().limitToFirst(1).once().timeout(
              const Duration(seconds: 3), // Very short timeout
              onTimeout: () {
                debugPrint(
                    '[SongRepository] ⏰ Quick songs test timed out - likely offline');
                throw Exception('Quick songs test timeout');
              },
            );

            // Even if we get data, check if it's likely cached by examining metadata
            final hasData =
                event.snapshot.exists && event.snapshot.value != null;

            if (hasData) {
              debugPrint(
                  '[SongRepository] ⚠️ Last resort test got data, but may be cached');
              // Consider this "likely online" but not definitive
              return true;
            } else {
              debugPrint(
                  '[SongRepository] ❌ Last resort test: No data available');
              return false;
            }
          } catch (lastResortError) {
            debugPrint(
                '[SongRepository] ❌ Last resort test failed: $lastResortError');
            return false;
          }
        }
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Critical connectivity check error: $e');

      // ✅ Final error handling with specific error type detection
      if (e.toString().contains('timeout')) {
        debugPrint(
            '[SongRepository] ⏰ Network timeout detected - assuming offline');
        return false;
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        debugPrint(
            '[SongRepository] 🔒 Permission denied - check Firebase rules');
        return false;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        debugPrint(
            '[SongRepository] 📡 Network connectivity issue - assuming offline');
        return false;
      } else {
        debugPrint(
            '[SongRepository] 🔧 Unknown Firebase error - assuming offline: $e');
        return false;
      }
    }
  }

  // ✅ UPDATED: Added proper connectivity detection
  Future<PaginatedSongDataResult> getPaginatedSongs(
      {int pageSize = 30, String? startAfterKey}) async {
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

  // ✅ FIXED: Complete rewrite with proper connectivity detection
  Future<SongDataResult> getAllSongs() async {
    debugPrint('[SongRepository] 🔍 Starting getAllSongs...');

    // Step 1: Check if Firebase is initialized
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading all from local assets');
      return await _loadAllFromLocalAssets();
    }

    // Step 2: Check real connectivity with timeout
    debugPrint('[SongRepository] 🌐 Checking real connectivity...');
    final isReallyOnline = await _checkRealConnectivity();

    if (!isReallyOnline) {
      debugPrint(
          '[SongRepository] ❌ No real connectivity detected, using local assets');
      return await _loadAllFromLocalAssets();
    }

    debugPrint(
        '[SongRepository] ✅ Real connectivity confirmed, attempting Firebase fetch...');

    try {
      final database = _database;
      if (database == null) {
        debugPrint('[SongRepository] ❌ Database instance is null');
        throw Exception('Could not get database instance');
      }

      final DatabaseReference ref = database.ref('songs');

      // ✅ NEW: Add timeout to Firebase call
      final DatabaseEvent event = await ref.once().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              '[SongRepository] ⏰ Firebase query timed out after 15 seconds');
          throw Exception('Firebase query timeout');
        },
      );

      if (event.snapshot.exists && event.snapshot.value != null) {
        debugPrint('[SongRepository] ✅ Firebase data received, parsing...');

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
              '[SongRepository] ✅ Successfully loaded ${songs.length} songs from Firebase (ONLINE)');
          return SongDataResult(songs: songs, isOnline: true);
        } else {
          debugPrint(
              '[SongRepository] ⚠️ Firebase returned empty data, falling back to local assets');
        }
      } else {
        debugPrint(
            '[SongRepository] ⚠️ Firebase snapshot does not exist, falling back to local assets');
      }

      // If we get here, Firebase didn't have data, use local assets
      return await _loadAllFromLocalAssets();
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Firebase full fetch failed: $e. Falling back to local assets.');
      return await _loadAllFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadAllFromLocalAssets() async {
    try {
      debugPrint('[SongRepository] 📁 Loading songs from local assets...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
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
}
