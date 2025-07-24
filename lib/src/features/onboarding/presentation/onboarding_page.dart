import 'dart:ui'; // Needed for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_popup.dart';

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingPage({super.key, required this.onCompleted});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Welcome to LPMI40',
      subtitle: 'The Future of Digital Hymnals',
      description:
          'Experience premium audio playback, offline downloads, real-time sync, and smart features designed for modern worship.',
      icon: Icons.music_note_rounded,
    ),
    OnboardingContent(
      title: 'Premium Audio Experience',
      subtitle: 'High-quality hymnal recordings',
      description:
          'Listen to professionally recorded hymns with crystal-clear audio. Download for offline access and enjoy seamless playback controls.',
      icon: Icons.headphones_rounded,
    ),
    OnboardingContent(
      title: 'Multi-Tier Access System',
      subtitle: 'Roles: Guest → Premium → Admin → Super Admin',
      description:
          'Unlock features based on your role: Browse as guest, access audio as Premium, manage collections as Admin, or control everything as Super Admin.',
      icon: Icons.admin_panel_settings_rounded,
    ),
    OnboardingContent(
      title: 'Smart Features & More',
      subtitle: 'Themes, Collections, Admin Tools',
      description:
          'Enjoy 8 custom themes, instant search, favorites sync, multiple collections, verse-of-the-day, and comprehensive admin tools for church management.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final onboardingService = await OnboardingService.getInstance();
    await onboardingService.completeOnboarding(name: 'Friend');
    widget.onCompleted();
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    }
  }

  Future<void> _skipOnboarding() async {
    final onboardingService = await OnboardingService.getInstance();
    await onboardingService.completeOnboarding(name: '');
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
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
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Demo popup button (for development/testing)
          if (_currentPage == 0)
            TextButton(
              onPressed: () => OnboardingPopup.showDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.8),
                textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, letterSpacing: 1),
              ),
              child: const Text('POPUP DEMO'),
            )
          else
            const SizedBox(),
          // Skip button
          _currentPage == _pages.length - 1
              ? const SizedBox()
              : TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  child: const Text('SKIP'),
                ),
        ],
      ),
    );
  }

  // ✅ UPDATED: The "box" (BackdropFilter and Container) has been removed.
  // The content now "floats" on the blurred background.
  Widget _buildPageContent(OnboardingContent content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Icon(
            content.icon,
            size: 120,
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 15, color: Colors.black54)],
          ),
          const SizedBox(height: 48),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                    blurRadius: 4, color: Colors.black54, offset: Offset(2, 2))
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              shadows: const [
                Shadow(
                    blurRadius: 4, color: Colors.black54, offset: Offset(1, 1))
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
