import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  final FirebaseService _firebaseService = FirebaseService();

  // Save theme mode preference
  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Retrieve theme mode preference
  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  // Save font size preference
  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
  }

  // Retrieve font size preference
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fontSize') ?? 16.0;
  }

  // Save font style preference
  Future<void> saveFontStyle(String fontStyle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontStyle', fontStyle);
  }

  // Retrieve font style preference
  Future<String> getFontStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fontStyle') ?? 'Roboto';
  }

  // Save text alignment preference
  Future<void> saveTextAlign(TextAlign textAlign) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('textAlign', textAlign.index);
  }

  // Retrieve text alignment preference
  Future<TextAlign> getTextAlign() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('textAlign') ?? 0;
    return TextAlign.values[index];
  }

  // Favorites Management with Firebase sync
  Future<void> saveFavoriteSongs(List<String> favoriteSongs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteSongs', favoriteSongs);

    // Sync to Firebase if user is signed in
    if (_firebaseService.isSignedIn) {
      await _firebaseService.syncLocalFavorites(favoriteSongs);
    }
  }

  Future<List<String>> getFavoriteSongs() async {
    // Try to get from Firebase first if user is signed in
    if (_firebaseService.isSignedIn) {
      try {
        final cloudFavorites = await _firebaseService.getFavorites();
        if (cloudFavorites.isNotEmpty) {
          // Update local storage with cloud data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('favoriteSongs', cloudFavorites);
          return cloudFavorites;
        }
      } catch (e) {
        debugPrint('Failed to get cloud favorites: $e');
      }
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favoriteSongs') ?? [];
  }

  // Add individual favorite with Firebase sync
  Future<void> addFavorite(String songNumber) async {
    final favorites = await getFavoriteSongs();
    if (!favorites.contains(songNumber)) {
      favorites.add(songNumber);
      await saveFavoriteSongs(favorites);

      // Add to Firebase
      if (_firebaseService.isSignedIn) {
        await _firebaseService.addToFavorites(songNumber);
      }
    }
  }

  // Remove individual favorite with Firebase sync
  Future<void> removeFavorite(String songNumber) async {
    final favorites = await getFavoriteSongs();
    if (favorites.contains(songNumber)) {
      favorites.remove(songNumber);
      await saveFavoriteSongs(favorites);

      // Remove from Firebase
      if (_firebaseService.isSignedIn) {
        await _firebaseService.removeFromFavorites(songNumber);
      }
    }
  }

  // Check if song is favorite
  Future<bool> isFavorite(String songNumber) async {
    final favorites = await getFavoriteSongs();
    return favorites.contains(songNumber);
  }

  // Sync local favorites to cloud when user signs in
  Future<void> syncToCloud() async {
    if (!_firebaseService.isSignedIn) return;

    try {
      final localFavorites = await getFavoriteSongs();
      await _firebaseService.syncLocalFavorites(localFavorites);

      // Then get the merged favorites from cloud
      final cloudFavorites = await _firebaseService.getFavorites();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoriteSongs', cloudFavorites);
    } catch (e) {
      debugPrint('Sync to cloud failed: $e');
    }
  }

  // Get favorites as stream for real-time updates
  Stream<List<String>> getFavoritesStream() {
    if (_firebaseService.isSignedIn) {
      return _firebaseService.getFavoritesStream();
    } else {
      // Return local favorites as stream
      return Stream.fromFuture(getFavoriteSongs());
    }
  }

  // Clear all local data (for sign out)
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favoriteSongs');
  }

  // First time setup flag
  Future<void> setFirstTimeSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstTimeSetupComplete', true);
  }

  Future<bool> isFirstTimeSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('firstTimeSetupComplete') ?? false;
  }

  // Sync preferences
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('syncEnabled', enabled);
  }

  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('syncEnabled') ?? true;
  }

  // Last sync timestamp
  Future<void> setLastSyncTime(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSyncTime', timestamp.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('lastSyncTime');
    return timeString != null ? DateTime.parse(timeString) : null;
  }
}
