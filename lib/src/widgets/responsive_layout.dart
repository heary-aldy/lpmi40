// lib/src/widgets/responsive_layout.dart

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
        body: Row(
          children: [
            // Sidebar
            Container(
              width: AppConstants.sidebarWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: sidebar!,
            ),
            // Main content
            Expanded(child: body),
          ],
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

    return GridView.builder(
      padding: padding ?? EdgeInsets.all(spacing),
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
        mainAxisSpacing: mainAxisSpacing ?? spacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
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

    return Container(
      padding: responsivePadding,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? AppConstants.maxContentWidth,
      ),
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

    // For larger screens, use a grid
    return Padding(
      padding: padding ?? EdgeInsets.all(spacing),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.2, // Adjust based on content
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
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
