// lib/src/features/admin/presentation/collection_migrator_page.dart
// ✅ MIGRATION: Upload collections to Firebase Database
// 🔧 FIXED: Layout constraint issue with ElevatedButton.icon in Row

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class CollectionMigratorPage extends StatefulWidget {
  const CollectionMigratorPage({super.key});

  @override
  State<CollectionMigratorPage> createState() => _CollectionMigratorPageState();
}

class _CollectionMigratorPageState extends State<CollectionMigratorPage> {
  String _output = 'Ready to migrate collections to Firebase...\n';
  bool _isRunning = false;

  void _addOutput(String line) {
    setState(() {
      _output +=
          '${DateTime.now().toIso8601String().substring(11, 19)}: $line\n';
    });
    print('🔄 [MIGRATOR] $line');
  }

  Future<void> _migrateCollections() async {
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

      // Define your collections based on the JSON you provided
      final collectionsData = {
        'LPMI': {
          'metadata': {
            'name': 'Lagu Pujian Masa Ini',
            'description': 'The main collection of hymns.',
            'access_level': 'public',
            'status': 'active',
            'song_count': 266,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'created_by': 'system',
          },
          // Note: We're not adding songs here since they're already in the database
        },
        'Lagu_belia': {
          'metadata': {
            'name': 'Lagu Belia',
            'description': 'Songs for the youth.',
            'access_level': 'registered',
            'status': 'active',
            'song_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'created_by': 'system',
          },
          'songs': {}, // Empty for now
        },
        'SRD': {
          'metadata': {
            'name': 'Saat Hening',
            'description': 'Songs for personal devotion.',
            'access_level': 'registered',
            'status': 'active',
            'song_count': 222,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'created_by': 'system',
          },
          // Note: We're not adding songs here since they would need to be migrated from your JSON
        },
      };

      // Upload each collection
      for (final entry in collectionsData.entries) {
        final collectionId = entry.key;
        final collectionData = entry.value;

        try {
          _addOutput('📁 Uploading collection: $collectionId');

          final collectionRef = database.ref(collectionId);
          await collectionRef.set(collectionData);

          _addOutput('✅ Successfully uploaded: $collectionId');
        } catch (e) {
          _addOutput('❌ Failed to upload $collectionId: $e');
        }
      }

      // Now let's also create the LPMI collection with existing songs
      _addOutput('🔄 Linking existing songs to LPMI collection...');
      try {
        // Get existing songs from the songs path
        final songsRef = database.ref('songs');
        final songsSnapshot = await songsRef.get();

        if (songsSnapshot.exists && songsSnapshot.value != null) {
          final songsData =
              Map<String, dynamic>.from(songsSnapshot.value as Map);
          _addOutput('📊 Found ${songsData.length} existing songs');

          // Update LPMI collection with the existing songs
          final lpmiSongsRef = database.ref('LPMI/songs');
          await lpmiSongsRef.set(songsData);

          // Update the song count
          final lpmiMetadataRef = database.ref('LPMI/metadata/song_count');
          await lpmiMetadataRef.set(songsData.length);

          _addOutput('✅ Linked ${songsData.length} songs to LPMI collection');
        } else {
          _addOutput('⚠️ No existing songs found in /songs path');
        }
      } catch (e) {
        _addOutput('❌ Failed to link songs: $e');
      }

      _addOutput('🎉 Collection migration completed!');
      _addOutput('📋 You should now see collections in the app');
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
          final collectionRef = database.ref(collectionId);
          final snapshot =
              await collectionRef.get().timeout(const Duration(seconds: 5));

          if (snapshot.exists) {
            final data = snapshot.value as Map?;
            final metadata = data?['metadata'] as Map?;
            final name = metadata?['name'] ?? 'Unknown';
            final songCount = metadata?['song_count'] ?? 0;

            _addOutput('✅ $collectionId: $name ($songCount songs)');
          } else {
            _addOutput('❌ $collectionId: Not found');
          }
        } catch (e) {
          _addOutput('❌ $collectionId: Error - $e');
        }
      }
    } catch (e) {
      _addOutput('💥 Test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Migrator'),
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
                  '🚀 Collection Migration Tool',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will create your collections in Firebase Database so they appear in your app.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // 🔧 FIXED: Added Expanded wrappers to prevent infinite width constraints
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _migrateCollections,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload),
                        label: Text(_isRunning
                            ? 'Migrating...'
                            : 'Migrate Collections'),
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
                  '⚠️ This will create 3 collections: LPMI (public), Lagu Belia (registered), SRD (registered)',
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
