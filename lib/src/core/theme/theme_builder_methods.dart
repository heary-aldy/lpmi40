// lib/src/core/theme/theme_builder_methods.dart
// 🛠️ THEME BUILDER METHODS - Implementation of all enhanced theme building methods
// This file contains all the _buildEnhanced... methods used by ThemeManager

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/utils/constants.dart';
import 'theme_manager.dart'; // Import for accessing classes

/// Extension to add all the enhanced theme building methods to ThemeManager
extension ThemeBuilderMethods on ThemeManager {
  // ===== ENHANCED APP BAR THEME =====
  static AppBarTheme _buildEnhancedAppBarTheme({
    required ColorScheme colorScheme,
    required SurfaceColors surfaces,
    required DeviceType deviceType,
    required double typographyScale,
    required bool isDarkMode,
  }) {
    return AppBarTheme(
      backgroundColor: surfaces.surfaceContainer,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      toolbarHeight: _getAppBarHeight(deviceType),
      centerTitle: true,
      titleSpacing: AppConstants.getSpacing(deviceType),

      // Enhanced title style with better typography
      titleTextStyle: TextStyle(
        fontSize: 20 * typographyScale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.2,
      ),

      // Enhanced icon themes
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: _getIconSize(deviceType),
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: _getIconSize(deviceType),
      ),

      // System overlay style for status bar
      systemOverlayStyle: isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.light,
            ),
    );
  }

  // ===== ENHANCED CARD THEME =====
  static CardThemeData _buildEnhancedCardTheme({
    required ColorScheme colorScheme,
    required SurfaceColors surfaces,
    required DeviceType deviceType,
    required bool isDarkMode,
  }) {
    return CardThemeData(
      color: surfaces.surfaceContainerLow,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow.withValues(alpha: isDarkMode ? 0.3 : 0.1),
      elevation: AppConstants.getCardElevation(deviceType),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      margin: EdgeInsets.all(AppConstants.getSpacing(deviceType) / 2),
      clipBehavior: Clip.antiAlias,
    );
  }

  // ===== ENHANCED BOTTOM SHEET THEME =====
  static BottomSheetThemeData _buildEnhancedBottomSheetTheme({
    required SurfaceColors surfaces,
    required DeviceType deviceType,
  }) {
    return BottomSheetThemeData(
      backgroundColor: surfaces.surfaceContainerHigh,
      modalBackgroundColor: surfaces.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_getBorderRadius(deviceType) * 1.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        maxWidth: deviceType == DeviceType.mobile ? double.infinity : 600,
      ),
    );
  }

  // ===== ENHANCED DIALOG THEME =====
  static DialogTheme _buildEnhancedDialogTheme({
    required ColorScheme colorScheme,
    required SurfaceColors surfaces,
    required DeviceType deviceType,
    required double typographyScale,
  }) {
    return DialogTheme(
      backgroundColor: surfaces.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 12,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
      ),

      // Enhanced typography for dialogs
      titleTextStyle: TextStyle(
        fontSize: 22 * typographyScale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16 * typographyScale,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
        letterSpacing: 0.25,
      ),

      // Enhanced alignment and inset
      alignment: Alignment.center,
      insetPadding: EdgeInsets.all(AppConstants.getSpacing(deviceType) * 2),
    );
  }

  // ===== ENHANCED ELEVATED BUTTON THEME =====
  static ElevatedButtonThemeData _buildEnhancedElevatedButtonTheme({
    required ColorScheme colorScheme,
    required DeviceType deviceType,
    required double typographyScale,
    required AnimationTheme animTheme,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),

        // Enhanced sizing
        minimumSize: Size(64, _getButtonHeight(deviceType)),
        maximumSize: Size(double.infinity, _getButtonHeight(deviceType)),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(deviceType) * 1.5,
          vertical: AppConstants.getSpacing(deviceType) * 0.75,
        ),

        // Enhanced visual design
        elevation: AppConstants.getCardElevation(deviceType),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        surfaceTintColor: colorScheme.surfaceTint,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        ),

        // Enhanced typography
        textStyle: TextStyle(
          fontSize: 16 * typographyScale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.25,
        ),

        // Enhanced interaction states

        // Animation duration
        animationDuration: animTheme.transitionDuration,
      ),
    );
  }

  // ===== ENHANCED FILLED BUTTON THEME =====
  static FilledButtonThemeData _buildEnhancedFilledButtonTheme({
    required ColorScheme colorScheme,
    required DeviceType deviceType,
    required double typographyScale,
  }) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        minimumSize: Size(64, _getButtonHeight(deviceType)),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(deviceType) * 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        ),
        textStyle: TextStyle(
          fontSize: 16 * typographyScale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ===== ENHANCED TEXT BUTTON THEME =====
  static TextButtonThemeData _buildEnhancedTextButtonTheme({
    required ColorScheme colorScheme,
    required double typographyScale,
    required AnimationTheme animTheme,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 14 * typographyScale,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        animationDuration: animTheme.microAnimationDuration,
      ),
    );
  }

  // ===== ENHANCED OUTLINED BUTTON THEME =====
  static OutlinedButtonThemeData _buildEnhancedOutlinedButtonTheme({
    required ColorScheme colorScheme,
    required DeviceType deviceType,
    required double typographyScale,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        minimumSize: Size(64, _getButtonHeight(deviceType)),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(deviceType) * 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        ),
        side: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
        textStyle: TextStyle(
          fontSize: 16 * typographyScale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ===== ENHANCED INPUT DECORATION THEME =====
  static InputDecorationTheme _buildEnhancedInputTheme({
    required ColorScheme colorScheme,
    required SurfaceColors surfaces,
    required DeviceType deviceType,
    required double typographyScale,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaces.surfaceContainerHighest,

      contentPadding: EdgeInsets.symmetric(
        horizontal: AppConstants.getSpacing(deviceType),
        vertical: AppConstants.getSpacing(deviceType),
      ),

      // Enhanced text styles
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16 * typographyScale,
        letterSpacing: 0.15,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 16 * typographyScale,
        letterSpacing: 0.15,
      ),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 12 * typographyScale,
        letterSpacing: 0.4,
      ),

      // Enhanced borders with better state management
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),

      // Enhanced icon colors
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
    );
  }

  // ===== HELPER METHODS (From original AppTheme) =====
  static double _getAppBarHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 56.0;
      case DeviceType.tablet:
        return 64.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 72.0;
    }
  }

  static double _getIconSize(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 28.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 32.0;
    }
  }

  static double _getBorderRadius(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 12.0;
      case DeviceType.tablet:
        return 14.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 16.0;
    }
  }

  static double _getButtonHeight(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 40.0;
      case DeviceType.tablet:
        return 44.0;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 48.0;
    }
  }
}
