// lib/src/widgets/responsive_layout.dart
// ✅ CRITICAL FIX: Added constraint safety to prevent ListTile layout errors
// ✅ NEW: Added SongListContainer for extending song list width

import 'package:flutter/material.dart';
import 'package:lpmi40/utils/constants.dart';

/// A responsive layout widget that adapts to different screen sizes
/// Provides consistent layout patterns across the app
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// A widget that provides responsive scaffold with sidebar for larger screens
/// ✅ CRITICAL FIX: Added constraint safety and adaptive sidebar width
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final Widget? sidebar;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.sidebar,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final shouldShowSidebar = AppConstants.shouldShowSidebar(deviceType);

    if (shouldShowSidebar && sidebar != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ✅ CRITICAL FIX: Calculate adaptive sidebar width based on available space
              final screenWidth = constraints.maxWidth;
              final minSidebarWidth = 240.0; // Minimum for usability
              final maxSidebarWidth = AppConstants.sidebarWidth; // 280.0
              final minContentWidth = 400.0; // Minimum for main content

              // Calculate optimal sidebar width
              double adaptiveSidebarWidth;
              if (screenWidth < (minSidebarWidth + minContentWidth)) {
                // Screen too small for sidebar - fallback to drawer
                return Scaffold(
                  backgroundColor: backgroundColor,
                  appBar: appBar,
                  drawer: _buildSidebarAsDrawer(),
                  floatingActionButton: floatingActionButton,
                  floatingActionButtonLocation: floatingActionButtonLocation,
                  extendBodyBehindAppBar: extendBodyBehindAppBar,
                  body: body,
                );
              } else if (screenWidth < (maxSidebarWidth + minContentWidth)) {
                // Adjust sidebar width to fit
                adaptiveSidebarWidth =
                    (screenWidth * 0.3).clamp(minSidebarWidth, maxSidebarWidth);
              } else {
                // Full sidebar width
                adaptiveSidebarWidth = maxSidebarWidth;
              }

              return Row(
                children: [
                  // ✅ FIXED: Sidebar with adaptive width and proper constraints
                  SizedBox(
                    width: adaptiveSidebarWidth,
                    child: Material(
                      elevation: 1,
                      color: Theme.of(context).colorScheme.surface,
                      child: Container(
                        width: adaptiveSidebarWidth,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: adaptiveSidebarWidth,
                            maxWidth: adaptiveSidebarWidth,
                            minHeight: 0,
                            maxHeight: double.infinity,
                          ),
                          child: sidebar!,
                        ),
                      ),
                    ),
                  ),
                  // ✅ FIXED: Main content with explicit remaining space
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        minHeight: 0,
                        maxHeight: double.infinity,
                      ),
                      child: body,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // Standard scaffold for mobile
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: body,
    );
  }

  // ✅ NEW: Convert sidebar to drawer when space is limited
  Widget _buildSidebarAsDrawer() {
    return Drawer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 240,
          maxWidth: 280,
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        child: sidebar!,
      ),
    );
  }
}

/// A responsive grid widget for displaying items in a grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final columns = AppConstants.getSongColumns(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal aspect ratio based on available width
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final calculatedAspectRatio =
            childAspectRatio ?? (itemWidth / 80).clamp(2.0, 8.0);

        return GridView.builder(
          padding: padding ?? EdgeInsets.all(spacing),
          physics: physics,
          shrinkWrap: shrinkWrap,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossAxisSpacing ?? spacing,
            mainAxisSpacing: mainAxisSpacing ?? spacing,
            childAspectRatio: calculatedAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 60,
              maxHeight: itemWidth / calculatedAspectRatio,
            ),
            child: children[index],
          ),
        );
      },
    );
  }
}

/// A responsive sliver grid for use in CustomScrollView
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;

  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final columns = AppConstants.getSongColumns(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
        mainAxisSpacing: mainAxisSpacing ?? spacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
    );
  }
}

/// A responsive container that constrains content width on larger screens
/// This is used for readable content like text, forms, and dashboards
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final responsivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: AppConstants.getContentPadding(deviceType),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerMaxWidth = maxWidth ?? AppConstants.maxContentWidth;

        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            maxWidth: containerMaxWidth,
            minHeight: 0,
          ),
          padding: responsivePadding,
          child: child,
        );
      },
    );
  }
}

/// ✅ NEW: A specialized container for song lists that uses more screen width
/// while maintaining the constrained ResponsiveContainer for other content
class SongListContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SongListContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    // Desktop and large desktop: Use 85% width with comfortable margins
    if (deviceType == DeviceType.desktop ||
        deviceType == DeviceType.largeDesktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Use 85% of available width with reasonable min/max constraints
          final targetWidth =
              (constraints.maxWidth * 0.85).clamp(600.0, 1400.0);
          final horizontalPadding = (constraints.maxWidth - targetWidth) / 2;

          return Container(
            width: constraints.maxWidth,
            padding:
                padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          );
        },
      );
    }

    // ✅ BALANCED: Mobile - comfortable edge padding while keeping titles spacious
    if (deviceType == DeviceType.mobile) {
      return Container(
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal:
                    12.0), // ✅ INCREASED: From 4px to 12px for better edge breathing
        child: child,
      );
    }

    // Tablet: comfortable padding for full width
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
              horizontal:
                  16.0), // ✅ INCREASED: From 8px to 16px for better balance
      child: child,
    );
  }
}

/// A responsive wrapper for dashboard sections
class ResponsiveDashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ResponsiveDashboardGrid({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final columns = AppConstants.getDashboardColumns(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    // For mobile, use a column layout
    if (deviceType == DeviceType.mobile) {
      return Padding(
        padding: padding ?? EdgeInsets.all(spacing),
        child: Column(
          children: children
              .map((child) => Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: child,
                  ))
              .toList(),
        ),
      );
    }

    // For larger screens, use a responsive grid with proper constraints
    return Padding(
      padding: padding ?? EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate optimal columns based on available width
          final minItemWidth = 250.0;
          final availableWidth =
              constraints.maxWidth - (spacing * (columns - 1));
          final optimalColumns =
              (availableWidth / minItemWidth).floor().clamp(1, columns);

          if (optimalColumns == 1) {
            return Column(
              children: children
                  .map((child) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: child,
                      ))
                  .toList(),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: optimalColumns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.5, // Adjust based on content
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 120,
                minWidth: minItemWidth,
              ),
              child: children[index],
            ),
          );
        },
      ),
    );
  }
}

/// Responsive spacing helper
class ResponsiveSpacing {
  static SizedBox vertical(BuildContext context, {double multiplier = 1.0}) {
    final spacing = AppConstants.getSpacing(
      AppConstants.getDeviceTypeFromContext(context),
    );
    return SizedBox(height: spacing * multiplier);
  }

  static SizedBox horizontal(BuildContext context, {double multiplier = 1.0}) {
    final spacing = AppConstants.getSpacing(
      AppConstants.getDeviceTypeFromContext(context),
    );
    return SizedBox(width: spacing * multiplier);
  }
}

/// Responsive text helper
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);

    TextStyle? responsiveStyle = style;
    if (responsiveStyle?.fontSize != null) {
      responsiveStyle = responsiveStyle!.copyWith(
        fontSize: responsiveStyle.fontSize! * scale,
      );
    }

    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
