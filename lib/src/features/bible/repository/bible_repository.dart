// 📖 Bible Repository
// Manages Bible data access, caching, and premium controls

import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_models.dart';
import '../../../core/services/premium_service.dart';

class BibleRepository {
  static const String _cachePrefix = 'bible_cache_';
  static const String _booksCacheKey = 'bible_books_cache';
  static const String _collectionsCacheKey = 'bible_collections_cache';
  static const Duration _cacheExpiry = Duration(hours: 24);

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final PremiumService _premiumService;
  SharedPreferences? _prefs;

  // Cache for frequently accessed data
  final Map<String, BibleBook> _booksCache = {};
  final Map<String, BibleChapter> _chaptersCache = {};
  final Map<String, BibleCollection> _collectionsCache = {};

  // Stream controllers for real-time updates
  final StreamController<List<BibleBook>> _booksController =
      StreamController.broadcast();
  final StreamController<List<BibleCollection>> _collectionsController =
      StreamController.broadcast();

  BibleRepository() {
    _premiumService = PremiumService();
    _initializeCache();
  }

  // Initialize SharedPreferences for caching
  Future<void> _initializeCache() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all available Bible collections
  Stream<List<BibleCollection>> get collectionsStream =>
      _collectionsController.stream;

  /// Get all books stream
  Stream<List<BibleBook>> get booksStream => _booksController.stream;

  /// Fetch all available Bible collections
  Future<List<BibleCollection>> getCollections() async {
    try {
      // Check cache first
      final cached = await _getCachedCollections();
      if (cached.isNotEmpty) {
        _collectionsController.add(cached);
        return cached;
      }

      // Fetch from Firebase
      final snapshot = await _database.ref('bible/collections').get();

      if (!snapshot.exists) {
        debugPrint('⚠️ No Bible collections found in database');
        return [];
      }

      final collections = <BibleCollection>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          collections.add(
              BibleCollection.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Cache the results
      await _cacheCollections(collections);

      // Update stream
      _collectionsController.add(collections);

      // Update local cache
      for (var collection in collections) {
        _collectionsCache[collection.id] = collection;
      }

      debugPrint('✅ Loaded ${collections.length} Bible collections');
      return collections;
    } catch (e) {
      debugPrint('❌ Error fetching Bible collections: $e');
      rethrow;
    }
  }

  /// Get books for a specific collection
  Future<List<BibleBook>> getBooksForCollection(String collectionId) async {
    try {
      // Check if user has access to this collection
      final hasAccess = await _checkCollectionAccess(collectionId);
      if (!hasAccess) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Check cache first
      final cached = await _getCachedBooks(collectionId);
      if (cached.isNotEmpty) {
        return cached;
      }

      // Fetch from Firebase
      final snapshot = await _database
          .ref('bible/books')
          .orderByChild('collectionId')
          .equalTo(collectionId)
          .get();

      if (!snapshot.exists) {
        debugPrint('⚠️ No books found for collection: $collectionId');
        return [];
      }

      final books = <BibleBook>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          books.add(BibleBook.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Sort books by book number
      books.sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

      // Cache the results
      await _cacheBooks(collectionId, books);

      // Update local cache
      for (var book in books) {
        _booksCache[book.id] = book;
      }

      debugPrint(
          '✅ Loaded ${books.length} books for collection: $collectionId');
      return books;
    } catch (e) {
      debugPrint('❌ Error fetching books for collection $collectionId: $e');
      rethrow;
    }
  }

  /// Get all books (premium access required)
  Future<List<BibleBook>> getAllBooks() async {
    try {
      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Check cache first
      final cached = await _getCachedAllBooks();
      if (cached.isNotEmpty) {
        _booksController.add(cached);
        return cached;
      }

      // Fetch from Firebase
      final snapshot = await _database.ref('bible/books').get();

      if (!snapshot.exists) {
        debugPrint('⚠️ No Bible books found in database');
        return [];
      }

      final books = <BibleBook>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          books.add(BibleBook.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Sort books by book number
      books.sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

      // Cache the results
      await _cacheAllBooks(books);

      // Update stream
      _booksController.add(books);

      // Update local cache
      for (var book in books) {
        _booksCache[book.id] = book;
      }

      debugPrint('✅ Loaded ${books.length} Bible books');
      return books;
    } catch (e) {
      debugPrint('❌ Error fetching all Bible books: $e');
      rethrow;
    }
  }

  /// Get a specific Bible book by ID
  Future<BibleBook?> getBook(String bookId) async {
    try {
      // Check cache first
      if (_booksCache.containsKey(bookId)) {
        return _booksCache[bookId];
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Fetch from Firebase
      final snapshot = await _database.ref('bible/books/$bookId').get();

      if (!snapshot.exists) {
        debugPrint('⚠️ Book not found: $bookId');
        return null;
      }

      final book = BibleBook.fromSnapshot(snapshot);

      // Cache the result
      _booksCache[bookId] = book;

      debugPrint('✅ Loaded Bible book: ${book.name}');
      return book;
    } catch (e) {
      debugPrint('❌ Error fetching Bible book $bookId: $e');
      rethrow;
    }
  }

  /// Get a specific chapter
  Future<BibleChapter?> getChapter(String bookId, int chapterNumber) async {
    try {
      final chapterId = '${bookId}_${chapterNumber.toString().padLeft(3, '0')}';

      // Check cache first
      if (_chaptersCache.containsKey(chapterId)) {
        return _chaptersCache[chapterId];
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Fetch from Firebase
      final snapshot = await _database.ref('bible/chapters/$chapterId').get();

      if (!snapshot.exists) {
        debugPrint('⚠️ Chapter not found: $chapterId');
        return null;
      }

      final chapter = BibleChapter.fromSnapshot(snapshot);

      // Cache the result
      _chaptersCache[chapterId] = chapter;

      debugPrint('✅ Loaded Bible chapter: ${chapter.reference}');
      return chapter;
    } catch (e) {
      debugPrint('❌ Error fetching Bible chapter $bookId $chapterNumber: $e');
      rethrow;
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
    try {
      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for Bible search');
      }

      if (query.trim().isEmpty) {
        return [];
      }

      final results = <BibleSearchResult>[];
      final queryLower = query.toLowerCase();

      // Build Firebase query
      DatabaseReference ref = _database.ref('bible/chapters');

      // Apply filters
      if (bookId != null) {
        ref = ref.orderByChild('bookId').equalTo(bookId);
      }

      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      int resultCount = 0;

      // Search through chapters
      for (var chapterEntry in data.entries) {
        if (limit != null && resultCount >= limit) break;

        final chapterData = chapterEntry.value as Map<dynamic, dynamic>;

        // Apply testament filter
        if (testament != null) {
          final book = await getBook(chapterData['bookId']);
          if (book?.testament != testament) continue;
        }

        // Apply language filter
        if (language != null && chapterData['language'] != language) continue;

        // Search through verses
        final versesData = chapterData['verses'] as Map<dynamic, dynamic>?;
        if (versesData != null) {
          for (var verseEntry in versesData.entries) {
            if (limit != null && resultCount >= limit) break;

            final verseData = verseEntry.value as Map<dynamic, dynamic>;
            final verseText = verseData['cleanText'] ?? verseData['text'] ?? '';

            if (verseText.toLowerCase().contains(queryLower)) {
              final verse = BibleVerse.fromMap(
                  verseEntry.key, Map<String, dynamic>.from(verseData));

              // Find match positions
              final matchPositions = <int>[];
              int startIndex = 0;
              while (true) {
                final index =
                    verseText.toLowerCase().indexOf(queryLower, startIndex);
                if (index == -1) break;
                matchPositions.add(index);
                startIndex = index + 1;
              }

              results.add(BibleSearchResult(
                bookId: chapterData['bookId'],
                bookName: chapterData['bookName'],
                chapterNumber: chapterData['chapterNumber'],
                verse: verse,
                query: query,
                matchPositions: matchPositions,
              ));

              resultCount++;
            }
          }
        }
      }

      debugPrint('✅ Found ${results.length} search results for: "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ Error searching Bible verses: $e');
      rethrow;
    }
  }

  /// Get user bookmarks
  Future<List<BibleBookmark>> getUserBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for bookmarks');
      }

      final snapshot = await _database.ref('bible/bookmarks/${user.uid}').get();

      if (!snapshot.exists) {
        return [];
      }

      final bookmarks = <BibleBookmark>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          bookmarks
              .add(BibleBookmark.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Sort by creation date (newest first)
      bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ Loaded ${bookmarks.length} bookmarks');
      return bookmarks;
    } catch (e) {
      debugPrint('❌ Error fetching user bookmarks: $e');
      rethrow;
    }
  }

  /// Add bookmark
  Future<void> addBookmark(BibleBookmark bookmark) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremiumUser()) {
        throw Exception('Premium subscription required for bookmarks');
      }

      await _database
          .ref('bible/bookmarks/${user.uid}/${bookmark.id}')
          .set(bookmark.toMap());

      debugPrint('✅ Bookmark added: ${bookmark.reference}');
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
      rethrow;
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _database.ref('bible/bookmarks/${user.uid}/$bookmarkId').remove();

      debugPrint('✅ Bookmark removed: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
      rethrow;
    }
  }

  /// Get user preferences
  Future<BiblePreferences?> getUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final snapshot =
          await _database.ref('bible/preferences/${user.uid}').get();

      if (!snapshot.exists) {
        // Return default preferences
        return BiblePreferences(userId: user.uid);
      }

      return BiblePreferences.fromSnapshot(snapshot);
    } catch (e) {
      debugPrint('❌ Error fetching user preferences: $e');
      return null;
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(BiblePreferences preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _database
          .ref('bible/preferences/${user.uid}')
          .set(preferences.toMap());

      debugPrint('✅ Bible preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating user preferences: $e');
      rethrow;
    }
  }

  /// Check if user has access to a collection
  Future<bool> _checkCollectionAccess(String collectionId) async {
    try {
      // Get collection info
      final collection = _collectionsCache[collectionId] ??
          await _getCollectionFromDatabase(collectionId);

      if (collection == null) {
        return false;
      }

      // If collection is not premium, allow access
      if (!collection.isPremium) {
        return true;
      }

      // Check premium status
      return await _premiumService.isPremiumUser();
    } catch (e) {
      debugPrint('❌ Error checking collection access: $e');
      return false;
    }
  }

  /// Get collection from database
  Future<BibleCollection?> _getCollectionFromDatabase(
      String collectionId) async {
    try {
      final snapshot =
          await _database.ref('bible/collections/$collectionId').get();

      if (!snapshot.exists) {
        return null;
      }

      final collection = BibleCollection.fromSnapshot(snapshot);
      _collectionsCache[collectionId] = collection;

      return collection;
    } catch (e) {
      debugPrint('❌ Error fetching collection $collectionId: $e');
      return null;
    }
  }

  // Cache management methods
  Future<void> _cacheCollections(List<BibleCollection> collections) async {
    if (_prefs == null) return;

    try {
      final data = {
        'collections': collections.map((c) => c.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs!.setString(_collectionsCacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Error caching collections: $e');
    }
  }

  Future<List<BibleCollection>> _getCachedCollections() async {
    if (_prefs == null) return [];

    try {
      final cached = _prefs!.getString(_collectionsCacheKey);
      if (cached == null) return [];

      final data = jsonDecode(cached);
      final timestamp = DateTime.parse(data['timestamp']);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        return [];
      }

      final collectionsData = data['collections'] as List;
      return collectionsData
          .map((c) => BibleCollection.fromSnapshot(
              DataSnapshot(key: c['id'], value: c)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error reading cached collections: $e');
      return [];
    }
  }

  Future<void> _cacheBooks(String collectionId, List<BibleBook> books) async {
    if (_prefs == null) return;

    try {
      final data = {
        'books': books.map((b) => b.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs!
          .setString('$_cachePrefix${collectionId}_books', jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Error caching books: $e');
    }
  }

  Future<List<BibleBook>> _getCachedBooks(String collectionId) async {
    if (_prefs == null) return [];

    try {
      final cached = _prefs!.getString('$_cachePrefix${collectionId}_books');
      if (cached == null) return [];

      final data = jsonDecode(cached);
      final timestamp = DateTime.parse(data['timestamp']);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        return [];
      }

      final booksData = data['books'] as List;
      return booksData
          .map((b) =>
              BibleBook.fromSnapshot(DataSnapshot(key: b['id'], value: b)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error reading cached books: $e');
      return [];
    }
  }

  Future<void> _cacheAllBooks(List<BibleBook> books) async {
    if (_prefs == null) return;

    try {
      final data = {
        'books': books.map((b) => b.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs!.setString(_booksCacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Error caching all books: $e');
    }
  }

  Future<List<BibleBook>> _getCachedAllBooks() async {
    if (_prefs == null) return [];

    try {
      final cached = _prefs!.getString(_booksCacheKey);
      if (cached == null) return [];

      final data = jsonDecode(cached);
      final timestamp = DateTime.parse(data['timestamp']);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        return [];
      }

      final booksData = data['books'] as List;
      return booksData
          .map((b) =>
              BibleBook.fromSnapshot(DataSnapshot(key: b['id'], value: b)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error reading cached all books: $e');
      return [];
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!
          .getKeys()
          .where((key) =>
              key.startsWith(_cachePrefix) ||
              key == _booksCacheKey ||
              key == _collectionsCacheKey)
          .toList();

      for (final key in keys) {
        await _prefs!.remove(key);
      }

      // Clear in-memory cache
      _booksCache.clear();
      _chaptersCache.clear();
      _collectionsCache.clear();

      debugPrint('✅ Bible cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _booksController.close();
    _collectionsController.close();
  }
}
