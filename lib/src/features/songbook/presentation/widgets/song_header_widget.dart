// lib/src/features/songbook/presentation/widgets/song_header_widget.dart
// ✅ UPDATED: Added fullscreen mode navigation for premium users

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/fullscreen_lyrics_page.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/utils/constants.dart';

class SongHeaderWidget extends StatefulWidget {
  final Song song;
  final String? initialCollection;
  final bool isOnline;
  final DeviceType deviceType;
  final VoidCallback onFontSizeIncrease;
  final VoidCallback onFontSizeDecrease;

  const SongHeaderWidget({
    super.key,
    required this.song,
    this.initialCollection,
    required this.isOnline,
    required this.deviceType,
    required this.onFontSizeIncrease,
    required this.onFontSizeDecrease,
  });

  @override
  State<SongHeaderWidget> createState() => _SongHeaderWidgetState();
}

class _SongHeaderWidgetState extends State<SongHeaderWidget> {
  bool _isAppBarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double collapsedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final headerHeight = AppConstants.getHeaderHeight(widget.deviceType);
    final scale = AppConstants.getTypographyScale(widget.deviceType);
    final spacing = AppConstants.getSpacing(widget.deviceType);

    return SliverAppBar(
      expandedHeight: headerHeight,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: theme.colorScheme.primary,
      title: _isAppBarCollapsed
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    widget.song.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * scale,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing * 0.5),
                _buildStatusIndicator(),
              ],
            )
          : null,
      actions: [
        _buildMenuButton(context, scale),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var isCollapsed = constraints.maxHeight <= collapsedHeight;
          if (isCollapsed != _isAppBarCollapsed) {
            Future.microtask(() {
              if (mounted) setState(() => _isAppBarCollapsed = isCollapsed);
            });
          }
          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
            title: const Text(''),
            background: _buildHeaderBackground(context, spacing, scale),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBackground(
      BuildContext context, double spacing, double scale) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/header_image.png',
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              Container(color: theme.colorScheme.primary),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.6)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: spacing,
          left: spacing,
          right: 72 * scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 4 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_getCollectionAbbreviation(widget.initialCollection)} #${widget.song.number}',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing * 0.5),
                  _buildStatusIndicator(),
                ],
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                widget.song.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 2, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, double scale) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      iconColor: Colors.white,
      icon: Icon(Icons.more_vert, size: 24 * scale),
      color: theme.popupMenuTheme.color,
      shape: theme.popupMenuTheme.shape,
      onSelected: (value) {
        switch (value) {
          case 'increase_font':
            widget.onFontSizeIncrease();
            break;
          case 'decrease_font':
            widget.onFontSizeDecrease();
            break;
          case 'upgrade_premium':
            _showPremiumUpgradeDialog();
            break;
          case 'fullscreen_mode':
            _openFullScreenMode();
            break;
        }
      },
      itemBuilder: (context) {
        final songProvider = context.read<SongProvider>();
        final isPremium = songProvider.isPremium;
        final isRegistered = _isUserRegistered();

        return [
          PopupMenuItem(
            value: 'decrease_font',
            child: ListTile(
              leading: Icon(
                Icons.text_decrease,
                color: theme.iconTheme.color,
                size: 20 * scale,
              ),
              title: Text(
                'Decrease Font',
                style: theme.popupMenuTheme.textStyle?.copyWith(
                  fontSize:
                      (theme.popupMenuTheme.textStyle?.fontSize ?? 14) * scale,
                ),
              ),
            ),
          ),
          PopupMenuItem(
            value: 'increase_font',
            child: ListTile(
              leading: Icon(
                Icons.text_increase,
                color: theme.iconTheme.color,
                size: 20 * scale,
              ),
              title: Text(
                'Increase Font',
                style: theme.popupMenuTheme.textStyle?.copyWith(
                  fontSize:
                      (theme.popupMenuTheme.textStyle?.fontSize ?? 14) * scale,
                ),
              ),
            ),
          ),
          if (isRegistered && isPremium) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'fullscreen_mode',
              child: ListTile(
                leading: Icon(
                  Icons.fullscreen,
                  color: theme.colorScheme.primary,
                  size: 20 * scale,
                ),
                title: Text(
                  'Full Screen Mode',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (isRegistered && !isPremium) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'upgrade_premium',
              child: ListTile(
                leading: Icon(
                  Icons.star,
                  color: Colors.purple,
                  size: 20 * scale,
                ),
                title: Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ];
      },
    );
  }

  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isOnline
            ? (isDark
                ? Colors.green.withOpacity(0.2)
                : Colors.green.withOpacity(0.1))
            : (isDark
                ? Colors.grey.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isOnline ? Icons.cloud_queue_rounded : Icons.storage_rounded,
            size: 14,
            color: widget.isOnline
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            widget.isOnline ? 'Online' : 'Local',
            style: TextStyle(
              fontSize: 11,
              color: widget.isOnline
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getCollectionAbbreviation(String? collectionName) {
    if (collectionName == null || collectionName == 'All') return 'LPMI';
    switch (collectionName) {
      case 'Lagu Pujian Masa Ini':
      case 'LPMI':
        return 'LPMI';
      case 'Syair Rindu Dendam':
        return 'SRD';
      case 'Lagu Belia':
        return 'LB';
      case 'Favorites':
        return 'FAV';
      default:
        return collectionName.length > 4
            ? collectionName.substring(0, 4).toUpperCase()
            : collectionName.toUpperCase();
    }
  }

  bool _isUserRegistered() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> _showPremiumUpgradeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          const PremiumUpgradeDialog(feature: 'audio_playback'),
    );
  }

  void _openFullScreenMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenLyricsPage(song: widget.song),
        fullscreenDialog: true,
      ),
    );
  }
}

// Compact header for smaller screens
class CompactSongHeader extends StatelessWidget {
  final Song song;
  final String? initialCollection;
  final bool isOnline;

  const CompactSongHeader({
    super.key,
    required this.song,
    this.initialCollection,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getCollectionAbbreviation(initialCollection)} #${song.number}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildCompactStatusIndicator(context),
        ],
      ),
    );
  }

  Widget _buildCompactStatusIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.offline_bolt,
            size: 12,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 10,
              color: isOnline ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getCollectionAbbreviation(String? collectionName) {
    if (collectionName == null || collectionName == 'All') return 'LPMI';
    switch (collectionName) {
      case 'Lagu Pujian Masa Ini':
      case 'LPMI':
        return 'LPMI';
      case 'Syair Rindu Dendam':
        return 'SRD';
      case 'Lagu Belia':
        return 'LB';
      case 'Favorites':
        return 'FAV';
      default:
        return collectionName.length > 4
            ? collectionName.substring(0, 4).toUpperCase()
            : collectionName.toUpperCase();
    }
  }
}
