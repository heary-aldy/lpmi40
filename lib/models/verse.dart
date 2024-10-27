// verse.dart
class Verse {
  final String number;
  final String lyrics;

  Verse({
    required this.number,
    required this.lyrics,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['verse_number'],
      lyrics: json['lyrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verse_number': number,
      'lyrics': lyrics,
    };
  }
}
