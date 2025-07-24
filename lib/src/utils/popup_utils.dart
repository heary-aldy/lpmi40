// lib/src/utils/popup_utils.dart
// ✅ UTILITY: Helper functions for showing popup modals throughout the app
// ✅ WEB OPTIMIZED: Centralized popup management for web compatibility

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_popup.dart';
import 'package:lpmi40/src/features/auth/presentation/auth_popup.dart';

class PopupUtils {
  /// Show onboarding popup with optional customization
  static Future<void> showOnboarding(
    BuildContext context, {
    VoidCallback? onCompleted,
    String? title,
    Color? backgroundColor,
    Color? primaryColor,
    bool barrierDismissible = true,
  }) {
    return OnboardingPopup.showDialog(
      context,
      onCompleted: onCompleted,
      title: title,
      backgroundColor: backgroundColor,
      primaryColor: primaryColor,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show login popup
  static Future<bool?> showLogin(
    BuildContext context, {
    bool isDarkMode = false,
    bool barrierDismissible = true,
  }) {
    return AuthPopup.showDialog(
      context,
      isDarkMode: isDarkMode,
      startWithSignUp: false,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show sign up popup
  static Future<bool?> showSignUp(
    BuildContext context, {
    bool isDarkMode = false,
    bool barrierDismissible = true,
  }) {
    return AuthPopup.showDialog(
      context,
      isDarkMode: isDarkMode,
      startWithSignUp: true,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show auth popup that allows switching between login and sign up
  static Future<bool?> showAuth(
    BuildContext context, {
    bool isDarkMode = false,
    bool startWithSignUp = false,
    bool barrierDismissible = true,
  }) {
    return AuthPopup.showDialog(
      context,
      isDarkMode: isDarkMode,
      startWithSignUp: startWithSignUp,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a custom popup with the standard animation and styling
  static Future<T?> showCustomPopup<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 300),
    bool useRootNavigator = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'CustomPopup',
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      transitionDuration: transitionDuration,
      useRootNavigator: useRootNavigator,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Check if the current platform supports advanced popup features
  static bool get supportsAdvancedPopups {
    // All platforms support our popup implementation
    return true;
  }

  /// Get recommended popup size for current screen
  static Size getRecommendedPopupSize(
    BuildContext context, {
    double maxWidthRatio = 0.9,
    double maxHeightRatio = 0.9,
    double minWidth = 300,
    double minHeight = 400,
    double maxWidth = 600,
    double maxHeight = 700,
  }) {
    final screenSize = MediaQuery.of(context).size;

    final recommendedWidth =
        (screenSize.width * maxWidthRatio).clamp(minWidth, maxWidth);
    final recommendedHeight =
        (screenSize.height * maxHeightRatio).clamp(minHeight, maxHeight);

    return Size(recommendedWidth, recommendedHeight);
  }

  /// Check if the screen is suitable for popup display
  static bool isScreenSuitableForPopups(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Minimum screen size requirements for good popup experience
    return screenSize.width >= 300 && screenSize.height >= 400;
  }
}
