import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_migration_service.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
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
  bool _isOnboardingComplete = false;
  bool _isInitializationComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final onboardingService = await OnboardingService.getInstance();
      await onboardingService.incrementLaunchCount();

      final shouldShow = onboardingService.shouldShowOnboarding;

      if (mounted) {
        setState(() {
          _isOnboardingComplete = !shouldShow;
        });
      }

      if (!shouldShow) {
        await _initializeUserMigration();
      } else {
        if (mounted) {
          setState(() {
            _isMigrationComplete = true; // Skip migration check for now
            _isInitializationComplete = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      if (mounted) {
        setState(() {
          _isOnboardingComplete = true;
          _isMigrationComplete = true;
          _isInitializationComplete = true;
        });
      }
    }
  }

  Future<void> _initializeUserMigration() async {
    // This logic seems fine as is, setting flags upon completion
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await UserMigrationService().checkAndMigrateCurrentUser();
    }
    if (mounted) {
      setState(() {
        _isMigrationComplete = true;
        _isInitializationComplete = true;
      });
    }
  }

  void _onOnboardingComplete() {
    debugPrint('🎉 Onboarding completed, starting user migration...');
    setState(() {
      _isOnboardingComplete = true;
    });
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
          home: _buildHomePage(),
        );
      },
    );
  }

  Widget _buildHomePage() {
    if (!_isInitializationComplete) {
      return const InitializationLoadingScreen();
    }
    if (!_isOnboardingComplete) {
      return OnboardingPage(onCompleted: _onOnboardingComplete);
    }
    if (!_isMigrationComplete) {
      return const MigrationLoadingScreen();
    }
    return const DashboardPage();
  }
}

// Loading Screen Widgets (Initialization and Migration)
class InitializationLoadingScreen extends StatelessWidget {
  const InitializationLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MigrationLoadingScreen extends StatelessWidget {
  const MigrationLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
