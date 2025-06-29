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

  // Method to convert a Song object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'song_number': number,
      'song_title': title,
      'verses': verses.map((v) => v.toJson()).toList(),
    };
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

  // Method to convert a Verse object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
    };
  }
}
