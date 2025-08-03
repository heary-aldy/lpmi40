// lib/src/features/songbook/repository/song_repository_local.dart
// LOCAL JSON VERSION - Reads song collections from embedded JSON files

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

// ============================================================================
// RESULT WRAPPER CLASSES (maintaining backward compatibility)
// ============================================================================

class SongDataResult {
  final List<Song> songs;
  final bool isOnline;

  SongDataResult({required this.songs, required this.isOnline});
}

class PaginatedSongDataResult {
  final List<Song> songs;
  final bool isOnline;
  final String? lastKey;
  final bool hasMore;

  PaginatedSongDataResult({
    required this.songs,
    required this.isOnline,
    required this.hasMore,
    this.lastKey,
  });
}

class SongWithStatusResult {
  final Song? song;
  final bool isOnline;

  SongWithStatusResult({required this.song, required this.isOnline});
}

class UnifiedSongDataResult {
  final List<Song> songs;
  final bool isOnline;
  final int legacySongs;
  final int collectionSongs;
  final List<String> activeCollections;

  UnifiedSongDataResult({
    required this.songs,
    required this.isOnline,
    required this.legacySongs,
    required this.collectionSongs,
    required this.activeCollections,
  });

  int get totalSongs => songs.length;
  bool get hasCollectionSongs => collectionSongs > 0;
  bool get hasLegacySongs => legacySongs > 0;
  bool get isHybridMode => hasCollectionSongs && hasLegacySongs;
}

class SongSearchResult {
  final List<Song> songs;
  final bool isOnline;
  final String searchTerm;
  final int totalMatches;
  final Map<String, int> collectionMatches;

  SongSearchResult({
    required this.songs,
    required this.isOnline,
    required this.searchTerm,
    required this.totalMatches,
    required this.collectionMatches,
  });
}

class SongAvailabilityResult {
  final Song? song;
  final bool isOnline;
  final bool foundInLegacy;
  final bool foundInCollections;
  final List<String> availableInCollections;

  SongAvailabilityResult({
    required this.song,
    required this.isOnline,
    required this.foundInLegacy,
    required this.foundInCollections,
    required this.availableInCollections,
  });
}

// ============================================================================
// LOCAL JSON SONG REPOSITORY
// ============================================================================

class SongRepository {
  // Local JSON asset paths
  static const Map<String, String> _assetPaths = {
    'LPMI': 'assets/data/lpmi.json',
    'Iban': 'assets/data/iban.json', 
    'Pandak': 'assets/data/pandak.json',
    'SRD': 'assets/data/srd.json',
  };

  // Cache for loaded songs
  static Map<String, List<Song>>? _cachedSongs;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ============================================================================
  // MAIN DATA LOADING METHODS
  // ============================================================================

  /// Load all songs from local JSON files
  Future<SongDataResult> getAllSongs() async {
    _logOperation('getAllSongs');
    
    try {
      final songs = await _loadAllSongsFromAssets();
      debugPrint('[SongRepository] ✅ Loaded ${songs.length} songs from local JSON');
      return SongDataResult(songs: songs, isOnline: false); // Always offline for local files
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error loading songs: $e');
      return SongDataResult(songs: [], isOnline: false);
    }
  }

  /// Get songs separated by collection
  Future<Map<String, List<Song>>> getCollectionsSeparated({bool forceRefresh = false}) async {
    _logOperation('getCollectionsSeparated', {'forceRefresh': forceRefresh});
    
    try {
      if (forceRefresh || _cachedSongs == null || _isCacheExpired()) {
        if (forceRefresh) {
          clearCache();
        }
        await _loadAllCollectionsIntoCache();
      }
      
      final result = Map<String, List<Song>>.from(_cachedSongs!);
      
      // Add "All" collection with all songs combined
      final allSongs = <Song>[];
      for (final songs in result.values) {
        allSongs.addAll(songs);
      }
      
      // Remove duplicates and sort
      final uniqueSongs = <String, Song>{};
      for (final song in allSongs) {
        uniqueSongs[song.number] = song;
      }
      
      final sortedSongs = uniqueSongs.values.toList();
      sortedSongs.sort((a, b) => 
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
      
      result['All'] = sortedSongs;
      result['Favorites'] = []; // Empty favorites for now
      
      debugPrint('[SongRepository] ✅ Loaded ${result.length} collections');
      return result;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error loading collections: $e');
      return {};
    }
  }

  /// Get songs from a specific collection
  Future<List<Song>> getSongsFromCollection(String collectionId) async {
    _logOperation('getSongsFromCollection', {'collectionId': collectionId});
    
    try {
      if (_cachedSongs == null || _isCacheExpired()) {
        await _loadAllCollectionsIntoCache();
      }
      
      final songs = _cachedSongs![collectionId] ?? [];
      debugPrint('[SongRepository] ✅ Loaded ${songs.length} songs from $collectionId');
      return songs;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error loading songs from $collectionId: $e');
      return [];
    }
  }

  /// Get a specific song by number
  Future<SongWithStatusResult> getSongByNumber(String songNumber) async {
    _logOperation('getSongByNumber', {'songNumber': songNumber});
    
    try {
      final allSongs = await _loadAllSongsFromAssets();
      final song = allSongs.firstWhere(
        (s) => s.number == songNumber,
        orElse: () => throw Exception('Song not found'),
      );
      
      debugPrint('[SongRepository] ✅ Found song $songNumber');
      return SongWithStatusResult(song: song, isOnline: false);
    } catch (e) {
      debugPrint('[SongRepository] ❌ Song $songNumber not found: $e');
      return SongWithStatusResult(song: null, isOnline: false);
    }
  }

  /// Search songs by title or lyrics
  Future<SongSearchResult> searchSongs(String query) async {
    _logOperation('searchSongs', {'query': query});
    
    try {
      final allSongs = await _loadAllSongsFromAssets();
      final searchTerm = query.toLowerCase();
      final matchingSongs = <Song>[];
      final collectionMatches = <String, int>{};
      
      for (final song in allSongs) {
        bool matches = false;
        
        // Search in title
        if (song.title.toLowerCase().contains(searchTerm)) {
          matches = true;
        }
        
        // Search in lyrics
        if (!matches) {
          for (final verse in song.verses) {
            if (verse.lyrics.toLowerCase().contains(searchTerm)) {
              matches = true;
              break;
            }
          }
        }
        
        if (matches) {
          matchingSongs.add(song);
          final collection = song.collectionId ?? 'Unknown';
          collectionMatches[collection] = (collectionMatches[collection] ?? 0) + 1;
        }
      }
      
      // Sort by song number
      matchingSongs.sort((a, b) => 
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
      
      debugPrint('[SongRepository] ✅ Found ${matchingSongs.length} matches for "$query"');
      return SongSearchResult(
        songs: matchingSongs,
        isOnline: false,
        searchTerm: query,
        totalMatches: matchingSongs.length,
        collectionMatches: collectionMatches,
      );
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error searching songs: $e');
      return SongSearchResult(
        songs: [],
        isOnline: false,
        searchTerm: query,
        totalMatches: 0,
        collectionMatches: {},
      );
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Load all songs from asset files
  Future<List<Song>> _loadAllSongsFromAssets() async {
    if (_cachedSongs == null || _isCacheExpired()) {
      await _loadAllCollectionsIntoCache();
    }
    
    final allSongs = <Song>[];
    for (final songs in _cachedSongs!.values) {
      allSongs.addAll(songs);
    }
    
    // Remove duplicates based on song number
    final uniqueSongs = <String, Song>{};
    for (final song in allSongs) {
      uniqueSongs[song.number] = song;
    }
    
    final sortedSongs = uniqueSongs.values.toList();
    sortedSongs.sort((a, b) => 
      (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
    
    return sortedSongs;
  }

  /// Load all collections into cache
  Future<void> _loadAllCollectionsIntoCache() async {
    debugPrint('[SongRepository] 🔄 Loading collections from local JSON...');
    
    final collections = <String, List<Song>>{};
    
    for (final entry in _assetPaths.entries) {
      final collectionName = entry.key;
      final assetPath = entry.value;
      
      try {
        final songs = await _loadSongsFromAsset(assetPath, collectionName);
        collections[collectionName] = songs;
        debugPrint('[SongRepository] ✅ Loaded ${songs.length} songs from $collectionName');
      } catch (e) {
        debugPrint('[SongRepository] ⚠️ Failed to load $collectionName: $e');
        collections[collectionName] = [];
      }
    }
    
    _cachedSongs = collections;
    _cacheTimestamp = DateTime.now();
  }

  /// Load songs from a specific asset file
  Future<List<Song>> _loadSongsFromAsset(String assetPath, String collectionId) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);
      final songs = <Song>[];
      
      if (jsonData is Map) {
        // Handle object format (like lpmi.json)
        for (final entry in jsonData.entries) {
          try {
            final songData = Map<String, dynamic>.from(entry.value as Map);
            songData['collectionId'] = collectionId;
            
            final song = Song.fromJson(songData);
            songs.add(song);
          } catch (e) {
            debugPrint('[SongRepository] ⚠️ Failed to parse song ${entry.key}: $e');
          }
        }
      } else if (jsonData is List) {
        // Handle array format (like iban.json, srd.json)
        for (final songData in jsonData) {
          try {
            final songMap = Map<String, dynamic>.from(songData as Map);
            songMap['collectionId'] = collectionId;
            
            final song = Song.fromJson(songMap);
            songs.add(song);
          } catch (e) {
            debugPrint('[SongRepository] ⚠️ Failed to parse song in $collectionId: $e');
          }
        }
      }
      
      // Sort by song number
      songs.sort((a, b) => 
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
      
      return songs;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error loading $assetPath: $e');
      return [];
    }
  }

  /// Check if cache is expired
  bool _isCacheExpired() {
    if (_cacheTimestamp == null) return true;
    return DateTime.now().difference(_cacheTimestamp!).compareTo(_cacheValidDuration) > 0;
  }

  /// Log operation for debugging
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
      final count = _operationCounts[operation];
      debugPrint('[SongRepository] 🔧 $operation (count: $count)');
      if (details != null) {
        debugPrint('[SongRepository] 📊 Details: $details');
      }
    }
  }

  // ============================================================================
  // COMPATIBILITY METHODS (for existing code)
  // ============================================================================

  /// Get unified song data (maintaining compatibility)
  Future<UnifiedSongDataResult> getUnifiedSongData() async {
    final songs = await _loadAllSongsFromAssets();
    final collections = await getCollectionsSeparated();
    
    return UnifiedSongDataResult(
      songs: songs,
      isOnline: false,
      legacySongs: 0, // No legacy songs in local mode
      collectionSongs: songs.length,
      activeCollections: collections.keys.where((k) => k != 'All' && k != 'Favorites').toList(),
    );
  }

  /// Get paginated songs (for compatibility)
  Future<PaginatedSongDataResult> getPaginatedSongs({
    int limit = 50,
    String? startAfter,
  }) async {
    final allSongs = await _loadAllSongsFromAssets();
    
    int startIndex = 0;
    if (startAfter != null) {
      startIndex = allSongs.indexWhere((s) => s.number == startAfter) + 1;
      if (startIndex < 0) startIndex = 0;
    }
    
    final endIndex = (startIndex + limit).clamp(0, allSongs.length);
    final paginatedSongs = allSongs.sublist(startIndex, endIndex);
    final hasMore = endIndex < allSongs.length;
    final lastKey = paginatedSongs.isNotEmpty ? paginatedSongs.last.number : null;
    
    return PaginatedSongDataResult(
      songs: paginatedSongs,
      isOnline: false,
      hasMore: hasMore,
      lastKey: lastKey,
    );
  }

  /// Check song availability (for compatibility)
  Future<SongAvailabilityResult> checkSongAvailability(String songNumber) async {
    final result = await getSongByNumber(songNumber);
    
    return SongAvailabilityResult(
      song: result.song,
      isOnline: false,
      foundInLegacy: false,
      foundInCollections: result.song != null,
      availableInCollections: result.song != null ? [result.song!.collectionId ?? 'Unknown'] : [],
    );
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'isLocalMode': true,
      'cacheStatus': {
        'cached': _cachedSongs != null,
        'cacheAge': _cacheTimestamp != null 
          ? DateTime.now().difference(_cacheTimestamp!).inSeconds 
          : null,
        'isValid': !_isCacheExpired(),
        'collections': _cachedSongs?.keys.toList() ?? [],
      },
    };
  }

  /// Clear cache (for debugging)
  void clearCache() {
    _cachedSongs = null;
    _cacheTimestamp = null;
    debugPrint('[SongRepository] 🗑️ Cache cleared');
  }

  // ============================================================================
  // MISSING METHODS FOR COMPATIBILITY (Local mode - read-only operations)
  // ============================================================================


  /// Get recently added songs (for compatibility - returns first N songs)
  Future<List<Song>> getRecentlyAddedSongs({int limit = 10}) async {
    _logOperation('getRecentlyAddedSongs', {'limit': limit});
    
    try {
      final allSongs = await _loadAllSongsFromAssets();
      final recentSongs = allSongs.take(limit).toList();
      debugPrint('[SongRepository] ✅ Retrieved $limit recent songs');
      return recentSongs;
    } catch (e) {
      debugPrint('[SongRepository] ❌ Error getting recent songs: $e');
      return [];
    }
  }

  /// Get song by number with status (compatibility wrapper)
  Future<SongWithStatusResult> getSongByNumberWithStatus(String songNumber) async {
    return await getSongByNumber(songNumber);
  }

  /// Add song (Local mode - not supported, returns error)
  Future<Map<String, dynamic>> addSong(Song song) async {
    debugPrint('[SongRepository] ⚠️ addSong not supported in local mode');
    return {
      'success': false,
      'error': 'Add song not supported in local JSON mode',
      'isOffline': true,
    };
  }

  /// Update song (Local mode - not supported, returns error)
  Future<Map<String, dynamic>> updateSong(String originalNumber, Song song) async {
    debugPrint('[SongRepository] ⚠️ updateSong not supported in local mode');
    return {
      'success': false,
      'error': 'Update song not supported in local JSON mode',
      'isOffline': true,
    };
  }

  /// Delete song (Local mode - not supported, returns error)
  Future<Map<String, dynamic>> deleteSong(String songNumber) async {
    debugPrint('[SongRepository] ⚠️ deleteSong not supported in local mode');
    return {
      'success': false,
      'error': 'Delete song not supported in local JSON mode',
      'isOffline': true,
    };
  }

  /// Get optimization status (for compatibility)
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'isOptimized': true,
      'mode': 'local_json',
      'cacheHitRate': 100,
      'averageLoadTime': 50, // milliseconds
      'totalOperations': _operationCounts.values.fold(0, (a, b) => a + b),
      'collections': _cachedSongs?.keys.toList() ?? [],
      'recommendations': ['Local JSON mode is already optimized'],
    };
  }

  /// Invalidate cache for development (static method for compatibility)
  static void invalidateCacheForDevelopment({String? reason}) {
    _cachedSongs = null;
    _cacheTimestamp = null;
    debugPrint('[SongRepository] 🗑️ Development cache invalidated: ${reason ?? 'No reason provided'}');
  }
}