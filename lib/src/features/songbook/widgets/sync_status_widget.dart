// lib/src/features/songbook/widgets/sync_status_widget.dart
// Widget to display sync status and allow manual sync

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/services/asset_sync_service.dart';

class SyncStatusWidget extends StatefulWidget {
  final VoidCallback? onSyncComplete;

  const SyncStatusWidget({
    super.key,
    this.onSyncComplete,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final AssetSyncService _syncService = AssetSyncService();
  bool _isSyncing = false;
  SyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await _syncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _syncStatus = status;
      });
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _syncService.syncFromFirebase();

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        if (result.success) {
          await _loadSyncStatus();
          widget.onSyncComplete?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null) {
      return const SizedBox(width: 24, height: 24);
    }

    return PopupMenuButton<String>(
      icon: _buildSyncIcon(),
      tooltip: _getSyncTooltip(),
      onSelected: (value) {
        switch (value) {
          case 'sync':
            _performSync();
            break;
          case 'status':
            _showSyncStatus();
            break;
          case 'clear':
            _clearLocalData();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'sync',
          enabled: !_isSyncing,
          child: Row(
            children: [
              Icon(
                _isSyncing ? Icons.sync : Icons.cloud_download,
                size: 20,
                color: _isSyncing ? Colors.grey : null,
              ),
              const SizedBox(width: 8),
              Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.info, size: 20),
              SizedBox(width: 8),
              Text('Sync Status'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.clear_all, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Local Data', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncIcon() {
    if (_isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    IconData iconData;
    Color iconColor;

    if (!_syncStatus!.hasLocalData) {
      iconData = Icons.cloud_download;
      iconColor = Colors.orange;
    } else if (_syncStatus!.needsSync) {
      iconData = Icons.sync_problem;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.cloud_done;
      iconColor = Colors.green;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  String _getSyncTooltip() {
    if (_isSyncing) return 'Syncing...';
    if (!_syncStatus!.hasLocalData) return 'No local data - tap to sync';
    if (_syncStatus!.needsSync) return 'Local data outdated - tap to sync';
    return 'Data up to date';
  }

  void _showSyncStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync),
            SizedBox(width: 8),
            Text('Sync Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Has Local Data', _syncStatus!.hasLocalData),
            _buildStatusRow('Needs Sync', _syncStatus!.needsSync),
            _buildStatusRow(
                'Firebase Changed', _syncStatus!.hasFirebaseChanged),
            const SizedBox(height: 12),
            if (_syncStatus!.lastSyncTime != null) ...[
              Text(
                'Last Sync:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                _formatDateTime(_syncStatus!.lastSyncTime!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'Never synced',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_syncStatus!.needsSync)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performSync();
              },
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will remove all locally stored song data. '
          'The app will need to download data from Firebase again. '
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _syncService.clearLocalData();
      await _loadSyncStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
