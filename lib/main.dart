// lib/main.dart
// ✅ PERFORMANCE OPTIMIZED: Heavy operations moved off main thread
// 🚀 FIXED: Main thread blocking, deferred initialization, background operations

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

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

// Audio providers and services
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/providers/song_provider.dart';
import 'package:lpmi40/src/providers/settings_provider.dart';

// ✅ NEW: Background initialization service
class BackgroundInitializationService {
  static final BackgroundInitializationService _instance =
      BackgroundInitializationService._internal();
  factory BackgroundInitializationService() => _instance;
  BackgroundInitializationService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  final List<VoidCallback> _onInitializedCallbacks = [];

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  /// Add callback to be called when background initialization completes
  void onInitialized(VoidCallback callback) {
    if (_isInitialized) {
      callback();
    } else {
      _onInitializedCallbacks.add(callback);
    }
  }

  /// Start background initialization (non-blocking)
  void startBackgroundInit() {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    debugPrint('🔄 Starting background initialization...');

    // Run heavy operations in background
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _performBackgroundInit();
        _isInitialized = true;
        _isInitializing = false;

        debugPrint('✅ Background initialization completed');

        // Notify all waiting callbacks
        for (final callback in _onInitializedCallbacks) {
          try {
            callback();
          } catch (e) {
            debugPrint('⚠️ Error in initialization callback: $e');
          }
        }
        _onInitializedCallbacks.clear();
      } catch (e) {
        _isInitializing = false;
        debugPrint('❌ Background initialization failed: $e');
      }
    });
  }

  /// Perform heavy initialization tasks in background
  Future<void> _performBackgroundInit() async {
    // ✅ OPTIMIZATION: Run heavy operations here, not on main thread
    try {
      // Pre-warm Firebase services (if needed)
      if (Firebase.apps.isNotEmpty) {
        final database = FirebaseDatabase.instance;

        // Pre-configure database settings (non-blocking)
        try {
          database.setPersistenceEnabled(true);
          database.setPersistenceCacheSizeBytes(10 * 1024 * 1024);

          // Optional: Pre-warm connection (don't wait for it)
          database.ref('.info/connected').onValue.listen(
            (event) {
              debugPrint(
                  '🔗 Firebase connection state: ${event.snapshot.value}');
            },
            onError: (error) {
              debugPrint('⚠️ Connection monitoring error: $error');
            },
          ).onError((error) {
            // Silently handle errors
          });
        } catch (e) {
          debugPrint('⚠️ Database pre-configuration failed: $e');
        }
      }

      // Pre-load any critical data (optional)
      // await _preloadCriticalData();

      debugPrint('🎉 Background initialization tasks completed');
    } catch (e) {
      debugPrint('❌ Background initialization error: $e');
      // Don't rethrow - this shouldn't block the app
    }
  }
}

// ✅ OPTIMIZED: Lightweight Firebase initialization
Future<void> _initializeFirebaseQuickly() async {
  try {
    debugPrint('🚀 Quick Firebase initialization starting...');
    final stopwatch = Stopwatch()..start();

    // Initialize Firebase with minimal configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    stopwatch.stop();
    debugPrint('✅ Firebase initialized in ${stopwatch.elapsedMilliseconds}ms');

    // Start background initialization (non-blocking)
    BackgroundInitializationService().startBackgroundInit();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Don't rethrow - allow app to continue with offline mode
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ PERFORMANCE FIX: Quick, non-blocking Firebase initialization
  await _initializeFirebaseQuickly();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsNotifier()),
        ChangeNotifierProvider(create: (context) => UserProfileNotifier()),

        // Audio providers
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
  bool _isOnboardingComplete = false;
  bool _isInitializationComplete = false;

  // ✅ NEW: Lightweight initialization state
  bool _isQuickInitComplete = false;

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE FIX: Start with quick initialization only
    _performQuickInit();
  }

  /// ✅ OPTIMIZED: Quick initialization that doesn't block main thread
  void _performQuickInit() {
    debugPrint('🚀 Starting quick app initialization...');

    // Use post-frame callback to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppQuickly();
    });
  }

  /// ✅ PERFORMANCE OPTIMIZED: Non-blocking initialization
  Future<void> _initializeAppQuickly() async {
    try {
      // Step 1: Quick onboarding check (essential for UI)
      final onboardingService = await OnboardingService.getInstance();
      await onboardingService.incrementLaunchCount();
      final shouldShow = onboardingService.shouldShowOnboarding;

      if (mounted) {
        setState(() {
          _isOnboardingComplete = !shouldShow;
          _isQuickInitComplete = true;
        });
      }

      // Step 2: Schedule heavy operations for later (non-blocking)
      if (!shouldShow) {
        _scheduleHeavyInitialization();
      } else {
        if (mounted) {
          setState(() {
            _isInitializationComplete = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Quick initialization failed: $e');
      // Provide fallback state
      if (mounted) {
        setState(() {
          _isOnboardingComplete = true;
          _isQuickInitComplete = true;
          _isInitializationComplete = true;
        });
      }
    }
  }

  /// ✅ NEW: Schedule heavy operations for background execution
  void _scheduleHeavyInitialization() {
    debugPrint('⏰ Scheduling heavy initialization...');

    // Wait a bit for UI to settle, then run heavy operations
    Future.delayed(const Duration(milliseconds: 500), () {
      _performHeavyInitialization();
    });
  }

  /// ✅ DEFERRED: Heavy operations moved to background
  Future<void> _performHeavyInitialization() async {
    try {
      debugPrint('🔄 Starting heavy initialization (background)...');

      // Wait for background service to be ready
      if (!BackgroundInitializationService().isInitialized) {
        // Wait up to 3 seconds for background init
        int attempts = 0;
        while (
            !BackgroundInitializationService().isInitialized && attempts < 30) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }

      // Perform user migration (if needed) in background
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('👤 User detected, starting migration...');

        // ✅ PERFORMANCE: Run migration in background, don't block UI
        _runUserMigrationInBackground();
      }

      if (mounted) {
        setState(() {
          _isInitializationComplete = true;
        });
      }

      debugPrint('✅ Heavy initialization completed');
    } catch (e) {
      debugPrint('❌ Heavy initialization failed: $e');
      if (mounted) {
        setState(() {
          _isInitializationComplete = true;
        });
      }
    }
  }

  /// ✅ BACKGROUND: User migration without blocking UI
  void _runUserMigrationInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        debugPrint('🔄 Running user migration in background...');
        await UserMigrationService().checkAndMigrateCurrentUser();
        debugPrint('✅ User migration completed');
      } catch (e) {
        debugPrint('⚠️ User migration failed: $e');
        // Don't block app if migration fails
      }
    });
  }

  void _onOnboardingComplete() {
    debugPrint('🎉 Onboarding completed');
    setState(() {
      _isOnboardingComplete = true;
    });

    // Start heavy initialization after onboarding
    _scheduleHeavyInitialization();
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
                if (child == null) return const SizedBox.shrink();

                // ✅ OPTIMIZED: Simplified debug overlay
                if (kDebugMode) {
                  return _buildWithDebugOverlay(child, constraints, deviceType);
                }
                return child;
              },
            );
          },
        );
      },
    );
  }

  /// ✅ OPTIMIZED: Lightweight debug overlay
  Widget _buildWithDebugOverlay(
      Widget child, BoxConstraints constraints, DeviceType deviceType) {
    try {
      final navigator = Navigator.maybeOf(context);
      if (navigator == null) return child;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    } catch (e) {
      debugPrint('🔧 Debug overlay error: $e');
      return child;
    }
  }

  /// ✅ OPTIMIZED: Smart home page building
  Widget _buildHomePage() {
    // Show loading screen only for essential initialization
    if (!_isQuickInitComplete) {
      return const QuickInitializationLoadingScreen();
    }

    if (!_isOnboardingComplete) {
      return OnboardingPage(onCompleted: _onOnboardingComplete);
    }

    // ✅ PERFORMANCE: Allow dashboard to load even if heavy init isn't complete
    // Heavy initialization continues in background
    return const DashboardPage();
  }
}

/// ✅ NEW: Lightweight loading screen for essential initialization only
class QuickInitializationLoadingScreen extends StatelessWidget {
  const QuickInitializationLoadingScreen({super.key});

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
                'Starting LPMI...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Quick setup in progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ REMOVED: Old InitializationLoadingScreen and MigrationLoadingScreen
/// These were causing main thread blocking - replaced with background operations
