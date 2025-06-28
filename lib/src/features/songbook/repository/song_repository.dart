import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for the 'compute' function
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// This function MUST be a top-level function (outside of any class)
// to be used with the 'compute' function.
List<Song> _parseSongs(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((data) => Song.fromJson(data as Map<String, dynamic>))
      .toList();
}

class SongRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<List<Song>> getSongs() async {
    try {
      final ref = _database.ref('songs');
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
      print('Firebase failed, loading from local assets: $e');
      final jsonString = await rootBundle.loadString('assets/data/lpmi.json');

      // --- CORRECTED: Use compute to parse in the background ---
      // This moves the heavy JSON parsing to a separate isolate,
      // preventing the UI from freezing.
      return compute(_parseSongs, jsonString);
    }
  }
}
