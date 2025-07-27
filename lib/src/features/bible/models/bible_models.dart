// 📖 Bible Data Models
// Core models for Bible content management and access control

import 'package:firebase_database/firebase_database.dart';

/// Represents a complete Bible book with metadata and chapters
class BibleBook {
  final String id; // "01_kejadian", "40_matius"
  final String name; // "Kejadian", "Matius"
  final String englishName; // "Genesis", "Matthew"
  final String abbreviation; // "Kej", "Mat"
  final String testament; // "old" or "new"
  final int bookNumber; // 1-66
  final int totalChapters; // Number of chapters in book
  final String collectionId; // Collection this book belongs to
  final String language; // "malay" or "indonesian"
  final String
      translation; // "TB" (Terjemahan Baru), "BIS" (Bahasa Indonesia Sehari-hari)
  final Map<String, dynamic>? metadata; // Additional book information
  final DateTime createdAt;
  final DateTime updatedAt;

  BibleBook({
    required this.id,
    required this.name,
    required this.englishName,
    required this.abbreviation,
    required this.testament,
    required this.bookNumber,
    required this.totalChapters,
    required this.collectionId,
    required this.language,
    required this.translation,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BibleBook.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return BibleBook(
      id: snapshot.key!,
      name: data['name'] ?? '',
      englishName: data['englishName'] ?? '',
      abbreviation: data['abbreviation'] ?? '',
      testament: data['testament'] ?? 'old',
      bookNumber: data['bookNumber'] ?? 1,
      totalChapters: data['totalChapters'] ?? 1,
      collectionId: data['collectionId'] ?? '',
      language: data['language'] ?? 'malay',
      translation: data['translation'] ?? 'TB',
      metadata: data['metadata'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Create from map data
  factory BibleBook.fromMap(Map<String, dynamic> data) {
    return BibleBook(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      englishName: data['englishName'] ?? '',
      abbreviation: data['abbreviation'] ?? '',
      testament: data['testament'] ?? 'old',
      bookNumber: data['bookNumber'] ?? 1,
      totalChapters: data['totalChapters'] ?? 1,
      collectionId: data['collectionId'] ?? '',
      language: data['language'] ?? 'malay',
      translation: data['translation'] ?? 'TB',
      metadata: data['metadata'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'englishName': englishName,
      'abbreviation': abbreviation,
      'testament': testament,
      'bookNumber': bookNumber,
      'totalChapters': totalChapters,
      'collectionId': collectionId,
      'language': language,
      'translation': translation,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get display name with chapter count
  String get displayName => '$name ($totalChapters pasal)';

  /// Check if this is Old Testament book
  bool get isOldTestament => testament == 'old';

  /// Check if this is New Testament book
  bool get isNewTestament => testament == 'new';
}

/// Represents a single chapter within a Bible book
class BibleChapter {
  final String id; // "01_kejadian_001", "40_matius_028"
  final String bookId; // "01_kejadian"
  final String bookName; // "Kejadian"
  final int chapterNumber; // 1-150 (Psalms has 150 chapters)
  final int totalVerses; // Number of verses in chapter
  final List<BibleVerse> verses; // All verses in this chapter
  final String language; // "malay" or "indonesian"
  final String translation; // "TB", "BIS"
  final Map<String, dynamic>? metadata; // Chapter-specific metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  BibleChapter({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.totalVerses,
    required this.verses,
    required this.language,
    required this.translation,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BibleChapter.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Parse verses from the verses map
    List<BibleVerse> versesList = [];
    if (data['verses'] != null) {
      final versesMap = Map<String, dynamic>.from(data['verses']);
      versesMap.forEach((verseKey, verseData) {
        if (verseData is Map) {
          versesList.add(BibleVerse.fromMap(
              verseKey, Map<String, dynamic>.from(verseData)));
        }
      });

      // Sort verses by verse number
      versesList.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    }

    return BibleChapter(
      id: snapshot.key!,
      bookId: data['bookId'] ?? '',
      bookName: data['bookName'] ?? '',
      chapterNumber: data['chapterNumber'] ?? 1,
      totalVerses: data['totalVerses'] ?? 0,
      verses: versesList,
      language: data['language'] ?? 'malay',
      translation: data['translation'] ?? 'TB',
      metadata: data['metadata'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    Map<String, dynamic> versesMap = {};
    for (var verse in verses) {
      versesMap[verse.id] = verse.toMap();
    }

    return {
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'totalVerses': totalVerses,
      'verses': versesMap,
      'language': language,
      'translation': translation,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get chapter reference (e.g., "Kejadian 1")
  String get reference => '$bookName $chapterNumber';

  /// Get verse by number
  BibleVerse? getVerse(int verseNumber) {
    try {
      return verses.firstWhere((verse) => verse.verseNumber == verseNumber);
    } catch (e) {
      return null;
    }
  }

  /// Get verse range
  List<BibleVerse> getVerseRange(int startVerse, int endVerse) {
    return verses
        .where((verse) =>
            verse.verseNumber >= startVerse && verse.verseNumber <= endVerse)
        .toList();
  }
}

/// Represents a single Bible verse
class BibleVerse {
  final String id; // "001", "002", etc.
  final int verseNumber; // 1-176 (Psalm 119 has 176 verses)
  final String text; // The actual verse content
  final String cleanText; // Text without formatting/footnotes
  final List<String>? footnotes; // Optional footnotes
  final Map<String, String>? formatting; // Text formatting information
  final Map<String, dynamic>? metadata; // Additional verse data

  BibleVerse({
    String? id,
    required this.verseNumber,
    required this.text,
    String? cleanText,
    this.footnotes,
    this.formatting,
    this.metadata,
  })  : id = id ?? verseNumber.toString().padLeft(3, '0'),
        cleanText = cleanText ?? _cleanText(text);

  /// Create from Firebase map data
  factory BibleVerse.fromMap(String id, Map<String, dynamic> data) {
    List<String>? footnotesList;
    if (data['footnotes'] != null) {
      footnotesList = List<String>.from(data['footnotes']);
    }

    Map<String, String>? formattingMap;
    if (data['formatting'] != null) {
      formattingMap = Map<String, String>.from(data['formatting']);
    }

    return BibleVerse(
      id: id,
      verseNumber: data['verseNumber'] ?? 1,
      text: data['text'] ?? '',
      cleanText: data['cleanText'],
      footnotes: footnotesList,
      formatting: formattingMap,
      metadata: data['metadata'],
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'verseNumber': verseNumber,
      'text': text,
      'cleanText': cleanText,
      'footnotes': footnotes,
      'formatting': formatting,
      'metadata': metadata,
    };
  }

  /// Clean text by removing formatting markers
  static String _cleanText(String text) {
    // Remove common formatting markers and footnotes
    return text
        .replaceAll(
            RegExp(r'\[\d+\]'), '') // Remove footnote markers [1], [2], etc.
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML-like tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Get verse reference with chapter (e.g., "Kejadian 1:1")
  String getReference(String bookName, int chapterNumber) {
    return '$bookName $chapterNumber:$verseNumber';
  }

  /// Get word count of the verse
  int get wordCount => cleanText.split(' ').length;

  /// Search for text within verse (case-insensitive)
  bool containsText(String searchText) {
    return cleanText.toLowerCase().contains(searchText.toLowerCase());
  }
}

/// Bible collection metadata and access control
class BibleCollection {
  final String id; // "malay_bible_tb", "indonesian_bible_bis"
  final String
      name; // "Alkitab Bahasa Malaysia (TB)", "Alkitab Bahasa Indonesia (BIS)"
  final String language; // "malay", "indonesian"
  final String translation; // "TB", "BIS", etc.
  final String description; // Collection description
  final bool isPremium; // Premium access required
  final List<String> availableBooks; // List of book IDs in this collection
  final Map<String, dynamic>? settings; // Collection-specific settings
  final DateTime createdAt;
  final DateTime updatedAt;

  BibleCollection({
    required this.id,
    required this.name,
    required this.language,
    required this.translation,
    required this.description,
    required this.isPremium,
    required this.availableBooks,
    this.settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BibleCollection.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    List<String> booksList = [];
    if (data['availableBooks'] != null) {
      booksList = List<String>.from(data['availableBooks']);
    }

    return BibleCollection(
      id: snapshot.key!,
      name: data['name'] ?? '',
      language: data['language'] ?? 'malay',
      translation: data['translation'] ?? 'TB',
      description: data['description'] ?? '',
      isPremium: data['isPremium'] ?? true,
      availableBooks: booksList,
      settings: data['settings'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Create from map data
  factory BibleCollection.fromMap(Map<String, dynamic> data) {
    List<String> booksList = [];
    if (data['availableBooks'] != null) {
      booksList = List<String>.from(data['availableBooks']);
    }

    return BibleCollection(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      language: data['language'] ?? 'malay',
      translation: data['translation'] ?? 'TB',
      description: data['description'] ?? '',
      isPremium: data['isPremium'] ?? true,
      availableBooks: booksList,
      settings: data['settings'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'language': language,
      'translation': translation,
      'description': description,
      'isPremium': isPremium,
      'availableBooks': availableBooks,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get total number of books in collection
  int get totalBooks => availableBooks.length;

  /// Check if a specific book is available
  bool hasBook(String bookId) => availableBooks.contains(bookId);
}

/// Bible search result
class BibleSearchResult {
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final BibleVerse verse;
  final String query;
  final List<int> matchPositions; // Character positions of matches in text
  final String? collectionId; // Collection where this result was found
  final String? translation; // Translation used

  BibleSearchResult({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verse,
    required this.query,
    required this.matchPositions,
    this.collectionId,
    this.translation,
  });

  /// Get full verse reference
  String get reference => verse.getReference(bookName, chapterNumber);

  /// Get highlighted text with search matches
  String get highlightedText {
    if (matchPositions.isEmpty) return verse.cleanText;

    String highlighted = verse.cleanText;
    final queryLower = query.toLowerCase();
    final textLower = verse.cleanText.toLowerCase();

    // Find all occurrences and mark them
    int lastIndex = 0;
    String result = '';

    while (lastIndex < textLower.length) {
      final index = textLower.indexOf(queryLower, lastIndex);
      if (index == -1) {
        result += highlighted.substring(lastIndex);
        break;
      }

      result += highlighted.substring(lastIndex, index);
      result += '**${highlighted.substring(index, index + query.length)}**';
      lastIndex = index + query.length;
    }

    return result;
  }
}

/// User Bible bookmark
class BibleBookmark {
  final String id;
  final String userId;
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final String? note; // User's personal note
  final List<String> tags; // Bookmark tags
  final DateTime createdAt;
  final DateTime updatedAt;

  BibleBookmark({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    this.note,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BibleBookmark.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    List<String> tagsList = [];
    if (data['tags'] != null) {
      tagsList = List<String>.from(data['tags']);
    }

    return BibleBookmark(
      id: snapshot.key!,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      bookName: data['bookName'] ?? '',
      chapterNumber: data['chapterNumber'] ?? 1,
      verseNumber: data['verseNumber'] ?? 1,
      verseText: data['verseText'] ?? '',
      note: data['note'],
      tags: tagsList,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'note': note,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get verse reference
  String get reference => '$bookName $chapterNumber:$verseNumber';

  /// Create bookmark ID from verse reference
  static String createId(String userId, String bookId, int chapter, int verse) {
    return '${userId}_${bookId}_${chapter}_$verse';
  }
}

/// Bible reading preferences
class BiblePreferences {
  final String userId;
  final String preferredTranslation; // "TB", "BIS"
  final String preferredLanguage; // "malay", "indonesian"
  final double fontSize; // Font size multiplier (0.8 - 2.0)
  final String fontFamily; // Font family name
  final bool showVerseNumbers; // Show verse numbers in text
  final bool enableNightMode; // Dark mode for reading
  final Map<String, dynamic>? customSettings; // Additional user settings
  final DateTime updatedAt;

  BiblePreferences({
    required this.userId,
    this.preferredTranslation = 'TB',
    this.preferredLanguage = 'malay',
    this.fontSize = 1.0,
    this.fontFamily = 'Default',
    this.showVerseNumbers = true,
    this.enableNightMode = false,
    this.customSettings,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Create from Firebase snapshot
  factory BiblePreferences.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return BiblePreferences(
      userId: snapshot.key!,
      preferredTranslation: data['preferredTranslation'] ?? 'TB',
      preferredLanguage: data['preferredLanguage'] ?? 'malay',
      fontSize: (data['fontSize'] ?? 1.0).toDouble(),
      fontFamily: data['fontFamily'] ?? 'Default',
      showVerseNumbers: data['showVerseNumbers'] ?? true,
      enableNightMode: data['enableNightMode'] ?? false,
      customSettings: data['customSettings'],
      updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'preferredTranslation': preferredTranslation,
      'preferredLanguage': preferredLanguage,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'showVerseNumbers': showVerseNumbers,
      'enableNightMode': enableNightMode,
      'customSettings': customSettings,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create copy with updated values
  BiblePreferences copyWith({
    String? preferredTranslation,
    String? preferredLanguage,
    double? fontSize,
    String? fontFamily,
    bool? showVerseNumbers,
    bool? enableNightMode,
    Map<String, dynamic>? customSettings,
  }) {
    return BiblePreferences(
      userId: userId,
      preferredTranslation: preferredTranslation ?? this.preferredTranslation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      enableNightMode: enableNightMode ?? this.enableNightMode,
      customSettings: customSettings ?? this.customSettings,
      updatedAt: DateTime.now(),
    );
  }
}
