import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'package:lpmi40/src/core/theme/app_theme.dart';
// Import the DashboardPage
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // Set DashboardPage as the home widget
          home: const DashboardPage(),
        );
      },
    );
  }
}
