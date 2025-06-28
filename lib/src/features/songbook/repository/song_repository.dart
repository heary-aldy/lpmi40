import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class SongRepository {
  /// Fetches songs from Firebase Realtime Database with a local JSON fallback.
  Future<List<Song>> getSongs() async {
    try {
      final ref = FirebaseDatabase.instance.ref('songs');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final List<Song> loadedSongs = [];
        for (final child in snapshot.children) {
          final songMap = Map<String, dynamic>.from(child.value as Map);
          loadedSongs.add(Song.fromJson(songMap));
        }
        return loadedSongs;
      } else {
        // If Firebase is empty, throw an exception to trigger the catch block
        throw Exception('No data found in Firebase');
      }
    } catch (e) {
      // If Firebase fails (offline on first launch, etc.), load from local assets
      print('Firebase failed, loading from local assets: $e');
      final jsonString = await rootBundle.loadString('assets/data/lpmi.json');
      // In your local JSON, the data is a Map, not an array.
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final List<Song> loadedSongs = [];
      jsonMap.forEach((key, value) {
        loadedSongs.add(Song.fromJson(value));
      });
      return loadedSongs;
    }
  }
}
