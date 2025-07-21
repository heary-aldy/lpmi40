// lib/src/features/songbook/presentation/widgets/main_page_header.dart
// ✅ NEW: Extracted header component from main_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:lpmi40/src/features/songbook/widgets/sync_status_widget.dart';
import 'package:lpmi40/utils/constants.dart';

class MainPageHeader extends StatelessWidget {
  final MainPageController controller;
  final VoidCallback onMenuPressed;
  final VoidCallback onRefreshPressed;
  final bool showBackButton;

  const MainPageHeader({
    super.key,
    required this.controller,
    required this.onMenuPressed,
    required this.onRefreshPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final isLargeScreen = deviceType != DeviceType.mobile;

    return isLargeScreen
        ? _buildResponsiveHeader(context, theme, deviceType)
        : _buildMobileHeader(context, theme);
  }

  Widget _buildMobileHeader(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: theme.colorScheme.primary),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 4.0,
                right: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Menu/Back button
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        showBackButton ? Icons.arrow_back : Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: showBackButton
                          ? () => Navigator.of(context).pop()
                          : onMenuPressed,
                      tooltip: showBackButton ? 'Back' : 'Open Menu',
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Title section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lagu Pujian Masa Ini',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.currentDisplayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              controller.getCollectionIcon(),
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${controller.activeFilter} • ${_getCurrentDate()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Sync status widget
                  SyncStatusWidget(
                    onSyncComplete: () => onRefreshPressed(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveHeader(
      BuildContext context, ThemeData theme, DeviceType deviceType) {
    final headerHeight = AppConstants.getHeaderHeight(deviceType);
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: theme.colorScheme.primary),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: spacing,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content area
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lagu Pujian Masa Ini',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: spacing / 4),
                        Text(
                          controller.currentDisplayTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing / 3),
                        Row(
                          children: [
                            Icon(
                              controller.getCollectionIcon(),
                              color: Colors.white70,
                              size: 16,
                            ),
                            SizedBox(width: spacing / 3),
                            Expanded(
                              child: Text(
                                '${controller.activeFilter} • ${_getCurrentDate()}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: spacing),

                  // Sync status widget
                  Padding(
                    padding: EdgeInsets.only(top: spacing / 2),
                    child: SyncStatusWidget(
                      onSyncComplete: () => onRefreshPressed(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    return DateFormat('EEEE | MMMM d, y').format(DateTime.now());
  }
}

class CollectionInfoBar extends StatelessWidget {
  final MainPageController controller;
  final VoidCallback onRefreshPressed;

  const CollectionInfoBar({
    super.key,
    required this.controller,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final isLargeScreen = deviceType != DeviceType.mobile;

    return isLargeScreen
        ? _buildResponsiveInfoBar(context, theme, deviceType)
        : _buildMobileInfoBar(context, theme);
  }

  Widget _buildMobileInfoBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Songs in Collection',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${controller.filteredSongCount} songs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator(context, theme),
        ],
      ),
    );
  }

  Widget _buildResponsiveInfoBar(
      BuildContext context, ThemeData theme, DeviceType deviceType) {
    final contentPadding = AppConstants.getContentPadding(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: contentPadding,
        vertical: spacing / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Songs in Collection',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing / 2,
              vertical: spacing / 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${controller.filteredSongCount} songs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: spacing / 2),
          _buildStatusIndicator(context, theme),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Refreshing collections...'),
            duration: Duration(seconds: 1),
          ),
        );
        onRefreshPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: controller.isOnline
              ? (isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green.withOpacity(0.1))
              : (isDark
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.isOnline
                ? (isDark ? Colors.green.shade600 : Colors.green.shade300)
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controller.isOnline
                  ? Icons.cloud_queue_rounded
                  : Icons.storage_rounded,
              size: 14,
              color: controller.isOnline
                  ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(width: 4),
            Text(
              controller.isOnline ? 'Online' : 'Local',
              style: theme.textTheme.bodySmall?.copyWith(
                color: controller.isOnline
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.refresh,
              size: 10,
              color: controller.isOnline
                  ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
