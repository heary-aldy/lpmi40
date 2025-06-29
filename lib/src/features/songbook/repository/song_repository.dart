import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongDataResult {
  final List<Song> songs;
  final bool isOnline;
  SongDataResult({required this.songs, required this.isOnline});
}

List<Song> _parseSongsFromFirebaseMap(String jsonString) {
  final Map<String, dynamic>? jsonMap = json.decode(jsonString);
  if (jsonMap == null) return [];
  return jsonMap.values
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

List<Song> _parseSongsFromList(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
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

  Future<SongDataResult> getSongs() async {
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading from local assets');
      return await _loadFromLocalAssets();
    }
    try {
      final database = _database;
      if (database == null) throw Exception('Could not get database instance');
      final ref = database.ref('songs');
      final event = await ref.once();
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        String jsonString;
        List<Song> songs;
        if (data is Map) {
          jsonString = json.encode(data);
          songs = await compute(_parseSongsFromFirebaseMap, jsonString);
        } else if (data is List) {
          jsonString = json.encode(data);
          songs = await compute(_parseSongsFromList, jsonString);
        } else {
          throw Exception(
              'Unexpected data structure from Firebase: ${data.runtimeType}');
        }
        if (songs.isNotEmpty) {
          songs.sort((a, b) => (int.tryParse(a.number) ?? 0)
              .compareTo(int.tryParse(b.number) ?? 0));
          return SongDataResult(songs: songs, isOnline: true);
        } else {
          throw Exception('No songs found in Firebase data');
        }
      } else {
        throw Exception('No data found at Firebase path: songs');
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Firebase fetch failed: $e');
      debugPrint('[SongRepository] 📱 Falling back to local assets...');
      return await _loadFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadFromLocalAssets() async {
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

  Future<Map<String, String>> getVerseOfTheDay() async {
    try {
      final songData = await getSongs();
      if (songData.songs.isEmpty) {
        return {'text': 'No songs found.', 'location': 'LPMI Songbook'};
      }
      final songsWithVerses =
          songData.songs.where((s) => s.verses.isNotEmpty).toList();
      if (songsWithVerses.isEmpty) {
        return {'text': 'No verses found.', 'location': 'LPMI Songbook'};
      }
      final randomSong =
          songsWithVerses[Random().nextInt(songsWithVerses.length)];
      final randomVerse =
          randomSong.verses[Random().nextInt(randomSong.verses.length)];
      return {
        'text': randomVerse.lyrics,
        'location': '${randomSong.title} (No. ${randomSong.number})'
      };
    } catch (e) {
      return {'text': 'Could not load a verse.', 'location': 'Error'};
    }
  }

  Future<void> addSong(Song song) async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = _database;
    if (database == null) throw Exception('Could not get database instance');
    try {
      final ref = database.ref('songs');
      final snapshot = await ref.orderByKey().limitToLast(1).once();
      int nextIndex = 0;
      if (snapshot.snapshot.exists && snapshot.snapshot.value is Map) {
        final lastKey = (snapshot.snapshot.value as Map).keys.first;
        nextIndex = (int.tryParse(lastKey) ?? -1) + 1;
      }
      await ref.child(nextIndex.toString()).set(song.toJson());
    } catch (e) {
      debugPrint('❌ Failed to add song: $e');
      rethrow;
    }
  }

  Future<void> updateSong(String songNumber, Song song) async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = _database;
    if (database == null) throw Exception('Could not get database instance');
    try {
      final ref = database.ref('songs');
      final event =
          await ref.orderByChild('song_number').equalTo(songNumber).once();
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final keyToUpdate = (event.snapshot.value as Map).keys.first;
        await ref.child(keyToUpdate).update(song.toJson());
      } else {
        throw Exception('Song with number $songNumber not found for update.');
      }
    } catch (e) {
      debugPrint('❌ Failed to update song: $e');
      rethrow;
    }
  }

  Future<void> deleteSong(String songNumber) async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = _database;
    if (database == null) throw Exception('Could not get database instance');
    try {
      final ref = database.ref('songs');
      final event =
          await ref.orderByChild('song_number').equalTo(songNumber).once();
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final keyToDelete = (event.snapshot.value as Map).keys.first;
        await ref.child(keyToDelete).remove();
      } else {
        throw Exception('Song with number $songNumber not found for deletion.');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete song: $e');
      rethrow;
    }
  }

  // ✅ FIX: Added the missing helper and debug methods

  Future<void> uploadLocalSongsToFirebase() async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = _database;
    if (database == null) throw Exception('Could not get database instance');
    try {
      debugPrint(
          '[SongRepository] 🚀 Starting upload of local songs to Firebase...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final List<dynamic> songsArray = json.decode(localJsonString);
      final Map<String, dynamic> songsMap = {};
      for (int i = 0; i < songsArray.length; i++) {
        songsMap[i.toString()] = songsArray[i];
      }
      final ref = database.ref('songs');
      await ref.set(songsMap);
      debugPrint(
          '[SongRepository] ✅ Successfully uploaded ${songsArray.length} songs to Firebase');
    } catch (e) {
      debugPrint('❌ Failed to upload songs to Firebase: $e');
      rethrow;
    }
  }

  Future<bool> testFirebaseConnection() async {
    if (!_isFirebaseInitialized) return false;
    final database = _database;
    if (database == null) return false;
    try {
      final ref = database.ref('.info/connected');
      final event = await ref.once();
      return event.snapshot.value as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }

  Future<void> clearFirebaseSongs() async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final database = _database;
    if (database == null) throw Exception('Could not get database instance');
    try {
      final ref = database.ref('songs');
      await ref.remove();
      debugPrint('[SongRepository] ✅ Successfully cleared Firebase songs');
    } catch (e) {
      debugPrint('❌ Failed to clear Firebase songs: $e');
      rethrow;
    }
  }
}
