// lib/src/features/songbook/services/app_initialization_service.dart
// Service to handle app initialization including asset sync

import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/songbook/services/asset_sync_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final AssetSyncService _syncService = AssetSyncService();
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if the app has been initialized
  bool get isInitialized => _isInitialized;

  /// Check if initialization is in progress
  bool get isInitializing => _isInitializing;

  /// Initialize the app with data sync if needed
  Future<InitializationResult> initializeApp({
    bool forceSync = false,
    bool silentSync = true,
  }) async {
    if (_isInitialized && !forceSync) {
      return InitializationResult(
        success: true,
        message: 'App already initialized',
        hadLocalData: true,
        performedSync: false,
      );
    }

    if (_isInitializing) {
      return InitializationResult(
        success: false,
        message: 'Initialization already in progress',
        hadLocalData: false,
        performedSync: false,
      );
    }

    _isInitializing = true;

    try {
      // Check if we have local data and if it needs syncing
      final syncStatus = await _syncService.getSyncStatus();

      // If we have no local data or sync is forced, perform initial sync
      if (!syncStatus.hasLocalData || forceSync || syncStatus.needsSync) {
        if (kDebugMode) {
          print('AppInitialization: Performing initial sync...');
          print('- Has local data: ${syncStatus.hasLocalData}');
          print('- Needs sync: ${syncStatus.needsSync}');
          print('- Force sync: $forceSync');
        }

        final syncResult = await _syncService.syncFromFirebase();

        _isInitialized = syncResult.success;
        _isInitializing = false;

        return InitializationResult(
          success: syncResult.success,
          message: syncResult.message,
          hadLocalData: syncStatus.hasLocalData,
          performedSync: true,
          syncResult: syncResult,
        );
      } else {
        // We have up-to-date local data
        if (kDebugMode) {
          print('AppInitialization: Using existing local data');
        }

        _isInitialized = true;
        _isInitializing = false;

        return InitializationResult(
          success: true,
          message: 'Using existing local data',
          hadLocalData: true,
          performedSync: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('AppInitialization: Error during initialization: $e');
      }

      _isInitializing = false;

      return InitializationResult(
        success: false,
        message: 'Initialization failed: $e',
        hadLocalData: false,
        performedSync: false,
      );
    }
  }

  /// Reset initialization state (useful for testing or forced refresh)
  void resetInitialization() {
    _isInitialized = false;
    _isInitializing = false;
  }

  /// Check if initial sync is recommended
  Future<bool> shouldPerformInitialSync() async {
    try {
      final syncStatus = await _syncService.getSyncStatus();
      return !syncStatus.hasLocalData || syncStatus.needsSync;
    } catch (e) {
      return true; // If we can't check, assume we should sync
    }
  }

  /// Get current sync status for debugging
  Future<SyncStatus> getCurrentSyncStatus() async {
    return await _syncService.getSyncStatus();
  }
}

class InitializationResult {
  final bool success;
  final String message;
  final bool hadLocalData;
  final bool performedSync;
  final SyncResult? syncResult;

  const InitializationResult({
    required this.success,
    required this.message,
    required this.hadLocalData,
    required this.performedSync,
    this.syncResult,
  });

  @override
  String toString() {
    return 'InitializationResult(success: $success, message: $message, '
        'hadLocalData: $hadLocalData, performedSync: $performedSync)';
  }
}
