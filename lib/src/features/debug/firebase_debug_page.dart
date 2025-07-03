// lib/src/features/debug/firebase_debug_page.dart
// UI UPDATED: Using AdminHeader for consistent UI

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/widgets/admin_header.dart'; // ✅ NEW: Import AdminHeader

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

  Future<void> _migrateSongKeysToPadded() async {
    _addLog('🔒 Checking admin privileges for migration...');
    final isSuperAdmin = await _isCurrentUserSuperAdmin();
    if (!isSuperAdmin) {
      _addLog('❌ Access Denied: Migration requires Super Admin privileges.');
      _showMessage('Only Super Admins can run this migration.', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Confirm Data Migration'),
            content: const Text(
                'This will read all songs, delete the existing /songs data, and re-upload it with dynamically zero-padded keys. This should only be run ONCE.\n\nAre you sure you want to proceed?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Yes, Migrate Data'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      _addLog('🚫 Migration cancelled by user.');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Starting migration...';
    });

    try {
      _addLog('STEP 1: Fetching all existing songs...');
      final SongDataResult result = await _songRepository.getAllSongs();
      if (result.songs.isEmpty) {
        throw Exception("No songs found to migrate.");
      }
      _addLog('✅ Fetched ${result.songs.length} songs.');

      _addLog('STEP 2: Determining optimal padding...');
      final highestNumber =
          result.songs.map((s) => int.tryParse(s.number) ?? 0).reduce(max);
      final paddingLength = highestNumber.toString().length;
      _addLog(
          '✅ Highest song number is $highestNumber. Padding all keys to $paddingLength digits.');

      _addLog('STEP 3: Preparing new data with padded keys...');
      final Map<String, dynamic> newSongsMap = {};
      for (final song in result.songs) {
        final paddedKey = song.number.padLeft(paddingLength, '0');
        newSongsMap[paddedKey] = song.toJson();
      }
      _addLog('✅ Prepared ${newSongsMap.length} songs with new keys.');

      final database = FirebaseDatabase.instance;
      final songsRef = database.ref('songs');

      _addLog('STEP 4: Deleting old song data...');
      await songsRef.remove();
      _addLog('✅ Old /songs node deleted.');

      _addLog('STEP 5: Uploading new, corrected song data...');
      await songsRef.set(newSongsMap);
      _addLog(
          '✅ MIGRATION COMPLETE! Your song keys are now fixed and future-proof.');

      setState(() => _status = 'Migration Successful!');
      _showMessage('Migration completed successfully!', Colors.green);
    } catch (e) {
      _addLog('❌ MIGRATION FAILED: $e');
      setState(() => _status = 'Migration Failed!');
      _showMessage('An error occurred during migration: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      _addLog('Testing Firebase connection...');
      final database = FirebaseDatabase.instance;
      final ref = database.ref('.info/connected');
      final event = await ref.once();
      final isConnected = event.snapshot.value as bool? ?? false;

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
      final localJsonString =
          await rootBundle.loadString('assets/data/lpmi.json');
      final List<dynamic> songsArray = json.decode(localJsonString);
      _addLog('📖 Loaded ${songsArray.length} songs from local file');
      final Map<String, dynamic> songsMap = {};
      for (int i = 0; i < songsArray.length; i++) {
        final song = songsArray[i];
        final key = song['song_number']?.toString() ?? i.toString();
        songsMap[key] = song;
      }
      final DatabaseReference ref = FirebaseDatabase.instance.ref('songs');
      await ref.set(songsMap);
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
      final result = await _songRepository.getAllSongs();

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
              content: SingleChildScrollView(
                child: Column(
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
                    const Icon(Icons.delete_forever,
                        color: Colors.red, size: 64),
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
    _addLog('🔒 Checking admin privileges...');
    final isSuperAdmin = await _isCurrentUserSuperAdmin();

    if (!isSuperAdmin) {
      _addLog('❌ Access denied: Only Super Admins can delete database');
      _showMessage('Only Super Admins can delete the database', Colors.red);
      return;
    }

    final firstConfirm = await _showDeleteConfirmation();
    if (!firstConfirm) {
      _addLog('🚫 Database deletion cancelled by user');
      return;
    }

    final finalConfirm = await _showFinalWarning();
    if (!finalConfirm) {
      _addLog('🚫 Database deletion cancelled at final warning');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Clearing Firebase database...';
    });

    try {
      _addLog('💥 INITIATING DATABASE DELETION...');
      final database = FirebaseDatabase.instance;
      await database.ref('songs').remove();
      _addLog('✅ Cleared /songs node.');
      await database.ref('users').remove();
      _addLog('✅ Cleared /users node.');

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

  // ✅ ADDED: The missing helper method
  void _showMessage(String message, Color color) {
    if (!mounted) return;
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

  // ✅ UI UPDATE: Replaced original Scaffold with CustomScrollView and AdminHeader
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: 'Firebase Debug',
            subtitle: 'Tools for migration and database management',
            icon: Icons.bug_report,
            primaryColor: Colors.red,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            'Database: https://lmpi-c5c5c-default-rtdb.firebaseio.com/',
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Firebase Actions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _migrateSongKeysToPadded,
                            icon: const Icon(Icons.upgrade),
                            label: const Text(
                                'MIGRATE Song Keys to Padded Format'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Run this ONCE to fix lazy loading. Requires Super Admin.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Divider(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConnection,
                            icon: const Icon(Icons.wifi),
                            label: const Text('Test Firebase Connection'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _uploadSongs,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload Local Songs to Firebase'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testFetch,
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('Test Fetch from Firebase'),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning,
                                        color: Colors.red),
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
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
                  Card(
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            Color? textColor;
                            if (log.contains('✅')) {
                              textColor = Colors.green;
                            } else if (log.contains('❌')) {
                              textColor = Colors.red;
                            } else if (log.contains('⚠️') ||
                                log.contains('💥')) {
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
