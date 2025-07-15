// lib/src/features/songbook/services/collection_service.dart
// ✅ FIXED: Switched to a more reliable collection fetching strategy
// ✅ OPTIMIZED: Reduced duplicate API calls with better caching

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/collection_repository.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart'; // ✅ NEW: Import SongRepository
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:flutter/foundation.dart';

class CollectionService {
  final CollectionRepository _repository = CollectionRepository();
  final SongRepository _songRepository =
      SongRepository(); // ✅ NEW: Add SongRepository instance
  final AuthorizationService _authService = AuthorizationService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static String? _cachedUserRole;
  static DateTime? _roleCacheTimestamp;
  static const Duration _roleCacheValidDuration = Duration(minutes: 2);

  static List<SongCollection>? _cachedAccessibleCollections;
  static DateTime? _collectionsCacheTimestamp;
  static const Duration _collectionsCacheValidDuration = Duration(minutes: 3);

  Future<String> _getCurrentUserRole() async {
    if (_cachedUserRole != null &&
        _roleCacheTimestamp != null &&
        DateTime.now().difference(_roleCacheTimestamp!).inMinutes <
            _roleCacheValidDuration.inMinutes) {
      return _cachedUserRole!;
    }

    final adminStatus = await _authService.checkAdminStatus();
    final String userRole = adminStatus['isSuperAdmin'] == true
        ? 'super_admin'
        : adminStatus['isAdmin'] == true
            ? 'admin'
            : 'user';

    _cachedUserRole = userRole;
    _roleCacheTimestamp = DateTime.now();
    return userRole;
  }

  /// ✅ FIXED: Implemented a more reliable collection fetching strategy.
  Future<List<SongCollection>> getAccessibleCollections() async {
    if (_cachedAccessibleCollections != null &&
        _collectionsCacheTimestamp != null &&
        DateTime.now().difference(_collectionsCacheTimestamp!).inMinutes <
            _collectionsCacheValidDuration.inMinutes) {
      debugPrint("✅ [CollectionService] Using cached collections.");
      return _cachedAccessibleCollections!;
    }

    debugPrint("🔄 [CollectionService] Fetching accessible collections...");

    try {
      // 1. Use the known-working SongRepository to get the IDs of all collections.
      final separatedData = await _songRepository.getCollectionsSeparated();
      final collectionIds = separatedData.keys
          .where((k) => k != 'All' && k != 'Favorites')
          .toList();

      debugPrint(
          "🔍 [CollectionService] Found ${collectionIds.length} collection IDs: $collectionIds");

      if (collectionIds.isEmpty) {
        debugPrint(
            "⚠️ [CollectionService] No collection IDs found from SongRepository.");
        return [];
      }

      final List<SongCollection> collections = [];
      final userRole = await _getCurrentUserRole();

      // 2. Fetch the detailed metadata for each collection ID.
      for (final id in collectionIds) {
        final collection =
            await _repository.getCollectionById(id, userRole: userRole);
        if (collection != null) {
          collections.add(collection);
        } else {
          debugPrint(
              "⚠️ [CollectionService] Could not fetch details for collection ID: $id");
        }
      }

      debugPrint(
          "✅ [CollectionService] Successfully fetched details for ${collections.length} collections.");

      // 3. Cache and return the result.
      _cachedAccessibleCollections = collections;
      _collectionsCacheTimestamp = DateTime.now();

      return collections;
    } catch (e) {
      debugPrint("❌ [CollectionService] Error in getAccessibleCollections: $e");
      return []; // Return empty list on error
    }
  }

  Future<SongCollection?> getCollectionById(String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getCollectionById(collectionId,
        userRole: userRole);
  }

  Future<CollectionWithSongsResult> getSongsFromCollection(
      String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getSongsFromCollection(collectionId,
        userRole: userRole);
  }

  Future<List<Song>> getAllSongsFromCollections() async {
    final collections = await getAccessibleCollections();
    final List<Song> allSongs = [];

    for (final collection in collections) {
      final result = await getSongsFromCollection(collection.id);
      allSongs.addAll(result.songs);
    }

    final Map<String, Song> uniqueSongs = {};
    for (final song in allSongs) {
      uniqueSongs[song.number] = song;
    }

    final sortedSongs = uniqueSongs.values.toList();
    sortedSongs.sort((a, b) =>
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

    return sortedSongs;
  }

  Future<CollectionWithSongsResult> getSongsForCollection(
      String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getCollectionSongs(collectionId,
        userRole: userRole);
  }

  Future<CollectionOperationResult> createNewCollection(
      String name, String description) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return CollectionOperationResult(
          success: false, errorMessage: 'User not authenticated.');
    }

    final newCollection = SongCollection(
      id: '',
      name: name,
      description: description,
      accessLevel: CollectionAccessLevel.admin,
      status: CollectionStatus.active,
      songCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: currentUser.uid,
    );

    final result = await _repository.createCollection(newCollection);

    if (result.success) {
      invalidateCache();
    }
    return result;
  }

  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    final result = await _repository.updateCollection(collection);

    if (result.success) {
      invalidateCache();
    }
    return result;
  }

  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    final result = await _repository.deleteCollection(collectionId);

    if (result.success) {
      invalidateCache();
    }
    return result;
  }

  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song) async {
    final result = await _repository.addSongToCollection(collectionId, song);

    if (result.success) {
      invalidateCache();
    }
    return result;
  }

  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    final result =
        await _repository.removeSongFromCollection(collectionId, songNumber);

    if (result.success) {
      invalidateCache();
    }
    return result;
  }

  Map<String, dynamic> getRepoPerformanceMetrics() {
    return _repository.getPerformanceMetrics();
  }

  static void invalidateCache() {
    _cachedUserRole = null;
    _roleCacheTimestamp = null;
    _cachedAccessibleCollections = null;
    _collectionsCacheTimestamp = null;
    CollectionRepository.invalidateCache();
    debugPrint('🗑️ [CollectionService] All caches invalidated');
  }

  Map<String, dynamic> getCacheStatus() {
    return {
      'userRole': {
        'cached': _cachedUserRole,
        'cacheAge': _roleCacheTimestamp != null
            ? DateTime.now().difference(_roleCacheTimestamp!).inSeconds
            : null,
        'isValid': _cachedUserRole != null &&
            _roleCacheTimestamp != null &&
            DateTime.now().difference(_roleCacheTimestamp!).inMinutes <
                _roleCacheValidDuration.inMinutes,
      },
      'collections': {
        'cached': _cachedAccessibleCollections?.length ?? 0,
        'cacheAge': _collectionsCacheTimestamp != null
            ? DateTime.now().difference(_collectionsCacheTimestamp!).inSeconds
            : null,
        'isValid': _cachedAccessibleCollections != null &&
            _collectionsCacheTimestamp != null &&
            DateTime.now().difference(_collectionsCacheTimestamp!).inMinutes <
                _collectionsCacheValidDuration.inMinutes,
      }
    };
  }
}
