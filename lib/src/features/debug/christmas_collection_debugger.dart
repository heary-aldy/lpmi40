// lib/src/features/debug/christmas_collection_debugger.dart
// Christmas Collection Debugger - Help diagnose and fix Christmas collection loading issues

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/core/services/firebase_database_service.dart';
import 'package:lpmi40/src/features/songbook/services/persistent_collections_config.dart';

class ChristmasCollectionDebugger {
  final FirebaseDatabaseService _databaseService =
      FirebaseDatabaseService.instance;

  /// Debug Christmas collection loading issues
  Future<Map<String, dynamic>> debugChristmasCollection() async {
    final debugResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'checks': [],
      'recommendations': [],
      'persistent_config': {},
    };

    try {
      // Get persistent collections configuration
      final configSummary =
          await PersistentCollectionsConfig.getConfigSummary();
      debugResults['persistent_config'] = configSummary;

      if (!_databaseService.isInitialized) {
        debugResults['error'] = 'Firebase not initialized';
        return debugResults;
      }

      final database = FirebaseDatabase.instance;

      // Check 1: Look for Christmas collection in different paths
      final possiblePaths = [
        'song_collection/lagu_krismas_26346',
        'song_collection/lagu_krismas_26346/songs',
        'song_collection/christmas',
        'song_collection/christmas/songs',
        'song_collection/Christmas',
        'song_collection/Christmas/songs',
        'song_collection/lagu_krismas',
        'song_collection/lagu_krismas/songs',
        'songs/lagu_krismas_26346',
        'legacy_songs/lagu_krismas_26346',
      ];

      for (final path in possiblePaths) {
        try {
          final ref = database.ref(path);
          final snapshot = await ref.get().timeout(const Duration(seconds: 5));

          final check = {
            'path': path,
            'exists': snapshot.exists,
            'hasValue': snapshot.value != null,
            'dataType': snapshot.value?.runtimeType.toString(),
            'size': _getDataSize(snapshot.value),
          };

          if (snapshot.exists && snapshot.value != null) {
            check['sample'] = _getSampleData(snapshot.value);
          }

          debugResults['checks'].add(check);

          debugPrint(
              '🔍 Christmas Debug - $path: exists=${snapshot.exists}, value=${snapshot.value != null}');
        } catch (e) {
          debugResults['checks'].add({
            'path': path,
            'error': e.toString(),
          });
          debugPrint('❌ Christmas Debug - $path: ERROR - $e');
        }
      }

      // Check 2: Look for any collection with "christmas" or "krismas" in the name
      try {
        final collectionsRef = database.ref('song_collection');
        final collectionsSnapshot =
            await collectionsRef.get().timeout(const Duration(seconds: 8));

        if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
          final collections =
              Map<String, dynamic>.from(collectionsSnapshot.value as Map);
          final christmasLikeCollections = collections.keys
              .where((key) =>
                  key.toLowerCase().contains('christmas') ||
                  key.toLowerCase().contains('krismas'))
              .toList();

          debugResults['found_christmas_collections'] =
              christmasLikeCollections;
          debugResults['all_collections'] = collections.keys.toList();

          for (final collectionKey in christmasLikeCollections) {
            debugPrint('🎄 Found Christmas-like collection: $collectionKey');
            final collectionData = collections[collectionKey];
            if (collectionData is Map) {
              final mapData = Map<String, dynamic>.from(collectionData);
              debugResults['christmas_collection_data'] = {
                'key': collectionKey,
                'structure': mapData.keys.toList(),
                'has_songs': mapData.containsKey('songs'),
                'songs_count': _getDataSize(mapData['songs']),
              };
            }
          }
        }
      } catch (e) {
        debugResults['collections_check_error'] = e.toString();
      }

      // Generate recommendations
      _generateRecommendations(debugResults);
    } catch (e) {
      debugResults['fatal_error'] = e.toString();
    }

    return debugResults;
  }

  int _getDataSize(dynamic data) {
    if (data == null) return 0;
    if (data is Map) return data.length;
    if (data is List) return data.length;
    return 1;
  }

  dynamic _getSampleData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.isEmpty) return {};

      // Return first few keys for structure inspection
      final keys = map.keys.take(3).toList();
      final sample = <String, dynamic>{};
      for (final key in keys) {
        sample[key] = _getSampleData(map[key]);
      }
      if (map.length > 3) {
        sample['...'] = '${map.length - 3} more items';
      }
      return sample;
    }
    if (data is List) {
      if (data.isEmpty) return [];
      return [
        _getSampleData(data.first),
        if (data.length > 1) '... ${data.length - 1} more items'
      ];
    }
    return data.toString().length > 50
        ? '${data.toString().substring(0, 50)}...'
        : data;
  }

  void _generateRecommendations(Map<String, dynamic> debugResults) {
    final recommendations = <String>[];
    final checks = debugResults['checks'] as List;
    final configSummary =
        debugResults['persistent_config'] as Map<String, dynamic>;

    // Check if any path returned data
    final hasData = checks
        .any((check) => check['exists'] == true && check['hasValue'] == true);

    if (!hasData) {
      recommendations
          .add('❌ No Christmas collection found in any expected path');
      recommendations.add(
          '✅ SOLUTION 1: Check if Christmas collection exists in Firebase Console');
      recommendations
          .add('✅ SOLUTION 2: Import Christmas songs into the database');
      recommendations.add(
          '✅ SOLUTION 3: Use the "Auto-Fix" button to temporarily manage persistent collections');
    } else {
      final workingPaths = checks
          .where(
              (check) => check['exists'] == true && check['hasValue'] == true)
          .toList();
      recommendations
          .add('✅ Found Christmas data in ${workingPaths.length} path(s)');

      for (final path in workingPaths) {
        recommendations
            .add('📍 Working path: ${path['path']} (${path['size']} items)');

        // Extract collection ID from path
        final pathStr = path['path'] as String;
        if (pathStr.contains('song_collection/')) {
          final collectionId =
              pathStr.split('song_collection/')[1].split('/')[0];

          // Check if it's in persistent collections
          final persistentCollections =
              configSummary['persistent_collections'] as List;
          if (!persistentCollections.contains(collectionId)) {
            recommendations.add(
                '🔧 SOLUTION: Add "$collectionId" to persistent collections using Auto-Fix');
          }
        }
      }
    }

    // Add persistent collections status
    final persistentCollections =
        configSummary['persistent_collections'] as List;
    final lastChristmas = configSummary['last_working_christmas'];

    recommendations.add('');
    recommendations.add(
        '📋 Current persistent collections: ${persistentCollections.join(', ')}');
    if (lastChristmas != null) {
      recommendations
          .add('🎄 Last working Christmas collection: $lastChristmas');
    }

    debugResults['recommendations'] = recommendations;
  }

  /// Auto-fix Christmas collection issues
  Future<Map<String, dynamic>> autoFixChristmasCollection() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'actions_taken': [],
      'success': false,
    };

    try {
      final database = FirebaseDatabase.instance;

      // Get all collections
      final collectionsRef = database.ref('song_collection');
      final collectionsSnapshot =
          await collectionsRef.get().timeout(const Duration(seconds: 8));

      if (collectionsSnapshot.exists && collectionsSnapshot.value != null) {
        final collections =
            Map<String, dynamic>.from(collectionsSnapshot.value as Map);

        // Try to find and save Christmas collection
        final christmasCollection =
            await PersistentCollectionsConfig.findAndSaveChristmasCollection(
                collections);

        if (christmasCollection != null) {
          results['actions_taken'].add(
              '✅ Found and saved Christmas collection: $christmasCollection');
          results['actions_taken'].add('✅ Added to persistent collections');
          results['success'] = true;
          results['christmas_collection'] = christmasCollection;
        } else {
          results['actions_taken']
              .add('❌ No working Christmas collection found');
          results['actions_taken'].add(
              '🔧 Removing any non-working Christmas collections from persistent list');

          // Remove any Christmas-like collections that don't work
          final candidates =
              PersistentCollectionsConfig.getChristmasCollectionCandidates();
          for (final candidate in candidates) {
            try {
              await PersistentCollectionsConfig.removePersistentCollection(
                  candidate);
              results['actions_taken'].add('➖ Removed non-working: $candidate');
            } catch (e) {
              // Ignore removal errors
            }
          }
        }

        // Show current persistent collections
        final persistent =
            await PersistentCollectionsConfig.getPersistentCollections();
        results['persistent_collections'] = persistent;
        results['actions_taken']
            .add('📋 Current persistent collections: ${persistent.join(', ')}');
      } else {
        results['actions_taken']
            .add('❌ Could not access song collections database');
      }
    } catch (e) {
      results['error'] = e.toString();
      results['actions_taken'].add('❌ Error during auto-fix: $e');
    }

    return results;
  }

  /// Quick fix: Temporarily disable Christmas collection from priority loading
  static List<String> getWorkingPriorityCollections() {
    return [
      'LPMI',
      'SRD',
      'Lagu_belia',
      // 'lagu_krismas_26346', // Temporarily disabled due to loading issues
    ];
  }

  /// Get alternative Christmas collection IDs to try
  static List<String> getChristmasCollectionAlternatives() {
    return [
      'lagu_krismas_26346',
      'christmas',
      'Christmas',
      'lagu_krismas',
      'christmas_songs',
      'Christmas_Songs',
    ];
  }
}

/// Debug page for Christmas collection issues
class ChristmasDebugPage extends StatefulWidget {
  const ChristmasDebugPage({super.key});

  @override
  State<ChristmasDebugPage> createState() => _ChristmasDebugPageState();
}

class _ChristmasDebugPageState extends State<ChristmasDebugPage> {
  Map<String, dynamic>? _debugResults;
  Map<String, dynamic>? _autoFixResults;
  bool _isLoading = false;
  bool _isFixing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎄 Christmas Collection Debug'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎄 Christmas Collection Debug Tool',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'This tool helps diagnose Christmas collection loading issues and manage persistent collections.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading || _isFixing ? null : _runDebug,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.bug_report),
                            label:
                                Text(_isLoading ? 'Debugging...' : 'Run Debug'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading || _isFixing ? null : _runAutoFix,
                            icon: _isFixing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_fix_high),
                            label: Text(_isFixing ? 'Fixing...' : 'Auto-Fix'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_debugResults != null || _autoFixResults != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Auto-fix results
                      if (_autoFixResults != null) ...[
                        Card(
                          color: _autoFixResults!['success'] == true
                              ? Colors.green[50]
                              : Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _autoFixResults!['success'] == true
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      color: _autoFixResults!['success'] == true
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '🔧 Auto-Fix Results',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '🕒 ${_autoFixResults!['timestamp']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                if (_autoFixResults!['actions_taken'] !=
                                    null) ...[
                                  const Text(
                                    '📋 Actions Taken:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._autoFixResults!['actions_taken']
                                      .map<Widget>((action) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $action'),
                                          ))
                                      .toList(),
                                ],
                                if (_autoFixResults!['error'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Error: ${_autoFixResults!['error']}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Debug results
                      if (_debugResults != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📊 Debug Results',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '🕒 ${_debugResults!['timestamp']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),

                                // Recommendations
                                if (_debugResults!['recommendations'] !=
                                    null) ...[
                                  const Text(
                                    '💡 Recommendations:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._debugResults!['recommendations']
                                      .map<Widget>((rec) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text('• $rec'),
                                          ))
                                      .toList(),
                                  const SizedBox(height: 16),
                                ],

                                // Raw debug data
                                const Text(
                                  '🔍 Raw Debug Data:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    const JsonEncoder.withIndent('  ')
                                        .convert(_debugResults),
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else if (_isLoading || _isFixing) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_isFixing
                          ? 'Running auto-fix...'
                          : 'Debugging Christmas collection...'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text('Tap "Run Debug" to start diagnosis'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runDebug() async {
    setState(() {
      _isLoading = true;
      _debugResults = null;
    });

    try {
      final debugger = ChristmasCollectionDebugger();
      final results = await debugger.debugChristmasCollection();
      setState(() {
        _debugResults = results;
      });
    } catch (e) {
      setState(() {
        _debugResults = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAutoFix() async {
    setState(() {
      _isFixing = true;
      _autoFixResults = null;
    });

    try {
      final debugger = ChristmasCollectionDebugger();
      final results = await debugger.autoFixChristmasCollection();
      setState(() {
        _autoFixResults = results;
      });

      // Also refresh debug results if auto-fix was successful
      if (results['success'] == true) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _runDebug();
      }
    } catch (e) {
      setState(() {
        _autoFixResults = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
          'success': false,
          'actions_taken': ['❌ Error during auto-fix: $e'],
        };
      });
    } finally {
      setState(() {
        _isFixing = false;
      });
    }
  }
}
