// lib/src/features/onboarding/presentation/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Welcome to LPMI',
      subtitle: 'Lagu Pujian Masa Ini',
      description:
          'Your comprehensive digital hymnal with hundreds of praise songs. Access your favorite hymns anytime, anywhere.',
      image: 'assets/images/onboarding_1.png',
      icon: Icons.music_note,
      color: Colors.blue,
    ),
    OnboardingContent(
      title: 'Browse & Search',
      subtitle: 'Find songs easily',
      description:
          'Search by song number or title. Browse through the complete songbook with our intuitive interface.',
      image: 'assets/images/onboarding_2.png',
      icon: Icons.search,
      color: Colors.green,
    ),
    OnboardingContent(
      title: 'Favorites & Sync',
      subtitle: 'Save your preferred songs',
      description:
          'Mark your favorite songs and sync them across all your devices. Create your personal collection.',
      image: 'assets/images/onboarding_3.png',
      icon: Icons.favorite,
      color: Colors.red,
    ),
    OnboardingContent(
      title: 'Customization',
      subtitle: 'Make it yours',
      description:
          'Adjust font size, choose themes, and customize text alignment for the best reading experience.',
      image: 'assets/images/onboarding_4.png',
      icon: Icons.palette,
      color: Colors.purple,
    ),
    OnboardingContent(
      title: 'Share & Report',
      subtitle: 'Community features',
      description:
          'Share songs with others and help improve the app by reporting any issues you find.',
      image: 'assets/images/onboarding_5.png',
      icon: Icons.share,
      color: Colors.orange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ FIXED: Top bar with responsive padding
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LPMI Onboarding',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          theme.textTheme.titleMedium?.color?.withOpacity(0.7),
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ✅ FIXED: Responsive page indicator
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: isSmallScreen ? 6.0 : 8.0,
                    width: _currentPage == index
                        ? (isSmallScreen ? 20.0 : 24.0)
                        : (isSmallScreen ? 6.0 : 8.0),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _pages[_currentPage].color
                          : theme.dividerColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ FIXED: Flexible page content with scroll support
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                      _pages[index], theme, isSmallScreen);
                },
              ),
            ),

            // ✅ FIXED: Responsive bottom navigation
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 8 : 12,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: isSmallScreen ? 60 : 80),

                  // Next/Get Started button
                  FilledButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      isLastPage ? Icons.check : Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    label: Text(isLastPage ? 'Get Started' : 'Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Scrollable and responsive onboarding page
  Widget _buildOnboardingPage(
      OnboardingContent content, ThemeData theme, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: isSmallScreen ? 8.0 : 16.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ FIXED: Responsive icon/image container
            Container(
              width: isSmallScreen ? 150 : 200,
              height: isSmallScreen ? 150 : 200,
              decoration: BoxDecoration(
                color: content.color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: content.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  content.icon,
                  size: isSmallScreen ? 60 : 80,
                  color: content.color,
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 24 : 40),

            // ✅ FIXED: Responsive title
            Text(
              content.title,
              style: (isSmallScreen
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: content.color,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 4 : 8),

            // ✅ FIXED: Responsive subtitle
            Text(
              content.subtitle,
              style: (isSmallScreen
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                color: theme.textTheme.titleLarge?.color?.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            // ✅ FIXED: Responsive description
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
              child: Text(
                content.description,
                style: (isSmallScreen
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isSmallScreen ? 24 : 40),

            // ✅ FIXED: Responsive feature highlights
            if (_currentPage == 1)
              _buildFeatureHighlights([
                'Search by song number',
                'Search by title',
                'Browse categories',
                'Sort options',
              ], content.color, theme, isSmallScreen),

            if (_currentPage == 2)
              _buildFeatureHighlights([
                'Heart icon to favorite',
                'Sync across devices',
                'Quick access',
                'Personal collection',
              ], content.color, theme, isSmallScreen),

            if (_currentPage == 3)
              _buildFeatureHighlights([
                'Multiple font sizes',
                'Color themes',
                'Text alignment',
                'Dark/Light mode',
              ], content.color, theme, isSmallScreen),

            // ✅ ADDED: Bottom padding to prevent cut-off
            SizedBox(height: isSmallScreen ? 16 : 24),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Responsive feature highlights
  Widget _buildFeatureHighlights(
    List<String> features,
    Color color,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: isSmallScreen ? 14 : 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  feature,
                  style: (isSmallScreen
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final String image;
  final IconData icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.icon,
    required this.color,
  });
}
