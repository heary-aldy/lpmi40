// lib/src/core/services/firebase_database_service.dart
// 🔧 CENTRALIZED: Shared Firebase Database service to prevent multiple initialization errors
// ✅ WEB COMPATIBLE: Handles web platform persistence limitations
// 🚀 SINGLETON: Single database instance shared across all repositories

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseDatabaseService {
  static FirebaseDatabaseService? _instance;
  static FirebaseDatabase? _dbInstance;
  static bool _dbInitialized = false;
  static DateTime? _lastConnectionCheck;
  static bool? _lastConnectionResult;

  // Private constructor for singleton
  FirebaseDatabaseService._();

  // Singleton instance getter
  static FirebaseDatabaseService get instance {
    _instance ??= FirebaseDatabaseService._();
    return _instance!;
  }

  // ============================================================================
  // CORE DATABASE ACCESS
  // ============================================================================

  bool get _isFirebaseInitialized {
    try {
      final app = Firebase.app();
      return app.options.databaseURL?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  /// ✅ CENTRALIZED: Single database instance shared across all repositories
  Future<FirebaseDatabase?> get database async {
    // Return cached instance if available and valid
    if (_dbInstance != null && _dbInitialized) {
      return _dbInstance;
    }

    // Initialize if needed
    if (_isFirebaseInitialized) {
      try {
        // ✅ FIX: Use the default instance to prevent multiple initialization
        _dbInstance = FirebaseDatabase.instance;

        // ✅ PERFORMANCE: Configure database settings once (skip entirely on web)
        if (!_dbInitialized && !kIsWeb) {
          try {
            _dbInstance!.setPersistenceEnabled(true);
            _dbInstance!.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
          } catch (e) {
            debugPrint('[FirebaseDB] ⚠️ Persistence not supported: $e');
          }

          if (kDebugMode) {
            _dbInstance!.setLoggingEnabled(false); // Reduce console noise
          }
        }

        _dbInitialized = true;

        if (kIsWeb) {
          debugPrint(
              '[FirebaseDB] ✅ Database initialized for web (no persistence)');
        } else {
          debugPrint('[FirebaseDB] ✅ Database initialized and configured');
        }

        return _dbInstance;
      } catch (e) {
        debugPrint('[FirebaseDB] ❌ Database initialization failed: $e');
        // Return the instance anyway, it might still work
        return _dbInstance ?? FirebaseDatabase.instance;
      }
    }

    return null;
  }

  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================

  /// ✅ OPTIMIZED: Smart connectivity check with caching
  Future<bool> checkConnectivity() async {
    // Use cached result if recent (within 30 seconds)
    if (_lastConnectionCheck != null && _lastConnectionResult != null) {
      final timeSinceCheck = DateTime.now().difference(_lastConnectionCheck!);
      if (timeSinceCheck.inSeconds < 30) {
        return _lastConnectionResult!;
      }
    }

    try {
      final db = await database;
      if (db == null) {
        _lastConnectionResult = false;
        _lastConnectionCheck = DateTime.now();
        return false;
      }

      // Quick connection test with timeout
      final completer = Completer<bool>();
      late StreamSubscription subscription;

      subscription = db.ref('.info/connected').onValue.listen(
        (event) {
          if (!completer.isCompleted) {
            final connected = event.snapshot.value == true;
            completer.complete(connected);
          }
          subscription.cancel();
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          subscription.cancel();
        },
      );

      // Timeout after 5 seconds
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          subscription.cancel();
        }
      });

      final result = await completer.future;
      _lastConnectionResult = result;
      _lastConnectionCheck = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('[FirebaseDB] ❌ Connectivity check failed: $e');
      _lastConnectionResult = false;
      _lastConnectionCheck = DateTime.now();
      // Don't fail completely, return false and let app continue offline
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get a database reference
  DatabaseReference? getRef(String path) {
    if (_dbInstance != null) {
      return _dbInstance!.ref(path);
    }
    return null;
  }

  /// Reset the database instance (for testing or reinitialization)
  static void reset() {
    _instance = null;
    _dbInstance = null;
    _dbInitialized = false;
    _lastConnectionCheck = null;
    _lastConnectionResult = null;
  }

  /// Check if database is initialized
  bool get isInitialized => _dbInitialized && _dbInstance != null;
}
