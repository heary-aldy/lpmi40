// song.dart
import 'verse.dart';

class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  bool isFavorite;

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.isFavorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    // Parsing list of verses from JSON
    var versesJson = json['verses'] as List;
    List<Verse> versesList = versesJson.map((verse) => Verse.fromJson(verse)).toList();

    return Song(
      number: json['song_number'],
      title: json['song_title'],
      verses: versesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song_number': number,
      'song_title': title,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }
}
