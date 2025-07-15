// lib/src/features/dashboard/presentation/dashboard_performance_optimizations.dart
// ✅ PERFORMANCE: Additional optimizations for collection loading and caching

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';

// ✅ OPTIMIZATION 1: Preload collections on app start
class DashboardPreloader {
  static bool _preloadStarted = false;
  static Future<void>? _preloadFuture;

  /// Call this during app initialization to preload collections
  static Future<void> preloadCollections() async {
    if (_preloadStarted) return _preloadFuture;

    _preloadStarted = true;
    _preloadFuture = _performPreload();
    return _preloadFuture;
  }

  static Future<void> _performPreload() async {
    try {
      debugPrint('🚀 [Dashboard] Starting collection preload...');
      final collectionService = CollectionService();
      await collectionService.getAccessibleCollections();
      debugPrint('✅ [Dashboard] Collection preload completed');
    } catch (e) {
      debugPrint('⚠️  [Dashboard] Collection preload failed: $e');
    }
  }
}

// ✅ OPTIMIZATION 2: Collection widget with built-in caching
class OptimizedCollectionWidget extends StatelessWidget {
  final Widget Function(List<Map<String, dynamic>> collections) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const OptimizedCollectionWidget({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  // Static cache for widget-level caching
  static List<Map<String, dynamic>>? _widgetCache;
  static DateTime? _widgetCacheTime;
  static const Duration _widgetCacheTimeout = Duration(minutes: 5);

  Future<List<Map<String, dynamic>>> _getCachedCollections() async {
    // Check widget-level cache first
    if (_widgetCache != null &&
        _widgetCacheTime != null &&
        DateTime.now().difference(_widgetCacheTime!).inMinutes <
            _widgetCacheTimeout.inMinutes) {
      debugPrint('🎯 [Dashboard] Using widget cache');
      return _widgetCache!;
    }

    try {
      debugPrint('🔄 [Dashboard] Loading collections...');
      final collectionService = CollectionService();
      final collections = await collectionService.getAccessibleCollections();

      final convertedCollections = collections
          .map((collection) => {
                'id': collection.id,
                'name': collection.name,
                'description': collection.description,
                'songCount': collection.songCount,
                'color': _getCollectionColor(collection.id),
                'icon': _getCollectionIcon(collection.id),
              })
          .toList();

      // Cache the result
      _widgetCache = convertedCollections;
      _widgetCacheTime = DateTime.now();

      debugPrint(
          '✅ [Dashboard] Collections cached: ${convertedCollections.length}');
      return convertedCollections;
    } catch (e) {
      debugPrint('❌ [Dashboard] Error loading collections: $e');
      return _getFallbackCollections();
    }
  }

  static void invalidateWidgetCache() {
    _widgetCache = null;
    _widgetCacheTime = null;
    debugPrint('🗑️ [Dashboard] Widget cache invalidated');
  }

  static Color _getCollectionColor(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Colors.blue;
      case 'SRD':
        return Colors.purple;
      case 'Lagu_belia':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  static IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      default:
        return Icons.folder_special;
    }
  }

  static List<Map<String, dynamic>> _getFallbackCollections() {
    return [
      {
        'id': 'LPMI',
        'name': 'LPMI',
        'description': 'Main praise songs collection',
        'songCount': 272,
        'color': Colors.blue,
        'icon': Icons.library_music,
      },
      {
        'id': 'SRD',
        'name': 'SRD',
        'description': 'Revival and devotional songs',
        'songCount': 222,
        'color': Colors.purple,
        'icon': Icons.auto_stories,
      },
      {
        'id': 'Lagu_belia',
        'name': 'Lagu Belia',
        'description': 'Songs for young people',
        'songCount': 50,
        'color': Colors.green,
        'icon': Icons.child_care,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCachedCollections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('❌ [OptimizedCollectionWidget] Error: ${snapshot.error}');
          return errorWidget ?? builder(_getFallbackCollections());
        }

        return builder(snapshot.data ?? _getFallbackCollections());
      },
    );
  }
}

// ✅ OPTIMIZATION 3: Performance monitoring
class DashboardPerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, Duration> _durations = {};

  static void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    debugPrint('⏱️ [Dashboard] Started: $operation');
  }

  static void endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _durations[operation] = duration;
      debugPrint(
          '✅ [Dashboard] Completed: $operation in ${duration.inMilliseconds}ms');
      _startTimes.remove(operation);
    }
  }

  static Map<String, Duration> getMetrics() => Map.from(_durations);

  static void logSummary() {
    debugPrint('📊 [Dashboard] Performance Summary:');
    _durations.forEach((operation, duration) {
      debugPrint('   • $operation: ${duration.inMilliseconds}ms');
    });
  }
}

// ✅ OPTIMIZATION 4: Collection service enhancements
extension CollectionServiceOptimizations on CollectionService {
  /// Pre-warm the cache with essential collections
  Future<void> preWarmCache() async {
    try {
      DashboardPerformanceMonitor.startTimer('cache_prewarm');
      await getAccessibleCollections();
      DashboardPerformanceMonitor.endTimer('cache_prewarm');
    } catch (e) {
      debugPrint('❌ [CollectionService] Pre-warm failed: $e');
    }
  }

  /// Get cache health status
  Map<String, dynamic> getCacheHealth() {
    final serviceStatus = getCacheStatus();
    return {
      'service_cache': serviceStatus,
      'widget_cache': {
        'has_data': OptimizedCollectionWidget._widgetCache != null,
        'item_count': OptimizedCollectionWidget._widgetCache?.length ?? 0,
        'cache_age': OptimizedCollectionWidget._widgetCacheTime != null
            ? DateTime.now()
                .difference(OptimizedCollectionWidget._widgetCacheTime!)
                .inSeconds
            : null,
      },
      'performance': DashboardPerformanceMonitor.getMetrics(),
    };
  }
}

// ✅ OPTIMIZATION 5: Usage in main app
class DashboardOptimizations {
  /// Call this during app initialization
  static Future<void> initializeOptimizations() async {
    // Preload collections
    await DashboardPreloader.preloadCollections();

    // Pre-warm collection service cache
    final collectionService = CollectionService();
    await collectionService.preWarmCache();

    debugPrint('🎯 [Dashboard] All optimizations initialized');
  }

  /// Call this when collections are modified
  static void invalidateAllCaches() {
    CollectionService.invalidateCache();
    OptimizedCollectionWidget.invalidateWidgetCache();
    debugPrint('🗑️ [Dashboard] All caches invalidated');
  }

  /// Get performance and cache status
  static Map<String, dynamic> getSystemStatus() {
    final collectionService = CollectionService();
    return collectionService.getCacheHealth();
  }
}
