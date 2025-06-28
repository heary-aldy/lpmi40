import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';
import 'package:lpmi40/pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase services
  await _initializeFirebaseServices();

  runApp(const MyApp());
}

Future<void> _initializeFirebaseServices() async {
  // Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Firebase In-App Messaging
  await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(true);

  // Firebase Cloud Messaging
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Directly return the appropriate page instead of using navigation
        if (snapshot.hasData) {
          return MainPage(
            isDarkMode: false, // Will be overridden by actual state
            fontSize: 16.0,
            fontStyle: 'Roboto',
            textAlign: TextAlign.left,
            onToggleTheme: () {},
            onFontSizeChange: (_) {},
            onFontStyleChange: (_) {},
            onTextAlignChange: (_) {},
          );
        } else {
          return AuthPage(
            isDarkMode: false,
            onToggleTheme: () {},
          );
        }
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  double fontSize = 16.0;
  String fontStyle = 'Roboto';
  TextAlign textAlign = TextAlign.left;

  final PreferencesService _preferencesService = PreferencesService();
  final FirebaseService _firebaseService = FirebaseService();

  // Firebase Analytics
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _setupFirebaseMessaging();
  }

  Future<void> _loadPreferences() async {
    final darkMode = await _preferencesService.getThemeMode();
    final fSize = await _preferencesService.getFontSize();
    final fStyle = await _preferencesService.getFontStyle();
    final tAlign = await _preferencesService.getTextAlign();

    setState(() {
      isDarkMode = darkMode;
      fontSize = fSize;
      fontStyle = fStyle;
      textAlign = tAlign;
    });
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground message
      if (message.notification != null && mounted) {
        _showNotificationSnackBar(message.notification!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle message tap
      _handleMessageTap(message);
    });
  }

  void _showNotificationSnackBar(RemoteNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.body}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    // Navigate based on message data
    final data = message.data;
    if (data.containsKey('song_number')) {
      // Navigate to specific song
    }
  }

  void _updateThemeMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _preferencesService.saveThemeMode(isDarkMode);

    // Analytics
    analytics.logEvent(
      name: 'theme_changed',
      parameters: {'is_dark_mode': isDarkMode},
    );
  }

  void _updateFontSize(double? size) {
    if (size != null) {
      setState(() {
        fontSize = size;
      });
      _preferencesService.saveFontSize(fontSize);
    }
  }

  void _updateFontStyle(String? style) {
    if (style != null) {
      setState(() {
        fontStyle = style;
      });
      _preferencesService.saveFontStyle(fontStyle);
    }
  }

  void _updateTextAlign(TextAlign? align) {
    if (align != null) {
      setState(() {
        textAlign = align;
      });
      _preferencesService.saveTextAlign(textAlign);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lagu Pujian Masa Ini',
      navigatorObservers: <NavigatorObserver>[observer],
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDarkMode ? Colors.black87 : Colors.grey[100],
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize, fontFamily: fontStyle),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => MainPage(
              isDarkMode: isDarkMode,
              fontSize: fontSize,
              fontStyle: fontStyle,
              textAlign: textAlign,
              onToggleTheme: _updateThemeMode,
              onFontSizeChange: _updateFontSize,
              onFontStyleChange: _updateFontStyle,
              onTextAlignChange: _updateTextAlign,
            ),
        '/auth': (context) => AuthPage(
              isDarkMode: isDarkMode,
              onToggleTheme: _updateThemeMode,
            ),
      },
    );
  }
}
