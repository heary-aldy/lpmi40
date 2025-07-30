// 📖 Bible Repository
// Manages Bible data access, caching, and premium controls

import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late final PremiumService _premiumService;
  SharedPreferences? _prefs;

  // Cache for frequently accessed data
  final Map<String, BibleBook> _booksCache = {};
  final Map<String, BibleChapter> _chaptersCache = {};
  final Map<String, BibleCollection> _collectionsCache = {};
  final Map<String, Map<String, dynamic>> _bibleDataCache =
      {}; // Cache for JSON data

  // Stream controllers for real-time updates
  final StreamController<List<BibleBook>> _booksController =
      StreamController.broadcast();
  final StreamController<List<BibleCollection>> _collectionsController =
      StreamController.broadcast();

  // Bible JSON file configurations
  static const Map<String, Map<String, String>> _bibleConfigs = {
    'indo_tb': {
      'name': 'Alkitab Terjemahan Baru',
      'language': 'indonesian',
      'translation': 'Terjemahan Baru',
      'description': 'Alkitab Bahasa Indonesia - Terjemahan Baru',
      'filename': 'indo_tb.json',
    },
    'indo_tm': {
      'name': 'Alkitab Terjemahan Lama',
      'language': 'indonesian',
      'translation': 'Terjemahan Lama',
      'description': 'Alkitab Bahasa Indonesia - Terjemahan Lama',
      'filename': 'indo_tm.json',
    },
  };

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
      debugPrint('📚 Repository: Getting Bible collections');
      
      // TEMPORARY: Clear cache for testing
      await clearCache();
      debugPrint('📚 Repository: Cache cleared for testing');
      
      // Check cache first
      final cached = await _getCachedCollections();
      if (cached.isNotEmpty) {
        debugPrint('📚 Repository: Found ${cached.length} cached collections');
        _collectionsController.add(cached);
        return cached;
      }

      debugPrint('📚 Repository: Creating collections from configs');
      debugPrint('📚 Repository: Available configs: ${_bibleConfigs.keys.toList()}');

      // Create collections from static configurations
      final collections = <BibleCollection>[];

      _bibleConfigs.forEach((id, config) {
        debugPrint('📚 Repository: Creating collection $id');
        collections.add(BibleCollection(
          id: id,
          name: config['name']!,
          language: config['language']!,
          translation: config['translation']!,
          description: config['description']!,
          isPremium: true, // All Bible collections require premium
          availableBooks: [], // Will be populated when loading books
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      });

      // Cache the results
      await _cacheCollections(collections);

      // Update stream
      _collectionsController.add(collections);

      // Update local cache
      for (var collection in collections) {
        _collectionsCache[collection.id] = collection;
      }

      debugPrint('✅ Repository: Created ${collections.length} Bible collections');
      return collections;
    } catch (e) {
      debugPrint('❌ Repository: Error fetching Bible collections: $e');
      rethrow;
    }
  }

  /// Load Bible data from JSON file in local assets
  Future<Map<String, dynamic>?> _loadBibleDataFromJson(
      String collectionId) async {
    try {
      // Check cache first
      if (_bibleDataCache.containsKey(collectionId)) {
        return _bibleDataCache[collectionId];
      }

      final config = _bibleConfigs[collectionId];
      if (config == null) {
        debugPrint('⚠️ No configuration found for collection: $collectionId');
        return null;
      }

      // Load from local assets
      final assetPath = 'assets/bibles/${config['filename']}';
      debugPrint('📖 Loading Bible data from asset: $assetPath');

      try {
        final jsonString = await rootBundle.loadString(assetPath);
        debugPrint('📖 Asset loaded successfully, parsing JSON...');
        
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('📖 JSON parsed successfully, transforming data...');

        // Transform flat verse structure to organized book structure
        final transformedData = _transformVerseData(jsonData);
        debugPrint('📖 Data transformed successfully');

        // Cache the transformed data
        _bibleDataCache[collectionId] = transformedData;

        debugPrint('✅ Loaded Bible data for collection: $collectionId');
        return transformedData;
      } catch (assetError) {
        debugPrint('❌ Error loading asset $assetPath: $assetError');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error loading Bible data for $collectionId: $e');
      return null;
    }
  }

  /// Transform flat verse array into organized book/chapter structure
  Map<String, dynamic> _transformVerseData(Map<String, dynamic> originalData) {
    final verses = originalData['verses'] as List<dynamic>;
    final booksMap = <String, Map<String, dynamic>>{};

    // Group verses by book
    for (final verse in verses) {
      if (verse is Map<String, dynamic>) {
        final bookNumber = verse['book'] as int;
        final bookName = verse['book_name'] as String;
        final chapter = verse['chapter'] as int;
        final verseNumber = verse['verse'] as int;
        final text = verse['text'] as String;

        // Create book ID (simple mapping for now)
        final bookId = _getBookIdFromNumber(bookNumber);

        // Initialize book structure if not exists
        if (!booksMap.containsKey(bookId)) {
          booksMap[bookId] = {
            'name': bookName,
            'englishName': _getEnglishBookName(bookNumber),
            'bookNumber': bookNumber,
            'totalChapters': 0,
            'chapters': <String, Map<String, dynamic>>{},
          };
        }

        // Initialize chapter if not exists
        final chaptersMap =
            booksMap[bookId]!['chapters'] as Map<String, dynamic>;
        final chapterKey = chapter.toString();
        if (!chaptersMap.containsKey(chapterKey)) {
          chaptersMap[chapterKey] = {
            'chapterNumber': chapter,
            'totalVerses': 0,
            'verses': <String, Map<String, dynamic>>{},
          };
        }

        // Add verse
        final versesMap =
            chaptersMap[chapterKey]!['verses'] as Map<String, dynamic>;
        versesMap[verseNumber.toString()] = {
          'verseNumber': verseNumber,
          'text': text,
          'cleanText': text,
        };

        // Update totals
        chaptersMap[chapterKey]!['totalVerses'] = versesMap.length;
        booksMap[bookId]!['totalChapters'] = chaptersMap.length;
      }
    }

    return {
      'metadata': originalData['metadata'],
      'books': booksMap,
    };
  }

  /// Get book ID from book number (basic mapping)
  String _getBookIdFromNumber(int bookNumber) {
    const bookIds = [
      'genesis',
      'exodus',
      'leviticus',
      'numbers',
      'deuteronomy',
      'joshua',
      'judges',
      'ruth',
      '1samuel',
      '2samuel',
      '1kings',
      '2kings',
      '1chronicles',
      '2chronicles',
      'ezra',
      'nehemiah',
      'esther',
      'job',
      'psalms',
      'proverbs',
      'ecclesiastes',
      'song_of_songs',
      'isaiah',
      'jeremiah',
      'lamentations',
      'ezekiel',
      'daniel',
      'hosea',
      'joel',
      'amos',
      'obadiah',
      'jonah',
      'micah',
      'nahum',
      'habakkuk',
      'zephaniah',
      'haggai',
      'zechariah',
      'malachi',
      'matthew',
      'mark',
      'luke',
      'john',
      'acts',
      'romans',
      '1corinthians',
      '2corinthians',
      'galatians',
      'ephesians',
      'philippians',
      'colossians',
      '1thessalonians',
      '2thessalonians',
      '1timothy',
      '2timothy',
      'titus',
      'philemon',
      'hebrews',
      'james',
      '1peter',
      '2peter',
      '1john',
      '2john',
      '3john',
      'jude',
      'revelation'
    ];

    if (bookNumber >= 1 && bookNumber <= bookIds.length) {
      return bookIds[bookNumber - 1];
    }
    return 'book$bookNumber';
  }

  /// Get English book name from book number
  String _getEnglishBookName(int bookNumber) {
    const englishNames = [
      'Genesis',
      'Exodus',
      'Leviticus',
      'Numbers',
      'Deuteronomy',
      'Joshua',
      'Judges',
      'Ruth',
      '1 Samuel',
      '2 Samuel',
      '1 Kings',
      '2 Kings',
      '1 Chronicles',
      '2 Chronicles',
      'Ezra',
      'Nehemiah',
      'Esther',
      'Job',
      'Psalms',
      'Proverbs',
      'Ecclesiastes',
      'Song of Songs',
      'Isaiah',
      'Jeremiah',
      'Lamentations',
      'Ezekiel',
      'Daniel',
      'Hosea',
      'Joel',
      'Amos',
      'Obadiah',
      'Jonah',
      'Micah',
      'Nahum',
      'Habakkuk',
      'Zephaniah',
      'Haggai',
      'Zechariah',
      'Malachi',
      'Matthew',
      'Mark',
      'Luke',
      'John',
      'Acts',
      'Romans',
      '1 Corinthians',
      '2 Corinthians',
      'Galatians',
      'Ephesians',
      'Philippians',
      'Colossians',
      '1 Thessalonians',
      '2 Thessalonians',
      '1 Timothy',
      '2 Timothy',
      'Titus',
      'Philemon',
      'Hebrews',
      'James',
      '1 Peter',
      '2 Peter',
      '1 John',
      '2 John',
      '3 John',
      'Jude',
      'Revelation'
    ];

    if (bookNumber >= 1 && bookNumber <= englishNames.length) {
      return englishNames[bookNumber - 1];
    }
    return 'Book $bookNumber';
  }

  /// Get books for a specific collection
  /// Get books for a specific collection
  Future<List<BibleBook>> getBooksForCollection(String collectionId) async {
    try {
      debugPrint('📖 Repository: Getting books for collection: $collectionId');
      
      // Check if user has access to this collection
      final hasAccess = await _checkCollectionAccess(collectionId);
      if (!hasAccess) {
        debugPrint('❌ Repository: No premium access for collection: $collectionId');
        throw Exception('Premium subscription required for Bible access');
      }
      debugPrint('✅ Repository: Premium access confirmed');

      // Check cache first
      final cached = await _getCachedBooks(collectionId);
      if (cached.isNotEmpty) {
        debugPrint('📖 Repository: Found ${cached.length} cached books');
        return cached;
      }

      // Load Bible data from JSON file
      debugPrint('📖 Repository: Loading Bible data from JSON');
      final bibleData = await _loadBibleDataFromJson(collectionId);
      if (bibleData == null) {
        debugPrint('⚠️ Repository: No Bible data found for collection: $collectionId');
        return [];
      }

      final books = <BibleBook>[];

      // Parse books from JSON structure
      if (bibleData.containsKey('books')) {
        final booksData = bibleData['books'] as Map<String, dynamic>;

        booksData.forEach((bookKey, bookValue) {
          if (bookValue is Map<String, dynamic>) {
            final book = BibleBook(
              id: bookKey,
              name: bookValue['name'] ?? bookKey,
              englishName: bookValue['englishName'] ?? bookKey,
              abbreviation:
                  bookValue['abbreviation'] ?? bookKey.substring(0, 3),
              testament: _getTestament(bookValue['bookNumber'] ?? 1),
              bookNumber: bookValue['bookNumber'] ?? 1,
              totalChapters: bookValue['totalChapters'] ?? 0,
              collectionId: collectionId,
              language:
                  _bibleConfigs[collectionId]?['language'] ?? 'indonesian',
              translation: _bibleConfigs[collectionId]?['translation'] ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            books.add(book);
          }
        });
      }

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

  /// Helper method to determine testament based on book number
  String _getTestament(int bookNumber) {
    return bookNumber <= 39 ? 'old' : 'new';
  }

  /// Get all books (premium access required)
  Future<List<BibleBook>> getAllBooks() async {
    try {
      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Check cache first
      final cached = await _getCachedAllBooks();
      if (cached.isNotEmpty) {
        _booksController.add(cached);
        return cached;
      }

      // Load books from all collections
      final allBooks = <BibleBook>[];

      for (final collectionId in _bibleConfigs.keys) {
        try {
          final books = await getBooksForCollection(collectionId);
          allBooks.addAll(books);
        } catch (e) {
          debugPrint(
              '⚠️ Error loading books from collection $collectionId: $e');
        }
      }

      // Sort books by book number
      allBooks.sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

      // Cache the results
      await _cacheAllBooks(allBooks);

      // Update stream
      _booksController.add(allBooks);

      // Update local cache
      for (var book in allBooks) {
        _booksCache[book.id] = book;
      }

      debugPrint('✅ Loaded ${allBooks.length} Bible books');
      return allBooks;
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
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // Try to find the book in all collections
      for (final collectionId in _bibleConfigs.keys) {
        try {
          final books = await getBooksForCollection(collectionId);
          final book = books.firstWhere((b) => b.id == bookId,
              orElse: () => throw StateError('Book not found'));

          // Cache the result
          _booksCache[bookId] = book;

          debugPrint('✅ Loaded Bible book: ${book.name}');
          return book;
        } catch (e) {
          // Continue to next collection
          continue;
        }
      }

      debugPrint('⚠️ Book not found: $bookId');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching Bible book $bookId: $e');
      rethrow;
    }
  }

  /// Get a specific chapter
  Future<BibleChapter?> getChapter(String bookId, int chapterNumber,
      {String? collectionId}) async {
    try {
      final chapterId = '${bookId}_${chapterNumber.toString().padLeft(3, '0')}';

      // Check cache first
      if (_chaptersCache.containsKey(chapterId)) {
        return _chaptersCache[chapterId];
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for Bible access');
      }

      // If collectionId is not provided, try to find it from cached books
      String? targetCollectionId = collectionId;
      if (targetCollectionId == null) {
        // Look for the book in cache to determine collection
        final cachedBook = _booksCache[bookId];
        if (cachedBook != null) {
          targetCollectionId = cachedBook.collectionId;
        } else {
          // Default to first available collection
          targetCollectionId = _bibleConfigs.keys.first;
        }
      }

      // Load Bible data from JSON file
      final bibleData = await _loadBibleDataFromJson(targetCollectionId);
      if (bibleData == null) {
        debugPrint(
            '⚠️ No Bible data found for collection: $targetCollectionId');
        return null;
      }

      // Find the chapter in the JSON data
      BibleChapter? chapter;

      if (bibleData.containsKey('books')) {
        final booksData = bibleData['books'] as Map<String, dynamic>;
        final bookData = booksData[bookId] as Map<String, dynamic>?;

        if (bookData != null && bookData.containsKey('chapters')) {
          final chaptersData = bookData['chapters'] as Map<String, dynamic>;
          final chapterData =
              chaptersData[chapterNumber.toString()] as Map<String, dynamic>?;

          if (chapterData != null) {
            // Parse verses
            final verses = <BibleVerse>[];
            final versesData = chapterData['verses'] as Map<String, dynamic>?;

            if (versesData != null) {
              versesData.forEach((verseKey, verseValue) {
                if (verseValue is Map<String, dynamic>) {
                  verses.add(BibleVerse(
                    verseNumber: int.tryParse(verseKey) ?? 1,
                    text: verseValue['text'] ?? '',
                    cleanText:
                        verseValue['cleanText'] ?? verseValue['text'] ?? '',
                  ));
                }
              });
            }

            // Sort verses by verse number
            verses.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

            chapter = BibleChapter(
              id: chapterId,
              bookId: bookId,
              bookName: bookData['name'] ?? bookId,
              chapterNumber: chapterNumber,
              totalVerses: verses.length,
              verses: verses,
              language: _bibleConfigs[targetCollectionId]?['language'] ??
                  'indonesian',
              translation:
                  _bibleConfigs[targetCollectionId]?['translation'] ?? '',
            );
          }
        }
      }

      if (chapter == null) {
        debugPrint('⚠️ Chapter not found: $chapterId');
        return null;
      }

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
    String? collectionId,
    int? limit = 50,
  }) async {
    try {
      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for Bible search');
      }

      if (query.trim().isEmpty) {
        return [];
      }

      final results = <BibleSearchResult>[];
      final queryLower = query.toLowerCase();

      // Determine which collections to search
      List<String> collectionsToSearch = [];
      if (collectionId != null) {
        collectionsToSearch = [collectionId];
      } else {
        collectionsToSearch = _bibleConfigs.keys.toList();
      }

      int resultCount = 0;

      // Search through each collection
      for (final targetCollectionId in collectionsToSearch) {
        if (limit != null && resultCount >= limit) break;

        // Load Bible data from JSON file
        final bibleData = await _loadBibleDataFromJson(targetCollectionId);
        if (bibleData == null) continue;

        // Apply language filter
        if (language != null &&
            _bibleConfigs[targetCollectionId]?['language'] != language) {
          continue;
        }

        if (bibleData.containsKey('books')) {
          final booksData = bibleData['books'] as Map<String, dynamic>;

          // Search through books
          for (final bookEntry in booksData.entries) {
            if (limit != null && resultCount >= limit) break;

            final currentBookId = bookEntry.key;
            final bookData = bookEntry.value as Map<String, dynamic>;

            // Apply book filter
            if (bookId != null && currentBookId != bookId) continue;

            // Apply testament filter
            if (testament != null) {
              final bookNumber = bookData['bookNumber'] ?? 1;
              final bookTestament = _getTestament(bookNumber);
              if (bookTestament != testament) continue;
            }

            // Search through chapters
            final chaptersData = bookData['chapters'] as Map<String, dynamic>?;
            if (chaptersData != null) {
              for (final chapterEntry in chaptersData.entries) {
                if (limit != null && resultCount >= limit) break;

                final chapterNumber = int.tryParse(chapterEntry.key) ?? 1;
                final chapterData = chapterEntry.value as Map<String, dynamic>;

                // Search through verses
                final versesData =
                    chapterData['verses'] as Map<String, dynamic>?;
                if (versesData != null) {
                  for (final verseEntry in versesData.entries) {
                    if (limit != null && resultCount >= limit) break;

                    final verseNumber = int.tryParse(verseEntry.key) ?? 1;
                    final verseData = verseEntry.value as Map<String, dynamic>;
                    final verseText =
                        verseData['cleanText'] ?? verseData['text'] ?? '';

                    if (verseText.toLowerCase().contains(queryLower)) {
                      final verse = BibleVerse(
                        verseNumber: verseNumber,
                        text: verseData['text'] ?? '',
                        cleanText:
                            verseData['cleanText'] ?? verseData['text'] ?? '',
                      );

                      // Find match positions
                      final matchPositions = <int>[];
                      int startIndex = 0;
                      while (true) {
                        final index = verseText
                            .toLowerCase()
                            .indexOf(queryLower, startIndex);
                        if (index == -1) break;
                        matchPositions.add(index);
                        startIndex = index + 1;
                      }

                      results.add(BibleSearchResult(
                        bookId: currentBookId,
                        bookName: bookData['name'] ?? currentBookId,
                        chapterNumber: chapterNumber,
                        verse: verse,
                        query: query,
                        matchPositions: matchPositions,
                        collectionId: targetCollectionId,
                        translation: _bibleConfigs[targetCollectionId]
                                ?['translation'] ??
                            '',
                      ));

                      resultCount++;
                    }
                  }
                }
              }
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
      if (!await _premiumService.isPremium()) {
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
      if (!await _premiumService.isPremium()) {
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

  /// Update bookmark
  Future<void> updateBookmark(String bookmarkId, String? note, List<String>? tags) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for bookmarks');
      }

      final updates = <String, dynamic>{
        'note': note,
        'tags': tags ?? [],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _database.ref('bible/bookmarks/${user.uid}/$bookmarkId').update(updates);

      debugPrint('✅ Bookmark updated: $bookmarkId');
    } catch (e) {
      debugPrint('❌ Error updating bookmark: $e');
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
      debugPrint('🔐 Repository: Checking access for collection: $collectionId');
      
      // Get collection info
      final collection = _collectionsCache[collectionId] ??
          await _getCollectionFromDatabase(collectionId);

      if (collection == null) {
        debugPrint('🔐 Repository: Collection not found');
        return false;
      }

      // If collection is not premium, allow access
      if (!collection.isPremium) {
        debugPrint('🔐 Repository: Collection is free, access granted');
        return true;
      }

      // Check premium status
      final isPremium = await _premiumService.isPremium();
      debugPrint('🔐 Repository: Premium status: $isPremium');
      
      // TEMPORARY: Allow access even without premium for testing
      if (!isPremium) {
        debugPrint('🔐 Repository: WARNING - Allowing access without premium for testing');
        return true;
      }
      
      return isPremium;
    } catch (e) {
      debugPrint('❌ Error checking collection access: $e');
      // TEMPORARY: Allow access on error for testing
      debugPrint('🔐 Repository: WARNING - Allowing access due to error for testing');
      return true;
    }
  }

  /// Get collection from database
  Future<BibleCollection?> _getCollectionFromDatabase(
      String collectionId) async {
    try {
      debugPrint('🔍 Repository: Getting collection $collectionId from database');
      
      final snapshot =
          await _database.ref('bible/collections/$collectionId').get();

      if (!snapshot.exists) {
        debugPrint('🔍 Repository: Collection $collectionId not found in database');
        return null;
      }

      final collection = BibleCollection.fromSnapshot(snapshot);
      _collectionsCache[collectionId] = collection;

      debugPrint('🔍 Repository: Retrieved collection $collectionId from database');
      return collection;
    } catch (e) {
      debugPrint('❌ Error fetching collection $collectionId from database: $e');
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
          .map((c) => BibleCollection.fromMap(Map<String, dynamic>.from(c)))
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
          .map((b) => BibleBook.fromMap(Map<String, dynamic>.from(b)))
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
          .map((b) => BibleBook.fromMap(Map<String, dynamic>.from(b)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error reading cached all books: $e');
      return [];
    }
  }

  /// Get user highlights
  Future<List<BibleHighlight>> getUserHighlights() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for highlights');
      }

      final snapshot = await _database.ref('bible/highlights/${user.uid}').get();

      if (!snapshot.exists) {
        return [];
      }

      final highlights = <BibleHighlight>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          highlights.add(BibleHighlight.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Sort by creation date (newest first)
      highlights.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ Loaded ${highlights.length} highlights');
      return highlights;
    } catch (e) {
      debugPrint('❌ Error fetching user highlights: $e');
      rethrow;
    }
  }

  /// Add highlight
  Future<void> addHighlight(BibleHighlight highlight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for highlights');
      }

      await _database
          .ref('bible/highlights/${user.uid}/${highlight.id}')
          .set(highlight.toMap());

      debugPrint('✅ Highlight added: ${highlight.reference}');
    } catch (e) {
      debugPrint('❌ Error adding highlight: $e');
      rethrow;
    }
  }

  /// Get specific highlight
  Future<BibleHighlight?> getHighlight(String highlightId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final snapshot = await _database.ref('bible/highlights/${user.uid}/$highlightId').get();

      if (!snapshot.exists) {
        return null;
      }

      return BibleHighlight.fromSnapshot(snapshot);
    } catch (e) {
      debugPrint('❌ Error fetching highlight: $e');
      return null;
    }
  }

  /// Update highlight color
  Future<void> updateHighlightColor(String highlightId, String newColor) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _database.ref('bible/highlights/${user.uid}/$highlightId/color').set(newColor);
      await _database.ref('bible/highlights/${user.uid}/$highlightId/updatedAt').set(DateTime.now().toIso8601String());

      debugPrint('✅ Highlight color updated: $highlightId -> $newColor');
    } catch (e) {
      debugPrint('❌ Error updating highlight color: $e');
      rethrow;
    }
  }

  /// Remove highlight
  Future<void> removeHighlight(String highlightId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _database.ref('bible/highlights/${user.uid}/$highlightId').remove();

      debugPrint('✅ Highlight removed: $highlightId');
    } catch (e) {
      debugPrint('❌ Error removing highlight: $e');
      rethrow;
    }
  }

  /// Get user notes
  Future<List<BibleNote>> getUserNotes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for notes');
      }

      final snapshot = await _database.ref('bible/notes/${user.uid}').get();

      if (!snapshot.exists) {
        return [];
      }

      final notes = <BibleNote>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map) {
          notes.add(BibleNote.fromSnapshot(snapshot.child(key.toString())));
        }
      });

      // Sort by creation date (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ Loaded ${notes.length} notes');
      return notes;
    } catch (e) {
      debugPrint('❌ Error fetching user notes: $e');
      rethrow;
    }
  }

  /// Add note
  Future<void> addNote(BibleNote note) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check premium access
      if (!await _premiumService.isPremium()) {
        throw Exception('Premium subscription required for notes');
      }

      await _database
          .ref('bible/notes/${user.uid}/${note.id}')
          .set(note.toMap());

      debugPrint('✅ Note added: ${note.reference}');
    } catch (e) {
      debugPrint('❌ Error adding note: $e');
      rethrow;
    }
  }

  /// Get specific note
  Future<BibleNote?> getNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final snapshot = await _database.ref('bible/notes/${user.uid}/$noteId').get();

      if (!snapshot.exists) {
        return null;
      }

      return BibleNote.fromSnapshot(snapshot);
    } catch (e) {
      debugPrint('❌ Error fetching note: $e');
      return null;
    }
  }

  /// Update note
  Future<void> updateNote(String noteId, String newNoteText, {List<String>? tags}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'note': newNoteText,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (tags != null) {
        updates['tags'] = tags;
      }

      await _database.ref('bible/notes/${user.uid}/$noteId').update(updates);

      debugPrint('✅ Note updated: $noteId');
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      rethrow;
    }
  }

  /// Remove note
  Future<void> removeNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _database.ref('bible/notes/${user.uid}/$noteId').remove();

      debugPrint('✅ Note removed: $noteId');
    } catch (e) {
      debugPrint('❌ Error removing note: $e');
      rethrow;
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
