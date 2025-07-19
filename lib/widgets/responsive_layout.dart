// lib/src/widgets/responsive_layout.dart
// ✅ ADD THESE WIDGETS if they don't exist in your project

import 'package:flutter/material.dart';
import 'package:lpmi40/utils/constants.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop: // ✅ FIX: Handle largeDesktop case
        return desktop;
      default: // ✅ FIX: Add default case for safety
        return desktop;
    }
  }
}

class ResponsiveScaffold extends StatelessWidget {
  final Widget? sidebar;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ResponsiveScaffold({
    super.key,
    this.sidebar,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);

    if (deviceType == DeviceType.mobile) {
      return Scaffold(
        appBar: appBar,
        drawer: sidebar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    } else {
      // Handle tablet, desktop, and largeDesktop with sidebar layout
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            if (sidebar != null) ...[
              SizedBox(
                width: _getSidebarWidth(deviceType),
                child: sidebar!,
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    }
  }

  // Helper method to get sidebar width based on device type
  double _getSidebarWidth(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 280;
      case DeviceType.tablet:
        return 280;
      case DeviceType.desktop:
        return 320;
      case DeviceType.largeDesktop: // ✅ FIX: Handle largeDesktop case
        return 360;
      default:
        return 320;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final defaultPadding = EdgeInsets.all(_getContentPadding(deviceType));

    return Container(
      padding: padding ?? defaultPadding,
      margin: margin,
      child: child,
    );
  }

  // Helper method to get content padding based on device type
  double _getContentPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 24.0;
      case DeviceType.desktop:
        return 32.0;
      case DeviceType.largeDesktop: // ✅ FIX: Handle largeDesktop case
        return 40.0;
      default:
        return 16.0;
    }
  }
}
