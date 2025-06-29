import 'dart:convert';
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

// This function parses the MAP structure from your live Firebase database
List<Song> _parseSongsFromMap(String jsonString) {
  final Map<String, dynamic>? jsonMap = json.decode(jsonString);
  if (jsonMap == null) return [];

  // Convert the map's values to a list of Song objects
  return jsonMap.values
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

// This function parses the LIST structure from your local lpmi.json
List<Song> _parseSongsFromList(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

class SongRepository {
  // Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database =>
      _isFirebaseInitialized ? FirebaseDatabase.instance : null;

  Future<SongDataResult> getSongs() async {
    // If Firebase is not initialized, load from local assets directly
    if (!_isFirebaseInitialized) {
      debugPrint(
          '[SongRepository] Firebase not initialized, loading from local assets');
      return await _loadFromLocalAssets();
    }

    try {
      // Use Firebase SDK instead of direct HTTP calls
      final DatabaseReference ref =
          _database!.ref('songs'); // Adjust path as needed
      final DatabaseEvent event = await ref.once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value;
        String jsonString;

        if (data is Map) {
          // If data is a Map, convert it to JSON string
          jsonString = json.encode(data);
          debugPrint(
              '[SongRepository] Firebase fetch successful. Using MAP parser for online data.');
          final songs = await compute(_parseSongsFromMap, jsonString);
          return SongDataResult(songs: songs, isOnline: true);
        } else if (data is List) {
          // If data is a List, convert it to JSON string
          jsonString = json.encode(data);
          debugPrint(
              '[SongRepository] Firebase fetch successful. Using LIST parser for online data.');
          final songs = await compute(_parseSongsFromList, jsonString);
          return SongDataResult(songs: songs, isOnline: true);
        } else {
          throw Exception('Unexpected data structure from Firebase');
        }
      } else {
        throw Exception('No data found in Firebase');
      }
    } catch (e) {
      debugPrint(
          '[SongRepository] Firebase fetch failed, loading from local assets. Reason: $e');
      return await _loadFromLocalAssets();
    }
  }

  Future<SongDataResult> _loadFromLocalAssets() async {
    try {
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      // Use the List parser for the local file (assuming local file is a list)
      final songs = await compute(_parseSongsFromList, localJsonString);
      return SongDataResult(songs: songs, isOnline: false);
    } catch (assetError) {
      debugPrint('[SongRepository] Local asset loading failed: $assetError');
      // Return empty result if both online and offline loading fail
      return SongDataResult(songs: [], isOnline: false);
    }
  }
}
