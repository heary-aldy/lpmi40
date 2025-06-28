import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  // Your Firebase Database URL. The .json suffix is required for the REST API.
  final String _firebaseUrl = 'https://lmpi-c5c5c.firebaseio.com/';

  Future<SongDataResult> getSongs() async {
    try {
      final response = await http.get(Uri.parse(_firebaseUrl));

      if (response.statusCode == 200 &&
          response.body != 'null' &&
          response.body.isNotEmpty) {
        print(
            '[SongRepository] Firebase fetch successful. Using MAP parser for online data.');
        // Use the Map parser for the live data from Firebase
        final songs = await compute(_parseSongsFromMap, response.body);
        return SongDataResult(songs: songs, isOnline: true);
      } else {
        throw Exception('Server returned an error or empty data.');
      }
    } catch (e) {
      print(
          '[SongRepository] Firebase fetch failed, loading from local assets. Reason: $e');
      // If anything fails, use the local backup file
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      // Use the List parser for the local file
      final songs = await compute(_parseSongsFromList, localJsonString);
      return SongDataResult(songs: songs, isOnline: false);
    }
  }
}
