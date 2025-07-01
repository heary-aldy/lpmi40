import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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

  // ✅ Get favorites using proper data structure from your export
  // Structure: "favorites": { "001": true, "004": true }
  Future<List<String>> getFavorites() async {
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
      debugPrint('🔄 Fetching favorites for user: ${user.email}');

      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        // ✅ The data structure is: { "001": true, "004": true }
        // We need to extract the keys (song numbers) where value is true
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final favoritesList = data.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

        debugPrint('✅ Found ${favoritesList.length} favorites: $favoritesList');
        return favoritesList;
      } else {
        debugPrint('📭 No favorites found for user');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching favorites: $e");
      return [];
    }
  }

  // ✅ Toggle favorite using proper data structure
  Future<void> toggleFavoriteStatus(
      String songNumber, bool isCurrentlyFavorite) async {
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
          '🔄 Toggling favorite status for song $songNumber (currently: $isCurrentlyFavorite)');

      final ref = _database!.ref('users/${user.uid}/favorites/$songNumber');

      if (isCurrentlyFavorite) {
        // Remove from favorites by deleting the key
        await ref.remove();
        debugPrint('✅ Removed song $songNumber from favorites');
      } else {
        // Add to favorites by setting the value to true
        await ref.set(true);
        debugPrint('✅ Added song $songNumber to favorites');
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

  // ✅ Check if a specific song is favorited
  Future<bool> isSongFavorite(String songNumber) async {
    if (!_isFirebaseInitialized) return false;

    final user = _auth?.currentUser;
    if (user == null) return false;

    try {
      final ref = _database!.ref('users/${user.uid}/favorites/$songNumber');
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
}
