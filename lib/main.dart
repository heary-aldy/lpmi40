import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart'; // ✅ NEW: Import UserProfileNotifier
import 'package:lpmi40/src/core/services/user_migration_service.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:lpmi40/utils/constants.dart'; // ✅ NEW: Import responsive constants

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
    // ✅ UPDATED: Add MultiProvider for multiple notifiers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsNotifier()),
        ChangeNotifierProvider(
            create: (context) =>
                UserProfileNotifier()), // ✅ NEW: Add UserProfileNotifier
      ],
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
        // ✅ NEW: Use responsive theme generation
        return LayoutBuilder(
          builder: (context, constraints) {
            // Determine device type for responsive theming
            final deviceType = AppConstants.getDeviceType(constraints.maxWidth);

            // Generate responsive theme
            final theme = AppTheme.getTheme(
              isDarkMode: settings.isDarkMode,
              themeColorKey: settings.colorThemeKey,
              deviceType:
                  deviceType, // ✅ NEW: Pass device type for responsive theming
            );

            return MaterialApp(
              title: 'LPMI40',
              theme: theme.copyWith(brightness: Brightness.light),
              darkTheme: theme.copyWith(brightness: Brightness.dark),
              themeMode: settings.themeMode,
              debugShowCheckedModeBanner: false,
              home: _buildHomePage(),
              // ✅ NEW: Add responsive debug info in debug mode
              builder: (context, child) {
                // Add responsive debug overlay in debug mode
                if (kDebugMode) {
                  return Stack(
                    children: [
                      child!,
                      // Debug info for screen size (only visible in debug mode)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 50,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '${deviceType.name.toUpperCase()}\n${constraints.maxWidth.toInt()}px',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return child!;
              },
            );
          },
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

// ✅ ENHANCED: Responsive Loading Screen Widgets
class InitializationLoadingScreen extends StatelessWidget {
  const InitializationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: spacing),
              Text(
                'Initializing LPMI...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MigrationLoadingScreen extends StatelessWidget {
  const MigrationLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final spacing = AppConstants.getSpacing(deviceType);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: spacing),
              Text(
                'Setting up your account...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
