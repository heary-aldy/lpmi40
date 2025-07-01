import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart'; // Import your service

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // Use the service to get the user name
    final onboardingService = await OnboardingService.getInstance();
    if (mounted) {
      setState(() {
        _userName = onboardingService.userName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LPMI Dashboard'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show a loading spinner until the name is loaded
            if (_userName == null)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Welcome, ${(_userName?.isNotEmpty ?? false) ? _userName : "Friend"}!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Your Hymnal Awaits You.',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
