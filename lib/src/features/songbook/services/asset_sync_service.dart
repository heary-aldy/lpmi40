// lib/src/features/songbook/services/asset_sync_service.dart
// Local Asset Update Service - Syncs Firebase data with local storage

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class AssetSyncService {
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _syncedDataVersionKey = 'synced_data_version';
  static const String _localSongsDataKey = 'local_songs_data';
  static const String _localCollectionsDataKey = 'local_collections_data';

  // Sync interval in hours (default: 24 hours)
  static const int _syncIntervalHours = 24;

  final SongRepository _songRepository = SongRepository();

  /// Check if local data needs to be synced with Firebase
  Future<bool> needsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncTimestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Check if sync interval has passed
      final timeDifference = currentTime - lastSync;
      final hoursSinceLastSync = timeDifference / (1000 * 60 * 60);

      print('🕐 Last sync: ${DateTime.fromMillisecondsSinceEpoch(lastSync)}');
      print(
          '🕐 Hours since last sync: ${hoursSinceLastSync.toStringAsFixed(1)}');

      if (hoursSinceLastSync >= _syncIntervalHours) {
        print('✅ Sync needed - time interval exceeded');
        return true;
      }

      // Also check if we have any local data at all
      final hasLocalData = prefs.containsKey(_localSongsDataKey);
      if (!hasLocalData) {
        print('✅ Sync needed - no local data found');
        return true;
      }

      print('❌ Sync not needed - local data is current');
      return false;
    } catch (e) {
      print('❌ Error checking sync status: $e');
      return true; // Err on the side of syncing if we can't determine
    }
  }

  /// Check if Firebase data has been updated since last sync
  Future<bool> hasFirebaseDataChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncVersion = prefs.getString(_syncedDataVersionKey);

      // Get current Firebase data version (using last modified timestamp)
      final firebaseVersion = await _getFirebaseDataVersion();

      if (lastSyncVersion != firebaseVersion) {
        print(
            '🔄 Firebase data changed - version: $lastSyncVersion -> $firebaseVersion');
        return true;
      }

      print('✅ Firebase data unchanged - version: $firebaseVersion');
      return false;
    } catch (e) {
      print('❌ Error checking Firebase data version: $e');
      return true; // Assume changed if we can't check
    }
  }

  /// Get a version identifier for Firebase data
  Future<String> _getFirebaseDataVersion() async {
    try {
      final database = FirebaseDatabase.instance;

      // Get timestamp of last modification to songs data
      final songsRef = database.ref('song_collection');
      final snapshot = await songsRef.get();

      if (snapshot.exists) {
        // Use a hash of the data structure as version identifier
        final dataHash = snapshot.value.hashCode.toString();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        return '$dataHash-$timestamp';
      }

      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      print('❌ Error getting Firebase data version: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Sync Firebase data to local storage
  Future<SyncResult> syncFromFirebase() async {
    try {
      print('🔄 Starting Firebase sync...');

      // Get fresh data from Firebase
      final songsResult = await _songRepository.getAllSongs();
      final collectionsResult = await _songRepository.getCollectionsSeparated();

      if (!songsResult.isOnline) {
        return SyncResult(
          success: false,
          message: 'No internet connection available',
          songsCount: 0,
          collectionsCount: 0,
        );
      }

      // Store data locally
      await _storeLocalData(songsResult.songs, collectionsResult);

      // Update sync metadata
      await _updateSyncMetadata();

      print('✅ Firebase sync completed successfully');
      return SyncResult(
        success: true,
        message:
            'Successfully synced ${songsResult.songs.length} songs and ${collectionsResult.length} collections',
        songsCount: songsResult.songs.length,
        collectionsCount: collectionsResult.length,
      );
    } catch (e) {
      print('❌ Firebase sync failed: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        songsCount: 0,
        collectionsCount: 0,
      );
    }
  }

  /// Store songs and collections data locally
  Future<void> _storeLocalData(
      List<Song> songs, Map<String, List<Song>> collections) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert songs to JSON
    final songsJson = songs.map((song) => song.toJson()).toList();
    await prefs.setString(_localSongsDataKey, jsonEncode(songsJson));

    // Convert collections to JSON
    final collectionsJson = <String, dynamic>{};
    collections.forEach((key, songList) {
      collectionsJson[key] = songList.map((song) => song.toJson()).toList();
    });
    await prefs.setString(
        _localCollectionsDataKey, jsonEncode(collectionsJson));

    print(
        '💾 Stored ${songs.length} songs and ${collections.length} collections locally');
  }

  /// Update sync metadata
  Future<void> _updateSyncMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final dataVersion = await _getFirebaseDataVersion();

    await prefs.setInt(_lastSyncTimestampKey, currentTime);
    await prefs.setString(_syncedDataVersionKey, dataVersion);

    print(
        '📝 Updated sync metadata - timestamp: $currentTime, version: $dataVersion');
  }

  /// Get locally stored songs
  Future<List<Song>> getLocalSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJsonString = prefs.getString(_localSongsDataKey);

      if (songsJsonString == null) {
        print('❌ No local songs data found');
        return [];
      }

      final songsJson = jsonDecode(songsJsonString) as List;
      final songs = songsJson.map((json) => Song.fromJson(json)).toList();

      print('📱 Retrieved ${songs.length} songs from local storage');
      return songs;
    } catch (e) {
      print('❌ Error retrieving local songs: $e');
      return [];
    }
  }

  /// Get locally stored collections
  Future<Map<String, List<Song>>> getLocalCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionsJsonString = prefs.getString(_localCollectionsDataKey);

      if (collectionsJsonString == null) {
        print('❌ No local collections data found');
        return {};
      }

      final collectionsJson =
          jsonDecode(collectionsJsonString) as Map<String, dynamic>;
      final collections = <String, List<Song>>{};

      collectionsJson.forEach((key, value) {
        final songList =
            (value as List).map((json) => Song.fromJson(json)).toList();
        collections[key] = songList;
      });

      print(
          '📱 Retrieved ${collections.length} collections from local storage');
      return collections;
    } catch (e) {
      print('❌ Error retrieving local collections: $e');
      return {};
    }
  }

  /// Get sync status information
  Future<SyncStatus> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncTimestampKey) ?? 0;
      final dataVersion = prefs.getString(_syncedDataVersionKey);
      final hasLocalData = prefs.containsKey(_localSongsDataKey);

      final needsSync = await this.needsSync();
      final hasChanged = hasLocalData ? await hasFirebaseDataChanged() : true;

      return SyncStatus(
        lastSyncTime:
            lastSync > 0 ? DateTime.fromMillisecondsSinceEpoch(lastSync) : null,
        dataVersion: dataVersion,
        hasLocalData: hasLocalData,
        needsSync: needsSync,
        hasFirebaseChanged: hasChanged,
      );
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return SyncStatus(
        lastSyncTime: null,
        dataVersion: null,
        hasLocalData: false,
        needsSync: true,
        hasFirebaseChanged: true,
      );
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localSongsDataKey);
    await prefs.remove(_localCollectionsDataKey);
    await prefs.remove(_lastSyncTimestampKey);
    await prefs.remove(_syncedDataVersionKey);

    print('🗑️ Cleared all local sync data');
  }

  /// Perform automatic sync if needed
  Future<SyncResult> autoSync() async {
    final needsSync = await this.needsSync();
    if (!needsSync) {
      return SyncResult(
        success: true,
        message: 'Local data is up to date',
        songsCount: 0,
        collectionsCount: 0,
      );
    }

    return await syncFromFirebase();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int songsCount;
  final int collectionsCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.songsCount,
    required this.collectionsCount,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, songs: $songsCount, collections: $collectionsCount)';
  }
}

/// Current sync status information
class SyncStatus {
  final DateTime? lastSyncTime;
  final String? dataVersion;
  final bool hasLocalData;
  final bool needsSync;
  final bool hasFirebaseChanged;

  SyncStatus({
    required this.lastSyncTime,
    required this.dataVersion,
    required this.hasLocalData,
    required this.needsSync,
    required this.hasFirebaseChanged,
  });

  @override
  String toString() {
    return 'SyncStatus(lastSync: $lastSyncTime, hasLocal: $hasLocalData, needsSync: $needsSync, firebaseChanged: $hasFirebaseChanged)';
  }
}
