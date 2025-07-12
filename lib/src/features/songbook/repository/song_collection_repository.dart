// lib/src/features/songbook/repository/song_collection_repository.dart
// Repository for managing song collections with Firebase integration

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/models/song_collection_model.dart';

class CollectionDataResult {
  final List<SongCollection> collections;
  final bool isOnline;

  CollectionDataResult({required this.collections, required this.isOnline});
}

class SongCollectionRepository {
  static const String _collectionsPath = 'song_collections';

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database =>
      _isFirebaseInitialized ? FirebaseDatabase.instance : null;

  FirebaseAuth? get _auth =>
      _isFirebaseInitialized ? FirebaseAuth.instance : null;

  // Get all collections with user access filtering
  Future<CollectionDataResult> getAllCollections({
    bool includeInactive = false,
    CollectionAccessLevel? filterByAccess,
  }) async {
    debugPrint('🔍 Fetching all song collections...');

    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, returning empty collections');
      return CollectionDataResult(collections: [], isOnline: false);
    }

    try {
      final database = _database!;
      final collectionsRef = database.ref(_collectionsPath);

      final snapshot = await collectionsRef.orderByChild('sortOrder').get();

      if (snapshot.exists && snapshot.value != null) {
        final collectionsData =
            Map<String, dynamic>.from(snapshot.value as Map);

        final collections = collectionsData.entries
            .map((entry) {
              try {
                final collectionData =
                    Map<String, dynamic>.from(entry.value as Map);
                return SongCollection.fromJson(collectionData);
              } catch (e) {
                debugPrint('❌ Error parsing collection ${entry.key}: $e');
                return null;
              }
            })
            .where((collection) => collection != null)
            .cast<SongCollection>()
            .where((collection) {
              // Filter by active status
              if (!includeInactive && !collection.isActive) return false;

              // Filter by access level if specified
              if (filterByAccess != null &&
                  collection.accessLevel != filterByAccess) {
                return false;
              }

              return true;
            })
            .toList();

        // Sort by sortOrder, then by name
        collections.sort((a, b) {
          int result = a.sortOrder.compareTo(b.sortOrder);
          if (result == 0) {
            result = a.name.compareTo(b.name);
          }
          return result;
        });

        debugPrint('✅ Loaded ${collections.length} collections');
        return CollectionDataResult(collections: collections, isOnline: true);
      } else {
        debugPrint('📭 No collections found');
        return CollectionDataResult(collections: [], isOnline: true);
      }
    } catch (e) {
      debugPrint('❌ Error fetching collections: $e');
      return CollectionDataResult(collections: [], isOnline: false);
    }
  }

  // Get collections filtered by user access level
  Future<CollectionDataResult> getCollectionsForUser({
    required bool isAnonymous,
    required bool isRegistered,
    required bool isPremium,
    required bool isAdmin,
    bool includePreview = true,
  }) async {
    final result = await getAllCollections();

    if (!result.isOnline) return result;

    final filteredCollections = result.collections.where((collection) {
      // Always include if user has full access
      if (CollectionAccessControl.canUserAccess(collection,
          isAnonymous: isAnonymous,
          isRegistered: isRegistered,
          isPremium: isPremium,
          isAdmin: isAdmin)) {
        return true;
      }

      // Include preview if enabled
      return includePreview;
    }).toList();

    return CollectionDataResult(
      collections: filteredCollections,
      isOnline: result.isOnline,
    );
  }

  // Get single collection by ID
  Future<SongCollection?> getCollectionById(String collectionId) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized');
      return null;
    }

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/$collectionId');

      final snapshot = await collectionRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final collectionData = Map<String, dynamic>.from(snapshot.value as Map);
        return SongCollection.fromJson(collectionData);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching collection $collectionId: $e');
      return null;
    }
  }

  // Create new collection
  Future<bool> createCollection(SongCollection collection) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot create collection');
      return false;
    }

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/${collection.id}');

      await collectionRef.set(collection.toJson());

      debugPrint('✅ Collection created: ${collection.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating collection: $e');
      return false;
    }
  }

  // Update existing collection
  Future<bool> updateCollection(SongCollection collection) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot update collection');
      return false;
    }

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/${collection.id}');

      // Update the updatedAt timestamp
      final updatedCollection = collection.copyWith(
        updatedAt: DateTime.now(),
      );

      await collectionRef.update(updatedCollection.toJson());

      debugPrint('✅ Collection updated: ${collection.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating collection: $e');
      return false;
    }
  }

  // Delete collection
  Future<bool> deleteCollection(String collectionId) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot delete collection');
      return false;
    }

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/$collectionId');

      await collectionRef.remove();

      debugPrint('✅ Collection deleted: $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting collection: $e');
      return false;
    }
  }

  // Add song to collection
  Future<bool> addSongToCollection(
      String collectionId, String songNumber) async {
    if (!_isFirebaseInitialized) return false;

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/$collectionId');

      // Update the songs map and song count
      await collectionRef.child('songs/$songNumber').set(true);

      // Get current collection to update count
      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        final newCount = collection.songs.length + 1;
        await collectionRef.child('songCount').set(newCount);
        await collectionRef
            .child('updatedAt')
            .set(DateTime.now().toIso8601String());
      }

      debugPrint('✅ Song $songNumber added to collection $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding song to collection: $e');
      return false;
    }
  }

  // Remove song from collection
  Future<bool> removeSongFromCollection(
      String collectionId, String songNumber) async {
    if (!_isFirebaseInitialized) return false;

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/$collectionId');

      // Remove from songs map and update count
      await collectionRef.child('songs/$songNumber').remove();

      // Get current collection to update count
      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        final newCount =
            (collection.songs.length - 1).clamp(0, double.infinity).toInt();
        await collectionRef.child('songCount').set(newCount);
        await collectionRef
            .child('updatedAt')
            .set(DateTime.now().toIso8601String());
      }

      debugPrint('✅ Song $songNumber removed from collection $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing song from collection: $e');
      return false;
    }
  }

  // Bulk add songs to collection
  Future<bool> bulkAddSongsToCollection(
      String collectionId, List<String> songNumbers) async {
    if (!_isFirebaseInitialized) return false;

    try {
      final database = _database!;
      final collectionRef = database.ref('$_collectionsPath/$collectionId');

      // Prepare batch updates
      final Map<String, dynamic> updates = {};
      for (final songNumber in songNumbers) {
        updates['songs/$songNumber'] = true;
      }

      // Get current collection to update count
      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        final newCount = collection.songs.length + songNumbers.length;
        updates['songCount'] = newCount;
        updates['updatedAt'] = DateTime.now().toIso8601String();
      }

      await collectionRef.update(updates);

      debugPrint(
          '✅ Bulk added ${songNumbers.length} songs to collection $collectionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error bulk adding songs to collection: $e');
      return false;
    }
  }

  // Get collections containing a specific song
  Future<List<SongCollection>> getCollectionsContainingSong(
      String songNumber) async {
    final result = await getAllCollections();

    if (!result.isOnline) return [];

    return result.collections
        .where((collection) => collection.containsSong(songNumber))
        .toList();
  }

  // Create default collections for new installation
  Future<bool> createDefaultCollections() async {
    debugPrint('🏗️ Creating default collections...');

    final defaultCollections = _getDefaultCollections();
    bool allCreated = true;

    for (final collection in defaultCollections) {
      final success = await createCollection(collection);
      if (!success) {
        allCreated = false;
        debugPrint('❌ Failed to create collection: ${collection.name}');
      }
    }

    if (allCreated) {
      debugPrint('✅ All default collections created successfully');
    }

    return allCreated;
  }

  // Bulk operations for admin
  Future<bool> bulkUpdateCollectionAccess(
    List<String> collectionIds,
    CollectionAccessLevel newAccessLevel,
  ) async {
    if (!_isFirebaseInitialized) return false;

    try {
      final database = _database!;
      final Map<String, dynamic> updates = {};

      for (final collectionId in collectionIds) {
        updates['$_collectionsPath/$collectionId/accessLevel'] =
            newAccessLevel.name;
        updates['$_collectionsPath/$collectionId/updatedAt'] =
            DateTime.now().toIso8601String();
      }

      await database.ref().update(updates);

      debugPrint(
          '✅ Bulk updated access level for ${collectionIds.length} collections');
      return true;
    } catch (e) {
      debugPrint('❌ Error bulk updating collection access: $e');
      return false;
    }
  }

  // Get preview songs (first 10) for locked collections
  List<String> getPreviewSongs(SongCollection collection, {int limit = 10}) {
    final allSongs = collection.songNumbers;
    return allSongs.take(limit).toList();
  }

  // Helper method to get default collections
  List<SongCollection> _getDefaultCollections() {
    final now = DateTime.now();

    return [
      // Public Collections
      SongCollection(
        id: 'public_sunday_service',
        name: 'Sunday Service Songs',
        description: 'Popular songs for Sunday worship services',
        accessLevel: CollectionAccessLevel.public,
        category: CollectionCategory.worship,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {}, // Will be populated by admin
        songCount: 0,
        sortOrder: 1,
        tags: ['worship', 'sunday', 'service'],
      ),

      SongCollection(
        id: 'public_traditional',
        name: 'Traditional Hymns',
        description: 'Classic traditional hymns and spiritual songs',
        accessLevel: CollectionAccessLevel.public,
        category: CollectionCategory.traditional,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 2,
        tags: ['traditional', 'hymns', 'classic'],
      ),

      SongCollection(
        id: 'public_christmas',
        name: 'Christmas Carols',
        description: 'Festive Christmas songs and carols',
        accessLevel: CollectionAccessLevel.public,
        category: CollectionCategory.seasonal,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 3,
        tags: ['christmas', 'seasonal', 'carols'],
      ),

      // Registered User Collections
      SongCollection(
        id: 'registered_favorites',
        name: 'Member Favorites',
        description: 'Curated favorites for registered members',
        accessLevel: CollectionAccessLevel.registered,
        category: CollectionCategory.special,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 4,
        tags: ['favorites', 'members', 'curated'],
      ),

      SongCollection(
        id: 'registered_weekly',
        name: 'Weekly Featured',
        description: 'Featured songs updated weekly for members',
        accessLevel: CollectionAccessLevel.registered,
        category: CollectionCategory.special,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 5,
        tags: ['weekly', 'featured', 'rotating'],
      ),

      // Premium Collections
      SongCollection(
        id: 'premium_exclusive',
        name: 'Exclusive Worship',
        description: 'Premium-only worship songs with enhanced audio',
        accessLevel: CollectionAccessLevel.premium,
        category: CollectionCategory.worship,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 6,
        tags: ['premium', 'exclusive', 'audio'],
      ),

      SongCollection(
        id: 'premium_advanced',
        name: 'Advanced Hymnal',
        description: 'Rare and advanced hymns for premium members',
        accessLevel: CollectionAccessLevel.premium,
        category: CollectionCategory.traditional,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 7,
        tags: ['premium', 'advanced', 'rare'],
      ),

      // Admin Collections
      SongCollection(
        id: 'admin_training',
        name: 'Staff Training Songs',
        description: 'Songs for staff training and practice',
        accessLevel: CollectionAccessLevel.admin,
        category: CollectionCategory.training,
        createdBy: 'system',
        createdAt: now,
        updatedAt: now,
        songs: {},
        songCount: 0,
        sortOrder: 8,
        tags: ['admin', 'training', 'staff'],
      ),
    ];
  }
}
