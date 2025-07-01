// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_migration_service.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart'; // ✅ NEW: Import onboarding service
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart'; // ✅ NEW: Import onboarding page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('📱 App will continue running with local data only');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isMigrationComplete = false;
  bool _isOnboardingComplete = false; // ✅ NEW: Track onboarding status
  bool _isInitializationComplete = false; // ✅ NEW: Track overall initialization

  @override
  void initState() {
    super.initState();
    _initializeApp(); // ✅ NEW: Initialize app with onboarding check
  }

  // ✅ NEW: Combined initialization method
  Future<void> _initializeApp() async {
    try {
      // Initialize onboarding service first
      final onboardingService = await OnboardingService.getInstance();
      await onboardingService.incrementLaunchCount();

      debugPrint('🚀 App initialization started');
      debugPrint('📊 Launch count: ${onboardingService.appLaunchCount}');
      debugPrint('👶 Is new user: ${onboardingService.isNewUser}');
      debugPrint(
          '✅ Should show onboarding: ${onboardingService.shouldShowOnboarding}');

      // Check onboarding status
      final shouldShowOnboarding = onboardingService.shouldShowOnboarding;

      if (mounted) {
        setState(() {
          _isOnboardingComplete = !shouldShowOnboarding;
        });
      }

      // If onboarding is complete, proceed with user migration
      if (!shouldShowOnboarding) {
        await _initializeUserMigration();
      } else {
        // Skip migration for now, will be done after onboarding
        if (mounted) {
          setState(() {
            _isMigrationComplete = true;
            _isInitializationComplete = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      // Don't block the app if initialization fails
      if (mounted) {
        setState(() {
          _isOnboardingComplete = true;
          _isMigrationComplete = true;
          _isInitializationComplete = true;
        });
      }
    }
  }

  // ✅ MODIFIED: Initialize user migration on app start
  Future<void> _initializeUserMigration() async {
    try {
      // Listen for auth state changes to trigger migration
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          debugPrint('🔄 User signed in, checking migration status...');
          await UserMigrationService().checkAndMigrateCurrentUser();
          debugPrint('✅ User migration check completed');
        }

        if (mounted) {
          setState(() {
            _isMigrationComplete = true;
            _isInitializationComplete = true;
          });
        }
      });

      // Also check immediately if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('🔄 User already signed in, running migration check...');
        await UserMigrationService().checkAndMigrateCurrentUser();
        debugPrint('✅ Initial user migration check completed');
      }

      if (mounted) {
        setState(() {
          _isMigrationComplete = true;
          _isInitializationComplete = true;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Migration initialization failed: $e');
      // Don't block the app if migration fails
      if (mounted) {
        setState(() {
          _isMigrationComplete = true;
          _isInitializationComplete = true;
        });
      }
    }
  }

  // ✅ NEW: Handle onboarding completion
  void _onOnboardingComplete() {
    debugPrint('🎉 Onboarding completed, starting user migration...');
    setState(() {
      _isOnboardingComplete = true;
    });

    // Start user migration after onboarding
    _initializeUserMigration();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsNotifier>(
      builder: (context, settings, child) {
        final theme = AppTheme.getTheme(
          isDarkMode: settings.isDarkMode,
          themeColorKey: settings.colorThemeKey,
        );

        return MaterialApp(
          title: 'LPMI40',
          theme: theme.copyWith(brightness: Brightness.light),
          darkTheme: theme.copyWith(brightness: Brightness.dark),
          themeMode: settings.themeMode,
          debugShowCheckedModeBanner: false,
          home: _buildHomePage(), // ✅ NEW: Dynamic home page based on state
        );
      },
    );
  }

  // ✅ NEW: Build appropriate home page based on initialization state
  Widget _buildHomePage() {
    // Show initialization loading screen
    if (!_isInitializationComplete) {
      return const InitializationLoadingScreen();
    }

    // Show onboarding if not completed
    if (!_isOnboardingComplete) {
      return const OnboardingPage();
    }

    // Show migration loading if needed
    if (!_isMigrationComplete) {
      return const MigrationLoadingScreen();
    }

    // Show main dashboard
    return const DashboardPage();
  }
}

// ✅ NEW: Initialization loading screen
class InitializationLoadingScreen extends StatelessWidget {
  const InitializationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Lagu Pujian Masa Ini',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing app...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ EXISTING: Loading screen during migration
class MigrationLoadingScreen extends StatelessWidget {
  const MigrationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Lagu Pujian Masa Ini',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Checking user data...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
