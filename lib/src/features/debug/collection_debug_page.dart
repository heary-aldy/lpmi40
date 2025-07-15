// lib/src/features/debug/collection_debug_page.dart
// ✅ DEBUG: Check what's happening with collection loading

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionDebugPage extends StatefulWidget {
  const CollectionDebugPage({super.key});

  @override
  State<CollectionDebugPage> createState() => _CollectionDebugPageState();
}

class _CollectionDebugPageState extends State<CollectionDebugPage> {
  final CollectionService _collectionService = CollectionService();
  final AuthorizationService _authService = AuthorizationService();

  String _debugOutput = 'Starting debug...\n';
  bool _isRunning = false;

  void _addDebugLine(String line) {
    setState(() {
      _debugOutput +=
          '${DateTime.now().toIso8601String().substring(11, 19)}: $line\n';
    });
    print('🔍 [DEBUG] $line');
  }

  Future<void> _runDebugTests() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _debugOutput = 'Starting debug tests...\n';
    });

    try {
      // Test 1: Check Firebase connection
      _addDebugLine('TEST 1: Checking Firebase connection...');
      final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://lmpi-c5c5c-default-rtdb.firebaseio.com");

      try {
        final testRef = database.ref('.info/connected');
        final testSnapshot =
            await testRef.get().timeout(const Duration(seconds: 5));
        _addDebugLine('✅ Firebase connected: ${testSnapshot.value}');
      } catch (e) {
        _addDebugLine('❌ Firebase connection failed: $e');
      }

      // Test 2: Check auth status
      _addDebugLine('TEST 2: Checking auth status...');
      try {
        final authStatus = await _authService.checkAdminStatus();
        _addDebugLine('✅ Auth status: $authStatus');
      } catch (e) {
        _addDebugLine('❌ Auth check failed: $e');
      }

      // Test 3: Check if song_collection path exists
      _addDebugLine('TEST 3: Checking song_collection path...');
      try {
        final collectionRef = database.ref('song_collection');
        final collectionSnapshot =
            await collectionRef.get().timeout(const Duration(seconds: 10));
        _addDebugLine('✅ song_collection exists: ${collectionSnapshot.exists}');
        if (collectionSnapshot.exists) {
          final data = collectionSnapshot.value;
          if (data is Map) {
            _addDebugLine('✅ song_collection keys: ${(data).keys.toList()}');
          } else {
            _addDebugLine('⚠️ song_collection data type: ${data.runtimeType}');
          }
        }
      } catch (e) {
        _addDebugLine('❌ song_collection check failed: $e');
      }

      // Test 4: Check if collections are at root level (LPMI, Lagu_belia, SRD)
      _addDebugLine('TEST 4: Checking root level collections...');
      try {
        final rootRef = database.ref();
        final rootSnapshot =
            await rootRef.get().timeout(const Duration(seconds: 10));
        if (rootSnapshot.exists && rootSnapshot.value is Map) {
          final rootData = rootSnapshot.value as Map;
          final rootKeys = rootData.keys.toList();
          _addDebugLine('✅ Root level keys: $rootKeys');

          // Check for known collections
          final knownCollections = ['LPMI', 'Lagu_belia', 'SRD'];
          for (final collection in knownCollections) {
            if (rootKeys.contains(collection)) {
              _addDebugLine('✅ Found collection: $collection');

              // Check metadata
              final collectionData = rootData[collection];
              if (collectionData is Map &&
                  collectionData.containsKey('metadata')) {
                final metadata = collectionData['metadata'];
                _addDebugLine('✅ $collection metadata: $metadata');
              } else {
                _addDebugLine('⚠️ $collection missing metadata');
              }
            } else {
              _addDebugLine('❌ Missing collection: $collection');
            }
          }
        }
      } catch (e) {
        _addDebugLine('❌ Root check failed: $e');
      }

      // Test 5: Try loading collections via service
      _addDebugLine('TEST 5: Loading collections via CollectionService...');
      try {
        final collections = await _collectionService.getAccessibleCollections();
        _addDebugLine('✅ Loaded ${collections.length} collections via service');
        for (final collection in collections) {
          _addDebugLine(
              '✅ Collection: ${collection.id} - ${collection.name} (${collection.songCount} songs)');
        }
      } catch (e) {
        _addDebugLine('❌ CollectionService failed: $e');
      }

      // Test 6: Cache status
      _addDebugLine('TEST 6: Checking cache status...');
      try {
        final cacheStatus = _collectionService.getCacheStatus();
        _addDebugLine('✅ Cache status: $cacheStatus');
      } catch (e) {
        _addDebugLine('❌ Cache status failed: $e');
      }

      _addDebugLine('🎯 DEBUG COMPLETE');
    } catch (e) {
      _addDebugLine('💥 DEBUG CRASHED: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Debug'),
        backgroundColor: Colors.red[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runDebugTests,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _debugOutput = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔍 Collection Debug Tool',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will test your collection loading and show what\'s happening.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runDebugTests,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label:
                      Text(_isRunning ? 'Running Tests...' : 'Run Debug Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugOutput.isEmpty
                      ? 'Click "Run Debug Tests" to start...'
                      : _debugOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
