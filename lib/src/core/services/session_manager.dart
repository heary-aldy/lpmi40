// lib/src/core/services/session_manager.dart
// 🔐 User Session Management for Premium Users and Device-based Access
// ✅ Secure, persistent, offline-capable session storage

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

/// User session data model
class UserSession {
  final String? userId;
  final String? email;
  final String userRole;
  final bool isPremium;
  final bool hasAudioAccess;
  final DateTime? premiumExpiryDate;
  final DateTime sessionCreatedAt;
  final DateTime sessionExpiresAt;
  final String deviceId;
  final Map<String, dynamic> permissions;

  UserSession({
    this.userId,
    this.email,
    this.userRole = 'guest',
    this.isPremium = false,
    this.hasAudioAccess = false,
    this.premiumExpiryDate,
    required this.sessionCreatedAt,
    required this.sessionExpiresAt,
    required this.deviceId,
    this.permissions = const {},
  });

  factory UserSession.guest(String deviceId) {
    final now = DateTime.now();
    return UserSession(
      userRole: 'guest',
      isPremium: false,
      hasAudioAccess: false,
      sessionCreatedAt: now,
      sessionExpiresAt: now.add(const Duration(days: 30)), // Guest sessions last 30 days
      deviceId: deviceId,
      permissions: {
        'canAccessPublicCollections': true,
        'canSaveFavorites': false,
        'canAccessAudio': false,
        'canAccessPremiumContent': false,
      },
    );
  }

  factory UserSession.registered({
    required String userId,
    required String email,
    required String deviceId,
    String userRole = 'user',
    bool isPremium = false,
    DateTime? premiumExpiryDate,
  }) {
    final now = DateTime.now();
    return UserSession(
      userId: userId,
      email: email,
      userRole: userRole,
      isPremium: isPremium,
      hasAudioAccess: isPremium || userRole == 'admin' || userRole == 'super_admin',
      premiumExpiryDate: premiumExpiryDate,
      sessionCreatedAt: now,
      sessionExpiresAt: now.add(const Duration(days: 90)), // Registered sessions last 90 days
      deviceId: deviceId,
      permissions: {
        'canAccessPublicCollections': true,
        'canSaveFavorites': true,
        'canAccessAudio': isPremium || userRole == 'admin' || userRole == 'super_admin',
        'canAccessPremiumContent': isPremium,
        'canAccessRegisteredContent': true,
        'canAccessAdminFeatures': userRole == 'admin' || userRole == 'super_admin',
        'canManageUsers': userRole == 'super_admin',
      },
    );
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'],
      email: json['email'],
      userRole: json['userRole'] ?? 'guest',
      isPremium: json['isPremium'] ?? false,
      hasAudioAccess: json['hasAudioAccess'] ?? false,
      premiumExpiryDate: json['premiumExpiryDate'] != null 
        ? DateTime.parse(json['premiumExpiryDate']) 
        : null,
      sessionCreatedAt: DateTime.parse(json['sessionCreatedAt']),
      sessionExpiresAt: DateTime.parse(json['sessionExpiresAt']),
      deviceId: json['deviceId'] ?? '',
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'userRole': userRole,
      'isPremium': isPremium,
      'hasAudioAccess': hasAudioAccess,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'sessionCreatedAt': sessionCreatedAt.toIso8601String(),
      'sessionExpiresAt': sessionExpiresAt.toIso8601String(),
      'deviceId': deviceId,
      'permissions': permissions,
    };
  }

  bool get isExpired => DateTime.now().isAfter(sessionExpiresAt);
  bool get isPremiumExpired => premiumExpiryDate != null && DateTime.now().isAfter(premiumExpiryDate!);
  bool get isGuest => userRole == 'guest';
  bool get isRegistered => userId != null && !isGuest;
  bool get isAdmin => userRole == 'admin' || userRole == 'super_admin';

  bool hasPermission(String permission) {
    return permissions[permission] == true;
  }
}

/// Session manager for handling user sessions across app restarts
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();

  static const String _sessionKey = 'user_session_v2';
  static const String _deviceIdKey = 'device_id_v2';
  static const String _premiumSessionKey = 'premium_session_cache';

  UserSession? _currentSession;
  String? _deviceId;

  // ============================================================================
  // SESSION INITIALIZATION & MANAGEMENT
  // ============================================================================

  /// Initialize session manager and restore session
  Future<UserSession> initialize() async {
    try {
      debugPrint('[SessionManager] 🚀 Initializing session manager...');
      
      // Generate or retrieve device ID
      _deviceId = await _getOrCreateDeviceId();
      debugPrint('[SessionManager] 📱 Device ID: $_deviceId');

      // Try to restore existing session
      final restoredSession = await _restoreSession();
      if (restoredSession != null && !restoredSession.isExpired) {
        _currentSession = restoredSession;
        debugPrint('[SessionManager] ✅ Restored valid session: ${restoredSession.userRole}');
        return restoredSession;
      }

      // Create guest session if no valid session exists
      final guestSession = UserSession.guest(_deviceId!);
      _currentSession = guestSession;
      await _saveSession(guestSession);
      
      debugPrint('[SessionManager] 👤 Created new guest session');
      return guestSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error initializing: $e');
      
      // Fallback to guest session
      final fallbackSession = UserSession.guest(_deviceId ?? 'unknown');
      _currentSession = fallbackSession;
      return fallbackSession;
    }
  }

  /// Create session for logged-in user
  Future<UserSession> createUserSession({
    required String userId,
    required String email,
    String userRole = 'user',
    bool isPremium = false,
    DateTime? premiumExpiryDate,
  }) async {
    try {
      debugPrint('[SessionManager] 👥 Creating user session for: $email');
      
      final session = UserSession.registered(
        userId: userId,
        email: email,
        deviceId: _deviceId ?? await _getOrCreateDeviceId(),
        userRole: userRole,
        isPremium: isPremium,
        premiumExpiryDate: premiumExpiryDate,
      );

      _currentSession = session;
      await _saveSession(session);
      
      debugPrint('[SessionManager] ✅ User session created: $userRole${isPremium ? ' (Premium)' : ''}');
      return session;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error creating user session: $e');
      rethrow;
    }
  }

  /// Grant premium access to current session
  Future<UserSession?> grantPremiumAccess({
    DateTime? expiryDate,
    String type = 'premium',
  }) async {
    try {
      if (_currentSession == null) {
        debugPrint('[SessionManager] ⚠️ No active session to grant premium access');
        return null;
      }

      debugPrint('[SessionManager] ⭐ Granting premium access...');

      // Create updated session with premium access
      final updatedSession = UserSession.registered(
        userId: _currentSession!.userId ?? 'premium_${_deviceId}',
        email: _currentSession!.email ?? 'premium_user@device.local',
        deviceId: _currentSession!.deviceId,
        userRole: _currentSession!.userRole == 'guest' ? 'premium' : _currentSession!.userRole,
        isPremium: true,
        premiumExpiryDate: expiryDate,
      );

      _currentSession = updatedSession;
      await _saveSession(updatedSession);
      
      // Cache premium session separately for extra persistence
      await _cachePremiumSession(updatedSession);
      
      debugPrint('[SessionManager] ✅ Premium access granted until: ${expiryDate ?? 'indefinite'}');
      return updatedSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error granting premium access: $e');
      return null;
    }
  }

  /// Logout and clear session
  Future<UserSession> logout() async {
    try {
      debugPrint('[SessionManager] 👋 Logging out user...');
      
      // Create new guest session
      final guestSession = UserSession.guest(_deviceId ?? await _getOrCreateDeviceId());
      _currentSession = guestSession;
      
      // Clear stored session
      await _clearSession();
      await _saveSession(guestSession);
      
      debugPrint('[SessionManager] ✅ Logged out, reverted to guest session');
      return guestSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error during logout: $e');
      // Return fallback guest session
      final fallbackSession = UserSession.guest(_deviceId ?? 'unknown');
      _currentSession = fallbackSession;
      return fallbackSession;
    }
  }

  /// Refresh session from Firebase if user is logged in
  Future<UserSession?> refreshFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[SessionManager] ℹ️ No Firebase user for refresh');
        return _currentSession;
      }

      debugPrint('[SessionManager] 🔄 Refreshing session from Firebase...');
      
      // TODO: Fetch user role and premium status from Firebase Database
      // This would integrate with your existing user management system
      
      return _currentSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error refreshing from Firebase: $e');
      return _currentSession;
    }
  }

  // ============================================================================
  // SESSION ACCESS METHODS
  // ============================================================================

  /// Get current session (never null)
  UserSession get currentSession {
    return _currentSession ?? UserSession.guest(_deviceId ?? 'unknown');
  }

  /// Check if user has premium access
  bool get isPremium {
    final session = currentSession;
    return session.isPremium && !session.isPremiumExpired;
  }

  /// Check if user can access audio features
  bool get canAccessAudio {
    return currentSession.hasAudioAccess && !currentSession.isPremiumExpired;
  }

  /// Check if user can save favorites
  bool get canSaveFavorites {
    return currentSession.hasPermission('canSaveFavorites');
  }

  /// Check specific permission
  bool hasPermission(String permission) {
    return currentSession.hasPermission(permission);
  }

  /// Get user role
  String get userRole => currentSession.userRole;

  /// Get user email
  String? get userEmail => currentSession.email;

  // ============================================================================
  // DEVICE-SPECIFIC PREMIUM ACCESS
  // ============================================================================

  /// Grant temporary premium access for this device only
  Future<UserSession?> grantDevicePremiumAccess({
    Duration duration = const Duration(days: 30),
    String reason = 'Device premium access',
  }) async {
    try {
      debugPrint('[SessionManager] 📱 Granting device-specific premium access...');
      
      final expiryDate = DateTime.now().add(duration);
      final session = await grantPremiumAccess(
        expiryDate: expiryDate,
        type: 'device_premium',
      );
      
      if (session != null) {
        // Store device premium info for tracking
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_premium_reason', reason);
        await prefs.setString('device_premium_granted', DateTime.now().toIso8601String());
        
        debugPrint('[SessionManager] ✅ Device premium access granted for ${duration.inDays} days');
      }
      
      return session;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error granting device premium: $e');
      return null;
    }
  }

  /// Check if device has cached premium access
  Future<bool> checkCachedPremiumAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSessionJson = prefs.getString(_premiumSessionKey);
      
      if (cachedSessionJson != null) {
        final cachedSession = UserSession.fromJson(jsonDecode(cachedSessionJson));
        
        if (cachedSession.isPremium && !cachedSession.isPremiumExpired) {
          debugPrint('[SessionManager] ⭐ Found valid cached premium access');
          _currentSession = cachedSession;
          await _saveSession(cachedSession);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error checking cached premium: $e');
      return false;
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Generate or retrieve device ID
  Future<String> _getOrCreateDeviceId() async {
    try {
      if (_deviceId != null) return _deviceId!;
      
      final prefs = await SharedPreferences.getInstance();
      String? existingId = prefs.getString(_deviceIdKey);
      
      if (existingId != null && existingId.isNotEmpty) {
        _deviceId = existingId;
        return existingId;
      }
      
      // Generate new device ID
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomString = DateTime.now().toIso8601String();
      final combined = '$timestamp-$randomString';
      final bytes = utf8.encode(combined);
      final hash = sha256.convert(bytes);
      
      final newDeviceId = 'device_${hash.toString().substring(0, 16)}';
      
      await prefs.setString(_deviceIdKey, newDeviceId);
      _deviceId = newDeviceId;
      
      debugPrint('[SessionManager] 🆔 Generated new device ID: $newDeviceId');
      return newDeviceId;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error creating device ID: $e');
      return 'device_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Save session to persistent storage
  Future<void> _saveSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = jsonEncode(session.toJson());
      await prefs.setString(_sessionKey, sessionJson);
      
      debugPrint('[SessionManager] 💾 Session saved: ${session.userRole}');
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error saving session: $e');
    }
  }

  /// Restore session from persistent storage
  Future<UserSession?> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      
      if (sessionJson != null) {
        final session = UserSession.fromJson(jsonDecode(sessionJson));
        debugPrint('[SessionManager] 📱 Restored session: ${session.userRole}');
        return session;
      }
      
      return null;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error restoring session: $e');
      return null;
    }
  }

  /// Clear session from storage
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_premiumSessionKey);
      
      debugPrint('[SessionManager] 🗑️ Session cleared');
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error clearing session: $e');
    }
  }

  /// Cache premium session for extra persistence
  Future<void> _cachePremiumSession(UserSession session) async {
    try {
      if (!session.isPremium) return;
      
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = jsonEncode(session.toJson());
      await prefs.setString(_premiumSessionKey, sessionJson);
      
      debugPrint('[SessionManager] ⭐ Premium session cached');
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error caching premium session: $e');
    }
  }
}