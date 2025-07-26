import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/widgets.dart' show Icon;

/// A widget that displays Material icons
/// Previously supported GIFs but now exclusively uses Material icons for better performance
class GifIconWidget extends StatelessWidget {
  // Kept for backwards compatibility but not used anymore
  final String? gifAssetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final bool forceAnimation;

  const GifIconWidget({
    super.key,
    this.gifAssetPath, // Kept for backwards compatibility
    required this.fallbackIcon,
    this.size = 24.0,
    this.color,
    this.forceAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? Colors.white : Colors.black87);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        // Subtle background that works in both themes
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade100.withOpacity(0.5),
      ),
      padding: EdgeInsets.all(size * 0.05), // Small padding
      child: Icon(
        fallbackIcon,
        size: size * 0.9,
        color: iconColor,
      ),
    );
  }
}
              gifAssetPath!,
              width: size * 0.9,
              height: size * 0.9,
              fit: BoxFit.contain,
              // Critical: These settings enable GIF animation
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to Material icon if GIF fails to load
                return Icon(
                  fallbackIcon,
                  size: size * 0.7,
                  color: color ?? Theme.of(context).iconTheme.color,
                );
              },
            ),
          ),
        ),
      );
    }

    // Default to Material icon
    return Icon(
      fallbackIcon,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
    );
  }
}

/// Helper class to manage dashboard icon mappings
class DashboardIconHelper {
  /// Get GIF asset path for song collections
  static String? getCollectionGifPath(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return 'assets/dashboard_icons/LPMI.gif';
      case 'SRD':
        return 'assets/dashboard_icons/SRD.gif';
      case 'Lagu_belia':
        return 'assets/dashboard_icons/lagu_belia.gif';
      default:
        return null;
    }
  }

  /// Get fallback Material icon for collections
  static IconData getCollectionFallbackIcon(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      default:
        return Icons.folder_special;
    }
  }

  /// Get GIF asset path for dashboard functions
  static String? getDashboardFunctionGifPath(String functionType) {
    switch (functionType) {
      case 'all_songs':
        return 'assets/dashboard_icons/all_song.gif';
      case 'favorites':
        return 'assets/dashboard_icons/favorite.gif';
      case 'settings':
        return 'assets/dashboard_icons/settings.gif';
      case 'donation':
        return 'assets/dashboard_icons/donation.gif';
      case 'add_song':
        return 'assets/dashboard_icons/add_song.gif';
      case 'song_management':
        return 'assets/dashboard_icons/song_management.gif';
      case 'collection_management':
        return 'assets/dashboard_icons/collection_management.gif';
      case 'reports':
        return 'assets/dashboard_icons/report_managment.gif';
      case 'announcements':
        return 'assets/dashboard_icons/announcement_management.gif';
      case 'user_management':
        return 'assets/dashboard_icons/user_management.gif';
      case 'admin_management':
        return 'assets/dashboard_icons/admin_management.gif';
      case 'debug':
        return 'assets/dashboard_icons/debug.gif';
      case 'sync_debug':
        return 'assets/dashboard_icons/sync_debug.gif';
      case 'system_analytics':
        return 'assets/dashboard_icons/sys_analytic.gif';
      case 'recent':
        return 'assets/dashboard_icons/recent.gif';
      case 'collection_debug':
        return 'assets/dashboard_icons/collection_debug.gif';
      case 'christmas_songs':
        return 'assets/dashboard_icons/christmas_song.gif';
      case 'new_collection':
        return 'assets/dashboard_icons/new_collection.gif';
      case 'login':
        return 'assets/dashboard_icons/login.gif';
      default:
        return null;
    }
  }

  /// Get fallback Material icon for dashboard functions
  static IconData getDashboardFunctionFallbackIcon(String functionType) {
    switch (functionType) {
      case 'all_songs':
        return Icons.library_music;
      case 'favorites':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'donation':
        return Icons.volunteer_activism;
      case 'add_song':
        return Icons.add_circle;
      case 'song_management':
        return Icons.edit_note;
      case 'collection_management':
        return Icons.folder_special;
      case 'reports':
        return Icons.assessment;
      case 'announcements':
        return Icons.campaign;
      case 'user_management':
        return Icons.people;
      case 'admin_management':
        return Icons.admin_panel_settings;
      case 'debug':
        return Icons.bug_report;
      case 'sync_debug':
        return Icons.sync;
      case 'system_analytics':
        return Icons.analytics;
      case 'recent':
        return Icons.history;
      case 'collection_debug':
        return Icons.folder_copy;
      case 'christmas_songs':
        return Icons.celebration;
      case 'new_collection':
        return Icons.create_new_folder;
      case 'login':
        return Icons.login;
      default:
        return Icons.help_outline;
    }
  }
}
