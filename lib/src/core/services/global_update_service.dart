// lib/src/core/services/global_update_service.dart
// 🌐 GLOBAL UPDATE MANAGEMENT: Force cache invalidation across all user devices
// 🎯 COST-EFFICIENT: Ultra-lightweight version checks to trigger updates
// 🛡️ ADMIN-CONTROLLED: Super admin panel for managing global updates

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/firebase_database_service.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';

class GlobalUpdateService {
  static GlobalUpdateService? _instance;
  static GlobalUpdateService get instance =>
      _instance ??= GlobalUpdateService._();
  GlobalUpdateService._();

  // Firebase paths for global update management
  static const String _globalVersionPath = 'app_global_version';
  static const String _forceUpdatePath = 'app_force_update';
  static const String _updateMessagePath = 'app_update_message';
  static const String _updateLogPath = 'app_update_log';

  // Local storage keys
  static const String _localVersionKey = 'local_app_version';
  static const String _lastVersionCheckKey = 'last_version_check';
  static const String _updateNotificationKey = 'update_notification_shown';

  // Version check frequency (cost-optimized)
  static const Duration _versionCheckInterval =
      Duration(hours: 12); // Check twice daily
  static const Duration _quickCheckInterval =
      Duration(minutes: 30); // On app startup/resume

  final FirebaseDatabaseService _databaseService =
      FirebaseDatabaseService.instance;

  // State tracking
  String _currentLocalVersion = '';
  String _currentGlobalVersion = '';
  DateTime? _lastVersionCheck;
  bool _updateAvailable = false;
  String _updateMessage = '';
  StreamSubscription? _versionListener;

  // ============================================================================
  // 🚀 INITIALIZATION & VERSION CHECKING
  // ============================================================================

  /// Initialize the global update service
  Future<void> initialize() async {
    try {
      debugPrint('[GlobalUpdate] 🚀 Initializing global update service...');

      // Load local version info
      await _loadLocalVersionInfo();

      // Check for updates on startup (quick check)
      await checkForUpdates(isStartupCheck: true);

      // Set up periodic version checking
      _setupPeriodicVersionCheck();

      debugPrint('[GlobalUpdate] ✅ Global update service initialized');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Failed to initialize: $e');
    }
  }

  /// Check for global updates with cost optimization
  Future<GlobalUpdateResult> checkForUpdates(
      {bool isStartupCheck = false}) async {
    try {
      // Rate limiting for cost optimization
      if (!isStartupCheck && !_shouldCheckVersion()) {
        debugPrint('[GlobalUpdate] ⏭️ Skipping version check (rate limited)');
        return GlobalUpdateResult(
          hasUpdate: _updateAvailable,
          currentVersion: _currentLocalVersion,
          latestVersion: _currentGlobalVersion,
          message: _updateMessage,
          isRateLimited: true,
        );
      }

      debugPrint('[GlobalUpdate] 🔍 Checking for global updates...');

      final database = await _databaseService.database;
      if (database == null) {
        throw Exception('Database not available');
      }

      // Ultra-lightweight version check (minimal data transfer)
      final versionRef = database.ref(_globalVersionPath);
      final versionSnapshot =
          await versionRef.get().timeout(const Duration(seconds: 3));

      if (!versionSnapshot.exists || versionSnapshot.value == null) {
        debugPrint('[GlobalUpdate] ⚠️ No global version found, using default');
        return _createNoUpdateResult();
      }

      final globalVersionData =
          Map<String, dynamic>.from(versionSnapshot.value as Map);
      final globalVersion = globalVersionData['version']?.toString() ?? '1.0.0';
      final forceUpdate = globalVersionData['force_update'] == true;
      final updateMessage = globalVersionData['message']?.toString() ?? '';
      final updateType = globalVersionData['type']?.toString() ?? 'optional';

      _currentGlobalVersion = globalVersion;
      _updateMessage = updateMessage;
      _lastVersionCheck = DateTime.now();

      // Compare versions
      final hasUpdate =
          _compareVersions(_currentLocalVersion, globalVersion) < 0;
      _updateAvailable = hasUpdate;

      // Save version check timestamp
      await _saveVersionCheckTimestamp();

      debugPrint('[GlobalUpdate] 📊 Version check result:');
      debugPrint('  Local: $_currentLocalVersion');
      debugPrint('  Global: $globalVersion');
      debugPrint('  Has Update: $hasUpdate');
      debugPrint('  Force Update: $forceUpdate');
      debugPrint('  Type: $updateType');

      if (hasUpdate) {
        await _handleGlobalUpdate(globalVersionData);
      }

      return GlobalUpdateResult(
        hasUpdate: hasUpdate,
        currentVersion: _currentLocalVersion,
        latestVersion: globalVersion,
        message: updateMessage,
        forceUpdate: forceUpdate,
        updateType: updateType,
        isRateLimited: false,
      );
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error checking for updates: $e');
      return GlobalUpdateResult(
        hasUpdate: false,
        currentVersion: _currentLocalVersion,
        latestVersion: _currentGlobalVersion,
        message: 'Failed to check for updates',
        hasError: true,
        error: e.toString(),
      );
    }
  }

  /// Handle global update when detected
  Future<void> _handleGlobalUpdate(Map<String, dynamic> updateData) async {
    try {
      debugPrint('[GlobalUpdate] 🔄 Handling global update...');

      final updateType = updateData['type']?.toString() ?? 'optional';
      final clearCache = updateData['clear_cache'] == true;
      final updateCollections = updateData['update_collections'] == true;
      final notifyUser = updateData['notify_user'] == true;

      // Clear caches if requested
      if (clearCache) {
        debugPrint('[GlobalUpdate] 🧹 Clearing all caches as requested...');
        await _clearAllCaches();
      }

      // Update specific collections if requested
      if (updateCollections) {
        debugPrint('[GlobalUpdate] 🔄 Updating collections as requested...');
        await _updateCollections();
      }

      // Log the update action
      await _logUpdateAction(updateData);

      debugPrint('[GlobalUpdate] ✅ Global update handled successfully');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error handling global update: $e');
    }
  }

  // ============================================================================
  // 🛠️ CACHE MANAGEMENT
  // ============================================================================

  /// Clear all caches across the app
  Future<void> _clearAllCaches() async {
    try {
      debugPrint('[GlobalUpdate] 🧹 Clearing all application caches...');

      // Clear song repository cache
      SongRepository.invalidateCacheForDevelopment(
          reason: 'Global update triggered');

      // Clear collection cache
      await CollectionCacheManager.instance.clearCache();

      // Clear local preferences related to caching
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs
          .getKeys()
          .where((key) =>
              key.startsWith('collection_cache_') ||
              key.startsWith('song_cache_') ||
              key.startsWith('cache_'))
          .toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('[GlobalUpdate] ✅ All caches cleared successfully');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error clearing caches: $e');
    }
  }

  /// Update collections based on global trigger
  Future<void> _updateCollections() async {
    try {
      debugPrint('[GlobalUpdate] 🔄 Triggering collection updates...');

      // Force refresh collections
      await CollectionCacheManager.instance
          .forceRefreshForDevelopment(reason: 'Global update triggered');

      debugPrint('[GlobalUpdate] ✅ Collections updated successfully');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error updating collections: $e');
    }
  }

  // ============================================================================
  // 🔧 VERSION MANAGEMENT
  // ============================================================================

  /// Load local version information
  Future<void> _loadLocalVersionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLocalVersion = prefs.getString(_localVersionKey) ?? '1.0.0';

      final lastCheckTimestamp = prefs.getInt(_lastVersionCheckKey);
      if (lastCheckTimestamp != null) {
        _lastVersionCheck =
            DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
      }

      debugPrint(
          '[GlobalUpdate] 📱 Local version loaded: $_currentLocalVersion');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error loading local version: $e');
      _currentLocalVersion = '1.0.0';
    }
  }

  /// Save version check timestamp for rate limiting
  Future<void> _saveVersionCheckTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastVersionCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error saving version check timestamp: $e');
    }
  }

  /// Update local version (call this after app updates)
  Future<void> updateLocalVersion(String newVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localVersionKey, newVersion);
      _currentLocalVersion = newVersion;
      _updateAvailable = false;

      debugPrint('[GlobalUpdate] ✅ Local version updated to: $newVersion');
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error updating local version: $e');
    }
  }

  /// Compare two version strings (returns -1, 0, or 1)
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1
        .split('.')
        .map(int.tryParse)
        .where((v) => v != null)
        .cast<int>()
        .toList();
    final v2Parts = version2
        .split('.')
        .map(int.tryParse)
        .where((v) => v != null)
        .cast<int>()
        .toList();

    final maxLength =
        v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }

    return 0;
  }

  /// Check if we should perform a version check (rate limiting)
  bool _shouldCheckVersion() {
    if (_lastVersionCheck == null) return true;

    final timeSinceLastCheck = DateTime.now().difference(_lastVersionCheck!);
    return timeSinceLastCheck >= _versionCheckInterval;
  }

  // ============================================================================
  // 🔄 PERIODIC CHECKS & MONITORING
  // ============================================================================

  /// Setup periodic version checking
  void _setupPeriodicVersionCheck() {
    // Check every 30 minutes when app is active
    Timer.periodic(_quickCheckInterval, (timer) async {
      if (!_shouldCheckVersion()) return;

      try {
        await checkForUpdates();
      } catch (e) {
        debugPrint('[GlobalUpdate] ❌ Periodic check failed: $e');
      }
    });
  }

  /// Log update action for monitoring
  Future<void> _logUpdateAction(Map<String, dynamic> updateData) async {
    try {
      final database = await _databaseService.database;
      if (database == null) return;

      final logRef = database.ref(_updateLogPath).push();
      await logRef.set({
        'timestamp': DateTime.now().toIso8601String(),
        'local_version': _currentLocalVersion,
        'global_version': _currentGlobalVersion,
        'update_type': updateData['type'] ?? 'unknown',
        'actions_taken': {
          'clear_cache': updateData['clear_cache'] == true,
          'update_collections': updateData['update_collections'] == true,
        },
        'device_info': {
          'platform': kIsWeb ? 'web' : 'mobile',
          'debug_mode': kDebugMode,
        }
      });
    } catch (e) {
      debugPrint('[GlobalUpdate] ❌ Error logging update action: $e');
    }
  }

  // ============================================================================
  // 🎯 UTILITY METHODS
  // ============================================================================

  /// Create a "no update" result
  GlobalUpdateResult _createNoUpdateResult() {
    return GlobalUpdateResult(
      hasUpdate: false,
      currentVersion: _currentLocalVersion,
      latestVersion: _currentLocalVersion,
      message: 'No updates available',
    );
  }

  /// Get current update status
  GlobalUpdateStatus get updateStatus {
    return GlobalUpdateStatus(
      hasUpdate: _updateAvailable,
      currentVersion: _currentLocalVersion,
      latestVersion: _currentGlobalVersion,
      message: _updateMessage,
      lastCheck: _lastVersionCheck,
    );
  }

  /// Force immediate update check (bypasses rate limiting)
  Future<GlobalUpdateResult> forceUpdateCheck() async {
    _lastVersionCheck = null; // Reset rate limiting
    return await checkForUpdates();
  }

  /// Dispose of resources
  void dispose() {
    _versionListener?.cancel();
  }
}

// ============================================================================
// 📊 DATA MODELS
// ============================================================================

class GlobalUpdateResult {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final bool forceUpdate;
  final String updateType;
  final bool isRateLimited;
  final bool hasError;
  final String? error;

  GlobalUpdateResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    this.forceUpdate = false,
    this.updateType = 'optional',
    this.isRateLimited = false,
    this.hasError = false,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasUpdate': hasUpdate,
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'message': message,
      'forceUpdate': forceUpdate,
      'updateType': updateType,
      'isRateLimited': isRateLimited,
      'hasError': hasError,
      'error': error,
    };
  }
}

class GlobalUpdateStatus {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final DateTime? lastCheck;

  GlobalUpdateStatus({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    this.lastCheck,
  });
}
