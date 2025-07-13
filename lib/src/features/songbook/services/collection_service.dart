// lib/src/features/songbook/services/collection_service.dart
// ✅ OPTIMIZED: Reduced duplicate API calls with better caching

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/collection_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionService {
  final CollectionRepository _repository = CollectionRepository();
  final AuthorizationService _authService = AuthorizationService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ✅ OPTIMIZATION: Cache user role to avoid repeated auth checks
  static String? _cachedUserRole;
  static DateTime? _roleCacheTimestamp;
  static const Duration _roleCacheValidDuration = Duration(minutes: 2);

  // ✅ OPTIMIZATION: Cache accessible collections
  static List<SongCollection>? _cachedAccessibleCollections;
  static DateTime? _collectionsCacheTimestamp;
  static const Duration _collectionsCacheValidDuration = Duration(minutes: 3);

  /// Gets the current user role with caching to reduce auth service calls
  Future<String> _getCurrentUserRole() async {
    // Check if cached role is still valid
    if (_cachedUserRole != null &&
        _roleCacheTimestamp != null &&
        DateTime.now().difference(_roleCacheTimestamp!).inMinutes <
            _roleCacheValidDuration.inMinutes) {
      return _cachedUserRole!;
    }

    // Get fresh role from auth service
    final adminStatus = await _authService.checkAdminStatus();
    final String userRole = adminStatus['isSuperAdmin'] == true
        ? 'super_admin'
        : adminStatus['isAdmin'] == true
            ? 'admin'
            : 'user';

    // Cache the result
    _cachedUserRole = userRole;
    _roleCacheTimestamp = DateTime.now();

    return userRole;
  }

  /// Fetches all collections that are accessible to the current user with caching
  Future<List<SongCollection>> getAccessibleCollections() async {
    // Check if cached collections are still valid
    if (_cachedAccessibleCollections != null &&
        _collectionsCacheTimestamp != null &&
        DateTime.now().difference(_collectionsCacheTimestamp!).inMinutes <
            _collectionsCacheValidDuration.inMinutes) {
      return _cachedAccessibleCollections!;
    }

    final userRole = await _getCurrentUserRole();
    final result = await _repository.getAllCollections(userRole: userRole);

    // Cache the result
    _cachedAccessibleCollections = result.collections;
    _collectionsCacheTimestamp = DateTime.now();

    return result.collections;
  }

  /// Fetches a specific collection by its ID.
  Future<SongCollection?> getCollectionById(String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getCollectionById(collectionId,
        userRole: userRole);
  }

  /// Fetches songs from a specific collection with proper access control.
  Future<CollectionWithSongsResult> getSongsFromCollection(
      String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getSongsFromCollection(collectionId,
        userRole: userRole);
  }

  /// Gets all songs from all accessible collections (for "All Songs" view).
  Future<List<Song>> getAllSongsFromCollections() async {
    final collections = await getAccessibleCollections();
    final List<Song> allSongs = [];

    for (final collection in collections) {
      final result = await getSongsFromCollection(collection.id);
      allSongs.addAll(result.songs);
    }

    // Remove duplicates by song number and sort
    final Map<String, Song> uniqueSongs = {};
    for (final song in allSongs) {
      uniqueSongs[song.number] = song;
    }

    final sortedSongs = uniqueSongs.values.toList();
    sortedSongs.sort((a, b) =>
        (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));

    return sortedSongs;
  }

  /// Fetches all songs within a specific collection.
  Future<CollectionWithSongsResult> getSongsForCollection(
      String collectionId) async {
    final userRole = await _getCurrentUserRole();
    return await _repository.getCollectionSongs(collectionId,
        userRole: userRole);
  }

  /// Creates a new song collection.
  Future<CollectionOperationResult> createNewCollection(
      String name, String description) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return CollectionOperationResult(
          success: false, errorMessage: 'User not authenticated.');
    }

    final newCollection = SongCollection(
      id: '', // The repository will generate this ID.
      name: name,
      description: description,
      accessLevel: CollectionAccessLevel.admin, // Default access
      status: CollectionStatus.active,
      songCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: currentUser.uid,
    );

    final result = await _repository.createCollection(newCollection);

    // ✅ OPTIMIZATION: Invalidate cache after create operation
    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Updates an existing song collection.
  Future<CollectionOperationResult> updateCollection(
      SongCollection collection) async {
    final result = await _repository.updateCollection(collection);

    // ✅ OPTIMIZATION: Invalidate cache after update operation
    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Deletes a collection and all of its songs.
  Future<CollectionOperationResult> deleteCollection(
      String collectionId) async {
    final result = await _repository.deleteCollection(collectionId);

    // ✅ OPTIMIZATION: Invalidate cache after delete operation
    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Adds a song to a specific collection.
  Future<CollectionOperationResult> addSongToCollection(
      String collectionId, Song song) async {
    final result = await _repository.addSongToCollection(collectionId, song);

    // ✅ OPTIMIZATION: Invalidate cache after modification
    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Removes a song from a specific collection.
  Future<CollectionOperationResult> removeSongFromCollection(
      String collectionId, String songNumber) async {
    final result =
        await _repository.removeSongFromCollection(collectionId, songNumber);

    // ✅ OPTIMIZATION: Invalidate cache after modification
    if (result.success) {
      invalidateCache();
    }

    return result;
  }

  /// Retrieves performance metrics from the repository for debugging.
  Map<String, dynamic> getRepoPerformanceMetrics() {
    return _repository.getPerformanceMetrics();
  }

  /// ✅ NEW: Manual cache invalidation method
  static void invalidateCache() {
    _cachedUserRole = null;
    _roleCacheTimestamp = null;
    _cachedAccessibleCollections = null;
    _collectionsCacheTimestamp = null;
    CollectionRepository.invalidateCache();
    print('🗑️ [CollectionService] All caches invalidated');
  }

  /// ✅ NEW: Get cache status for debugging
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
