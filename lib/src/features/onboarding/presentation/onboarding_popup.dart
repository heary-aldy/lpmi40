// lib/src/features/onboarding/presentation/onboarding_popup.dart
// ✅ WEB OPTIMIZED: Popup modal version of onboarding for web view and dialogs
// ✅ RESPONSIVE: Adapts to different screen sizes and orientations
// ✅ FEATURES: Compact design, smooth animations, mobile-friendly

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';

class OnboardingPopup extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool showAsDialog;
  final String? customTitle;
  final Color? backgroundColor;
  final Color? primaryColor;

  const OnboardingPopup({
    super.key,
    this.onCompleted,
    this.showAsDialog = true,
    this.customTitle,
    this.backgroundColor,
    this.primaryColor,
  });

  @override
  State<OnboardingPopup> createState() => _OnboardingPopupState();

  /// Show as a dialog with custom styling
  static Future<void> showDialog(
    BuildContext context, {
    VoidCallback? onCompleted,
    String? title,
    Color? backgroundColor,
    Color? primaryColor,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'OnboardingPopup',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      useRootNavigator: useRootNavigator,
      pageBuilder: (context, animation, secondaryAnimation) {
        return OnboardingPopup(
          onCompleted: () {
            Navigator.of(context, rootNavigator: useRootNavigator).pop();
            onCompleted?.call();
          },
          showAsDialog: true,
          customTitle: title,
          backgroundColor: backgroundColor,
          primaryColor: primaryColor,
        );
      },
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
}

class _OnboardingPopupState extends State<OnboardingPopup>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPopupContent> _pages = [
    OnboardingPopupContent(
      title: 'Welcome to LPMI40',
      subtitle: 'Your Digital Hymnal',
      description:
          'Modern worship with premium audio, real-time sync, and smart features.',
      icon: Icons.music_note_rounded,
      gradient: [Colors.blue.shade600, Colors.purple.shade600],
    ),
    OnboardingPopupContent(
      title: 'Premium Audio',
      subtitle: 'High-Quality Recordings',
      description:
          'Listen to professionally recorded hymns with crystal-clear audio and offline access.',
      icon: Icons.headphones_rounded,
      gradient: [Colors.green.shade600, Colors.teal.shade600],
    ),
    OnboardingPopupContent(
      title: 'Smart Access Control',
      subtitle: 'Role-Based Features',
      description:
          'Guest browsing, Premium audio, Admin management, Super Admin control.',
      icon: Icons.admin_panel_settings_rounded,
      gradient: [Colors.orange.shade600, Colors.red.shade600],
    ),
    OnboardingPopupContent(
      title: 'Advanced Features',
      subtitle: 'Everything You Need',
      description:
          'Custom themes, instant search, favorites sync, collections, and comprehensive admin tools.',
      icon: Icons.auto_awesome_rounded,
      gradient: [Colors.indigo.shade600, Colors.pink.shade600],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final onboardingService = await OnboardingService.getInstance();
    await onboardingService.completeOnboarding(name: 'User');
    widget.onCompleted?.call();
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWeb = kIsWeb;
    final isSmallScreen = screenSize.width < 600;

    // Determine dialog size based on platform and screen size
    final dialogWidth = isWeb
        ? (isSmallScreen ? screenSize.width * 0.95 : 600.0)
        : screenSize.width * 0.9;
    final dialogHeight = isWeb
        ? (isSmallScreen ? screenSize.height * 0.9 : 650.0)
        : screenSize.height * 0.8;

    Widget content = Container(
      width: dialogWidth,
      height: dialogHeight,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: 700,
        minHeight: isSmallScreen ? 400 : 500,
      ),
      child: Card(
        elevation: widget.showAsDialog ? 24 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _buildPageContent(_pages[index]),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );

    if (widget.showAsDialog) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 20 : 40,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.library_music_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.customTitle ?? 'Welcome to LPMI40',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              child: const Text('SKIP'),
            ),
          if (widget.showAsDialog)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPopupContent content) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 32,
        vertical: isSmallScreen ? 16 : 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmallScreen ? 80 : 100,
            height: isSmallScreen ? 80 : 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: content.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: content.gradient.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              content.icon,
              size: isSmallScreen ? 40 : 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicators
          Row(
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8.0),
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
          // Next/Get Started button
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              backgroundColor: widget.primaryColor ?? theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 28,
                vertical: isSmallScreen ? 12 : 14,
              ),
              elevation: 2,
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPopupContent {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingPopupContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
