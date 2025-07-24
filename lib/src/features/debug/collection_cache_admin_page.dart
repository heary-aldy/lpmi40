// lib/src/features/debug/collection_cache_admin_page.dart
// 🛠️ COLLECTION CACHE ADMINISTRATION
// Comprehensive admin interface for managing the new collection caching system

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';
import 'package:lpmi40/src/features/songbook/services/smart_collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_migration_service.dart';

class CollectionCacheAdminPage extends StatefulWidget {
  const CollectionCacheAdminPage({super.key});

  @override
  State<CollectionCacheAdminPage> createState() =>
      _CollectionCacheAdminPageState();
}

class _CollectionCacheAdminPageState extends State<CollectionCacheAdminPage> {
  Map<String, dynamic>? _cacheStats;
  Map<String, dynamic>? _migrationStatus;
  Map<String, dynamic>? _serviceStats;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _lastOperation;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheManager = CollectionCacheManager.instance;
      final smartService = SmartCollectionService.instance;

      final results = await Future.wait([
        cacheManager.getCacheStats(),
        CollectionMigrationService.getMigrationStatus(),
        smartService.getServiceStats(),
      ]);

      setState(() {
        _cacheStats = results[0] as Map<String, dynamic>;
        _migrationStatus = results[1] as Map<String, dynamic>;
        _serviceStats = results[2] as Map<String, dynamic>;
      });
    } catch (e) {
      _showError('Failed to load stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRefreshing = true;
      _lastOperation = 'Running migration...';
    });

    try {
      final success = await CollectionMigrationService.runMigrationIfNeeded();

      setState(() {
        _lastOperation = success
            ? '✅ Migration completed successfully'
            : '❌ Migration failed';
      });

      await _loadAllStats();
    } catch (e) {
      setState(() {
        _lastOperation = '❌ Migration error: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _isRefreshing = true;
      _lastOperation = 'Force refreshing collections...';
    });

    try {
      final smartService = SmartCollectionService.instance;
      final collections = await smartService.forceRefreshAllCollections();

      setState(() {
        _lastOperation = '✅ Refreshed ${collections.length} collections';
      });

      await _loadAllStats();
    } catch (e) {
      setState(() {
        _lastOperation = '❌ Refresh error: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog(
      'Clear Cache',
      'This will clear all cached collections and force a fresh download. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isRefreshing = true;
      _lastOperation = 'Clearing cache...';
    });

    try {
      final smartService = SmartCollectionService.instance;
      await smartService.clearCacheAndRefresh();

      setState(() {
        _lastOperation = '✅ Cache cleared and refreshed';
      });

      await _loadAllStats();
    } catch (e) {
      setState(() {
        _lastOperation = '❌ Clear cache error: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _ensureChristmas() async {
    setState(() {
      _isRefreshing = true;
      _lastOperation = 'Ensuring Christmas collection persistence...';
    });

    try {
      final smartService = SmartCollectionService.instance;
      await smartService.ensureChristmasCollectionPersistence();

      setState(() {
        _lastOperation = '✅ Christmas collection persistence ensured';
      });

      await _loadAllStats();
    } catch (e) {
      setState(() {
        _lastOperation = '❌ Christmas persistence error: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Collection Cache Admin'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isRefreshing ? null : _loadAllStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildCacheStatsCard(),
                  const SizedBox(height: 16),
                  _buildMigrationCard(),
                  const SizedBox(height: 16),
                  _buildServiceStatsCard(),
                  if (_lastOperation != null) ...[
                    const SizedBox(height: 16),
                    _buildLastOperationCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isHealthy = _serviceStats?['service_status'] == 'healthy';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHealthy
                  ? '✅ System is running smoothly'
                  : '⚠️ System needs attention',
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The new collection caching system ensures stable collection availability '
              'and prevents the "coming and going" issue you experienced.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _runMigration,
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Run Migration'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _forceRefresh,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Force Refresh'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _ensureChristmas,
                  icon: const Icon(Icons.celebration),
                  label: const Text('Fix Christmas'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _clearCache,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Cache'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
            if (_isRefreshing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_lastOperation ?? 'Processing...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    if (_cacheStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💾 Cache Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Last Sync', _cacheStats!['last_sync'] ?? 'Never'),
            _buildStatRow('Available Collections',
                '${_cacheStats!['available_collections']}'),
            _buildStatRow(
                'Cached Collections', '${_cacheStats!['cached_collections']}'),
            _buildStatRow(
                'Total Cached Songs', '${_cacheStats!['total_cached_songs']}'),
            _buildStatRow(
                'Memory Cache Size', '${_cacheStats!['memory_cache_size']}'),
            _buildStatRow(
                'Cache Validity', '${_cacheStats!['cache_validity']} hours'),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationCard() {
    if (_migrationStatus == null) return const SizedBox.shrink();

    final isUpToDate = _migrationStatus!['is_up_to_date'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUpToDate ? Icons.check_circle : Icons.info,
                  color: isUpToDate ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '🔄 Migration Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'Current Version', '${_migrationStatus!['current_version']}'),
            _buildStatRow(
                'Target Version', '${_migrationStatus!['target_version']}'),
            _buildStatRow(
                'Status', isUpToDate ? '✅ Up to date' : '⚠️ Needs migration'),
            _buildStatRow('Last Migration',
                _migrationStatus!['last_migration'] ?? 'Never'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatsCard() {
    if (_serviceStats == null) return const SizedBox.shrink();

    final persistentCollections =
        _serviceStats!['persistent_collections'] as List<dynamic>? ?? [];
    final recommendations =
        _serviceStats!['recommendations'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Service Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Service Status',
                _serviceStats!['service_status'] ?? 'Unknown'),
            _buildStatRow('Available Collections',
                '${_serviceStats!['available_collections_count']}'),
            const SizedBox(height: 8),
            Text(
              'Persistent Collections:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: persistentCollections
                  .map((id) => Chip(
                        label: Text(id.toString()),
                        backgroundColor: Colors.green.withOpacity(0.2),
                      ))
                  .toList(),
            ),
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '💡 Recommendations:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(rec.toString())),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastOperationCard() {
    return Card(
      color: _lastOperation!.startsWith('✅')
          ? Colors.green.withOpacity(0.1)
          : _lastOperation!.startsWith('❌')
              ? Colors.red.withOpacity(0.1)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Last Operation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_lastOperation!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
