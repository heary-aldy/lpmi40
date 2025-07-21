// lib/src/features/debug/sync_debug_page.dart
// Debug page to test asset sync functionality

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/services/asset_sync_service.dart';
import 'package:lpmi40/src/features/songbook/services/app_initialization_service.dart';

class SyncDebugPage extends StatefulWidget {
  const SyncDebugPage({super.key});

  @override
  State<SyncDebugPage> createState() => _SyncDebugPageState();
}

class _SyncDebugPageState extends State<SyncDebugPage> {
  final AssetSyncService _syncService = AssetSyncService();
  final AppInitializationService _initService = AppInitializationService();

  SyncStatus? _syncStatus;
  bool _isLoading = false;
  String _lastOperation = '';
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Loading sync status...';
    });

    try {
      final status = await _syncService.getSyncStatus();
      setState(() {
        _syncStatus = status;
        _lastResult = 'Status loaded successfully';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Error loading status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSync() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Syncing from Firebase...';
      _lastResult = '';
    });

    try {
      final result = await _syncService.syncFromFirebase();
      setState(() {
        _lastResult = result.success
            ? 'Sync successful: ${result.message}'
            : 'Sync failed: ${result.message}';
      });
      await _loadSyncStatus();
    } catch (e) {
      setState(() {
        _lastResult = 'Sync error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLocalData() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Clearing local data...';
      _lastResult = '';
    });

    try {
      await _syncService.clearLocalData();
      setState(() {
        _lastResult = 'Local data cleared successfully';
      });
      await _loadSyncStatus();
    } catch (e) {
      setState(() {
        _lastResult = 'Clear error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAppInitialization() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Testing app initialization...';
      _lastResult = '';
    });

    try {
      final result = await _initService.initializeApp(forceSync: false);
      setState(() {
        _lastResult =
            'Init ${result.success ? 'successful' : 'failed'}: ${result.message}\n'
            'Had local data: ${result.hadLocalData}\n'
            'Performed sync: ${result.performedSync}';
      });
      await _loadSyncStatus();
    } catch (e) {
      setState(() {
        _lastResult = 'Init error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Sync Debug'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Sync Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_syncStatus != null) ...[
                      _buildStatusRow(
                          'Has Local Data', _syncStatus!.hasLocalData),
                      _buildStatusRow('Needs Sync', _syncStatus!.needsSync),
                      _buildStatusRow(
                          'Firebase Changed', _syncStatus!.hasFirebaseChanged),
                      const SizedBox(height: 8),
                      Text(
                        'Last Sync: ${_syncStatus!.lastSyncTime?.toString() ?? 'Never'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      const Text('Loading status...'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Operation Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loadSyncStatus,
                            child: const Text('Refresh Status'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _performSync,
                            child: const Text('Sync Now'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _testAppInitialization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Test App Init'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _clearLocalData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear Local'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Operation Results Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Operation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_lastOperation),
                        ],
                      ),
                    ] else ...[
                      Text(
                        _lastResult.isEmpty
                            ? 'No operations performed yet'
                            : _lastResult,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'App Initialization Service:\n'
                      'Is Initialized: ${_initService.isInitialized}\n'
                      'Is Initializing: ${_initService.isInitializing}\n\n'
                      'This page allows you to test the asset sync functionality '
                      'and app initialization process. Use the buttons above to '
                      'perform different operations and monitor the results.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            status ? 'Yes' : 'No',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
