import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart'; // Import your service

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Welcome to LPMI',
      subtitle: 'Lagu Pujian Masa Ini',
      description:
          'Your comprehensive digital hymnal with hundreds of praise songs. Access your favorite hymns anytime, anywhere.',
      icon: Icons.music_note_rounded,
      gradientColors: [const Color(0xFF6AC8FF), const Color(0xFF4A80F0)],
    ),
    OnboardingContent(
      title: 'Browse & Search',
      subtitle: 'Find songs easily',
      description:
          'Search by song number or title. Browse through the complete songbook with our intuitive interface.',
      icon: Icons.search_rounded,
      gradientColors: [const Color(0xFF69F0AE), const Color(0xFF00C853)],
    ),
    OnboardingContent(
      title: 'Favorites & Sync',
      subtitle: 'Save your preferred songs',
      description:
          'Mark your favorite songs and sync them across all your devices. Create your personal collection.',
      icon: Icons.favorite_rounded,
      gradientColors: [const Color(0xFFFF8A80), const Color(0xFFF44336)],
    ),
    OnboardingContent(
      title: 'Customization',
      subtitle: 'Make it yours',
      description:
          'Adjust font size, choose themes, and customize text alignment for the best reading experience.',
      icon: Icons.palette_rounded,
      gradientColors: [const Color(0xFFE040FB), const Color(0xFF9C27B0)],
    ),
    OnboardingContent(
      title: 'Share & Report',
      subtitle: 'What is your name?',
      description:
          'Let\'s get you set up. Please enter a name or nickname we can use to greet you in the app.',
      icon: Icons.person_add_alt_1_rounded,
      gradientColors: [const Color(0xFFFFD180), const Color(0xFFFF9800)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      final onboardingService = await OnboardingService.getInstance();
      await onboardingService.completeOnboarding(
          name: _nameController.text.trim());
      widget.onCompleted();
    }
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
    await onboardingService.completeOnboarding(
        name: ''); // Skip with an empty name
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: _pages[_currentPage].gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: SafeArea(
            child: Column(children: [
          _buildTopBar(),
          Expanded(
              child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPageContent(_pages[index]),
          )),
          _buildBottomControls(),
        ])),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: _currentPage == _pages.length - 1
          ? null
          : TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              child: const Text('Skip')),
    );
  }

  Widget _buildPageContent(OnboardingContent content) {
    final bool isLastPage = content == _pages.last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(children: [
        const Spacer(flex: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child)),
          child: Container(
            key: ValueKey<IconData>(content.icon),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
                child: Icon(content.icon, size: 100, color: Colors.white)),
          ),
        ),
        const Spacer(flex: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(animation),
                  child: child)),
          child: Column(key: ValueKey<String>(content.title), children: [
            Text(content.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            Text(content.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.6)),
            if (isLastPage)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Enter your name or nickname',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.5))),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 2)),
                        errorStyle: GoogleFonts.poppins(
                            color: Colors.yellowAccent,
                            fontWeight: FontWeight.w600),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    )),
              ),
          ]),
        ),
        const Spacer(flex: 3),
      ]),
    );
  }

  Widget _buildBottomControls() {
    final bool isLastPage = _currentPage == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
            children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8.0),
                      height: 10.0,
                      width: _currentPage == index ? 30.0 : 10.0,
                      decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(5.0)),
                    ))),
        FilledButton(
          onPressed: _nextPage,
          style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _pages[_currentPage].gradientColors.last,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: Text(isLastPage ? 'Get Started' : 'Next',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ]),
    );
  }
}
