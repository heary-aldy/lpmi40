// lib/main.dart
// ✅ COMPLETE: Fixed Firebase initialization and provider configuration
// ✅ FIXED: Dynamic theme support for dark mode and color theme changes

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:lpmi40/src/core/services/firebase_database_service.dart';
import 'package:lpmi40/src/core/services/onboarding_service.dart';
import 'package:lpmi40/src/core/config/env_config.dart';
import 'package:lpmi40/src/core/config/production_config.dart';
import 'package:lpmi40/src/core/services/ai_service.dart';
import 'package:lpmi40/src/core/services/session_integration_service.dart';

// Repositories
import 'package:lpmi40/src/features/songbook/repository/favorites_repository.dart';

// Providers
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';

// App initialization
import 'package:lpmi40/src/features/songbook/services/app_initialization_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';

// Pages
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';
import 'package:lpmi40/pages/auth_page.dart';
import 'package:lpmi40/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:lpmi40/src/features/bible/presentation/bible_main_page.dart';
import 'package:lpmi40/src/features/settings/presentation/token_setup_page.dart';

// Theme
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/utils/constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Load environment variables
  try {
    await EnvConfig.load();
    debugPrint('✅ Environment configuration loaded');
  } catch (e) {
    debugPrint('⚠️ Environment configuration not found - using fallbacks: $e');
  }

  // ✅ SAFE: Initialize Firebase with duplicate handling and web support
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint(
          '✅ Firebase initialized successfully for $defaultTargetPlatform');
    } else {
      debugPrint('ℹ️ Firebase already initialized, using existing instance');
    }
  } on UnsupportedError catch (e) {
    if (e.message?.contains('not been configured for web') == true) {
      debugPrint(
          '⚠️ Firebase web configuration missing - this should now be fixed');
      debugPrint(
          'ℹ️ If you still see this error, please check firebase_options.dart');
    } else {
      debugPrint('⚠️ Platform not supported: $e');
    }
    // Don't rethrow - continue with app startup
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint(
          'ℹ️ Firebase already initialized (duplicate-app), continuing...');
    } else {
      debugPrint('⚠️ Firebase initialization failed: $e');
    }
    // Don't rethrow - continue with app startup
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

  // Initialize Firebase Database Service
  try {
    final dbService = FirebaseDatabaseService.instance;
    final dbInitialized = await dbService.initialize();
    if (dbInitialized) {
      debugPrint('✅ Firebase Database Service initialized successfully');

      // ✅ NEW: Initialize Collection Cache Manager and preload important collections
      try {
        final cacheManager = CollectionCacheManager.instance;
        // Preload important collections in background (non-blocking)
        cacheManager.preloadImportantCollections();
        debugPrint('✅ Collection Cache Manager initialized');
      } catch (e) {
        debugPrint('⚠️ Collection Cache Manager initialization error: $e');
      }

      // 🏭 Initialize Production Configuration
      try {
        await ProductionConfig.initialize();
        debugPrint('✅ Production configuration initialized');
      } catch (e) {
        debugPrint('⚠️ Production configuration initialization error: $e');
      }

      // 🤖 Initialize AI Service with usage tracking
      try {
        await AIService.initialize();
        debugPrint('✅ AI Service with usage tracking initialized');
      } catch (e) {
        debugPrint('⚠️ AI Service initialization error: $e');
      }

      // 🔐 Initialize Session Management
      try {
        await SessionIntegrationService.instance.initialize();
        debugPrint('✅ Session management initialized');
      } catch (e) {
        debugPrint('⚠️ Session management initialization error: $e');
      }
    } else {
      debugPrint(
          '⚠️ Firebase Database Service initialization failed, but continuing...');
    }
  } catch (e) {
    debugPrint('⚠️ Firebase Database Service initialization error: $e');
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

                // ✅ ADD: Route configuration for Bible navigation
                routes: {
                  '/bible': (context) => const BibleMainPage(),
                  '/dashboard': (context) => const RevampedDashboardPage(),
                  '/token-setup': (context) => const TokenSetupPage(),
                },

                // ✅ ADD: Handle unknown routes
                onUnknownRoute: (settings) {
                  debugPrint('⚠️ Unknown route: ${settings.name}');
                  return MaterialPageRoute(
                    builder: (context) => const RevampedDashboardPage(),
                  );
                },
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
  final bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Fallback: If stuck, force navigation after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        debugPrint('⏰ Fallback: Forcing navigation to dashboard after timeout');
        _forceDashboardIfStuck();
      }
    });
  }

  void _forceDashboardIfStuck() {
    // Only force if still on splash/loading
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RevampedDashboardPage()),
      );
    }
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('[AppInitializer] Step 1: Checking onboarding status...');
      setState(() {
        _statusMessage = 'Checking app status...';
      });

      final onboardingService = await OnboardingService.getInstance();
      debugPrint('[AppInitializer] OnboardingService loaded');
      // Increment launch count for analytics
      await onboardingService.incrementLaunchCount();
      debugPrint('[AppInitializer] Launch count incremented');
      final hasSeenOnboarding = onboardingService.isOnboardingCompleted;
      debugPrint('[AppInitializer] hasSeenOnboarding: $hasSeenOnboarding');

      if (!hasSeenOnboarding) {
        debugPrint('[AppInitializer] Showing onboarding page');
        if (!mounted) return;
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
        return;
      }

      // Step 2: Initialize app data
      debugPrint('[AppInitializer] Step 2: Initializing app data...');
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
      debugPrint('[AppInitializer] Step 3: Checking authentication...');
      setState(() {
        _statusMessage = 'Checking authentication...';
      });

      await _checkInitialRoute();
    } catch (e, st) {
      debugPrint('❌ [AppInitializer] Error during app initialization: $e\n$st');
      // Fallback to basic initialization
      await _checkInitialRoute();
    }
  }

  Future<void> _checkInitialRoute() async {
    try {
      debugPrint('[AppInitializer] _checkInitialRoute called');
      // Check authentication status
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('[AppInitializer] FirebaseAuth user: ${user?.uid}');

      if (user != null) {
        debugPrint(
            '[AppInitializer] User is logged in, navigating to dashboard');
        if (!mounted) return;
        
        // Use pushAndRemoveUntil to ensure clean navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const RevampedDashboardPage()),
          (route) => false, // Remove all previous routes including splash
        );
      } else {
        debugPrint(
            '[AppInitializer] User is not logged in, navigating to auth page');
        if (!mounted) return;
        
        // Use pushAndRemoveUntil to ensure clean navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => AuthPage(
              isDarkMode: context.read<SettingsNotifier>().isDarkMode,
              onToggleTheme: () {
                final settingsNotifier = context.read<SettingsNotifier>();
                settingsNotifier.updateDarkMode(!settingsNotifier.isDarkMode);
              },
            ),
          ),
          (route) => false, // Remove all previous routes including splash
        );
      }
    } catch (e, st) {
      debugPrint('❌ [AppInitializer] Error during route checking: $e\n$st');
      // Fallback to auth page
      if (!mounted) return;
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
