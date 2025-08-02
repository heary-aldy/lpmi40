// lib/src/widgets/global_update_notification.dart
// 🔔 GLOBAL UPDATE NOTIFICATION: Shows users when updates are available
// 🎯 FEATURES: Update notifications, force update handling, user-friendly messages
// 🚀 OPTIMIZED: Minimal Firebase calls, respects ultra-aggressive caching

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/global_update_service.dart';

class GlobalUpdateNotification extends StatefulWidget {
  final Widget child;
  final bool showOnStartup;
  
  const GlobalUpdateNotification({
    Key? key,
    required this.child,
    this.showOnStartup = true,
  }) : super(key: key);

  @override
  State<GlobalUpdateNotification> createState() => _GlobalUpdateNotificationState();
}

class _GlobalUpdateNotificationState extends State<GlobalUpdateNotification> {
  final GlobalUpdateService _updateService = GlobalUpdateService.instance;
  GlobalUpdateStatus? _updateStatus;
  bool _isCheckingUpdate = false;
  bool _hasShownStartupNotification = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOnStartup) {
      _checkForUpdatesOnStartup();
    }
  }

  Future<void> _checkForUpdatesOnStartup() async {
    if (_hasShownStartupNotification) return;
    
    setState(() => _isCheckingUpdate = true);
    
    try {
      final result = await _updateService.checkForUpdates(isStartupCheck: true);
      
      if (result.hasUpdate && !result.isRateLimited) {
        setState(() {
          _updateStatus = GlobalUpdateStatus(
            hasUpdate: result.hasUpdate,
            currentVersion: result.currentVersion,
            latestVersion: result.latestVersion,
            message: result.message,
            lastCheck: DateTime.now(),
          );
        });
        
        if (result.forceUpdate) {
          _showForceUpdateDialog(result);
        } else {
          _showUpdateAvailableSnackBar(result);
        }
      }
      
      _hasShownStartupNotification = true;
    } catch (e) {
      debugPrint('[GlobalUpdateNotification] Error checking for updates: $e');
    } finally {
      setState(() => _isCheckingUpdate = false);
    }
  }

  void _showUpdateAvailableSnackBar(GlobalUpdateResult result) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getUpdateIcon(result.updateType),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Update Available (${result.latestVersion})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (result.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(result.message),
            ],
          ],
        ),
        backgroundColor: _getUpdateColor(result.updateType),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'More Info',
          textColor: Colors.white,
          onPressed: () => _showUpdateDialog(result),
        ),
      ),
    );
  }

  void _showForceUpdateDialog(GlobalUpdateResult result) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Update Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A critical update is available and must be installed.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildUpdateDetails(result),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The app will restart to apply the update.',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _applyUpdate(result),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(GlobalUpdateResult result) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getUpdateIcon(result.updateType), color: _getUpdateColor(result.updateType)),
            const SizedBox(width: 8),
            Text('Update Available (${result.latestVersion})'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUpdateDetails(result),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The app will refresh its data to apply the update.',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyUpdate(result);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDetails(GlobalUpdateResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Current Version:', result.currentVersion),
        _buildDetailRow('Latest Version:', result.latestVersion),
        _buildDetailRow('Update Type:', _getUpdateTypeText(result.updateType)),
        if (result.message.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Message:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(result.message),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _applyUpdate(GlobalUpdateResult result) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Applying update...'),
              ],
            ),
          ),
        );
      }

      // Update local version to prevent repeated notifications
      await _updateService.updateLocalVersion(result.latestVersion);
      
      // The global update system will handle cache clearing automatically
      // when the app initialization service detects the update
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Update applied successfully! Data will refresh automatically.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('[GlobalUpdateNotification] Error applying update: $e');
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to apply update: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  IconData _getUpdateIcon(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'critical':
      case 'emergency':
        return Icons.warning;
      case 'required':
        return Icons.update;
      case 'recommended':
        return Icons.new_releases;
      default:
        return Icons.info;
    }
  }

  Color _getUpdateColor(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'critical':
      case 'emergency':
        return Colors.red;
      case 'required':
        return Colors.orange;
      case 'recommended':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getUpdateTypeText(String updateType) {
    switch (updateType.toLowerCase()) {
      case 'critical':
        return 'Critical Update';
      case 'emergency':
        return 'Emergency Update';
      case 'required':
        return 'Required Update';
      case 'recommended':
        return 'Recommended Update';
      case 'optional':
        return 'Optional Update';
      default:
        return 'Update Available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isCheckingUpdate)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Checking for updates...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Manual update checker widget for settings or admin pages
class ManualUpdateChecker extends StatefulWidget {
  const ManualUpdateChecker({Key? key}) : super(key: key);

  @override
  State<ManualUpdateChecker> createState() => _ManualUpdateCheckerState();
}

class _ManualUpdateCheckerState extends State<ManualUpdateChecker> {
  final GlobalUpdateService _updateService = GlobalUpdateService.instance;
  bool _isChecking = false;
  GlobalUpdateResult? _lastResult;

  Future<void> _checkForUpdates() async {
    setState(() => _isChecking = true);
    
    try {
      final result = await _updateService.forceUpdateCheck();
      setState(() => _lastResult = result);
      
      if (result.hasUpdate) {
        _showUpdateDialog(result);
      } else {
        _showNoUpdateSnackBar();
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showUpdateDialog(GlobalUpdateResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'Version ${result.latestVersion} is available.\n\n'
          '${result.message}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNoUpdateSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ You have the latest version'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error checking for updates: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Check for Updates'),
      subtitle: _lastResult != null
          ? Text('Last checked: ${_formatLastCheck(_lastResult!)}')
          : const Text('Check for app updates manually'),
      trailing: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isChecking ? null : _checkForUpdates,
    );
  }

  String _formatLastCheck(GlobalUpdateResult result) {
    if (result.hasUpdate) {
      return 'Update available (${result.latestVersion})';
    } else {
      return 'Up to date (${result.currentVersion})';
    }
  }
}