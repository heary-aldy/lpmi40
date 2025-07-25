// lib/src/features/debug/christmas_debug_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class ChristmasDebugPage extends StatefulWidget {
  const ChristmasDebugPage({super.key});

  @override
  State<ChristmasDebugPage> createState() => _ChristmasDebugPageState();
}

class _ChristmasDebugPageState extends State<ChristmasDebugPage> {
  final SongRepository _repository = SongRepository();
  bool _isLoading = false;
  final List<String> _debugLogs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Christmas Collection Debug'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎄 Christmas Collection Debug',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test the Christmas collection loading performance and identify any issues.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _debugChristmasCollection,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.bug_report),
                            label: Text(_isLoading
                                ? 'Testing...'
                                : 'Debug Christmas Collection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
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
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Debug Logs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_debugLogs.length} entries',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _debugLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No debug logs yet.\nClick "Debug Christmas Collection" to start.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _debugLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _debugLogs[index];
                                  final isError = log.contains('❌') ||
                                      log.contains('ERROR');
                                  final isSuccess = log.contains('✅') ||
                                      log.contains('SUCCESS');
                                  final isWarning = log.contains('⚠️') ||
                                      log.contains('WARNING');

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: isError
                                            ? Colors.red
                                            : isSuccess
                                                ? Colors.green
                                                : isWarning
                                                    ? Colors.orange
                                                    : Colors.black87,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _debugChristmasCollection() async {
    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    _addLog('🎄 Starting Christmas collection debug...');
    final startTime = DateTime.now();

    try {
      // Test 1: Debug the specific collection
      _addLog('📊 Test 1: Running repository debug method...');
      await _repository.debugChristmasCollection();

      // Test 2: Try to load collections
      _addLog('📊 Test 2: Loading all collections...');
      final collectionsResult = await _repository.getCollectionsSeparated();

      if (collectionsResult.containsKey('lagu_krismas_26346')) {
        final christmasSongs = collectionsResult['lagu_krismas_26346']!;
        _addLog(
            '✅ Christmas collection found with ${christmasSongs.length} songs');

        if (christmasSongs.isNotEmpty) {
          _addLog(
              '🎵 First song: ${christmasSongs.first.title} (#${christmasSongs.first.number})');
          _addLog(
              '🎵 Last song: ${christmasSongs.last.title} (#${christmasSongs.last.number})');
        }
      } else {
        _addLog('❌ Christmas collection not found in separated collections');
        _addLog('📋 Available collections: ${collectionsResult.keys.toList()}');
      }

      // Test 3: Try to load all songs
      _addLog('📊 Test 3: Loading all songs...');
      final allSongsResult = await _repository.getAllSongs();
      _addLog('✅ Total songs loaded: ${allSongsResult.songs.length}');

      // Check if Christmas songs are in the all songs list
      final christmasSongsInAll = allSongsResult.songs
          .where((song) => song.collectionId == 'lagu_krismas_26346')
          .toList();
      _addLog(
          '🎄 Christmas songs in "All Songs": ${christmasSongsInAll.length}');
    } catch (e) {
      _addLog('❌ Debug failed: $e');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    _addLog('⏱️ Total debug time: ${duration.inMilliseconds}ms');
    _addLog('🏁 Debug completed');

    setState(() {
      _isLoading = false;
    });
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _debugLogs.add('[$timestamp] $message');
    });
  }
}
