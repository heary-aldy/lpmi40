// TODO Implement this library.

class Verse {
  final String number;
  final String lyrics;

  Verse({
    required this.number,
    required this.lyrics,
  });

  // Create Verse from JSON (local assets)
  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'],
      lyrics: json['lyrics'],
    );
  }

  // Create Verse from Firestore document
  factory Verse.fromFirestore(Map<String, dynamic> data) {
    return Verse(
      number: data['verseNumber'] ?? '',
      lyrics: data['lyrics'] ?? '',
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'verseNumber': number,
      'lyrics': lyrics,
    };
  }

  // Helper methods
  String get cleanLyrics => lyrics.trim();

  bool get isEmpty => lyrics.trim().isEmpty;

  int get wordCount => lyrics.trim().split(RegExp(r'\s+')).length;

  // Copy method for updates
  Verse copyWith({
    String? number,
    String? lyrics,
  }) {
    return Verse(
      number: number ?? this.number,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Verse && other.number == number && other.lyrics == lyrics;
  }

  @override
  int get hashCode => number.hashCode ^ lyrics.hashCode;

  @override
  String toString() {
    return 'Verse(number: $number, lyrics: ${lyrics.length > 50 ? '${lyrics.substring(0, 50)}...' : lyrics})';
  }
}
