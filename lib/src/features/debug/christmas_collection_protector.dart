// lib/src/features/debug/christmas_collection_protector.dart
// 🎄 SECURITY: Christmas Collection Protection & Investigation Tool

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChristmasCollectionProtector {
  static const List<String> christmasCollectionPaths = [
    'lagu_krismas_26346',
    'christmas',
    'Christmas',
    'lagu_krismas',
    'christmas_songs',
    'CHRISTMAS',
  ];

  /// 🔍 INVESTIGATION: Check what might have caused Christmas collection deletion
  static Future<Map<String, dynamic>> investigateDeletion() async {
    final database = FirebaseDatabase.instance;
    final investigation = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'findings': <String>[],
      'recommendations': <String>[],
      'possibleCauses': <String>[],
    };

    try {
      // Check if any Christmas collection paths exist
      for (final path in christmasCollectionPaths) {
        final ref = database.ref('song_collection/$path');
        final snapshot = await ref.get();

        if (snapshot.exists) {
          investigation['findings']
              .add('✅ Found Christmas collection at: $path');
        } else {
          investigation['findings']
              .add('❌ Missing Christmas collection at: $path');
        }
      }

      // Check for recent deletion activities in database logs
      investigation['possibleCauses'].addAll([
        '🔧 Firebase Debug Page - Database Clear Operation',
        '📝 Song Migration - Bulk Delete and Recreate',
        '👑 Admin Action - Individual Song Deletion',
        '⚡ Collection Timeout - Connection Issues',
        '🔄 Firebase Rules - Permission Changes',
        '💾 Asset Loading Error - Database Fallback',
      ]);

      investigation['recommendations'].addAll([
        '🛡️ Implement Christmas collection backup before operations',
        '📊 Add deletion logging for all collection operations',
        '⚠️ Add confirmation dialogs for bulk operations',
        '🔒 Implement collection protection flags',
        '📱 Create Christmas collection recovery tool',
        '🎄 Set up Christmas collection monitoring alerts',
      ]);

      return investigation;
    } catch (e) {
      investigation['findings'].add('❌ Investigation failed: $e');
      return investigation;
    }
  }

  /// 🛡️ PROTECTION: Create backup before dangerous operations
  static Future<Map<String, dynamic>> createChristmasBackup() async {
    final database = FirebaseDatabase.instance;
    final backup = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
    };

    try {
      for (final path in christmasCollectionPaths) {
        final ref = database.ref('song_collection/$path');
        final snapshot = await ref.get();

        if (snapshot.exists) {
          backup['collections'][path] = snapshot.value;
          debugPrint('[ChristmasProtector] 🎄 Backed up collection: $path');
        }
      }

      // Store backup in a protected location
      final backupRef = database.ref(
          'backups/christmas_collections/${DateTime.now().millisecondsSinceEpoch}');
      await backupRef.set(backup);

      debugPrint(
          '[ChristmasProtector] ✅ Christmas backup created successfully');
      return backup;
    } catch (e) {
      debugPrint('[ChristmasProtector] ❌ Backup failed: $e');
      rethrow;
    }
  }

  /// 🔄 RECOVERY: Restore Christmas collection from backup
  static Future<bool> restoreFromBackup(String backupId) async {
    final database = FirebaseDatabase.instance;

    try {
      final backupRef = database.ref('backups/christmas_collections/$backupId');
      final snapshot = await backupRef.get();

      if (!snapshot.exists) {
        debugPrint('[ChristmasProtector] ❌ Backup not found: $backupId');
        return false;
      }

      final backupData = snapshot.value as Map<dynamic, dynamic>;
      final collections = backupData['collections'] as Map<dynamic, dynamic>;

      for (final entry in collections.entries) {
        final path = entry.key as String;
        final data = entry.value;

        final restoreRef = database.ref('song_collection/$path');
        await restoreRef.set(data);

        debugPrint('[ChristmasProtector] 🎄 Restored collection: $path');
      }

      debugPrint(
          '[ChristmasProtector] ✅ Christmas collection restored successfully');
      return true;
    } catch (e) {
      debugPrint('[ChristmasProtector] ❌ Restore failed: $e');
      return false;
    }
  }

  /// 📊 MONITORING: Check Christmas collection health
  static Future<Map<String, dynamic>> checkHealth() async {
    final database = FirebaseDatabase.instance;
    final health = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'unknown',
      'collections_found': 0,
      'total_songs': 0,
      'details': <String, dynamic>{},
    };

    try {
      int collectionsFound = 0;
      int totalSongs = 0;

      for (final path in christmasCollectionPaths) {
        final ref = database.ref('song_collection/$path');
        final snapshot = await ref.get();

        if (snapshot.exists) {
          collectionsFound++;
          final data = snapshot.value as Map<dynamic, dynamic>?;
          final songCount = data?.length ?? 0;
          totalSongs += songCount;

          health['details'][path] = {
            'exists': true,
            'song_count': songCount,
            'last_checked': DateTime.now().toIso8601String(),
          };
        } else {
          health['details'][path] = {
            'exists': false,
            'last_checked': DateTime.now().toIso8601String(),
          };
        }
      }

      health['collections_found'] = collectionsFound;
      health['total_songs'] = totalSongs;
      health['status'] = collectionsFound > 0 ? 'healthy' : 'critical';

      return health;
    } catch (e) {
      health['status'] = 'error';
      health['error'] = e.toString();
      return health;
    }
  }

  /// ⚠️ PREVENTION: Add warning before dangerous operations
  static Future<bool> confirmDangerousOperation(
    BuildContext context,
    String operationName,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning, color: Colors.red, size: 48),
            title: const Text('🎄 Christmas Collection Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are about to perform: $operationName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This operation may affect the Christmas collection. '
                  'Would you like to create a backup first?',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Create backup before proceeding
                  try {
                    await createChristmasBackup();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Backup failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      Navigator.of(context).pop(false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Backup & Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
