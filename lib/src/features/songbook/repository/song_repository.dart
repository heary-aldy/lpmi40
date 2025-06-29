import 'dart:convert';
import 'dart:math'; // Added for random number generation
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// A wrapper class to hold the fetch result and its status
class SongDataResult {
  final List<Song> songs;
  final bool isOnline;

  SongDataResult({required this.songs, required this.isOnline});
}

// --- PARSING FUNCTIONS ---
// These must be top-level functions to be used with the 'compute' isolate.

// This function parses the MAP structure from Firebase database
List<Song> _parseSongsFromFirebaseMap(String jsonString) {
  final Map<String, dynamic>? jsonMap = json.decode(jsonString);
  if (jsonMap == null) return [];

  // Firebase stores as Map<String, Map<String, dynamic>>
  return jsonMap.values
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

// This function parses the LIST structure from local lpmi.json
List<Song> _parseSongsFromList(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

class SongRepository {
  // ✅ CORRECT: Use the root database URL (without /songs path)
  static const String _firebaseUrl =
      'https://lmpi-c5c5c-default-rtdb.firebaseio.com/';

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ CORRECT: Use default instance or specify root URL only
  FirebaseDatabase? get _database {
    if (!_isFirebaseInitialized) return null;

    try {
      // Option 1: Use default instance (recommended)
      return FirebaseDatabase.instance;
    } catch (e) {
      debugPrint('[SongRepository] Error getting database instance: $e');
      return null;
    }
  }

  Future<SongDataResult> getSongs() async {
    // If Firebase is not initialized, load from local assets directly
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading from local assets');
      return await _loadFromLocalAssets();
    }

    try {
      debugPrint(
          '[SongRepository] Attempting to fetch from Firebase: $_firebaseUrl');

      final database = _database;
      if (database == null) {
        throw Exception('Could not get database instance');
      }

      final DatabaseReference ref = database.ref('songs');
      final DatabaseEvent event = await ref.once();

      debugPrint(
          '[SongRepository] Firebase response - exists: ${event.snapshot.exists}');

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        debugPrint('[SongRepository] Firebase data type: ${data.runtimeType}');

        String jsonString;
        List<Song> songs;

        if (data is Map) {
          jsonString = json.encode(data);
          debugPrint(
              '[SongRepository] Firebase fetch successful. Parsing MAP data with ${(data).length} items.');
          songs = await compute(_parseSongsFromFirebaseMap, jsonString);
        } else if (data is List) {
          jsonString = json.encode(data);
          debugPrint(
              '[SongRepository] Firebase fetch successful. Parsing LIST data with ${(data).length} items.');
          songs = await compute(_parseSongsFromList, jsonString);
        } else {
          throw Exception(
              'Unexpected data structure from Firebase: ${data.runtimeType}');
        }

        if (songs.isNotEmpty) {
          debugPrint(
              '[SongRepository] ✅ Successfully loaded ${songs.length} songs from Firebase');
          songs.sort((a, b) => (int.tryParse(a.number) ?? 0)
              .compareTo(int.tryParse(b.number) ?? 0));
          return SongDataResult(songs: songs, isOnline: true);
        } else {
          throw Exception('No songs found in Firebase data');
        }
      } else {
        throw Exception(
            'No data found at Firebase path: songs (database may be empty)');
      }
    } catch (e) {
      debugPrint('[SongRepository] ❌ Firebase fetch failed: $e');
      debugPrint('[SongRepository] 📱 Falling back to local assets...');
      return await _loadFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadFromLocalAssets() async {
    try {
      debugPrint('[SongRepository] Loading from local assets...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final songs = await compute(_parseSongsFromList, localJsonString);
      debugPrint(
          '[SongRepository] ✅ Successfully loaded ${songs.length} songs from local assets');
      return SongDataResult(songs: songs, isOnline: false);
    } catch (assetError) {
      debugPrint('[SongRepository] ❌ Local asset loading failed: $assetError');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

  // --- NEW METHOD ---
  // This method gets a random verse from a random song for the dashboard.
  Future<Map<String, String>> getVerseOfTheDay() async {
    try {
      final songData = await getSongs();
      if (songData.songs.isEmpty) {
        return {
          'text': 'No songs found in the database.',
          'location': 'LPMI Songbook',
        };
      }
      final songsWithVerses =
          songData.songs.where((s) => s.verses.isNotEmpty).toList();
      if (songsWithVerses.isEmpty) {
        return {
          'text': 'Songs are available, but they have no verses.',
          'location': 'LPMI Songbook',
        };
      }
      final randomSong =
          songsWithVerses[Random().nextInt(songsWithVerses.length)];
      final randomVerse =
          randomSong.verses[Random().nextInt(randomSong.verses.length)];

      return {
        'text': randomVerse.lyrics,
        'location': '${randomSong.title} (No. ${randomSong.number})',
      };
    } catch (e) {
      return {
        'text': 'Could not load a verse at this time.',
        'location': 'Error',
      };
    }
  }

  // Helper method to upload local songs to Firebase (for development)
  Future<void> uploadLocalSongsToFirebase() async {
    // ... (This method remains unchanged)
    if (!_isFirebaseInitialized) {
      debugPrint('[SongRepository] Firebase not initialized, cannot upload');
      throw Exception('Firebase not initialized');
    }

    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    try {
      debugPrint(
          '[SongRepository] 🚀 Starting upload of local songs to Firebase...');
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final List<dynamic> songsArray = json.decode(localJsonString);
      debugPrint(
          '[SongRepository] 📖 Loaded ${songsArray.length} songs from local file');
      final Map<String, dynamic> songsMap = {};
      for (int i = 0; i < songsArray.length; i++) {
        final song = songsArray[i];
        songsMap[i.toString()] = song;
      }
      final DatabaseReference ref = database.ref('songs');
      await ref.set(songsMap);
      debugPrint(
          '[SongRepository] ✅ Successfully uploaded ${songsArray.length} songs to Firebase');
      debugPrint('[SongRepository] 🔗 Data available at: ${_firebaseUrl}songs');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to upload songs to Firebase: $e');
      rethrow;
    }
  }

  // Method to check Firebase connection
  Future<bool> testFirebaseConnection() async {
    // ... (This method remains unchanged)
    if (!_isFirebaseInitialized) {
      debugPrint('[SongRepository] Firebase not initialized');
      return false;
    }

    final database = _database;
    if (database == null) {
      debugPrint('[SongRepository] Could not get database instance');
      return false;
    }

    try {
      debugPrint('[SongRepository] Testing connection to Firebase...');
      final DatabaseReference ref = database.ref('.info/connected');
      final DatabaseEvent event = await ref.once();
      final isConnected = event.snapshot.value as bool? ?? false;
      debugPrint(
          '[SongRepository] Firebase connection test result: $isConnected');
      if (isConnected) {
        final songsRef = database.ref('songs');
        final songsEvent = await songsRef.once();
        debugPrint(
            '[SongRepository] Songs path exists: ${songsEvent.snapshot.exists}');
        if (songsEvent.snapshot.exists) {
          final data = songsEvent.snapshot.value;
          if (data is Map) {
            debugPrint(
                '[SongRepository] Found ${(data).length} songs in database');
          }
        }
      }
      return isConnected;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Firebase connection test failed: $e');
      return false;
    }
  }

  // Method to clear all songs from Firebase (for testing)
  Future<void> clearFirebaseSongs() async {
    // ... (This method remains unchanged)
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    final database = _database;
    if (database == null) {
      throw Exception('Could not get database instance');
    }

    try {
      debugPrint('[SongRepository] 🗑️ Clearing all songs from Firebase...');
      final DatabaseReference ref = database.ref('songs');
      await ref.remove();
      debugPrint('[SongRepository] ✅ Successfully cleared Firebase songs');
    } catch (e) {
      debugPrint('[SongRepository] ❌ Failed to clear Firebase songs: $e');
      rethrow;
    }
  }
}
