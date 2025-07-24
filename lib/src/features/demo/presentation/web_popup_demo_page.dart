// lib/src/features/demo/presentation/web_popup_demo_page.dart
// ✅ WEB DEMO: Test page for popup modals in web view
// ✅ FEATURES: Onboarding popup, Auth popup, responsive design
// ✅ PURPOSE: Demo for web view compatibility testing

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_popup.dart';
import 'package:lpmi40/src/features/auth/presentation/auth_popup.dart';

class WebPopupDemoPage extends StatefulWidget {
  const WebPopupDemoPage({super.key});

  @override
  State<WebPopupDemoPage> createState() => _WebPopupDemoPageState();
}

class _WebPopupDemoPageState extends State<WebPopupDemoPage> {
  int _onboardingCompletions = 0;
  int _authSuccesses = 0;
  String _lastAuthResult = 'None';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWeb = kIsWeb;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Web Popup Demo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          if (isWeb)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(
                  'WEB VIEW',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.green.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.1),
              theme.colorScheme.secondaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStatsSection(),
                const SizedBox(height: 32),
                _buildOnboardingSection(),
                const SizedBox(height: 24),
                _buildAuthSection(),
                const SizedBox(height: 24),
                _buildInfoSection(),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.web_rounded,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'LPMI40 Web Popup Demo',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Test responsive popup modals for web view compatibility',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Demo Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (isSmallScreen) ...[
              _buildStatItem('Onboarding Completions', _onboardingCompletions),
              const SizedBox(height: 12),
              _buildStatItem('Auth Successes', _authSuccesses),
              const SizedBox(height: 12),
              _buildStatItem('Last Auth Result', _lastAuthResult),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                      'Onboarding Completions', _onboardingCompletions),
                  _buildStatItem('Auth Successes', _authSuccesses),
                  _buildStatItem('Last Auth Result', _lastAuthResult),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOnboardingSection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.tour_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Onboarding Popup',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Interactive introduction to LPMI40 features with smooth animations and responsive design.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showOnboardingPopup,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Show Onboarding'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showOnboardingCustom,
                    icon: const Icon(Icons.palette_rounded),
                    label: const Text('Custom Style'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Authentication Popup',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Firebase authentication with responsive forms, validation, and error handling.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showLoginPopup,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Show Login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSignUpPopup,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Show Sign Up'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    final isWeb = kIsWeb;
    final screenSize = MediaQuery.of(context).size;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Environment Info',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Platform', isWeb ? 'Web' : 'Mobile'),
            _buildInfoRow('Screen Size',
                '${screenSize.width.toInt()} x ${screenSize.height.toInt()}'),
            _buildInfoRow(
                'Is Small Screen', screenSize.width < 600 ? 'Yes' : 'No'),
            _buildInfoRow('Device Type', _getDeviceType(screenSize.width)),
            if (isWeb) ...[
              _buildInfoRow('Web View', 'Compatible'),
              _buildInfoRow('Modal Support', 'Full'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '🎵 LPMI40 Web Popup Testing',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All popups are fully responsive and optimized for web view compatibility.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDeviceType(double width) {
    if (width < 600) return 'Mobile';
    if (width < 1024) return 'Tablet';
    return 'Desktop';
  }

  void _showOnboardingPopup() {
    OnboardingPopup.showDialog(
      context,
      title: 'LPMI40 Demo',
      onCompleted: () {
        setState(() {
          _onboardingCompletions++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding completed!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _showOnboardingCustom() {
    OnboardingPopup.showDialog(
      context,
      title: 'Custom Onboarding',
      backgroundColor: Colors.purple.shade50,
      primaryColor: Colors.purple,
      onCompleted: () {
        setState(() {
          _onboardingCompletions++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom onboarding completed!'),
            backgroundColor: Colors.purple,
          ),
        );
      },
    );
  }

  void _showLoginPopup() {
    AuthPopup.showDialog(
      context,
      startWithSignUp: false,
    ).then((success) {
      setState(() {
        _lastAuthResult = success == true ? 'Login Success' : 'Login Cancelled';
        if (success == true) _authSuccesses++;
      });

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showSignUpPopup() {
    AuthPopup.showDialog(
      context,
      startWithSignUp: true,
    ).then((success) {
      setState(() {
        _lastAuthResult =
            success == true ? 'Sign Up Success' : 'Sign Up Cancelled';
        if (success == true) _authSuccesses++;
      });

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
