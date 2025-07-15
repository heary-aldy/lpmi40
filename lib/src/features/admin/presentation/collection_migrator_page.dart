// lib/src/features/admin/presentation/collection_migrator_page.dart
// ✅ MIGRATION: Upload collections to Firebase Database using /song_collection/ structure
// 🔧 FIXED: Layout constraint issue with ElevatedButton.icon in Row
// 📊 STRUCTURE: Uses /song_collection/{collectionId} to match your actual Firebase structure

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class CollectionMigratorPage extends StatefulWidget {
  const CollectionMigratorPage({super.key});

  @override
  State<CollectionMigratorPage> createState() => _CollectionMigratorPageState();
}

class _CollectionMigratorPageState extends State<CollectionMigratorPage> {
  String _output =
      'Ready to migrate collections to Firebase Database using proper structure...\n';
  bool _isRunning = false;

  void _addOutput(String line) {
    setState(() {
      _output +=
          '${DateTime.now().toIso8601String().substring(11, 19)}: $line\n';
    });
    print('🔄 [MIGRATOR] $line');
  }

  Future<void> _testCollectionAccess() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _output = 'Starting collection migration...\n';
    });

    try {
      final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://lmpi-c5c5c-default-rtdb.firebaseio.com");

      _addOutput('🌐 Connected to Firebase Database');

      // ✅ FIXED: Define collections using Firebase rules structure
      final collectionsData = {
        'LPMI': {
          'name': 'Lagu Pujian Masa Ini',
          'description': 'The main collection of hymns.',
          'access_level': 'public',
          'status': 'active',
          'song_count': 0, // Will be updated after linking songs
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
        'Lagu_belia': {
          'name': 'Lagu Belia',
          'description': 'Songs for the youth.',
          'access_level': 'registered',
          'status': 'active',
          'song_count': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
        'SRD': {
          'name': 'Saat Hening',
          'description': 'Songs for personal devotion.',
          'access_level': 'registered',
          'status': 'active',
          'song_count': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
      };

      // ✅ FIXED: Upload collection metadata to correct path
      for (final entry in collectionsData.entries) {
        final collectionId = entry.key;
        final collectionData = entry.value;

        try {
          _addOutput('📁 Uploading collection metadata: $collectionId');

          // ✅ FIXED: Write to song_collection/{collectionId} to match your actual Firebase structure
          final collectionRef = database.ref('song_collection/$collectionId');
          await collectionRef.set(collectionData);

          final songCount =
              (collectionData['metadata'] as Map)['songCount'] ?? 0;
          _addOutput(
              '✅ Successfully uploaded: $collectionId ($songCount songs)');
        } catch (e) {
          _addOutput('❌ Failed to upload $collectionId: $e');
        }
      }

      _addOutput('🎉 Collection migration completed!');
      _addOutput(
          '📋 Collections created in song_collection/ using your current structure');
    } catch (e) {
      _addOutput('💥 Migration failed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testCollections() async {
    _addOutput('🧪 Testing collection reading...');

    try {
      final database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: "https://lmpi-c5c5c-default-rtdb.firebaseio.com");

      final collections = ['LPMI', 'Lagu_belia', 'SRD'];

      for (final collectionId in collections) {
        try {
          // ✅ FIXED: Read from song_collection/{collectionId} path (your actual structure)
          final collectionRef = database.ref('song_collection/$collectionId');
          final snapshot =
              await collectionRef.get().timeout(const Duration(seconds: 5));

          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            final metadata = data['metadata'] as Map?;
            final songs = data['songs'] as Map?;

            final name = metadata?['name'] ?? 'Unknown';
            final songCount = songs?.length ?? 0;
            final metadataSongCount = metadata?['songCount'] ?? 0;

            _addOutput('✅ $collectionId: $name');
            _addOutput('   📊 Metadata song count: $metadataSongCount');
            _addOutput('   📊 Actual songs: $songCount');
          } else {
            _addOutput('❌ $collectionId: Not found in song_collection');
          }
        } catch (e) {
          _addOutput('❌ $collectionId: Error - $e');
        }
      }

      // Test reading the collections list from correct path
      _addOutput('🔍 Testing collections list access...');
      try {
        final collectionsRef = database.ref('song_collection');
        final collectionsSnapshot =
            await collectionsRef.get().timeout(const Duration(seconds: 5));

        if (collectionsSnapshot.exists) {
          final collectionsData = collectionsSnapshot.value as Map?;
          final collectionCount = collectionsData?.length ?? 0;
          _addOutput('✅ Found $collectionCount collections in song_collection');
        } else {
          _addOutput('❌ No collections found in song_collection');
        }
      } catch (e) {
        _addOutput('❌ Failed to read collections list: $e');
      }
    } catch (e) {
      _addOutput('💥 Test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Tester'),
        backgroundColor: Colors.green[100],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧪 Collection Access Tester',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will test and work with collections in your song_collection/ path structure.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // 🔧 FIXED: Added Expanded wrappers to prevent infinite width constraints
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _testCollectionAccess,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload),
                        label: Text(_isRunning
                            ? 'Testing...'
                            : 'Test Collection Access'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testCollections,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Test Collections'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ This will create 3 collections in song_collections/: LPMI (public), Lagu Belia (registered), SRD (registered)',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
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
                  _output,
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
