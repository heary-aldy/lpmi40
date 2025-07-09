// lib/main.dart
// ✅ FIXED: Added audio providers to the MultiProvider to resolve the exception.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

// Your existing services
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/core/services/user_migration_service.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';

// Your existing pages
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:lpmi40/utils/constants.dart';

// ✅ NEW: Import the new audio providers and services
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';

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
    // ✅ UPDATED: Added the new audio providers to your existing MultiProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsNotifier()),
        ChangeNotifierProvider(create: (context) => UserProfileNotifier()),

        // --- Added Audio Providers ---
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<AudioPlayerService, SongProvider>(
          create: (context) => SongProvider(context.read<AudioPlayerService>()),
          update: (context, audioService, previousSongProvider) =>
              previousSongProvider ?? SongProvider(audioService),
        ),
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = AppConstants.getDeviceType(constraints.maxWidth);
            final theme = AppTheme.getTheme(
              isDarkMode: settings.isDarkMode,
              themeColorKey: settings.colorThemeKey,
              deviceType: deviceType,
            );

            return MaterialApp(
              title: 'LPMI40',
              theme: theme.copyWith(brightness: Brightness.light),
              darkTheme: theme.copyWith(brightness: Brightness.dark),
              themeMode: settings.themeMode,
              debugShowCheckedModeBanner: false,
              home: _buildHomePage(),
              builder: (context, child) {
                if (child == null) {
                  return const SizedBox.shrink();
                }
                if (kDebugMode) {
                  try {
                    final navigator = Navigator.maybeOf(context);
                    if (navigator != null) {
                      return Stack(
                        children: [
                          child,
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 50,
                            right: 8,
                            child: IgnorePointer(
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
                          ),
                        ],
                      );
                    }
                  } catch (e) {
                    debugPrint('🔧 Navigator not ready for debug overlay: $e');
                  }
                }
                return child;
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
