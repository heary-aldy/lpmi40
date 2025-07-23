// lib/src/features/admin/presentation/asset_sync_utility_page.dart
// ✅ ASSET SYNC UTILITY: Sync Firebase LPMI collection to local JSON assets
// 🔄 PURPOSE: Update assets/data/lpmi.json and lmpi.json with latest Firebase data
// 📁 FIREBASE PATH: song_collection/LPMI/songs

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AssetSyncUtilityPage extends StatefulWidget {
  const AssetSyncUtilityPage({super.key});

  @override
  AssetSyncUtilityPageState createState() => AssetSyncUtilityPageState();
}

class AssetSyncUtilityPageState extends State<AssetSyncUtilityPage> {
  final List<String> _logs = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Firebase paths
  static const String _songCollectionPath = 'song_collection';
  static const String _lpmiCollectionId = 'LPMI';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _syncFirebaseToAssets() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🔄 Starting Firebase to Assets sync...');

      // Step 1: Fetch LPMI collection from Firebase
      _addLog('📡 Fetching LPMI collection from Firebase...');
      final database = FirebaseDatabase.instance;
      final songsRef =
          database.ref('$_songCollectionPath/$_lpmiCollectionId/songs');

      final snapshot = await songsRef.get();

      if (!snapshot.exists) {
        _addLog('❌ No LPMI collection found in Firebase');
        return;
      }

      // Step 2: Parse Firebase data
      final firebaseData = snapshot.value as Map<dynamic, dynamic>;
      _addLog(
          '✅ Found ${firebaseData.length} songs in Firebase LPMI collection');

      // Step 3: Create both JSON formats
      _addLog('🔄 Converting to JSON formats...');

      // Format 1: Array format for lpmi.json (used by main app)
      final List<Map<String, dynamic>> lpmiArrayFormat = [];

      // Format 2: Object format for lmpi.json (used by debug/upload)
      final Map<String, dynamic> lmpiObjectFormat = {};

      int index = 0;
      for (final entry in firebaseData.entries) {
        final songData = Map<String, dynamic>.from(entry.value as Map);

        // Ensure required fields exist
        if (!songData.containsKey('song_number') ||
            !songData.containsKey('song_title') ||
            !songData.containsKey('verses')) {
          _addLog('⚠️ Skipping malformed song: ${entry.key}');
          continue;
        }

        // Clean and format song data
        final cleanSong = {
          'song_number': songData['song_number'].toString(),
          'song_title': songData['song_title'].toString(),
          'verses': _cleanVerses(songData['verses']),
        };

        // Add URL if available (for lmpi.json)
        final songWithUrl = Map<String, dynamic>.from(cleanSong);
        if (songData.containsKey('url') && songData['url'] != null) {
          songWithUrl['url'] = songData['url'].toString();
        }

        // Add to both formats
        lpmiArrayFormat.add(cleanSong);
        lmpiObjectFormat[index.toString()] = songWithUrl;
        index++;
      }

      _addLog('✅ Processed ${lpmiArrayFormat.length} songs successfully');

      // Step 4: Generate JSON strings
      final lpmiJsonString =
          const JsonEncoder.withIndent('    ').convert(lpmiArrayFormat);
      final lmpiJsonString =
          const JsonEncoder.withIndent('  ').convert(lmpiObjectFormat);

      // Step 5: Save to temporary files and offer download
      await _saveAndOfferDownload('lpmi.json', lpmiJsonString);
      await _saveAndOfferDownload('lmpi.json', lmpiJsonString);

      _addLog('🎉 Sync completed successfully!');
      _addLog('📁 Updated files are ready for download');
      _addLog('');
      _addLog('📋 Instructions:');
      _addLog('1. Download both files');
      _addLog('2. Replace assets/data/lpmi.json and assets/data/lmpi.json');
      _addLog('3. Rebuild your app to use updated data');
    } catch (e) {
      _addLog('❌ Error during sync: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _cleanVerses(dynamic versesData) {
    if (versesData is! List) return [];

    return versesData
        .map((verse) {
          if (verse is Map) {
            return {
              'verse_number': (verse['verse_number'] ?? '').toString(),
              'lyrics': (verse['lyrics'] ?? '').toString(),
            };
          }
          return <String, dynamic>{};
        })
        .where((verse) => verse['verse_number']?.isNotEmpty == true)
        .toList();
  }

  Future<void> _saveAndOfferDownload(String filename, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      _addLog(
          '💾 Saved $filename (${(content.length / 1024).toStringAsFixed(1)} KB)');
    } catch (e) {
      _addLog('❌ Failed to save $filename: $e');
    }
  }

  Future<void> _downloadFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final lpmiFile = File('${directory.path}/lpmi.json');
      final lmpiFile = File('${directory.path}/lmpi.json');

      if (await lpmiFile.exists() && await lmpiFile.exists()) {
        // Share both files
        final files = [lpmiFile.path, lmpiFile.path];
        await Share.shareXFiles(
          files.map((path) => XFile(path)).toList(),
          subject: 'Updated LPMI JSON Assets',
          text: 'Updated lpmi.json and lmpi.json files synced from Firebase',
        );
        _addLog('📤 Files shared successfully');
      } else {
        _addLog('❌ Files not found. Please sync first.');
      }
    } catch (e) {
      _addLog('❌ Error sharing files: $e');
    }
  }

  Future<void> _compareSizes() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('📊 Comparing Firebase vs Assets data sizes...');

      // Get Firebase count
      final database = FirebaseDatabase.instance;
      final songsRef =
          database.ref('$_songCollectionPath/$_lpmiCollectionId/songs');
      final snapshot = await songsRef.get();

      final firebaseCount =
          snapshot.exists ? (snapshot.value as Map).length : 0;
      _addLog('🔥 Firebase LPMI songs: $firebaseCount');

      // Parse local assets (would need rootBundle in actual implementation)
      _addLog('📁 Local lpmi.json: Cannot count from assets in this context');
      _addLog('📁 Local lmpi.json: Cannot count from assets in this context');

      _addLog('');
      _addLog('💡 To get accurate comparison, use the sync function');
    } catch (e) {
      _addLog('❌ Error during comparison: $e');
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
        title: const Text('Asset Sync Utility'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Firebase ↔ Assets Sync Utility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sync LPMI collection from Firebase to update local JSON assets',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _syncFirebaseToAssets,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync from Firebase'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _downloadFiles,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _compareSizes,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare Sizes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Logs Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Sync Logs',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'Click "Sync from Firebase" to start',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 1),
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: _getLogColor(_logs[index]),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('❌')) return Colors.red[300]!;
    if (log.contains('✅')) return Colors.green[300]!;
    if (log.contains('⚠️')) return Colors.yellow[300]!;
    if (log.contains('🔄')) return Colors.blue[300]!;
    if (log.contains('📡') || log.contains('💾')) return Colors.cyan[300]!;
    if (log.contains('🎉')) return Colors.purple[300]!;
    return Colors.grey[300]!;
  }
}
