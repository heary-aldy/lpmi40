import 'package:cloud_firestore/cloud_firestore.dart';
import 'verse.dart';

class Song {
  final String number;
  final String title;
  final List<Verse> verses;
  bool isFavorite;
  String? userNote;
  DateTime? lastViewed;
  DateTime? addedToFavoritesAt;
  int viewCount;

  Song({
    required this.number,
    required this.title,
    required this.verses,
    this.isFavorite = false,
    this.userNote,
    this.lastViewed,
    this.addedToFavoritesAt,
    this.viewCount = 0,
  });

  // Create Song from JSON (local assets)
  factory Song.fromJson(Map<String, dynamic> json) {
    var versesJson = json['verses'] as List;
    List<Verse> versesList =
        versesJson.map((verse) => Verse.fromJson(verse)).toList();

    return Song(
      number: json['song_number'],
      title: json['song_title'],
      verses: versesList,
      isFavorite: json['isFavorite'] ?? false,
      userNote: json['userNote'],
      lastViewed: json['lastViewed'] != null
          ? DateTime.parse(json['lastViewed'])
          : null,
      addedToFavoritesAt: json['addedToFavoritesAt'] != null
          ? DateTime.parse(json['addedToFavoritesAt'])
          : null,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  // Create Song from Firestore document
  factory Song.fromFirestore(DocumentSnapshot doc, List<Verse> verses) {
    final data = doc.data() as Map<String, dynamic>;

    return Song(
      number: data['songNumber'] ?? '',
      title: data['songTitle'] ?? '',
      verses: verses,
      isFavorite: data['isFavorite'] ?? false,
      userNote: data['userNote'],
      lastViewed: data['lastViewed']?.toDate(),
      addedToFavoritesAt: data['addedToFavoritesAt']?.toDate(),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'song_number': number,
      'song_title': title,
      'verses': verses.map((verse) => verse.toJson()).toList(),
      'isFavorite': isFavorite,
      'userNote': userNote,
      'lastViewed': lastViewed?.toIso8601String(),
      'addedToFavoritesAt': addedToFavoritesAt?.toIso8601String(),
      'viewCount': viewCount,
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'songNumber': number,
      'songTitle': title,
      'isFavorite': isFavorite,
      'userNote': userNote,
      'lastViewed': lastViewed != null ? Timestamp.fromDate(lastViewed!) : null,
      'addedToFavoritesAt': addedToFavoritesAt != null
          ? Timestamp.fromDate(addedToFavoritesAt!)
          : null,
      'viewCount': viewCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  void markAsViewed() {
    lastViewed = DateTime.now();
    viewCount++;
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
    if (isFavorite) {
      addedToFavoritesAt = DateTime.now();
    } else {
      addedToFavoritesAt = null;
      userNote = null; // Clear note when unfavorited
    }
  }

  void setNote(String? note) {
    userNote = note?.trim().isEmpty == true ? null : note?.trim();
  }

  // Get formatted lyrics for sharing
  String getFormattedLyrics() {
    return verses
        .map((verse) => '${verse.number}. ${verse.lyrics}')
        .join('\n\n');
  }

  // Get song display info
  String get displayTitle => '$number. $title';

  bool get hasNote => userNote != null && userNote!.isNotEmpty;

  String get searchableText =>
      '$number $title ${verses.map((v) => v.lyrics).join(' ')}';

  // Copy method for updates
  Song copyWith({
    String? number,
    String? title,
    List<Verse>? verses,
    bool? isFavorite,
    String? userNote,
    DateTime? lastViewed,
    DateTime? addedToFavoritesAt,
    int? viewCount,
  }) {
    return Song(
      number: number ?? this.number,
      title: title ?? this.title,
      verses: verses ?? this.verses,
      isFavorite: isFavorite ?? this.isFavorite,
      userNote: userNote ?? this.userNote,
      lastViewed: lastViewed ?? this.lastViewed,
      addedToFavoritesAt: addedToFavoritesAt ?? this.addedToFavoritesAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.number == number;
  }

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() {
    return 'Song(number: $number, title: $title, isFavorite: $isFavorite)';
  }
}
