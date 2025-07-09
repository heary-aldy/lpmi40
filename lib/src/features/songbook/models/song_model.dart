class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  final String? audioUrl; // ✅ NEW: Maps from "url" field in JSON
  bool isFavorite; // This is a runtime state, not from JSON

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.audioUrl, // ✅ NEW: Optional parameter
    this.isFavorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    var verseList = json['verses'] as List;
    List<Verse> verses = verseList.map((i) => Verse.fromJson(i)).toList();

    return Song(
      number: json['song_number'] ?? '',
      title: json['song_title'] ?? '',
      verses: verses,
      audioUrl: json['url'], // ✅ FIXED: Now reads "url" field from your JSON
    );
  }

  // Method to convert a Song object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'song_number': number,
      'song_title': title,
      'verses': verses.map((v) => v.toJson()).toList(),
    };

    // ✅ NEW: Include audio URL in Firebase data (using "url" key for consistency)
    if (audioUrl != null && audioUrl!.isNotEmpty) {
      json['url'] = audioUrl;
    }

    return json;
  }

  // ✅ NEW: Convenience method to check if song has audio
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  // ✅ NEW: Backward compatibility getter (if UI code uses song.url)
  String? get url => audioUrl;

  // ✅ NEW: Method to create a copy with updated fields (useful for admin operations)
  Song copyWith({
    String? number,
    String? title,
    List<Verse>? verses,
    String? audioUrl,
    bool? isFavorite,
  }) {
    return Song(
      number: number ?? this.number,
      title: title ?? this.title,
      verses: verses ?? this.verses,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
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

  // Method to convert a Verse object into a JSON map for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
    };
  }
}
