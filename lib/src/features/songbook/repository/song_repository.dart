import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

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

  // ✅ NEW: Paginated method for lazy loading in MainPage
  Future<PaginatedSongDataResult> getPaginatedSongs(
      {int pageSize = 30, String? startAfterKey}) async {
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading from local assets for pagination');
      final allSongs = await _loadAllFromLocalAssets();
      return PaginatedSongDataResult(
          songs: allSongs.songs, isOnline: false, hasMore: false);
    }

    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');

      Query query = database.ref('songs').orderByKey();
      final fetchSize = pageSize + 1;

      if (startAfterKey != null) {
        query = query.startAt(startAfterKey);
      }

      query = query.limitToFirst(fetchSize);
      final event = await query.once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        final songs =
            await compute(_parseSongsFromFirebaseMap, json.encode(data));

        if (startAfterKey != null && songs.isNotEmpty) {
          songs.removeAt(0);
        }

        final bool hasMore = songs.length > pageSize;
        if (hasMore) {
          songs.removeLast();
        }

        final String? lastKey = songs.isNotEmpty ? songs.last.number : null;

        return PaginatedSongDataResult(
            songs: songs, isOnline: true, hasMore: hasMore, lastKey: lastKey);
      } else {
        return PaginatedSongDataResult(
            songs: [], isOnline: true, hasMore: false);
      }
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Firebase pagination failed: $e. Falling back to all local songs.');
      final allSongs = await _loadAllFromLocalAssets();
      return PaginatedSongDataResult(
          songs: allSongs.songs, isOnline: false, hasMore: false);
    }
  }

  // ✅ ROBUST: Method to get ALL songs for Dashboard, Admin pages, etc.
  Future<SongDataResult> getAllSongs() async {
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading all from local assets');
      return await _loadAllFromLocalAssets();
    }

    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');

      final DatabaseReference ref = database.ref('songs');
      final DatabaseEvent event = await ref.once();

      if (event.snapshot.exists && event.snapshot.value != null) {
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
          return SongDataResult(songs: songs, isOnline: true);
        }
      }
      // If Firebase has no data, fall back to local
      return await _loadAllFromLocalAssets();
    } catch (e) {
      debugPrint(
          '[SongRepository] ❌ Firebase full fetch failed: $e. Falling back to local assets.');
      return await _loadAllFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadAllFromLocalAssets() async {
    try {
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final songs = await compute(_parseSongsFromList, localJsonString);
      return SongDataResult(songs: songs, isOnline: false);
    } catch (assetError) {
      debugPrint('[SongRepository] ❌ Local asset loading failed: $assetError');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

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

  // --- CRUD Operations (add, update, delete) are unchanged ---
  Future<void> addSong(Song song) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized - cannot add song');
    }
    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }
    try {
      final songData = song.toJson(); // Assuming you have a toJson method
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
      final songData = updatedSong.toJson(); // Assuming toJson method
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
