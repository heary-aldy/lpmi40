// lib/src/core/services/fcm_service.dart
// 🔔 FIREBASE CLOUD MESSAGING (FCM) SERVICE
// 🎯 FEATURES: Push notifications, token management, message handling
// 🛡️ SECURE: Handles permissions and background notifications

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/firebase_database_service.dart';

class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  FCMService._();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabaseService _databaseService =
      FirebaseDatabaseService.instance;

  // Token and state management
  String? _fcmToken;
  bool _isInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Local storage keys
  static const String _fcmTokenKey = 'fcm_token';
  static const String _lastTokenUpdateKey = 'last_token_update';

  // ============================================================================
  // 🚀 INITIALIZATION
  // ============================================================================

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      debugPrint('[FCM] 🚀 Initializing Firebase Cloud Messaging...');

      // Request notification permissions
      await _requestPermissions();

      // Get initial token
      await _getToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _setupTokenRefreshListener();

      // Subscribe to global topics
      await _subscribeToTopics();

      _isInitialized = true;
      debugPrint('[FCM] ✅ Firebase Cloud Messaging initialized successfully');
    } catch (e) {
      debugPrint('[FCM] ❌ Failed to initialize FCM: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      debugPrint('[FCM] 📱 Requesting notification permissions...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] 🔐 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] ✅ Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('[FCM] ⚠️ Provisional notification permissions granted');
      } else {
        debugPrint('[FCM] ❌ Notification permissions denied');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error requesting permissions: $e');
    }
  }

  // ============================================================================
  // 🔑 TOKEN MANAGEMENT
  // ============================================================================

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      debugPrint('[FCM] 🔑 Getting FCM token...');

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveTokenLocally(token);
        await _saveTokenToFirebase(token);
        debugPrint('[FCM] ✅ FCM token obtained: ${token.substring(0, 20)}...');
        return token;
      } else {
        debugPrint('[FCM] ⚠️ No FCM token received');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save token locally for offline access
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setInt(
          _lastTokenUpdateKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('[FCM] 💾 Token saved locally');
    } catch (e) {
      debugPrint('[FCM] ❌ Error saving token locally: $e');
    }
  }

  /// Save token to Firebase for server-side notifications
  Future<void> _saveTokenToFirebase(String token) async {
    try {
      // Import Firebase Auth to get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[FCM] ⚠️ No authenticated user, skipping Firebase token save');
        return;
      }

      final database = await _databaseService.database;
      if (database == null) {
        debugPrint(
            '[FCM] ⚠️ Database not available, skipping Firebase token save');
        return;
      }

      // Create device info
      final deviceInfo = {
        'token': token,
        'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
        'updated_at': DateTime.now().toIso8601String(),
        'app_version': '2.2.0', // You can get this from package_info_plus
        'is_active': true,
        'user_id': user.uid,
      };

      // Save under user-specific path to ensure proper permissions
      final deviceId = token.substring(0, 12); // Use first 12 chars as device ID
      await database.ref('users/${user.uid}/fcm_tokens/$deviceId').set(deviceInfo);

      debugPrint('[FCM] ☁️ Token saved to Firebase under user/${user.uid}/fcm_tokens/$deviceId');
    } catch (e) {
      debugPrint('[FCM] ❌ Error saving token to Firebase: $e');
      // Don't throw the error, just log it - FCM can work without saving to Firebase
    }
  }

  /// Set up token refresh listener
  void _setupTokenRefreshListener() {
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('[FCM] 🔄 Token refreshed: ${newToken.substring(0, 20)}...');
        _fcmToken = newToken;
        await _saveTokenLocally(newToken);
        await _saveTokenToFirebase(newToken);
      },
      onError: (error) {
        debugPrint('[FCM] ❌ Token refresh error: $error');
      },
    );
  }

  // ============================================================================
  // 📨 MESSAGE HANDLING
  // ============================================================================

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    debugPrint('[FCM] 📨 Setting up message handlers...');

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is opened from terminated state
    _handleInitialMessage();
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] 📱 Foreground message received: ${message.messageId}');
    debugPrint('[FCM] 📄 Title: ${message.notification?.title}');
    debugPrint('[FCM] 📄 Body: ${message.notification?.body}');
    debugPrint('[FCM] 📊 Data: ${message.data}');

    // Check if it's a global update notification
    if (message.data['type'] == 'global_update') {
      _handleGlobalUpdateNotification(message);
    } else {
      _showLocalNotification(message);
    }
  }

  /// Handle messages when app is opened from background
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('[FCM] 🔙 Background message opened: ${message.messageId}');
    debugPrint('[FCM] 📊 Data: ${message.data}');

    // Handle based on message type
    if (message.data['type'] == 'global_update') {
      _handleGlobalUpdateNotification(message);
    }
  }

  /// Handle initial message when app is opened from terminated state
  void _handleInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] 🚀 Initial message: ${initialMessage.messageId}');
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error handling initial message: $e');
    }
  }

  /// Handle global update notifications specifically
  void _handleGlobalUpdateNotification(RemoteMessage message) {
    debugPrint('[FCM] 🌐 Global update notification received');

    // Extract update information from message data
    final version = message.data['version'] ?? '';
    final updateMessage = message.data['message'] ?? '';
    final forceUpdate = message.data['force_update'] == 'true';

    // You can trigger the global update service here
    // or show a custom dialog
    _showGlobalUpdateDialog(version, updateMessage, forceUpdate);
  }

  /// Show local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    // You can implement local notification display here
    // For now, just log the message
    debugPrint(
        '[FCM] 🔔 Would show local notification: ${message.notification?.title}');
  }

  /// Show global update dialog
  void _showGlobalUpdateDialog(
      String version, String message, bool forceUpdate) {
    // This would need a BuildContext, so you might want to use a global navigator key
    // or implement this in your main app widget
    debugPrint('[FCM] 🔄 Global update available: $version');
    debugPrint('[FCM] 📝 Message: $message');
    debugPrint('[FCM] ⚠️ Force update: $forceUpdate');
  }

  // ============================================================================
  // 📡 TOPIC SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to global topics for app-wide notifications
  Future<void> _subscribeToTopics() async {
    try {
      debugPrint('[FCM] 📡 Subscribing to topics...');

      // Subscribe to global update topic
      await _firebaseMessaging.subscribeToTopic('global_updates');
      debugPrint('[FCM] ✅ Subscribed to global_updates topic');

      // Subscribe to platform-specific topic
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      await _firebaseMessaging.subscribeToTopic('platform_$platform');
      debugPrint('[FCM] ✅ Subscribed to platform_$platform topic');

      // Subscribe to app version topic (for version-specific updates)
      await _firebaseMessaging.subscribeToTopic('version_2_2_0');
      debugPrint('[FCM] ✅ Subscribed to version_2_2_0 topic');
    } catch (e) {
      debugPrint('[FCM] ❌ Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from topics (useful for cleanup)
  Future<void> unsubscribeFromTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('global_updates');
      await _firebaseMessaging.unsubscribeFromTopic(
          'platform_${Platform.isIOS ? 'ios' : 'android'}');
      await _firebaseMessaging.unsubscribeFromTopic('version_2_2_0');
      debugPrint('[FCM] ✅ Unsubscribed from all topics');
    } catch (e) {
      debugPrint('[FCM] ❌ Error unsubscribing from topics: $e');
    }
  }

  // ============================================================================
  // 🔧 UTILITY METHODS
  // ============================================================================

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Get token from local storage
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('[FCM] ❌ Error getting stored token: $e');
      return null;
    }
  }

  /// Refresh FCM token manually
  Future<String?> refreshToken() async {
    try {
      debugPrint('[FCM] 🔄 Manually refreshing FCM token...');
      await _firebaseMessaging.deleteToken();
      return await _getToken();
    } catch (e) {
      debugPrint('[FCM] ❌ Error refreshing token: $e');
      return null;
    }
  }

  /// Get FCM service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _fcmToken != null,
      'tokenPreview': _fcmToken?.substring(0, 20) ?? 'No token',
    };
  }

  /// Dispose of resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}

// ============================================================================
// 🔥 BACKGROUND MESSAGE HANDLER (REQUIRED FOR FCM)
// ============================================================================

/// Top-level function to handle background messages
/// This must be a top-level function, not inside a class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] 🔥 Background message received: ${message.messageId}');
  debugPrint('[FCM] 📄 Title: ${message.notification?.title}');
  debugPrint('[FCM] 📄 Body: ${message.notification?.body}');
  debugPrint('[FCM] 📊 Data: ${message.data}');

  // Handle background message processing here
  // You can save to local storage, trigger local notifications, etc.
}
