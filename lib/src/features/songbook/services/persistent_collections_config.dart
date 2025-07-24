// lib/src/features/songbook/services/persistent_collections_config.dart
// Configuration service for managing persistent collections that should always be visible

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentCollectionsConfig {
  static const String _persistentCollectionsKey = 'persistent_collections';
  static const String _lastChristmasCollectionKey = 'last_christmas_collection';

  // Default persistent collections that should always appear
  static const List<String> _defaultPersistentCollections = [
    'LPMI',
    'SRD',
    'Lagu_belia',
  ];

  // Christmas collection candidates to try
  static const List<String> _christmasCollectionCandidates = [
    'lagu_krismas_26346',
    'christmas',
    'Christmas',
    'lagu_krismas',
    'Christmas_Songs',
    'christmas_songs',
  ];

  /// Get list of collections that should always be shown
  static Future<List<String>> getPersistentCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_persistentCollectionsKey);

      if (saved != null && saved.isNotEmpty) {
        debugPrint(
            '✅ [PersistentCollections] Loaded persistent collections: $saved');
        return saved;
      }
    } catch (e) {
      debugPrint(
          '⚠️ [PersistentCollections] Error loading from preferences: $e');
    }

    // Return default if nothing saved
    debugPrint(
        '📋 [PersistentCollections] Using default persistent collections');
    return List.from(_defaultPersistentCollections);
  }

  /// Save list of persistent collections
  static Future<void> setPersistentCollections(List<String> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_persistentCollectionsKey, collections);
      debugPrint(
          '💾 [PersistentCollections] Saved persistent collections: $collections');
    } catch (e) {
      debugPrint('❌ [PersistentCollections] Error saving to preferences: $e');
    }
  }

  /// Add a collection to persistent list
  static Future<void> addPersistentCollection(String collectionId) async {
    final current = await getPersistentCollections();
    if (!current.contains(collectionId)) {
      current.add(collectionId);
      await setPersistentCollections(current);
      debugPrint(
          '➕ [PersistentCollections] Added $collectionId to persistent list');
    }
  }

  /// Remove a collection from persistent list (except defaults)
  static Future<void> removePersistentCollection(String collectionId) async {
    if (_defaultPersistentCollections.contains(collectionId)) {
      debugPrint(
          '🚫 [PersistentCollections] Cannot remove default collection: $collectionId');
      return;
    }

    final current = await getPersistentCollections();
    if (current.remove(collectionId)) {
      await setPersistentCollections(current);
      debugPrint(
          '➖ [PersistentCollections] Removed $collectionId from persistent list');
    }
  }

  /// Find working Christmas collection and save it for next time
  static Future<String?> findAndSaveChristmasCollection(
      Map<String, dynamic> availableCollections) async {
    // First check if we have a previously working Christmas collection
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastWorking = prefs.getString(_lastChristmasCollectionKey);

      if (lastWorking != null &&
          availableCollections.containsKey(lastWorking)) {
        debugPrint(
            '🎄 [PersistentCollections] Using previously working Christmas collection: $lastWorking');
        return lastWorking;
      }
    } catch (e) {
      debugPrint(
          '⚠️ [PersistentCollections] Error checking last Christmas collection: $e');
    }

    // Try to find a working Christmas collection
    for (final candidate in _christmasCollectionCandidates) {
      if (availableCollections.containsKey(candidate)) {
        final songs = availableCollections[candidate];

        // Check if it has songs (not empty)
        if (songs != null &&
            ((songs is Map && songs.isNotEmpty) ||
                (songs is List && songs.isNotEmpty))) {
          debugPrint(
              '🎄 [PersistentCollections] Found working Christmas collection: $candidate');

          // Save this as the working Christmas collection
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_lastChristmasCollectionKey, candidate);
          } catch (e) {
            debugPrint(
                '⚠️ [PersistentCollections] Error saving Christmas collection: $e');
          }

          // Add to persistent collections if not already there
          await addPersistentCollection(candidate);
          return candidate;
        }
      }
    }

    debugPrint(
        '❌ [PersistentCollections] No working Christmas collection found');
    return null;
  }

  /// Get Christmas collection candidates for debugging
  static List<String> getChristmasCollectionCandidates() {
    return List.from(_christmasCollectionCandidates);
  }

  /// Check if a collection should be treated as persistent
  static Future<bool> isPersistentCollection(String collectionId) async {
    final persistent = await getPersistentCollections();
    return persistent.contains(collectionId);
  }

  /// Get default collections that should never be removed
  static List<String> getDefaultCollections() {
    return List.from(_defaultPersistentCollections);
  }

  /// Reset to default configuration
  static Future<void> resetToDefaults() async {
    await setPersistentCollections(List.from(_defaultPersistentCollections));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastChristmasCollectionKey);
    } catch (e) {
      debugPrint(
          '⚠️ [PersistentCollections] Error clearing Christmas collection: $e');
    }

    debugPrint('🔄 [PersistentCollections] Reset to default configuration');
  }

  /// Get configuration summary for debugging
  static Future<Map<String, dynamic>> getConfigSummary() async {
    final persistent = await getPersistentCollections();

    String? lastChristmas;
    try {
      final prefs = await SharedPreferences.getInstance();
      lastChristmas = prefs.getString(_lastChristmasCollectionKey);
    } catch (e) {
      // Ignore error
    }

    return {
      'persistent_collections': persistent,
      'default_collections': _defaultPersistentCollections,
      'christmas_candidates': _christmasCollectionCandidates,
      'last_working_christmas': lastChristmas,
      'total_persistent': persistent.length,
    };
  }
}
