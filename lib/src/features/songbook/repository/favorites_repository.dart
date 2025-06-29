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

  // Fetches the list of favorite song numbers for the current user.
  Future<List<String>> getFavorites() async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, returning empty favorites');
      return [];
    }

    final user = _auth?.currentUser;
    if (user == null) return []; // Return empty list if no user is logged in

    try {
      final ref = _database!.ref('users/${user.uid}/favorites');
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        // The data is stored as a Map where keys are song numbers and values are true
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.keys.toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      return [];
    }
  }

  // Toggles the favorite status of a song in the database.
  Future<void> toggleFavoriteStatus(
      String songNumber, bool isCurrentlyFavorite) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot toggle favorite');
      return;
    }

    final user = _auth?.currentUser;
    if (user == null) return; // Can't save favorites for a guest

    try {
      final ref = _database!.ref('users/${user.uid}/favorites/$songNumber');
      if (isCurrentlyFavorite) {
        // If it's already a favorite, remove it
        await ref.remove();
      } else {
        // If it's not a favorite, add it
        await ref.set(true);
      }
    } catch (e) {
      debugPrint("Error updating favorite status: $e");
    }
  }
}
