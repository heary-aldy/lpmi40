// lib/src/features/songbook/services/app_startup_service.dart
// 🚀 APP STARTUP SERVICE
// Handles initialization of the new collection caching system
// Call this during app startup to ensure smooth operation

import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/songbook/services/collection_integration_helper.dart';
import 'package:lpmi40/src/features/songbook/services/collection_migration_service.dart';

class AppStartupService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// 🚀 Initialize the app with new collection caching system
  /// Call this in main.dart or your app's initialization
  static Future<bool> initializeCollectionSystem() async {
    if (_isInitialized) {
      debugPrint('✅ [AppStartup] Collection system already initialized');
      return true;
    }

    if (_isInitializing) {
      debugPrint(
          '⏳ [AppStartup] Collection system initialization in progress...');
      // Wait for existing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    debugPrint('🚀 [AppStartup] Initializing collection system...');

    try {
      // Step 1: Initialize the integration helper
      await CollectionIntegrationHelper.instance.initialize();

      // Step 2: Run a quick health check
      final health =
          await CollectionIntegrationHelper.instance.getSystemHealthReport();
      debugPrint('📊 [AppStartup] System health: ${health['service_status']}');

      // Step 3: Ensure Christmas collection is available
      final christmasCount = (await CollectionIntegrationHelper.instance
              .getChristmasCollectionStable())
          .length;
      debugPrint('🎄 [AppStartup] Christmas collection: $christmasCount songs');

      // Step 4: Pre-warm cache with essential collections
      await _preWarmEssentialCollections();

      _isInitialized = true;
      debugPrint('✅ [AppStartup] Collection system initialized successfully');

      return true;
    } catch (e) {
      debugPrint('❌ [AppStartup] Initialization failed: $e');
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// 🔥 Pre-warm cache with essential collections for faster first load
  static Future<void> _preWarmEssentialCollections() async {
    try {
      debugPrint('🔥 [AppStartup] Pre-warming essential collections...');

      // Get all collections to warm the cache
      final allCollections =
          await CollectionIntegrationHelper.instance.getAllCollectionsStable();

      debugPrint(
          '🔥 [AppStartup] Pre-warmed ${allCollections.length} collections');

      // Log essential collections for verification
      final essentialCollections = ['LPMI', 'SRD', 'Lagu_belia'];
      for (final collection in essentialCollections) {
        final count = allCollections[collection]?.length ?? 0;
        debugPrint('   - $collection: $count songs');
      }
    } catch (e) {
      debugPrint('⚠️ [AppStartup] Pre-warming failed: $e');
      // Don't fail startup if pre-warming fails
    }
  }

  /// 🔧 Fix any collection issues during startup
  static Future<void> fixStartupIssues() async {
    try {
      debugPrint('🔧 [AppStartup] Checking for startup issues...');

      final results =
          await CollectionIntegrationHelper.instance.fixCollectionIssues();

      if (results['success'] == true) {
        final actionsCount = (results['actions_taken'] as List).length;
        debugPrint(
            '✅ [AppStartup] Fixed startup issues ($actionsCount actions taken)');
      } else {
        debugPrint(
            '⚠️ [AppStartup] Some issues could not be fixed automatically');
      }
    } catch (e) {
      debugPrint('❌ [AppStartup] Error fixing startup issues: $e');
    }
  }

  /// 📊 Get startup diagnostics
  static Future<Map<String, dynamic>> getStartupDiagnostics() async {
    try {
      final migrationStatus =
          await CollectionMigrationService.getMigrationStatus();
      final systemHealth =
          await CollectionIntegrationHelper.instance.getSystemHealthReport();

      return {
        'initialized': _isInitialized,
        'initializing': _isInitializing,
        'migration_status': migrationStatus,
        'system_health': systemHealth,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'initialized': _isInitialized,
        'initializing': _isInitializing,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🚨 Emergency startup (if normal initialization fails)
  static Future<bool> emergencyStartup() async {
    debugPrint('🚨 [AppStartup] Running emergency startup...');

    try {
      // Reset everything and start fresh
      await CollectionIntegrationHelper.instance.emergencyReset();

      // Try normal initialization again
      return await initializeCollectionSystem();
    } catch (e) {
      debugPrint('❌ [AppStartup] Emergency startup failed: $e');
      return false;
    }
  }

  /// ✅ Check if system is ready
  static bool get isReady => _isInitialized;

  /// ⏳ Check if system is initializing
  static bool get isInitializing => _isInitializing;
}

// ============================================================================
// USAGE EXAMPLE FOR MAIN.dart
// ============================================================================

/// Example of how to integrate this in your main.dart:
/// 
/// ```dart
/// import 'package:lpmi40/src/features/songbook/services/app_startup_service.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize Firebase (existing code)
///   await Firebase.initializeApp();
///   
///   // 🚀 NEW: Initialize collection caching system
///   final success = await AppStartupService.initializeCollectionSystem();
///   
///   if (!success) {
///     debugPrint('⚠️ Collection system initialization failed, trying emergency startup...');
///     await AppStartupService.emergencyStartup();
///   }
///   
///   runApp(MyApp());
/// }
/// ```
/// 
/// And in your app widget:
/// 
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: AppStartupService.isReady 
///           ? MainScreen() 
///           : LoadingScreen(),
///     );
///   }
/// }
/// ```
