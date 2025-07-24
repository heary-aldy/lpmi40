// lib/src/widgets/connectivity_status_indicator.dart
// Connectivity Status Indicator - Shows users their connection status

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A widget that shows the current connectivity status
class ConnectivityStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final bool showWhenOnline;
  final EdgeInsets? padding;
  final bool isCompact;

  const ConnectivityStatusIndicator({
    super.key,
    required this.isOnline,
    this.showWhenOnline = false,
    this.padding,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Only show when offline, unless explicitly requested to show when online
    if (isOnline && !showWhenOnline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final backgroundColor = isOnline
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.orange.withValues(alpha: 0.1);
    final textColor = isOnline ? Colors.green[700] : Colors.orange[700];
    final icon = isOnline ? Icons.wifi : Icons.wifi_off;
    final text = isOnline ? 'Online' : 'Offline Mode';
    final subtext = isOnline ? 'All features available' : 'Using cached data';

    if (isCompact) {
      return Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (textColor ?? Colors.grey).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (textColor ?? Colors.grey).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    color: textColor?.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isOnline) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showOfflineHelp(context),
              icon: Icon(
                Icons.help_outline,
                color: textColor,
                size: 20,
              ),
              tooltip: 'Learn about offline mode',
            ),
          ],
        ],
      ),
    );
  }

  void _showOfflineHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Offline Mode'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re currently using the app in offline mode. Here\'s what you can still do:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            OfflineFeatureList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class OfflineFeatureList extends StatelessWidget {
  const OfflineFeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      '✅ Browse all locally cached songs',
      '✅ View song lyrics and details',
      '✅ Access your saved favorites',
      '✅ Use search functionality',
      '✅ Change app settings and themes',
      '❌ Save new favorites (requires login)',
      '❌ Access latest song updates',
      '❌ Report song issues',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 13,
                    color: feature.startsWith('✅')
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Provider for connectivity status
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;

  bool get isOnline => _isOnline;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;

  void updateConnectivity(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      if (isOnline) {
        _lastOnlineTime = DateTime.now();
      } else {
        _lastOfflineTime = DateTime.now();
      }
      notifyListeners();
    }
  }

  String get statusText => _isOnline ? 'Online' : 'Offline';

  String get detailedStatus {
    if (_isOnline) {
      return 'Connected - All features available';
    } else {
      final offlineTime = _lastOfflineTime;
      if (offlineTime != null) {
        final duration = DateTime.now().difference(offlineTime);
        if (duration.inMinutes < 1) {
          return 'Offline for ${duration.inSeconds} seconds';
        } else if (duration.inHours < 1) {
          return 'Offline for ${duration.inMinutes} minutes';
        } else {
          return 'Offline for ${duration.inHours} hours';
        }
      }
      return 'Offline - Using cached data';
    }
  }
}

/// Connectivity-aware app bar that shows status
class ConnectivityAwareAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;

  const ConnectivityAwareAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              actions: [
                ...?actions,
                if (!connectivity.isOnline)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ConnectivityStatusIndicator(
                      isOnline: connectivity.isOnline,
                      isCompact: true,
                    ),
                  ),
              ],
              leading: leading,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              automaticallyImplyLeading: automaticallyImplyLeading,
            ),
            if (!connectivity.isOnline)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectivity.detailedStatus,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
      kToolbarHeight + 32); // Extra height for offline banner
}
