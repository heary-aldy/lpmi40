// lib/src/core/theme/theme_manager.dart
// 🎨 ENHANCED THEME MANAGER - Fixed compilation errors and improved structure

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/utils/constants.dart';

/// Enhanced Theme Manager with advanced Material 3 features and performance optimizations
class ThemeManager {
  // ===== THEME CACHE FOR PERFORMANCE =====
  static final Map<String, ThemeData> _themeCache = {};
  static const int _maxCacheSize = 20;

  // ===== ENHANCED COLOR THEMES WITH PERSONALITIES =====
  static const Map<String, ThemeColorSet> colorThemes = {
    'Blue': ThemeColorSet(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF42A5F5),
      accent: Color(0xFF2196F3),
      personality: ThemePersonality.professional,
    ),
    'Green': ThemeColorSet(
      primary: Color(0xFF388E3C),
      secondary: Color(0xFF66BB6A),
      accent: Color(0xFF4CAF50),
      personality: ThemePersonality.natural,
    ),
    'Purple': ThemeColorSet(
      primary: Color(0xFF7B1FA2),
      secondary: Color(0xFFBA68C8),
      accent: Color(0xFF9C27B0),
      personality: ThemePersonality.creative,
    ),
    'Orange': ThemeColorSet(
      primary: Color(0xFFE65100),
      secondary: Color(0xFFFFB74D),
      accent: Color(0xFFFF9800),
      personality: ThemePersonality.energetic,
    ),
    'Red': ThemeColorSet(
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFEF5350),
      accent: Color(0xFFF44336),
      personality: ThemePersonality.bold,
    ),
    'Teal': ThemeColorSet(
      primary: Color(0xFF00695C),
      secondary: Color(0xFF4DB6AC),
      accent: Color(0xFF009688),
      personality: ThemePersonality.calm,
    ),
    'Indigo': ThemeColorSet(
      primary: Color(0xFF303F9F),
      secondary: Color(0xFF7986CB),
      accent: Color(0xFF3F51B5),
      personality: ThemePersonality.sophisticated,
    ),
    'Pink': ThemeColorSet(
      primary: Color(0xFFC2185B),
      secondary: Color(0xFFF06292),
      accent: Color(0xFFE91E63),
      personality: ThemePersonality.playful,
    ),
  };

  // ===== THEME VARIANTS =====
  static const Map<String, ThemeVariant> themeVariants = {
    'standard': ThemeVariant(
      name: 'Standard',
      description: 'Balanced contrast and readability',
      contrastRatio: 1.0,
      saturationMultiplier: 1.0,
    ),
    'highContrast': ThemeVariant(
      name: 'High Contrast',
      description: 'Enhanced accessibility with high contrast',
      contrastRatio: 1.4,
      saturationMultiplier: 1.2,
    ),
    'lowContrast': ThemeVariant(
      name: 'Low Contrast',
      description: 'Softer, gentler appearance',
      contrastRatio: 0.8,
      saturationMultiplier: 0.8,
    ),
    'vivid': ThemeVariant(
      name: 'Vivid',
      description: 'Bright and vibrant colors',
      contrastRatio: 1.1,
      saturationMultiplier: 1.3,
    ),
  };

  // ===== ANIMATION THEMES =====
  static const Map<String, AnimationTheme> animationThemes = {
    'default': AnimationTheme(
      transitionDuration: Duration(milliseconds: 300),
      pageTransitionDuration: Duration(milliseconds: 400),
      microAnimationDuration: Duration(milliseconds: 150),
      curve: Curves.easeInOutCubic,
      bounceCurve: Curves.elasticOut,
    ),
    'fast': AnimationTheme(
      transitionDuration: Duration(milliseconds: 200),
      pageTransitionDuration: Duration(milliseconds: 250),
      microAnimationDuration: Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      bounceCurve: Curves.elasticOut,
    ),
    'slow': AnimationTheme(
      transitionDuration: Duration(milliseconds: 500),
      pageTransitionDuration: Duration(milliseconds: 600),
      microAnimationDuration: Duration(milliseconds: 250),
      curve: Curves.easeInOutQuart,
      bounceCurve: Curves.elasticOut,
    ),
  };

  /// 🚀 MAIN THEME GENERATOR - Enhanced with caching and advanced features
  static ThemeData getTheme({
    required bool isDarkMode,
    required String themeColorKey,
    DeviceType? deviceType,
    String themeVariant = 'standard',
    String animationTheme = 'default',
    String? fontFamily,
    bool enableHapticFeedback = true,
    bool enableAdvancedAnimations = true,
  }) {
    // Generate cache key
    final cacheKey = _generateCacheKey(
      isDarkMode,
      themeColorKey,
      deviceType,
      themeVariant,
      animationTheme,
      fontFamily,
    );

    // Return cached theme if available
    if (_themeCache.containsKey(cacheKey)) {
      return _themeCache[cacheKey]!;
    }

    // Generate new theme
    final theme = _buildTheme(
      isDarkMode: isDarkMode,
      themeColorKey: themeColorKey,
      deviceType: deviceType ?? DeviceType.mobile,
      themeVariant: themeVariant,
      animationTheme: animationTheme,
      fontFamily: fontFamily,
      enableHapticFeedback: enableHapticFeedback,
      enableAdvancedAnimations: enableAdvancedAnimations,
    );

    // Cache management
    if (_themeCache.length >= _maxCacheSize) {
      _themeCache.remove(_themeCache.keys.first);
    }
    _themeCache[cacheKey] = theme;

    return theme;
  }

  /// 🎨 ENHANCED THEME BUILDER - Core theme generation logic
  static ThemeData _buildTheme({
    required bool isDarkMode,
    required String themeColorKey,
    required DeviceType deviceType,
    required String themeVariant,
    required String animationTheme,
    String? fontFamily,
    required bool enableHapticFeedback,
    required bool enableAdvancedAnimations,
  }) {
    final colorSet = colorThemes[themeColorKey] ?? colorThemes['Blue']!;
    final variant = themeVariants[themeVariant] ?? themeVariants['standard']!;
    final animTheme =
        animationThemes[animationTheme] ?? animationThemes['default']!;
    final typographyScale = AppConstants.getTypographyScale(deviceType);

    // Generate enhanced color scheme
    final colorScheme = _generateEnhancedColorScheme(
      colorSet: colorSet,
      isDarkMode: isDarkMode,
      variant: variant,
    );

    // Generate surface colors
    final surfaces = _generateSurfaceColors(colorScheme, isDarkMode);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      fontFamily: fontFamily,

      // ===== ENHANCED SCAFFOLD =====
      scaffoldBackgroundColor: surfaces.background,

      // ===== ENHANCED APP BAR THEME =====
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        toolbarHeight: _getAppBarHeight(deviceType),
        centerTitle: true,
        titleSpacing: AppConstants.getSpacing(deviceType),
        titleTextStyle: TextStyle(
          fontSize: 20 * typographyScale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
          height: 1.2,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: _getIconSize(deviceType),
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: _getIconSize(deviceType),
        ),
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.light,
              ),
      ),

      // ===== ENHANCED CARD THEME =====
      cardTheme: CardThemeData(
        color: surfaces.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor:
            colorScheme.shadow.withValues(alpha: isDarkMode ? 0.3 : 0.1),
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
      ),

      // ===== ENHANCED BUTTON THEMES =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.38),
          minimumSize: Size(64, _getButtonHeight(deviceType)),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.getSpacing(deviceType) * 1.5,
            vertical: AppConstants.getSpacing(deviceType) * 0.75,
          ),
          elevation: AppConstants.getCardElevation(deviceType),
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
          ),
          textStyle: TextStyle(
            fontSize: 16 * typographyScale,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            height: 1.25,
          ),
          animationDuration: animTheme.transitionDuration,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
          ),
          textStyle: TextStyle(
            fontSize: 16 * typographyScale,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ===== ENHANCED INPUT DECORATION THEME =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.surfaceContainerHighest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(deviceType),
          vertical: AppConstants.getSpacing(deviceType),
        ),
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
      ),

      // ===== ENHANCED COMPONENT THEMES =====
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12 * typographyScale,
          fontWeight: FontWeight.w600,
        ),
        trackHeight: _getTrackHeight(deviceType),
      ),

      // ===== ENHANCED TEXT THEME =====
      textTheme: _buildEnhancedTextTheme(
        colorScheme: colorScheme,
        typographyScale: typographyScale,
        fontFamily: fontFamily,
      ),

      // ===== ENHANCED LIST THEME =====
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        subtitleTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14 * typographyScale,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.getSpacing(deviceType),
          vertical: AppConstants.getSpacing(deviceType) / 4,
        ),
      ),

      // ===== ENHANCED MISC THEMES =====
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: _getIconSize(deviceType),
      ),

      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: _getIconSize(deviceType),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: AppConstants.getSpacing(deviceType),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 14 * typographyScale,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(deviceType)),
        ),
      ),

      // ===== EXTENSIONS =====
      extensions: [
        ThemeManagerExtension(
          animationTheme: animTheme,
          enableHapticFeedback: enableHapticFeedback,
          enableAdvancedAnimations: enableAdvancedAnimations,
          themeVariant: variant,
          colorPersonality: colorSet.personality,
        ),
      ],
    );
  }

  // ===== ENHANCED COLOR SCHEME GENERATION =====
  static ColorScheme _generateEnhancedColorScheme({
    required ThemeColorSet colorSet,
    required bool isDarkMode,
    required ThemeVariant variant,
  }) {
    final adjustedPrimary = _adjustColorForVariant(colorSet.primary, variant);

    return ColorScheme.fromSeed(
      seedColor: adjustedPrimary,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
    ).copyWith(
      secondary: _adjustColorForVariant(colorSet.secondary, variant),
      tertiary: _adjustColorForVariant(colorSet.accent, variant),
    );
  }

  // ===== SURFACE COLOR GENERATION =====
  static SurfaceColors _generateSurfaceColors(
      ColorScheme colorScheme, bool isDarkMode) {
    if (isDarkMode) {
      return const SurfaceColors(
        background: Color(0xFF0F0F0F),
        surface: Color(0xFF1A1A1A),
        surfaceVariant: Color(0xFF2A2A2A),
        surfaceContainer: Color(0xFF1E1E1E),
        surfaceContainerLowest: Color(0xFF0A0A0A),
        surfaceContainerLow: Color(0xFF141414),
        surfaceContainerHigh: Color(0xFF252525),
        surfaceContainerHighest: Color(0xFF303030),
      );
    } else {
      return const SurfaceColors(
        background: Color(0xFFFEFEFE),
        surface: Colors.white,
        surfaceVariant: Color(0xFFF7F7F7),
        surfaceContainer: Color(0xFFF5F5F5),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFFCFCFC),
        surfaceContainerHigh: Color(0xFFF0F0F0),
        surfaceContainerHighest: Color(0xFFEBEBEB),
      );
    }
  }

  // ===== ENHANCED TEXT THEME =====
  static TextTheme _buildEnhancedTextTheme({
    required ColorScheme colorScheme,
    required double typographyScale,
    String? fontFamily,
  }) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 57 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 32 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 22 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.27,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * typographyScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * typographyScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: colorScheme.onSurfaceVariant,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * typographyScale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: colorScheme.onSurfaceVariant,
        fontFamily: fontFamily,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14 * typographyScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * typographyScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * typographyScale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
    );
  }

  // ===== UTILITY METHODS =====
  static String _generateCacheKey(
    bool isDarkMode,
    String themeColorKey,
    DeviceType? deviceType,
    String themeVariant,
    String animationTheme,
    String? fontFamily,
  ) {
    return '$isDarkMode-$themeColorKey-${deviceType?.name}-$themeVariant-$animationTheme-$fontFamily';
  }

  static Color _adjustColorForVariant(Color color, ThemeVariant variant) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(
            (hsl.saturation * variant.saturationMultiplier).clamp(0.0, 1.0))
        .toColor();
  }

  // ===== RESPONSIVE HELPER METHODS =====
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

  // ===== PUBLIC API METHODS =====

  /// Clear theme cache (useful for development/testing)
  static void clearCache() {
    _themeCache.clear();
  }

  /// Get available color themes
  static List<String> getAvailableColorThemes() {
    return colorThemes.keys.toList();
  }

  /// Get available theme variants
  static List<String> getAvailableThemeVariants() {
    return themeVariants.keys.toList();
  }

  /// Get theme for context with automatic device type detection
  static ThemeData getResponsiveTheme(
    BuildContext context, {
    required bool isDarkMode,
    required String themeColorKey,
    String themeVariant = 'standard',
    String animationTheme = 'default',
    String? fontFamily,
  }) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    return getTheme(
      isDarkMode: isDarkMode,
      themeColorKey: themeColorKey,
      deviceType: deviceType,
      themeVariant: themeVariant,
      animationTheme: animationTheme,
      fontFamily: fontFamily,
    );
  }

  /// 🎨 BACKWARD COMPATIBILITY - Keep your existing API
  static ThemeData getLegacyTheme({
    required bool isDarkMode,
    required String themeColorKey,
    DeviceType? deviceType,
  }) {
    return getTheme(
      isDarkMode: isDarkMode,
      themeColorKey: themeColorKey,
      deviceType: deviceType,
    );
  }
}

// ===== SUPPORTING CLASSES =====

class ThemeColorSet {
  final Color primary;
  final Color secondary;
  final Color accent;
  final ThemePersonality personality;

  const ThemeColorSet({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.personality,
  });
}

enum ThemePersonality {
  professional,
  creative,
  energetic,
  calm,
  natural,
  bold,
  sophisticated,
  playful,
}

class ThemeVariant {
  final String name;
  final String description;
  final double contrastRatio;
  final double saturationMultiplier;

  const ThemeVariant({
    required this.name,
    required this.description,
    required this.contrastRatio,
    required this.saturationMultiplier,
  });
}

class AnimationTheme {
  final Duration transitionDuration;
  final Duration pageTransitionDuration;
  final Duration microAnimationDuration;
  final Curve curve;
  final Curve bounceCurve;

  const AnimationTheme({
    required this.transitionDuration,
    required this.pageTransitionDuration,
    required this.microAnimationDuration,
    required this.curve,
    required this.bounceCurve,
  });
}

class SurfaceColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  const SurfaceColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });
}

class ThemeManagerExtension extends ThemeExtension<ThemeManagerExtension> {
  final AnimationTheme animationTheme;
  final bool enableHapticFeedback;
  final bool enableAdvancedAnimations;
  final ThemeVariant themeVariant;
  final ThemePersonality colorPersonality;

  const ThemeManagerExtension({
    required this.animationTheme,
    required this.enableHapticFeedback,
    required this.enableAdvancedAnimations,
    required this.themeVariant,
    required this.colorPersonality,
  });

  @override
  ThemeManagerExtension copyWith({
    AnimationTheme? animationTheme,
    bool? enableHapticFeedback,
    bool? enableAdvancedAnimations,
    ThemeVariant? themeVariant,
    ThemePersonality? colorPersonality,
  }) {
    return ThemeManagerExtension(
      animationTheme: animationTheme ?? this.animationTheme,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableAdvancedAnimations:
          enableAdvancedAnimations ?? this.enableAdvancedAnimations,
      themeVariant: themeVariant ?? this.themeVariant,
      colorPersonality: colorPersonality ?? this.colorPersonality,
    );
  }

  @override
  ThemeManagerExtension lerp(ThemeManagerExtension? other, double t) {
    if (other is! ThemeManagerExtension) return this;
    return this; // For now, we don't interpolate these values
  }
}
