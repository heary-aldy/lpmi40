import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/services/user_migration_service.dart'; // ✅ Add this import
import 'package:lpmi40/src/core/theme/app_theme.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeUserMigration();
  }

  // ✅ NEW: Initialize user migration on app start
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
        });
      }
    } catch (e) {
      debugPrint('⚠️ Migration initialization failed: $e');
      // Don't block the app if migration fails
      if (mounted) {
        setState(() {
          _isMigrationComplete = true;
        });
      }
    }
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
          home: _isMigrationComplete
              ? const DashboardPage()
              : const MigrationLoadingScreen(), // ✅ Show loading during migration
        );
      },
    );
  }
}

// ✅ NEW: Loading screen during migration
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
