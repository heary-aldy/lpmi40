// lib/src/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/utils/constants.dart';

/// A class to hold the application's theme data with responsive design support.
/// REASON: Centralizing theme data ensures a consistent UI, makes rebranding
/// easier, and cleans up widget code by removing inline styling.
/// NEW: Added responsive typography and spacing for larger screens.
class AppTheme {
  // Define color themes map that's referenced in settings
  static const Map<String, Color> colorThemes = {
    'Blue': Color(0xFF2196F3),
    'Green': Color(0xFF4CAF50),
    'Purple': Color(0xFF9C27B0),
    'Orange': Color(0xFFFF9800),
    'Red': Color(0xFFF44336),
    'Teal': Color(0xFF009688),
    'Indigo': Color(0xFF3F51B5),
    'Pink': Color(0xFFE91E63),
  };

  // Legacy constants for backward compatibility
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color lightGreyColor = Color(0xFFF5F5F5);

  /// Generate theme based on parameters with responsive support
  static ThemeData getTheme({
    required bool isDarkMode,
    required String themeColorKey,
    DeviceType? deviceType,
  }) {
    final Color selectedColor =
        colorThemes[themeColorKey] ?? colorThemes['Blue']!;

    // Use mobile as default if no device type provided
    final DeviceType currentDeviceType = deviceType ?? DeviceType.mobile;
    final double typographyScale =
        AppConstants.getTypographyScale(currentDeviceType);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: selectedColor,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),

      scaffoldBackgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),

      // ✅ ENHANCED: Responsive App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: _getAppBarHeight(currentDeviceType),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
          size: _getIconSize(currentDeviceType),
        ),
        actionsIconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
          size: _getIconSize(currentDeviceType),
        ),
      ),

      // ✅ ENHANCED: Responsive Card Theme
      cardTheme: CardThemeData(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: AppConstants.getCardElevation(currentDeviceType),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
        ),
        shadowColor: isDarkMode ? Colors.black54 : Colors.grey.withValues(alpha: 0.2),
        margin: EdgeInsets.all(AppConstants.getSpacing(currentDeviceType) / 2),
      ),

      // ✅ ENHANCED: Responsive Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        modalBackgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_getBorderRadius(currentDeviceType)),
          ),
        ),
      ),

      // ✅ ENHANCED: Responsive Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 20 * typographyScale,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
          fontSize: 14 * typographyScale,
        ),
      ),

      // ✅ ENHANCED: Responsive Icon Theme
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black54,
        size: _getIconSize(currentDeviceType),
      ),

      // ✅ FIXED: Better Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: selectedColor,
        size: _getIconSize(currentDeviceType),
      ),

      // ✅ ENHANCED: Responsive Text Theme
      textTheme: _getResponsiveTextTheme(isDarkMode, typographyScale),

      // ✅ ENHANCED: Responsive List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
        subtitleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
          fontSize: 12 * typographyScale,
        ),
        iconColor: isDarkMode ? Colors.white.withValues(alpha: 0.7) : selectedColor,
        tileColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(currentDeviceType),
          vertical: AppConstants.getSpacing(currentDeviceType) / 4,
        ),
      ),

      // ✅ ENHANCED: Responsive Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          minimumSize:
              Size(double.infinity, _getButtonHeight(currentDeviceType)),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(_getBorderRadius(currentDeviceType)),
          ),
          textStyle: TextStyle(
            fontSize: 16 * typographyScale,
            fontWeight: FontWeight.w600,
          ),
          elevation: AppConstants.getCardElevation(currentDeviceType),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(_getBorderRadius(currentDeviceType)),
          ),
          textStyle: TextStyle(
            fontSize: 16 * typographyScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedColor;
          }
          return isDarkMode ? Colors.grey[400] : Colors.grey[300];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedColor.withValues(alpha: 0.5);
          }
          return isDarkMode ? Colors.grey[700] : Colors.grey[300];
        }),
      ),

      // ✅ ENHANCED: Responsive Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: selectedColor,
        thumbColor: selectedColor,
        inactiveTrackColor: selectedColor.withValues(alpha: 0.3),
        overlayColor: selectedColor.withValues(alpha: 0.2),
        valueIndicatorColor: selectedColor,
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12 * typographyScale,
        ),
        trackHeight: _getTrackHeight(currentDeviceType),
      ),

      // ✅ ENHANCED: Responsive Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(currentDeviceType),
          vertical: AppConstants.getSpacing(currentDeviceType),
        ),
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
          fontSize: 14 * typographyScale,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
          fontSize: 14 * typographyScale,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
          borderSide: BorderSide(color: selectedColor, width: 2),
        ),
        prefixIconColor:
            isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
        suffixIconColor:
            isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
      ),

      // ✅ ENHANCED: Responsive Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        textStyle: TextStyle(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
          fontSize: 14 * typographyScale,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
        ),
      ),

      // ✅ FIXED: Better Divider Theme
      dividerTheme: DividerThemeData(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        thickness: 1,
        space: AppConstants.getSpacing(currentDeviceType),
      ),

      // ✅ ENHANCED: Responsive Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF323232),
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14 * typographyScale,
        ),
        actionTextColor: selectedColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(_getBorderRadius(currentDeviceType)),
        ),
      ),
    );
  }

  // ===== RESPONSIVE HELPER METHODS =====

  /// Generate responsive text theme
  static TextTheme _getResponsiveTextTheme(bool isDarkMode, double scale) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 24.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 22.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      displaySmall: TextStyle(
        fontSize: 20.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      headlineLarge: TextStyle(
        fontSize: 32.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.0 * scale,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 20.0 * scale,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0 * scale,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
      ),
      titleSmall: TextStyle(
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0 * scale,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0 * scale,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0 * scale,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
      ),
      labelLarge: TextStyle(
        fontSize: 16.0 * scale,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      labelMedium: TextStyle(
        fontSize: 12.0 * scale,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
      ),
      labelSmall: TextStyle(
        fontSize: 10.0 * scale,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
      ),
    );
  }

  /// Get responsive app bar height
  static double _getAppBarHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tablet:
        return kToolbarHeight + 8;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return kToolbarHeight + 16;
    }
  }

  /// Get responsive icon size
  static double _getIconSize(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 26.0;
      case DeviceType.desktop:
        return 28.0;
      case DeviceType.largeDesktop:
        return 30.0;
    }
  }

  /// Get responsive border radius
  static double _getBorderRadius(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.tablet:
        return 14.0;
      case DeviceType.desktop:
        return 16.0;
      case DeviceType.largeDesktop:
        return 18.0;
    }
  }

  /// Get responsive button height
  static double _getButtonHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 52.0;
      case DeviceType.tablet:
        return 56.0;
      case DeviceType.desktop:
        return 60.0;
      case DeviceType.largeDesktop:
        return 64.0;
    }
  }

  /// Get responsive track height for sliders
  static double _getTrackHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 4.0;
      case DeviceType.tablet:
        return 5.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 6.0;
    }
  }

  // ===== RESPONSIVE UTILITY METHODS =====

  /// Get responsive theme for context
  static ThemeData getResponsiveTheme(
    BuildContext context, {
    required bool isDarkMode,
    required String themeColorKey,
  }) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    return getTheme(
      isDarkMode: isDarkMode,
      themeColorKey: themeColorKey,
      deviceType: deviceType,
    );
  }

  /// Get responsive spacing for context
  static double getResponsiveSpacing(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    return AppConstants.getSpacing(deviceType);
  }

  /// Get responsive padding for context
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final spacing = getResponsiveSpacing(context);
    return EdgeInsets.all(spacing);
  }

  /// Get responsive content padding for context
  static EdgeInsets getResponsiveContentPadding(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final padding = AppConstants.getContentPadding(deviceType);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// The main theme for the application (Light Mode) - kept for backward compatibility
  static ThemeData get lightTheme {
    return getTheme(isDarkMode: false, themeColorKey: 'Green');
  }
}
