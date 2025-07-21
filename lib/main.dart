// lib/main.dart
// ✅ COMPLETE: Fixed Firebase initialization and provider configuration
// ✅ FIXED: Dynamic theme support for dark mode and color theme changes

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Core services
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

// Repositories
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';

// Providers
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';

// App initialization
import 'package:lpmi40/src/features/songbook/services/app_initialization_service.dart';

// Pages
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';

// Theme
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/utils/constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ SAFE: Initialize Firebase with duplicate handling
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('ℹ️ Firebase already initialized, using existing instance');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint(
          'ℹ️ Firebase already initialized (duplicate-app), continuing...');
    } else {
      debugPrint('⚠️ Firebase initialization failed: $e');
      // Don't rethrow - continue with app startup
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Don't rethrow - continue with app startup
  }

  // Initialize SharedPreferences
  try {
    await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized');
  } catch (e) {
    debugPrint('⚠️ SharedPreferences initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
        ChangeNotifierProvider(create: (_) => UserProfileNotifier()),

        // Audio & Premium services
        ChangeNotifierProvider<AudioPlayerService>(
          create: (_) => AudioPlayerService(),
        ),
        Provider<PremiumService>(
          create: (_) => PremiumService(),
        ),
        Provider<AuthorizationService>(
          create: (_) => AuthorizationService(),
        ),

        // Repositories
        Provider<FavoritesRepository>(
          create: (_) => FavoritesRepository(),
        ),

        // Settings provider
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),

        // ✅ ENHANCED: Song provider with proper dependency injection
        ChangeNotifierProxyProvider3<AudioPlayerService, PremiumService,
            FavoritesRepository, SongProvider>(
          create: (context) => SongProvider(
            context.read<AudioPlayerService>(),
            context.read<PremiumService>(),
            context.read<FavoritesRepository>(),
          ),
          update: (context, audioService, premiumService, favoritesRepo,
                  previous) =>
              previous ??
              SongProvider(audioService, premiumService, favoritesRepo),
        ),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (context, settings, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // ✅ Get device type for responsive themes
              final deviceType =
                  AppConstants.getDeviceType(constraints.maxWidth);

              return MaterialApp(
                title: 'LPMI40 - Lagu Pujian Masa Ini',

                // ✅ FIXED: Dynamic light theme with user-selected color
                theme: AppTheme.getTheme(
                  isDarkMode: false,
                  themeColorKey: settings.colorThemeKey,
                  deviceType: deviceType,
                ),

                // ✅ FIXED: Dynamic dark theme with user-selected color
                darkTheme: AppTheme.getTheme(
                  isDarkMode: true,
                  themeColorKey: settings.colorThemeKey,
                  deviceType: deviceType,
                ),

                // ✅ FIXED: Responds to dark mode toggle
                themeMode: settings.themeMode,

                home: const AppInitializer(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _statusMessage = 'Initializing...';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Check onboarding status
      setState(() {
        _statusMessage = 'Checking app status...';
      });

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (!hasSeenOnboarding) {
        // Show onboarding for first-time users
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnboardingPage(
                onCompleted: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const RevampedDashboardPage()),
                  );
                },
              ),
            ),
          );
        }
        return;
      }

      // Step 2: Initialize app data
      setState(() {
        _statusMessage = 'Loading app data...';
      });

      final initService = AppInitializationService();
      final initResult = await initService.initializeApp(silentSync: true);

      if (!initResult.success) {
        debugPrint(
            '⚠️ [AppInitializer] Data initialization failed: ${initResult.message}');
        // Continue anyway - app can work with online data
      } else {
        debugPrint('✅ [AppInitializer] Data initialization successful');
        if (initResult.performedSync) {
          debugPrint('📱 Initial sync completed');
        } else {
          debugPrint('📱 Using existing local data');
        }
      }

      // Step 3: Check authentication and navigate
      setState(() {
        _statusMessage = 'Checking authentication...';
      });

      await _checkInitialRoute();
    } catch (e) {
      debugPrint('❌ [AppInitializer] Error during app initialization: $e');
      // Fallback to basic initialization
      await _checkInitialRoute();
    }
  }

  Future<void> _checkInitialRoute() async {
    try {
      // Check authentication status
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, go to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const RevampedDashboardPage()),
          );
        }
      } else {
        // User is not logged in, go to auth page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AuthPage(
                isDarkMode: context.read<SettingsNotifier>().isDarkMode,
                onToggleTheme: () {
                  final settingsNotifier = context.read<SettingsNotifier>();
                  settingsNotifier.updateDarkMode(!settingsNotifier.isDarkMode);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AppInitializer] Error during route checking: $e');
      // Fallback to auth page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AuthPage(
              isDarkMode: false,
              onToggleTheme: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LPMI40',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lagu Pujian Masa Ini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
