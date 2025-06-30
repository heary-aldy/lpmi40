// lib/src/features/debug/firebase_debug_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
    debugPrint(message);
  }

  Future<bool> _isCurrentUserSuperAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${user.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final role = userData['role']?.toString().toLowerCase();
        return role == 'super_admin';
      }
      return false;
    } catch (e) {
      _addLog('❌ Error checking admin status: $e');
      return false;
    }
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

  Future<bool> _showDeleteConfirmation() async {
    final controller = TextEditingController();
    const confirmText = 'DELETE ALL DATA';
    bool isTextValid = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 32),
                  SizedBox(width: 8),
                  Text('⚠️ DANGER ZONE ⚠️'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action will PERMANENTLY delete ALL Firebase data including:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• All songs'),
                  const Text('• All user accounts'),
                  const Text('• All user preferences'),
                  const Text('• All application data'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      '🚨 THIS CANNOT BE UNDONE! 🚨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Type "$confirmText" to confirm deletion:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type confirmation text here',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        isTextValid = value == confirmText;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isTextValid
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('DELETE EVERYTHING'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<bool> _showFinalWarning() async {
    int countdown = 10;
    bool canProceed = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              if (!canProceed && countdown > 0) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setDialogState(() {
                      countdown--;
                      if (countdown == 0) {
                        canProceed = true;
                      }
                    });
                  }
                });
              }

              return AlertDialog(
                title: const Text('FINAL WARNING'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'You are about to delete ALL Firebase data.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!canProceed)
                      Text(
                        'Please wait $countdown seconds...',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.orange),
                      )
                    else
                      const Text(
                        'Are you absolutely sure?',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: canProceed
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('YES, DELETE ALL DATA'),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;
  }

  Future<void> _clearDatabase() async {
    // Step 1: Check if user is super admin
    _addLog('🔒 Checking admin privileges...');
    final isSuperAdmin = await _isCurrentUserSuperAdmin();

    if (!isSuperAdmin) {
      _addLog('❌ Access denied: Only Super Admins can delete database');
      _showMessage('Only Super Admins can delete the database', Colors.red);
      return;
    }

    _addLog('✅ Super Admin privileges confirmed');

    // Step 2: First confirmation dialog
    final firstConfirm = await _showDeleteConfirmation();
    if (!firstConfirm) {
      _addLog('🚫 Database deletion cancelled by user');
      return;
    }

    // Step 3: Final warning with countdown
    final finalConfirm = await _showFinalWarning();
    if (!finalConfirm) {
      _addLog('🚫 Database deletion cancelled at final warning');
      return;
    }

    // Step 4: Proceed with deletion
    setState(() {
      _isLoading = true;
      _status = 'Clearing Firebase database...';
    });

    try {
      _addLog('💥 INITIATING DATABASE DELETION...');
      await _songRepository.clearFirebaseSongs();

      // Clear users data as well
      final database = FirebaseDatabase.instance;
      await database.ref('users').remove();

      _addLog('✅ Firebase database cleared successfully!');
      _addLog('⚠️ ALL DATA HAS BEEN PERMANENTLY DELETED');
      setState(() {
        _status = 'Database cleared - ALL DATA DELETED';
      });

      _showMessage('Database successfully deleted', Colors.orange);
    } catch (e) {
      _addLog('❌ Clear failed: $e');
      setState(() {
        _status = 'Clear failed';
      });
      _showMessage('Error deleting database: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
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
                    Text(_status, style: const TextStyle(fontSize: 16)),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 16),

                    // Danger Zone
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'DANGER ZONE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Super Admin Only: This will permanently delete ALL Firebase data',
                            style: TextStyle(fontSize: 12, color: Colors.red),
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
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                          } else if (log.contains('⚠️') || log.contains('💥')) {
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
