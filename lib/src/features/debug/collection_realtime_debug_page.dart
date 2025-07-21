// lib/src/features/debug/collection_realtime_debug_page.dart
// Debug page to test real-time collection updates

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';

class CollectionRealtimeDebugPage extends StatefulWidget {
  const CollectionRealtimeDebugPage({super.key});

  @override
  State<CollectionRealtimeDebugPage> createState() =>
      _CollectionRealtimeDebugPageState();
}

class _CollectionRealtimeDebugPageState
    extends State<CollectionRealtimeDebugPage> {
  final CollectionNotifierService _collectionNotifier =
      CollectionNotifierService();
  StreamSubscription<List<SongCollection>>? _collectionsSubscription;

  List<SongCollection> _collections = [];
  bool _isListening = false;
  String _lastUpdate = 'Not started';
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _collectionsSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _lastUpdate = 'Started listening...';
    });

    _collectionsSubscription =
        _collectionNotifier.collectionsStream.listen((collections) {
      if (mounted) {
        setState(() {
          _collections = collections;
          _updateCount++;
          _lastUpdate =
              'Updated: ${DateTime.now().toString().substring(11, 19)} '
              '(${collections.length} collections)';
        });
      }
    });

    // Initialize the service
    _collectionNotifier.initialize();
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _lastUpdate = 'Stopped listening';
    });
    _collectionsSubscription?.cancel();
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _lastUpdate = 'Force refreshing...';
    });

    await _collectionNotifier.forceRefresh();

    setState(() {
      _lastUpdate =
          'Force refresh completed: ${DateTime.now().toString().substring(11, 19)}';
    });
  }

  void _simulateCollectionAdd() {
    final testCollection = SongCollection(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Collection ${DateTime.now().second}',
      description: 'Simulated collection for testing',
      songCount: 0,
      accessLevel: CollectionAccessLevel.public,
      status: CollectionStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'debug_user',
    );

    _collectionNotifier.notifyCollectionAdded(testCollection);

    setState(() {
      _lastUpdate = 'Simulated collection add: ${testCollection.name}';
    });
  }

  void _clearDebugData() {
    _collectionNotifier.clear();
    setState(() {
      _collections.clear();
      _updateCount = 0;
      _lastUpdate = 'Debug data cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Real-time Debug'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isListening
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _isListening ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Real-time Listening',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          'Updates: $_updateCount',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Update: $_lastUpdate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Collections Count: ${_collections.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _forceRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Force Refresh'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _simulateCollectionAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Simulate Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _clearDebugData,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Collections List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Collections (${_collections.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_collections.isEmpty) ...[
                      const Text('No collections loaded yet'),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _collections.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final collection = _collections[index];
                          return ListTile(
                            leading: Icon(
                              _getCollectionIcon(collection),
                              color: _getCollectionColor(collection),
                            ),
                            title: Text(collection.name),
                            subtitle: Text(
                              '${collection.songCount} songs • ${collection.status.toString().split('.').last}',
                            ),
                            trailing: Text(
                              collection.id,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
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
                      'Debug Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _collectionNotifier.getDebugInfo().toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test Real-time Updates:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Keep this page open\n'
                      '2. Navigate to Collection Management (Admin Panel)\n'
                      '3. Create, edit, or delete a collection\n'
                      '4. Return to this page to see real-time updates\n'
                      '5. Check the drawer menu to see updated collections\n\n'
                      'The "Updates" counter should increment automatically '
                      'when collections change in the admin panel.',
                      style: TextStyle(height: 1.4),
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

  IconData _getCollectionIcon(SongCollection collection) {
    switch (collection.id) {
      case 'LPMI':
        return Icons.library_music;
      case 'Lagu_belia':
        return Icons.people;
      case 'SRD':
        return Icons.self_improvement;
      case 'lagu_krismas_26346':
        return Icons.church;
      default:
        return Icons.folder_special;
    }
  }

  Color _getCollectionColor(SongCollection collection) {
    switch (collection.id) {
      case 'LPMI':
        return Colors.blue;
      case 'Lagu_belia':
        return Colors.green;
      case 'SRD':
        return Colors.purple;
      case 'lagu_krismas_26346':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }
}
