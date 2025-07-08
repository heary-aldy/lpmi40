import 'package:flutter/material.dart';

class AppConstants {
  // App-wide Strings
  static const String appTitle = 'Lagu Pujian Masa Ini';
  static const String searchHint = 'Search Songs';
  static const String allSongsLabel = 'All Songs';
  static const String favoritesLabel = 'Favorites';
  static const String toggleThemeLabel = 'Toggle Theme';
  static const String settingsLabel = 'Settings';
  static const String homeLabel = 'Home';

  // Error Messages
  static const String loadErrorMessage = 'Failed to load songs data';

  // Font Options
  static const List<String> fontStyles = ['Roboto', 'Arial', 'Times New Roman'];

  // Font Sizes Options
  static const List<double> fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0];

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color favoriteIconColor = Colors.red;
  static const Color lightModeTextColor = Colors.black;
  static const Color darkModeTextColor = Colors.white;

  // AppBar Height (can be adjusted based on design needs)
  static const double appBarHeightFactor = 0.25; // 25% of screen height

  // ===== RESPONSIVE DESIGN CONSTANTS =====

  // Responsive Breakpoints
  static const double mobileMaxWidth = 768.0;
  static const double tabletMinWidth = 768.0;
  static const double tabletMaxWidth = 1024.0;
  static const double desktopMinWidth = 1024.0;
  static const double largeDesktopMinWidth = 1440.0;

  // Device Type Detection
  static DeviceType getDeviceType(double width) {
    if (width < mobileMaxWidth) return DeviceType.mobile;
    if (width < desktopMinWidth) return DeviceType.tablet;
    if (width < largeDesktopMinWidth) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  // Responsive Spacing
  static const double mobileSpacing = 16.0;
  static const double tabletSpacing = 24.0;
  static const double desktopSpacing = 32.0;
  static const double largeDesktopSpacing = 40.0;

  static double getSpacing(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSpacing;
      case DeviceType.tablet:
        return tabletSpacing;
      case DeviceType.desktop:
        return desktopSpacing;
      case DeviceType.largeDesktop:
        return largeDesktopSpacing;
    }
  }

  // Responsive Grid Columns for Song Lists
  static const int mobileSongColumns = 1;
  static const int tabletSongColumns = 2;
  static const int desktopSongColumns = 3;
  static const int largeDesktopSongColumns = 4;

  static int getSongColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileSongColumns;
      case DeviceType.tablet:
        return tabletSongColumns;
      case DeviceType.desktop:
        return desktopSongColumns;
      case DeviceType.largeDesktop:
        return largeDesktopSongColumns;
    }
  }

  // Responsive Dashboard Columns
  static const int mobileDashboardColumns = 1;
  static const int tabletDashboardColumns = 2;
  static const int desktopDashboardColumns = 3;
  static const int largeDesktopDashboardColumns = 4;

  static int getDashboardColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileDashboardColumns;
      case DeviceType.tablet:
        return tabletDashboardColumns;
      case DeviceType.desktop:
        return desktopDashboardColumns;
      case DeviceType.largeDesktop:
        return largeDesktopDashboardColumns;
    }
  }

  // Sidebar Configuration
  static const double sidebarWidth = 280.0;
  static const double railWidth = 72.0;

  static bool shouldShowSidebar(DeviceType deviceType) {
    return deviceType == DeviceType.tablet ||
        deviceType == DeviceType.desktop ||
        deviceType == DeviceType.largeDesktop;
  }

  static bool shouldShowRail(DeviceType deviceType) {
    return deviceType == DeviceType.desktop ||
        deviceType == DeviceType.largeDesktop;
  }

  // Responsive Typography Scaling
  static const double mobileTypographyScale = 1.0;
  static const double tabletTypographyScale = 1.1;
  static const double desktopTypographyScale = 1.2;
  static const double largeDesktopTypographyScale = 1.3;

  static double getTypographyScale(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileTypographyScale;
      case DeviceType.tablet:
        return tabletTypographyScale;
      case DeviceType.desktop:
        return desktopTypographyScale;
      case DeviceType.largeDesktop:
        return largeDesktopTypographyScale;
    }
  }

  // Responsive Content Widths
  static const double maxContentWidth = 1200.0;
  static const double mobileContentPadding = 16.0;
  static const double tabletContentPadding = 32.0;
  static const double desktopContentPadding = 48.0;

  static double getContentPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileContentPadding;
      case DeviceType.tablet:
        return tabletContentPadding;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktopContentPadding;
    }
  }

  // Responsive Header Heights
  static const double mobileHeaderHeight = 120.0;
  static const double tabletHeaderHeight = 160.0;
  static const double desktopHeaderHeight = 200.0;

  static double getHeaderHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileHeaderHeight;
      case DeviceType.tablet:
        return tabletHeaderHeight;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktopHeaderHeight;
    }
  }

  // Responsive Card Sizes
  static const double mobileCardElevation = 2.0;
  static const double tabletCardElevation = 4.0;
  static const double desktopCardElevation = 6.0;

  static var appVersion;

  static double getCardElevation(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileCardElevation;
      case DeviceType.tablet:
        return tabletCardElevation;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktopCardElevation;
    }
  }

  // Layout Utilities
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMinWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  static DeviceType getDeviceTypeFromContext(BuildContext context) {
    return getDeviceType(MediaQuery.of(context).size.width);
  }
}

// Device Type Enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}
