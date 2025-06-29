// lib/src/features/debug/firebase_debug_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class FirebaseDebugPage extends StatefulWidget {
  const FirebaseDebugPage({super.key});

  @override
  State<FirebaseDebugPage> createState() => _FirebaseDebugPageState();
}

class _FirebaseDebugPageState extends State<FirebaseDebugPage> {
  final SongRepository _songRepository = SongRepository();
  bool _isLoading = false;
  String _status = 'Ready';
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal()}: $message');
    });
    print(message);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      _addLog('Testing Firebase connection...');
      final isConnected = await _songRepository.testFirebaseConnection();

      if (isConnected) {
        _addLog('✅ Firebase connection successful!');
        setState(() {
          _status = 'Firebase connected';
        });
      } else {
        _addLog('❌ Firebase connection failed');
        setState(() {
          _status = 'Firebase not connected';
        });
      }
    } catch (e) {
      _addLog('❌ Connection test error: $e');
      setState(() {
        _status = 'Connection test failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadSongs() async {
    setState(() {
      _isLoading = true;
      _status = 'Uploading songs to Firebase...';
    });

    try {
      _addLog('Starting upload of local songs to Firebase...');
      await _songRepository.uploadLocalSongsToFirebase();
      _addLog('✅ Songs uploaded successfully!');
      setState(() {
        _status = 'Upload completed';
      });
    } catch (e) {
      _addLog('❌ Upload failed: $e');
      setState(() {
        _status = 'Upload failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFetch() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing song fetch from Firebase...';
    });

    try {
      _addLog('Fetching songs from Firebase...');
      final result = await _songRepository.getSongs();

      if (result.isOnline) {
        _addLog(
            '✅ Successfully fetched ${result.songs.length} songs from Firebase');
        setState(() {
          _status = 'Fetch successful (Online)';
        });
      } else {
        _addLog(
            '⚠️ Fetched ${result.songs.length} songs from local assets (Offline)');
        setState(() {
          _status = 'Fetch from local assets';
        });
      }
    } catch (e) {
      _addLog('❌ Fetch failed: $e');
      setState(() {
        _status = 'Fetch failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearDatabase() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Firebase Database'),
        content: const Text(
            'This will permanently delete all songs from Firebase. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Clearing Firebase database...';
    });

    try {
      _addLog('Clearing Firebase database...');
      await _songRepository.clearFirebaseSongs();
      _addLog('✅ Firebase database cleared successfully!');
      setState(() {
        _status = 'Database cleared';
      });
    } catch (e) {
      _addLog('❌ Clear failed: $e');
      setState(() {
        _status = 'Clear failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = 'Logs cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Firebase Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Database: https://lmpi-c5c5c.firebaseio.com/',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test Firebase Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _uploadSongs,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Local Songs to Firebase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testFetch,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Test Fetch from Firebase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _clearDatabase,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear Firebase Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logs Section
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Debug Logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _clearLogs,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color? textColor;
                          if (log.contains('✅')) {
                            textColor = Colors.green;
                          } else if (log.contains('❌')) {
                            textColor = Colors.red;
                          } else if (log.contains('⚠️')) {
                            textColor = Colors.orange;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: textColor,
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
          ],
        ),
      ),
    );
  }
}
