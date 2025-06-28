class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  bool isFavorite; // This is a runtime state, not from JSON

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.isFavorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    var verseList = json['verses'] as List;
    List<Verse> verses = verseList.map((i) => Verse.fromJson(i)).toList();

    return Song(
      number: json['song_number'] ?? '',
      title: json['song_title'] ?? '',
      verses: verses,
    );
  }
}

class Verse {
  final String number;
  final String lyrics;

  Verse({
    required this.number,
    required this.lyrics,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'] ?? '',
      lyrics: json['lyrics'] ?? '',
    );
  }
}
