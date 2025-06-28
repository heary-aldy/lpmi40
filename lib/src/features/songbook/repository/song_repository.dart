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
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final songMap = Map<String, dynamic>.from(value);
          loadedSongs.add(Song.fromJson(songMap));
        });
        return loadedSongs;
      } else {
        throw Exception('No data found in Firebase');
      }
    } catch (e) {
      // THIS IS THE CORRECTED OFFLINE FALLBACK LOGIC
      print('Firebase failed, loading from local assets: $e');
      final jsonString = await rootBundle.loadString('assets/data/lpmi.json');

      // Correctly decode the JSON as a List
      final List<dynamic> jsonList = json.decode(jsonString);

      // Map the list of dynamic objects into a list of Song objects
      final List<Song> loadedSongs = jsonList.map((data) {
        return Song.fromJson(data as Map<String, dynamic>);
      }).toList();

      return loadedSongs;
    }
  }
}
