import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FavoritesRepository {
  // Check if Firebase is initialized
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

  // ✅ NEW: Get favorites grouped by collection for the new favorites page
  Future<Map<String, List<String>>> getFavoritesGroupedByCollection() async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, returning empty favorites');
      return {};
    }

    final user = _auth?.currentUser;
    if (user == null) {
      debugPrint('No user logged in, returning empty favorites');
      return {};
    }

    try {
      debugPrint('🔄 Fetching grouped favorites for user: ${user.email}');

      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final groupedFavorites = <String, List<String>>{};

        // Check if we have the new collection-based structure
        final hasCollectionStructure = data.containsKey('global') ||
            data.containsKey('LPMI') ||
            data.containsKey('SRD');

        if (hasCollectionStructure) {
          // NEW: Collection-specific favorites
          for (final collectionEntry in data.entries) {
            if (collectionEntry.value is Map) {
              final collectionFavorites =
                  Map<String, dynamic>.from(collectionEntry.value);
              final favorites = collectionFavorites.entries
                  .where((entry) => entry.value == true)
                  .map((entry) => entry.key)
                  .toList();

              if (favorites.isNotEmpty) {
                groupedFavorites[collectionEntry.key] = favorites;
              }
            }
          }
        } else {
          // OLD: Legacy structure - put all in global
          final favoritesList = data.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();

          if (favoritesList.isNotEmpty) {
            groupedFavorites['global'] = favoritesList;
          }

          // Migrate to new structure
          await _migrateLegacyFavoritesToCollections(favoritesList);
        }

        debugPrint(
            '✅ Found grouped favorites: ${groupedFavorites.keys.toList()}');
        return groupedFavorites;
      } else {
        debugPrint('📭 No favorites found for user');
        return {};
      }
    } catch (e) {
      debugPrint("❌ Error fetching grouped favorites: $e");
      return {};
    }
  }

  // ✅ Get favorites using proper data structure from your export
  // Structure: "favorites": { "001": true, "004": true } for legacy
  // NEW Structure: "favorites": { "global": { "001": true }, "LPMI": { "001": true }, "SRD": { "002": true } }
  Future<List<String>> getFavorites([String? collectionId]) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, returning empty favorites');
      return [];
    }

    final user = _auth?.currentUser;
    if (user == null) {
      debugPrint('No user logged in, returning empty favorites');
      return [];
    }

    try {
      debugPrint(
          '🔄 Fetching favorites for user: ${user.email}, collection: $collectionId');

      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Check if we have the new collection-based structure
        final hasCollectionStructure = data.containsKey('global') ||
            data.containsKey('LPMI') ||
            data.containsKey('SRD');

        if (hasCollectionStructure) {
          // NEW: Collection-specific favorites
          if (collectionId != null && data.containsKey(collectionId)) {
            final collectionFavorites =
                Map<String, dynamic>.from(data[collectionId]);
            final favoritesList = collectionFavorites.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList();
            debugPrint(
                '✅ Found ${favoritesList.length} favorites for $collectionId: $favoritesList');
            return favoritesList;
          } else if (collectionId == null) {
            // Return all favorites from all collections
            final allFavorites = <String>[];
            for (final collectionEntry in data.entries) {
              if (collectionEntry.value is Map) {
                final collectionFavorites =
                    Map<String, dynamic>.from(collectionEntry.value);
                final favorites = collectionFavorites.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => entry.key)
                    .toSet(); // Use set to avoid duplicates
                allFavorites.addAll(favorites);
              }
            }
            debugPrint(
                '✅ Found ${allFavorites.length} total favorites: $allFavorites');
            return allFavorites.toList();
          }
        } else {
          // OLD: Legacy structure - migrate and return
          final favoritesList = data.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();

          // Migrate to new structure
          await _migrateLegacyFavoritesToCollections(favoritesList);

          debugPrint(
              '✅ Found ${favoritesList.length} legacy favorites (migrated): $favoritesList');
          return favoritesList;
        }

        return [];
      } else {
        debugPrint('📭 No favorites found for user');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching favorites: $e");
      return [];
    }
  }

  // ✅ Toggle favorite using collection-aware structure
  Future<void> toggleFavoriteStatus(String songNumber, bool isCurrentlyFavorite,
      [String? collectionId]) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot toggle favorite');
      return;
    }

    final user = _auth?.currentUser;
    if (user == null) {
      debugPrint('No user logged in, cannot save favorites');
      return;
    }

    try {
      debugPrint(
          '🔄 Toggling favorite status for song $songNumber in collection $collectionId (currently: $isCurrentlyFavorite)');

      // Use collection-specific path if provided, otherwise use global
      final collection = collectionId ?? 'global';
      final ref =
          _database!.ref('users/${user.uid}/favorites/$collection/$songNumber');

      if (isCurrentlyFavorite) {
        // Remove from favorites by deleting the key
        await ref.remove();
        debugPrint('✅ Removed song $songNumber from $collection favorites');
      } else {
        // Add to favorites by setting the value to true
        await ref.set(true);
        debugPrint('✅ Added song $songNumber to $collection favorites');
      }
    } catch (e) {
      debugPrint("❌ Error updating favorite status: $e");
      rethrow; // Re-throw so UI can handle the error
    }
  }

  // ✅ Add multiple songs to favorites at once
  Future<void> addMultipleFavorites(List<String> songNumbers) async {
    if (!_isFirebaseInitialized || songNumbers.isEmpty) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Adding ${songNumbers.length} songs to favorites');

      final ref = _database!.ref('users/${user.uid}/favorites');
      final updateData = <String, dynamic>{};

      for (String songNumber in songNumbers) {
        updateData[songNumber] = true;
      }

      await ref.update(updateData);
      debugPrint('✅ Added multiple favorites: $songNumbers');
    } catch (e) {
      debugPrint("❌ Error adding multiple favorites: $e");
      rethrow;
    }
  }

  // ✅ Remove multiple songs from favorites
  Future<void> removeMultipleFavorites(List<String> songNumbers) async {
    if (!_isFirebaseInitialized || songNumbers.isEmpty) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Removing ${songNumbers.length} songs from favorites');

      final ref = _database!.ref('users/${user.uid}/favorites');

      // ✅ Remove each song individually to avoid type issues
      for (String songNumber in songNumbers) {
        await ref.child(songNumber).remove();
      }

      debugPrint('✅ Removed multiple favorites: $songNumbers');
    } catch (e) {
      debugPrint("❌ Error removing multiple favorites: $e");
      rethrow;
    }
  }

  // ✅ Clear all favorites
  Future<void> clearAllFavorites() async {
    if (!_isFirebaseInitialized) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Clearing all favorites for user: ${user.email}');

      final ref = _database!.ref('users/${user.uid}/favorites');
      await ref.remove();

      debugPrint('✅ All favorites cleared');
    } catch (e) {
      debugPrint("❌ Error clearing favorites: $e");
      rethrow;
    }
  }

  // ✅ Check if a specific song is favorited in a collection
  Future<bool> isSongFavorite(String songNumber, [String? collectionId]) async {
    if (!_isFirebaseInitialized) return false;

    final user = _auth?.currentUser;
    if (user == null) return false;

    try {
      final collection = collectionId ?? 'global';
      final ref =
          _database!.ref('users/${user.uid}/favorites/$collection/$songNumber');
      final snapshot = await ref.get();

      return snapshot.exists && snapshot.value == true;
    } catch (e) {
      debugPrint("❌ Error checking if song is favorite: $e");
      return false;
    }
  }

  // ✅ Get favorites count
  Future<int> getFavoritesCount() async {
    if (!_isFirebaseInitialized) return 0;

    final user = _auth?.currentUser;
    if (user == null) return 0;

    try {
      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.where((entry) => entry.value == true).length;
      }
      return 0;
    } catch (e) {
      debugPrint("❌ Error getting favorites count: $e");
      return 0;
    }
  }

  // ✅ Initialize favorites object if it doesn't exist
  Future<void> initializeFavoritesIfNeeded() async {
    if (!_isFirebaseInitialized) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        await ref.set(<String, dynamic>{});
        debugPrint('✅ Initialized empty favorites object for user');
      }
    } catch (e) {
      debugPrint("❌ Error initializing favorites: $e");
    }
  }

  // ✅ Sync favorites from another device/account
  Future<void> syncFavoritesFromData(Map<String, dynamic> favoritesData) async {
    if (!_isFirebaseInitialized || favoritesData.isEmpty) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      debugPrint('🔄 Syncing favorites from external data');

      final ref = _database!.ref('users/${user.uid}/favorites');

      // ✅ Filter to only include entries where value is true
      final validFavorites = <String, dynamic>{};
      for (var entry in favoritesData.entries) {
        if (entry.value == true) {
          validFavorites[entry.key] = true;
        }
      }

      await ref.set(validFavorites);
      debugPrint('✅ Synced ${validFavorites.length} favorites');
    } catch (e) {
      debugPrint("❌ Error syncing favorites: $e");
      rethrow;
    }
  }

  // ✅ Export favorites for backup/migration
  Future<Map<String, dynamic>?> exportFavorites() async {
    if (!_isFirebaseInitialized) return null;

    final user = _auth?.currentUser;
    if (user == null) return null;

    try {
      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return <String, dynamic>{};
    } catch (e) {
      debugPrint("❌ Error exporting favorites: $e");
      return null;
    }
  }

  Future<void> removeFavorite(String number) async {
    await toggleFavoriteStatus(number, true);
  }

  Future<void> addFavorite(String number) async {
    await toggleFavoriteStatus(number, false);
  }

  // ✅ NEW: Migrate legacy favorites to collection-based structure
  Future<void> _migrateLegacyFavoritesToCollections(
      List<String> legacyFavorites) async {
    if (!_isFirebaseInitialized || legacyFavorites.isEmpty) return;

    final user = _auth?.currentUser;
    if (user == null) return;

    try {
      debugPrint(
          '🔄 Migrating ${legacyFavorites.length} legacy favorites to collection structure');

      final ref = _database!.ref('users/${user.uid}/favorites');

      // Create new structure with global collection containing all legacy favorites
      final newStructure = {
        'global': {
          for (String songNumber in legacyFavorites) songNumber: true,
        }
      };

      await ref.set(newStructure);
      debugPrint('✅ Successfully migrated favorites to collection structure');
    } catch (e) {
      debugPrint('❌ Error migrating legacy favorites: $e');
    }
  }

  // ✅ NEW: Get collection-specific favorite color
  static Color getFavoriteColorForCollection(String? collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return const Color(0xFF1976D2); // Blue
      case 'SRD':
        return const Color(0xFF7B1FA2); // Purple
      case 'Lagu_belia':
        return const Color(0xFF388E3C); // Green
      case 'PPL':
        return const Color(0xFFD32F2F); // Red
      case 'Advent':
        return const Color(0xFFFF9800); // Orange
      case 'Natal':
        return const Color(0xFF5D4037); // Brown
      case 'Paskah':
        return const Color(0xFFE91E63); // Pink
      case 'Favorites':
        return const Color(0xFFD32F2F); // Red for favorites collection
      default:
        return const Color(0xFFD32F2F); // Default red
    }
  }
}
