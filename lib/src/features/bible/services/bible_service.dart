// 📖 Bible Service
// Business logic layer for Bible features with premium controls

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bible_models.dart';
import '../repository/bible_repository.dart';
import '../../../core/services/premium_service.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  late final BibleRepository _repository;
  late final PremiumService _premiumService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current state
  BibleCollection? _currentCollection;
  BibleBook? _currentBook;
  BibleChapter? _currentChapter;
  BiblePreferences? _userPreferences;

  // Stream controllers for UI updates
  final StreamController<BibleCollection?> _currentCollectionController =
      StreamController<BibleCollection?>.broadcast();
  final StreamController<BibleBook?> _currentBookController =
      StreamController<BibleBook?>.broadcast();
  final StreamController<BibleChapter?> _currentChapterController =
      StreamController<BibleChapter?>.broadcast();
  final StreamController<List<BibleBookmark>> _bookmarksController =
      StreamController<List<BibleBookmark>>.broadcast();

  // Initialization flag
  bool _isInitialized = false;

  /// Initialize the Bible service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _repository = BibleRepository();
      _premiumService = PremiumService();

      // Load user preferences if authenticated
      final user = _auth.currentUser;
      if (user != null) {
        _userPreferences = await _repository.getUserPreferences();
      }

      _isInitialized = true;
      debugPrint('✅ Bible service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Bible service: $e');
      rethrow;
    }
  }

  // Getters for streams
  Stream<BibleCollection?> get currentCollectionStream =>
      _currentCollectionController.stream;
  Stream<BibleBook?> get currentBookStream => _currentBookController.stream;
  Stream<BibleChapter?> get currentChapterStream =>
      _currentChapterController.stream;
  Stream<List<BibleBookmark>> get bookmarksStream =>
      _bookmarksController.stream;

  // Getters for current state
  BibleCollection? get currentCollection => _currentCollection;
  BibleBook? get currentBook => _currentBook;
  BibleChapter? get currentChapter => _currentChapter;
  BiblePreferences? get userPreferences => _userPreferences;

  /// Check if user has premium access for Bible features
  Future<bool> hasPremiumAccess() async {
    try {
      return await _premiumService.isPremium();
    } catch (e) {
      debugPrint('❌ Error checking premium access: $e');
      return false;
    }
  }

  /// Get available Bible collections
  Future<List<BibleCollection>> getAvailableCollections() async {
    await _ensureInitialized();

    try {
      debugPrint('📚 Fetching Bible collections');
      final collections = await _repository.getCollections();
      debugPrint('📚 Found ${collections.length} Bible collections');
      for (var collection in collections) {
        debugPrint('📚 Collection: ${collection.id} - ${collection.name}');
      }
      return collections;
    } catch (e) {
      debugPrint('❌ Error getting collections: $e');
      rethrow;
    }
  }

  /// Select a Bible collection
  Future<void> selectCollection(String collectionId) async {
    await _ensureInitialized();

    try {
      // Check premium access first
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for Bible access');
      }

      // Get all collections to find the selected one
      final collections = await _repository.getCollections();
      final collection = collections.firstWhere(
        (c) => c.id == collectionId,
        orElse: () =>
            throw BibleException('Collection not found: $collectionId'),
      );

      _currentCollection = collection;
      _currentCollectionController.add(_currentCollection);

      // Clear current book and chapter when collection changes
      _currentBook = null;
      _currentChapter = null;
      _currentBookController.add(null);
      _currentChapterController.add(null);

      debugPrint('✅ Selected Bible collection: ${collection.name}');
    } catch (e) {
      debugPrint('❌ Error selecting collection: $e');
      rethrow;
    }
  }

  /// Get books for current collection
  Future<List<BibleBook>> getBooksForCurrentCollection() async {
    await _ensureInitialized();

    if (_currentCollection == null) {
      throw BibleException('No collection selected');
    }

    try {
      return await _repository.getBooksForCollection(_currentCollection!.id);
    } catch (e) {
      debugPrint('❌ Error getting books for collection: $e');
      rethrow;
    }
  }

  /// Get all available books (requires premium)
  Future<List<BibleBook>> getAllBooks() async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for Bible access');
      }

      return await _repository.getAllBooks();
    } catch (e) {
      debugPrint('❌ Error getting all books: $e');
      rethrow;
    }
  }

  /// Select a Bible book
  Future<void> selectBook(String bookId) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for Bible access');
      }

      final book = await _repository.getBook(bookId);
      if (book == null) {
        throw BibleException('Book not found: $bookId');
      }

      _currentBook = book;
      _currentBookController.add(_currentBook);

      // Clear current chapter when book changes
      _currentChapter = null;
      _currentChapterController.add(null);

      debugPrint('✅ Selected Bible book: ${book.name}');
    } catch (e) {
      debugPrint('❌ Error selecting book: $e');
      rethrow;
    }
  }

  /// Select a chapter within current book
  Future<void> selectChapter(int chapterNumber) async {
    await _ensureInitialized();

    debugPrint('📖 Selecting chapter: $chapterNumber');

    if (_currentBook == null) {
      debugPrint('❌ No book selected');
      throw BibleException('No book selected');
    }

    debugPrint('📖 Current book: ${_currentBook!.name} (${_currentBook!.totalChapters} chapters)');

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for Bible access');
      }

      if (chapterNumber < 1 || chapterNumber > _currentBook!.totalChapters) {
        debugPrint('❌ Invalid chapter number: $chapterNumber (valid range: 1-${_currentBook!.totalChapters})');
        throw BibleException('Invalid chapter number: $chapterNumber');
      }

      final chapter =
          await _repository.getChapter(_currentBook!.id, chapterNumber);
      if (chapter == null) {
        throw BibleException(
            'Chapter not found: ${_currentBook!.name} $chapterNumber');
      }

      _currentChapter = chapter;
      _currentChapterController.add(_currentChapter);

      debugPrint('✅ Selected Bible chapter: ${chapter.reference}');
    } catch (e) {
      debugPrint('❌ Error selecting chapter: $e');
      rethrow;
    }
  }

  /// Navigate to next chapter
  Future<bool> goToNextChapter() async {
    if (_currentBook == null || _currentChapter == null) {
      return false;
    }

    try {
      final nextChapter = _currentChapter!.chapterNumber + 1;

      if (nextChapter <= _currentBook!.totalChapters) {
        await selectChapter(nextChapter);
        return true;
      }

      // Try to go to next book's first chapter
      final allBooks = await getAllBooks();
      final currentBookIndex =
          allBooks.indexWhere((b) => b.id == _currentBook!.id);

      if (currentBookIndex != -1 && currentBookIndex < allBooks.length - 1) {
        final nextBook = allBooks[currentBookIndex + 1];
        await selectBook(nextBook.id);
        await selectChapter(1);
        return true;
      }

      return false; // Already at the last chapter of the last book
    } catch (e) {
      debugPrint('❌ Error navigating to next chapter: $e');
      return false;
    }
  }

  /// Navigate to previous chapter
  Future<bool> goToPreviousChapter() async {
    if (_currentBook == null || _currentChapter == null) {
      return false;
    }

    try {
      final prevChapter = _currentChapter!.chapterNumber - 1;

      if (prevChapter >= 1) {
        await selectChapter(prevChapter);
        return true;
      }

      // Try to go to previous book's last chapter
      final allBooks = await getAllBooks();
      final currentBookIndex =
          allBooks.indexWhere((b) => b.id == _currentBook!.id);

      if (currentBookIndex > 0) {
        final prevBook = allBooks[currentBookIndex - 1];
        await selectBook(prevBook.id);
        await selectChapter(prevBook.totalChapters);
        return true;
      }

      return false; // Already at the first chapter of the first book
    } catch (e) {
      debugPrint('❌ Error navigating to previous chapter: $e');
      return false;
    }
  }

  /// Search Bible verses
  Future<List<BibleSearchResult>> searchVerses(
    String query, {
    String? bookId,
    String? testament,
    String? language,
    int? limit = 50,
  }) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for Bible search');
      }

      if (query.trim().isEmpty) {
        return [];
      }

      return await _repository.searchVerses(
        query,
        bookId: bookId,
        testament: testament,
        language: language,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ Error searching verses: $e');
      rethrow;
    }
  }

  /// Get user bookmarks
  Future<List<BibleBookmark>> getUserBookmarks() async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for bookmarks');
      }

      final bookmarks = await _repository.getUserBookmarks();
      _bookmarksController.add(bookmarks);
      return bookmarks;
    } catch (e) {
      debugPrint('❌ Error getting bookmarks: $e');
      rethrow;
    }
  }

  /// Add a bookmark
  Future<void> addBookmark(
    String bookId,
    String bookName,
    int chapterNumber,
    int verseNumber,
    String verseText, {
    String? note,
    List<String>? tags,
    String? reference,
  }) async {
    await _ensureInitialized();

    try {
      // Remove premium check, allow all authenticated users
      final user = _auth.currentUser;
      if (user == null) {
        throw BibleException('User not authenticated');
      }

      final bookmarkId =
          BibleBookmark.createId(user.uid, bookId, chapterNumber, verseNumber);

      final bookmark = BibleBookmark(
        id: bookmarkId,
        userId: user.uid,
        bookId: bookId,
        bookName: bookName,
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
        verseText: verseText,
        note: note,
        tags: tags ?? [],
        reference: reference ?? '$bookName $chapterNumber:$verseNumber',
      );

      await _repository.addBookmark(bookmark);

      // Refresh bookmarks
      await getUserBookmarks();

      // debugPrint('✅ Bookmark added: \\${bookmark.reference}');
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
      rethrow;
    }
  }

  /// Update a bookmark
  Future<void> updateBookmark(String bookmarkId, String? note, List<String>? tags) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for bookmarks');
      }

      await _repository.updateBookmark(bookmarkId, note, tags);

      // Refresh bookmarks
      await getUserBookmarks();

      debugPrint('✅ Bookmark updated: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error updating bookmark: $e');
      rethrow;
    }
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for bookmarks');
      }

      await _repository.removeBookmark(bookmarkId);

      // Refresh bookmarks
      await getUserBookmarks();

      debugPrint('✅ Bookmark removed: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
      rethrow;
    }
  }

  /// Get user highlights
  Future<List<BibleHighlight>> getUserHighlights() async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for highlights');
      }

      return await _repository.getUserHighlights();
    } catch (e) {
      debugPrint('❌ Error getting highlights: $e');
      rethrow;
    }
  }

  /// Add a highlight
  Future<void> addHighlight(
    String bookId,
    String bookName,
    int chapterNumber,
    int verseNumber,
    String verseText,
    String color, {
    String? note,
    List<String>? tags,
  }) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for highlights');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw BibleException('User not authenticated');
      }

      final highlightId =
          BibleHighlight.createId(user.uid, bookId, chapterNumber, verseNumber);

      final highlight = BibleHighlight(
        id: highlightId,
        userId: user.uid,
        bookId: bookId,
        bookName: bookName,
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
        verseText: verseText,
        color: color,
        note: note,
        tags: tags ?? [],
      );

      await _repository.addHighlight(highlight);

      // debugPrint('✅ Highlight added: \\${highlight.reference}');
    } catch (e) {
      debugPrint('❌ Error adding highlight: $e');
      rethrow;
    }
  }

  /// Update highlight color
  Future<void> updateHighlightColor(String highlightId, String newColor) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for highlights');
      }

      await _repository.updateHighlightColor(highlightId, newColor);

      debugPrint('✅ Highlight color updated: $highlightId -> $newColor');
    } catch (e) {
      debugPrint('❌ Error updating highlight color: $e');
      rethrow;
    }
  }

  /// Remove a highlight
  Future<void> removeHighlight(String highlightId) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for highlights');
      }

      await _repository.removeHighlight(highlightId);

      debugPrint('✅ Highlight removed: $highlightId');
    } catch (e) {
      debugPrint('❌ Error removing highlight: $e');
      rethrow;
    }
  }

  /// Check if a verse is highlighted
  Future<BibleHighlight?> getVerseHighlight(
      String bookId, int chapterNumber, int verseNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final highlightId =
          BibleHighlight.createId(user.uid, bookId, chapterNumber, verseNumber);
      return await _repository.getHighlight(highlightId);
    } catch (e) {
      debugPrint('❌ Error checking highlight status: $e');
      return null;
    }
  }

  /// Get user notes
  Future<List<BibleNote>> getUserNotes() async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for notes');
      }

      return await _repository.getUserNotes();
    } catch (e) {
      debugPrint('❌ Error getting notes: $e');
      rethrow;
    }
  }

  /// Add a note
  Future<void> addNote(
    String bookId,
    String bookName,
    int chapterNumber,
    int verseNumber,
    String verseText,
    String note, {
    List<String>? tags,
  }) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for notes');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw BibleException('User not authenticated');
      }

      final noteId =
          BibleNote.createId(user.uid, bookId, chapterNumber, verseNumber);

      final bibleNote = BibleNote(
        id: noteId,
        userId: user.uid,
        bookId: bookId,
        bookName: bookName,
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
        verseText: verseText,
        note: note,
        tags: tags ?? [],
      );

      await _repository.addNote(bibleNote);

      // debugPrint('✅ Note added: \\${bibleNote.reference}');
    } catch (e) {
      debugPrint('❌ Error adding note: $e');
      rethrow;
    }
  }

  /// Update a note
  Future<void> updateNote(String noteId, String newNoteText, {List<String>? tags}) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for notes');
      }

      await _repository.updateNote(noteId, newNoteText, tags: tags);

      debugPrint('✅ Note updated: $noteId');
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      rethrow;
    }
  }

  /// Remove a note
  Future<void> removeNote(String noteId) async {
    await _ensureInitialized();

    try {
      if (!await hasPremiumAccess()) {
        throw BibleException('Premium subscription required for notes');
      }

      await _repository.removeNote(noteId);

      debugPrint('✅ Note removed: $noteId');
    } catch (e) {
      debugPrint('❌ Error removing note: $e');
      rethrow;
    }
  }

  /// Get note for a verse
  Future<BibleNote?> getVerseNote(
      String bookId, int chapterNumber, int verseNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final noteId =
          BibleNote.createId(user.uid, bookId, chapterNumber, verseNumber);
      return await _repository.getNote(noteId);
    } catch (e) {
      debugPrint('❌ Error getting verse note: $e');
      return null;
    }
  }

  /// Check if a verse is bookmarked
  Future<bool> isVerseBookmarked(
      String bookId, int chapterNumber, int verseNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bookmarkId =
          BibleBookmark.createId(user.uid, bookId, chapterNumber, verseNumber);
      final bookmarks = await getUserBookmarks();

      return bookmarks.any((bookmark) => bookmark.id == bookmarkId);
    } catch (e) {
      debugPrint('❌ Error checking bookmark status: $e');
      return false;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(BiblePreferences preferences) async {
    await _ensureInitialized();

    try {
      await _repository.updateUserPreferences(preferences);
      _userPreferences = preferences;

      debugPrint('✅ Bible preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      rethrow;
    }
  }

  /// Get verse reference for navigation
  BibleVerseReference? getCurrentVerseReference() {
    if (_currentBook == null || _currentChapter == null) {
      return null;
    }

    return BibleVerseReference(
      bookId: _currentBook!.id,
      bookName: _currentBook!.name,
      chapterNumber: _currentChapter!.chapterNumber,
      verseNumber: 1, // Default to first verse
    );
  }

  /// Navigate to specific verse reference
  Future<void> navigateToReference(BibleVerseReference reference) async {
    try {
      await selectBook(reference.bookId);
      await selectChapter(reference.chapterNumber);

      debugPrint('✅ Navigated to: ${reference.toString()}');
    } catch (e) {
      debugPrint('❌ Error navigating to reference: $e');
      rethrow;
    }
  }

  /// Clear current selection
  void clearSelection() {
    _currentCollection = null;
    _currentBook = null;
    _currentChapter = null;

    _currentCollectionController.add(null);
    _currentBookController.add(null);
    _currentChapterController.add(null);

    debugPrint('✅ Bible selection cleared');
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  void dispose() {
    _currentCollectionController.close();
    _currentBookController.close();
    _currentChapterController.close();
    _bookmarksController.close();
    _repository.dispose();
  }
}

/// Bible-specific exception class
class BibleException implements Exception {
  final String message;
  const BibleException(this.message);

  @override
  String toString() => 'BibleException: $message';
}

/// Bible verse reference for navigation
class BibleVerseReference {
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;

  const BibleVerseReference({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
  });

  @override
  String toString() => '$bookName $chapterNumber:$verseNumber';

  /// Create from string (e.g., "Kejadian 1:1")
  static BibleVerseReference? fromString(
      String reference, List<BibleBook> availableBooks) {
    try {
      // Parse reference like "Kejadian 1:1"
      final parts = reference.trim().split(' ');
      if (parts.length < 2) return null;

      final bookName = parts.sublist(0, parts.length - 1).join(' ');
      final chapterVerse = parts.last.split(':');

      if (chapterVerse.length != 2) return null;

      final chapterNumber = int.parse(chapterVerse[0]);
      final verseNumber = int.parse(chapterVerse[1]);

      // Find matching book
      final book = availableBooks.firstWhere(
        (b) => b.name.toLowerCase() == bookName.toLowerCase(),
        orElse: () => throw Exception('Book not found'),
      );

      return BibleVerseReference(
        bookId: book.id,
        bookName: book.name,
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
      );
    } catch (e) {
      debugPrint('❌ Error parsing verse reference: $reference');
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
    };
  }

  factory BibleVerseReference.fromMap(Map<String, dynamic> map) {
    return BibleVerseReference(
      bookId: map['bookId'] ?? '',
      bookName: map['bookName'] ?? '',
      chapterNumber: map['chapterNumber'] ?? 1,
      verseNumber: map['verseNumber'] ?? 1,
    );
  }
}
