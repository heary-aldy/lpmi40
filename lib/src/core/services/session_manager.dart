// lib/src/core/services/session_manager.dart
// 🔐 User Session Management for Premium Users and Device-based Access
// ✅ Secure, persistent, offline-capable session storage

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final String deviceType; // 'phone', 'tablet', 'web'
  final String deviceInfo; // Additional device information
  final Map<String, dynamic> permissions;
  final bool isTrialUser;
  final DateTime? trialStartedAt;
  final String? trialType;

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
    this.deviceType = 'unknown',
    this.deviceInfo = '',
    this.permissions = const {},
    this.isTrialUser = false,
    this.trialStartedAt,
    this.trialType,
  });

  factory UserSession.guest(String deviceId, [String? deviceType, String? deviceInfo]) {
    final now = DateTime.now();
    return UserSession(
      userRole: 'guest',
      isPremium: false,
      hasAudioAccess: false,
      sessionCreatedAt: now,
      sessionExpiresAt:
          now.add(const Duration(days: 30)), // Guest sessions last 30 days
      deviceId: deviceId,
      deviceType: deviceType ?? _detectDeviceType(),
      deviceInfo: deviceInfo ?? _getDeviceInfo(),
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
    bool isTrialUser = false,
    DateTime? trialStartedAt,
    String? trialType,
    String? deviceType,
    String? deviceInfo,
  }) {
    final now = DateTime.now();
    return UserSession(
      userId: userId,
      email: email,
      userRole: userRole,
      isPremium: isPremium,
      hasAudioAccess:
          isPremium || userRole == 'admin' || userRole == 'super_admin',
      premiumExpiryDate: premiumExpiryDate,
      sessionCreatedAt: now,
      sessionExpiresAt:
          now.add(const Duration(days: 90)), // Registered sessions last 90 days
      deviceId: deviceId,
      deviceType: deviceType ?? _detectDeviceType(),
      deviceInfo: deviceInfo ?? _getDeviceInfo(),
      isTrialUser: isTrialUser,
      trialStartedAt: trialStartedAt,
      trialType: trialType,
      permissions: {
        'canAccessPublicCollections': true,
        'canSaveFavorites': true,
        'canAccessAudio':
            isPremium || userRole == 'admin' || userRole == 'super_admin',
        'canAccessPremiumContent': isPremium,
        'canAccessRegisteredContent': true,
        'canAccessAdminFeatures':
            userRole == 'admin' || userRole == 'super_admin',
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
      deviceType: json['deviceType'] ?? 'unknown',
      deviceInfo: json['deviceInfo'] ?? '',
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      isTrialUser: json['isTrialUser'] ?? false,
      trialStartedAt: json['trialStartedAt'] != null
          ? DateTime.parse(json['trialStartedAt'])
          : null,
      trialType: json['trialType'],
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
      'deviceType': deviceType,
      'deviceInfo': deviceInfo,
      'permissions': permissions,
      'isTrialUser': isTrialUser,
      'trialStartedAt': trialStartedAt?.toIso8601String(),
      'trialType': trialType,
    };
  }

  bool get isExpired => DateTime.now().isAfter(sessionExpiresAt);
  bool get isPremiumExpired =>
      premiumExpiryDate != null && DateTime.now().isAfter(premiumExpiryDate!);
  bool get isGuest => userRole == 'guest';
  bool get isRegistered => userId != null && !isGuest;
  bool get isAdmin => userRole == 'admin' || userRole == 'super_admin';

  // Trial-related getters
  bool get isTrialExpired {
    if (!isTrialUser || trialStartedAt == null) return false;
    final trialDuration = trialType == 'week_trial'
        ? const Duration(days: 7)
        : const Duration(days: 1);
    return DateTime.now().isAfter(trialStartedAt!.add(trialDuration));
  }

  bool get hasActiveTrial => isTrialUser && !isTrialExpired;

  Duration? get remainingTrialTime {
    if (!isTrialUser || trialStartedAt == null || isTrialExpired) return null;
    final trialDuration = trialType == 'week_trial'
        ? const Duration(days: 7)
        : const Duration(days: 1);
    final trialEnd = trialStartedAt!.add(trialDuration);
    return trialEnd.difference(DateTime.now());
  }

  bool get hasTrialAccess => hasActiveTrial || isPremium;

  bool hasPermission(String permission) {
    return permissions[permission] == true;
  }

  // Device type detection helpers
  static String _detectDeviceType() {
    if (kIsWeb) {
      return 'web';
    }
    
    // Import device_info_plus if available, otherwise use screen size detection
    try {
      // On mobile platforms, use screen size as a heuristic
      // This is a fallback - ideally use device_info_plus package
      return 'phone'; // Default to phone, can be enhanced with device_info_plus
    } catch (e) {
      return 'unknown';
    }
  }

  static String _getDeviceInfo() {
    if (kIsWeb) {
      return 'Web Browser';
    }
    
    try {
      // This could be enhanced with device_info_plus to get actual device model
      return 'Mobile Device';
    } catch (e) {
      return 'Unknown Device';
    }
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
  static const String _trialHistoryKey = 'trial_history_v1';
  static const String _trialEligibilityKey = 'trial_eligibility_v1';
  
  // Device session limits for Premium users
  static const int _maxPhoneSessions = 1;
  static const int _maxTabletSessions = 1;
  static const int _maxWebSessions = 1;

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
        debugPrint(
            '[SessionManager] ✅ Restored valid session: ${restoredSession.userRole}');
        return restoredSession;
      }

      // Create guest session if no valid session exists
      final guestSession = UserSession.guest(_deviceId!, UserSession._detectDeviceType(), UserSession._getDeviceInfo());
      _currentSession = guestSession;
      await _saveSession(guestSession);

      debugPrint('[SessionManager] 👤 Created new guest session');
      return guestSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error initializing: $e');

      // Fallback to guest session
      final fallbackSession = UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());
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

      final deviceId = _deviceId ?? await _getOrCreateDeviceId();
      final deviceType = UserSession._detectDeviceType();
      final deviceInfo = UserSession._getDeviceInfo();

      // Check device limits for Premium users
      if (isPremium) {
        final canCreateSession = await _checkDeviceLimits(userId, deviceType);
        if (!canCreateSession) {
          throw Exception('Device limit exceeded for Premium user. Maximum allowed: 1 phone, 1 tablet, 1 web.');
        }
      }

      final session = UserSession.registered(
        userId: userId,
        email: email,
        deviceId: deviceId,
        userRole: userRole,
        isPremium: isPremium,
        premiumExpiryDate: premiumExpiryDate,
        deviceType: deviceType,
        deviceInfo: deviceInfo,
      );

      _currentSession = session;
      await _saveSession(session);

      // Store session in Firebase for device limit tracking
      if (isPremium) {
        await _storeSessionInFirebase(session);
      }

      debugPrint(
          '[SessionManager] ✅ User session created: $userRole${isPremium ? ' (Premium)' : ''} on $deviceType');
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
        debugPrint(
            '[SessionManager] ⚠️ No active session to grant premium access');
        return null;
      }

      debugPrint('[SessionManager] ⭐ Granting premium access...');

      // Create updated session with premium access
      final updatedSession = UserSession.registered(
        userId: _currentSession!.userId ?? 'premium_$_deviceId',
        email: _currentSession!.email ?? 'premium_user@device.local',
        deviceId: _currentSession!.deviceId,
        userRole: _currentSession!.userRole == 'guest'
            ? 'premium'
            : _currentSession!.userRole,
        isPremium: true,
        premiumExpiryDate: expiryDate,
      );

      _currentSession = updatedSession;
      await _saveSession(updatedSession);

      // Cache premium session separately for extra persistence
      await _cachePremiumSession(updatedSession);

      debugPrint(
          '[SessionManager] ✅ Premium access granted until: ${expiryDate ?? 'indefinite'}');
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
      final deviceId = _deviceId ?? await _getOrCreateDeviceId();
      final guestSession =
          UserSession.guest(deviceId, UserSession._detectDeviceType(), UserSession._getDeviceInfo());
      _currentSession = guestSession;

      // Clear stored session
      await _clearSession();
      await _saveSession(guestSession);

      debugPrint('[SessionManager] ✅ Logged out, reverted to guest session');
      return guestSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error during logout: $e');
      // Return fallback guest session
      final fallbackSession = UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());
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
    return _currentSession ?? UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());
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
  // USER-TRIGGERED TRIAL SYSTEM
  // ============================================================================

  /// Check if user is eligible for a trial
  Future<bool> isTrialEligible() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialHistory = prefs.getStringList(_trialHistoryKey) ?? [];
      final deviceId = _deviceId ?? await _getOrCreateDeviceId();

      // Check if this device has already used a trial
      final hasUsedTrial = trialHistory.contains('${deviceId}_week_trial');

      debugPrint(
          '[SessionManager] 🔍 Trial eligibility check: ${!hasUsedTrial}');
      return !hasUsedTrial;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error checking trial eligibility: $e');
      return false; // Conservative approach - don't allow if we can't verify
    }
  }

  /// Start a 1-week premium trial for the user
  Future<UserSession?> startWeeklyTrial() async {
    try {
      debugPrint('[SessionManager] 🎯 Starting 1-week premium trial...');

      // Log trial request to Firebase for admin tracking
      await _logTrialRequest('week_trial', 'user_initiated');

      // Check eligibility first
      final isEligible = await isTrialEligible();
      if (!isEligible) {
        debugPrint('[SessionManager] ❌ User not eligible for trial');
        return null;
      }

      final now = DateTime.now();
      final currentSession =
          _currentSession ?? UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());

      // Create trial session
      final trialSession = UserSession.registered(
        userId: currentSession.userId ?? 'trial_$_deviceId',
        email: currentSession.email ?? 'trial_user@device.local',
        deviceId: currentSession.deviceId,
        userRole: currentSession.userRole == 'guest'
            ? 'trial'
            : currentSession.userRole,
        isPremium: true, // Grant premium access during trial
        premiumExpiryDate: now.add(const Duration(days: 7)), // 1 week trial
        isTrialUser: true,
        trialStartedAt: now,
        trialType: 'week_trial',
      );

      _currentSession = trialSession;
      await _saveSession(trialSession);

      // Record trial usage to prevent future trials
      await _recordTrialUsage('week_trial');

      // Update trial request status to 'activated'
      await _updateTrialRequestStatus('activated');

      debugPrint('[SessionManager] ✅ 1-week trial started successfully');
      return trialSession;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error starting weekly trial: $e');
      return null;
    }
  }

  /// Record that a trial has been used on this device
  Future<void> _recordTrialUsage(String trialType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialHistory = prefs.getStringList(_trialHistoryKey) ?? [];
      final deviceId = _deviceId ?? await _getOrCreateDeviceId();

      final trialRecord = '${deviceId}_$trialType';
      if (!trialHistory.contains(trialRecord)) {
        trialHistory.add(trialRecord);
        await prefs.setStringList(_trialHistoryKey, trialHistory);

        // Also record the timestamp
        await prefs.setString(
            '${trialRecord}_timestamp', DateTime.now().toIso8601String());

        debugPrint('[SessionManager] 📝 Trial usage recorded: $trialRecord');
      }
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error recording trial usage: $e');
    }
  }

  /// Get trial information for display
  Map<String, dynamic> getTrialInfo() {
    final session = currentSession;

    // Auto-update trial request status to 'expired' if trial just expired
    if (session.isTrialUser && session.isTrialExpired) {
      _updateTrialRequestStatusIfNeeded('expired');
    }

    return {
      'isTrialUser': session.isTrialUser,
      'trialType': session.trialType ?? 'none',
      'trialStartedAt': session.trialStartedAt?.toIso8601String(),
      'hasActiveTrial': session.hasActiveTrial,
      'isTrialExpired': session.isTrialExpired,
      'remainingTrialDays': session.remainingTrialTime?.inDays ?? 0,
      'remainingTrialHours': session.remainingTrialTime?.inHours ?? 0,
      'hasTrialAccess': session.hasTrialAccess,
      'trialEndedAt': session.isTrialExpired && session.trialStartedAt != null
          ? session.trialStartedAt!
              .add(const Duration(days: 7))
              .toIso8601String()
          : null,
    };
  }

  /// Update trial request status if needed (avoid spam updates)
  void _updateTrialRequestStatusIfNeeded(String status) {
    // Only update once per app session to avoid spamming Firebase
    if (!_hasUpdatedTrialStatusThisSession) {
      _hasUpdatedTrialStatusThisSession = true;
      _updateTrialRequestStatus(status).catchError((e) {
        debugPrint(
            '[SessionManager] ❌ Error updating trial status on expiration: $e');
      });
    }
  }

  static bool _hasUpdatedTrialStatusThisSession = false;

  /// Check if trial is expiring soon (for warnings)
  bool get isTrialExpiringSoon {
    final session = currentSession;
    if (!session.isTrialUser || session.isTrialExpired) return false;

    final remainingTime = session.remainingTrialTime;
    if (remainingTime == null) return false;

    // Show warning when less than 24 hours remain
    return remainingTime.inHours <= 24;
  }

  /// Get trial expiration warning message
  String? get trialExpirationWarning {
    final session = currentSession;
    if (!session.isTrialUser ||
        session.isTrialExpired ||
        !isTrialExpiringSoon) {
      return null;
    }

    final remainingTime = session.remainingTrialTime;
    if (remainingTime == null) return null;

    if (remainingTime.inHours <= 1) {
      return '⏰ Your premium trial expires in less than 1 hour!';
    } else if (remainingTime.inHours <= 24) {
      return '⏰ Your premium trial expires in ${remainingTime.inHours} hours!';
    }

    return null;
  }

  /// Log trial request to Firebase for admin tracking
  Future<void> _logTrialRequest(String trialType, String source) async {
    try {
      final currentSession =
          _currentSession ?? UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());
      final now = DateTime.now();

      final trialRequestId =
          '${currentSession.deviceId}_${now.millisecondsSinceEpoch}';

      final trialRequestData = {
        'requestId': trialRequestId,
        'userId': currentSession.userId,
        'email': currentSession.email,
        'deviceId': currentSession.deviceId,
        'userRole': currentSession.userRole,
        'trialType': trialType,
        'source': source, // 'user_initiated', 'admin_granted', etc.
        'status': 'requested',
        'requestedAt': now.toIso8601String(),
        'requestedAtTimestamp': now.millisecondsSinceEpoch,
      };

      // Store in Firebase under admin-protected 'admin/trial_requests' node
      final database = FirebaseDatabase.instance;
      final trialRequestsRef = database.ref('admin/trial_requests/$trialRequestId');
      await trialRequestsRef.set(trialRequestData);

      debugPrint('[SessionManager] 📝 Trial request logged: $trialRequestId');
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error logging trial request: $e');
      // Don't throw - logging failure shouldn't block trial
    }
  }

  /// Update trial request status
  Future<void> _updateTrialRequestStatus(String status) async {
    try {
      final currentSession =
          _currentSession ?? UserSession.guest(_deviceId ?? 'unknown', UserSession._detectDeviceType(), UserSession._getDeviceInfo());

      // Find the most recent trial request for this device
      final database = FirebaseDatabase.instance;
      final trialRequestsRef = database.ref('admin/trial_requests');

      final query = trialRequestsRef
          .orderByChild('deviceId')
          .equalTo(currentSession.deviceId);

      final snapshot = await query.get();

      if (snapshot.exists) {
        final requests = Map<String, dynamic>.from(snapshot.value as Map);

        // Find the most recent request
        String? latestRequestId;
        int latestTimestamp = 0;

        requests.forEach((requestId, requestData) {
          final data = Map<String, dynamic>.from(requestData);
          final timestamp = data['requestedAtTimestamp'] ?? 0;
          if (timestamp > latestTimestamp) {
            latestTimestamp = timestamp;
            latestRequestId = requestId;
          }
        });

        if (latestRequestId != null) {
          await trialRequestsRef.child(latestRequestId!).update({
            'status': status,
            'statusUpdatedAt': DateTime.now().toIso8601String(),
          });

          debugPrint(
              '[SessionManager] 📝 Trial request status updated: $status');
        }
      }
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error updating trial request status: $e');
      // Don't throw - status update failure shouldn't block trial
    }
  }

  /// Check if current user can access audio (includes trial access)
  bool get canAccessAudioWithTrial {
    final session = currentSession;
    return session.hasAudioAccess || session.hasActiveTrial;
  }

  /// Check if current user can access premium content (includes trial access)
  bool get canAccessPremiumWithTrial {
    final session = currentSession;
    return session.isPremium || session.hasActiveTrial;
  }

  // ============================================================================
  // DEVICE-SPECIFIC PREMIUM ACCESS
  // ============================================================================

  /// Grant temporary premium access for this device only
  Future<UserSession?> grantDevicePremiumAccess({
    Duration duration = const Duration(days: 30),
    String reason = 'Device premium access',
  }) async {
    try {
      debugPrint(
          '[SessionManager] 📱 Granting device-specific premium access...');

      final expiryDate = DateTime.now().add(duration);
      final session = await grantPremiumAccess(
        expiryDate: expiryDate,
        type: 'device_premium',
      );

      if (session != null) {
        // Store device premium info for tracking
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_premium_reason', reason);
        await prefs.setString(
            'device_premium_granted', DateTime.now().toIso8601String());

        debugPrint(
            '[SessionManager] ✅ Device premium access granted for ${duration.inDays} days');
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
        final cachedSession =
            UserSession.fromJson(jsonDecode(cachedSessionJson));

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

  // ============================================================================
  // DEVICE SESSION MANAGEMENT (PREMIUM LIMITS)
  // ============================================================================

  /// Check if user can create a session on the specified device type
  Future<bool> _checkDeviceLimits(String userId, String deviceType) async {
    try {
      final currentSessions = await _getUserActiveSessions(userId);
      
      final sessionsByType = <String, List<Map<String, dynamic>>>{};
      for (final session in currentSessions) {
        final type = session['deviceType'] ?? 'unknown';
        sessionsByType[type] = (sessionsByType[type] ?? [])..add(session);
      }

      final phoneCount = sessionsByType['phone']?.length ?? 0;
      final tabletCount = sessionsByType['tablet']?.length ?? 0;
      final webCount = sessionsByType['web']?.length ?? 0;

      debugPrint('[SessionManager] 📱 Current sessions - Phone: $phoneCount, Tablet: $tabletCount, Web: $webCount');

      switch (deviceType) {
        case 'phone':
          if (phoneCount >= _maxPhoneSessions) {
            debugPrint('[SessionManager] ❌ Phone session limit exceeded ($phoneCount/$_maxPhoneSessions)');
            // Remove oldest phone session
            await _removeOldestSession(userId, 'phone');
          }
          break;
        case 'tablet':
          if (tabletCount >= _maxTabletSessions) {
            debugPrint('[SessionManager] ❌ Tablet session limit exceeded ($tabletCount/$_maxTabletSessions)');
            // Remove oldest tablet session
            await _removeOldestSession(userId, 'tablet');
          }
          break;
        case 'web':
          if (webCount >= _maxWebSessions) {
            debugPrint('[SessionManager] ❌ Web session limit exceeded ($webCount/$_maxWebSessions)');
            // Remove oldest web session
            await _removeOldestSession(userId, 'web');
          }
          break;
      }

      return true; // Always allow after cleanup
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error checking device limits: $e');
      return true; // Allow session creation if check fails
    }
  }

  /// Get all active sessions for a user
  Future<List<Map<String, dynamic>>> _getUserActiveSessions(String userId) async {
    try {
      // Check if current user has permission to view sessions
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[SessionManager] ❌ No authenticated user to check sessions');
        return [];
      }

      // Only allow users to view their own sessions, unless they're admin
      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin && currentUser.uid != userId) {
        debugPrint('[SessionManager] ❌ Permission denied: User can only view own sessions');
        return [];
      }

      final database = FirebaseDatabase.instance;
      final sessionsRef = database.ref('users/$userId/sessions');
      final snapshot = await sessionsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final sessionsData = Map<String, dynamic>.from(snapshot.value as Map);
        final sessions = <Map<String, dynamic>>[];

        sessionsData.forEach((sessionId, sessionData) {
          if (sessionData is Map) {
            final session = Map<String, dynamic>.from(sessionData);
            session['sessionId'] = sessionId;
            
            // Check if session is still active (not expired)
            final expiresAt = session['sessionExpiresAt'];
            if (expiresAt != null) {
              try {
                final expiryDate = DateTime.parse(expiresAt);
                if (DateTime.now().isBefore(expiryDate)) {
                  sessions.add(session);
                }
              } catch (e) {
                // Include session if date parsing fails
                sessions.add(session);
              }
            } else {
              sessions.add(session);
            }
          }
        });

        return sessions;
      }

      return [];
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error getting user sessions: $e');
      // Return empty list instead of failing
      return [];
    }
  }

  /// Check if current user is admin
  Future<bool> _isCurrentUserAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final role = userData['role']?.toString().toLowerCase();
        return role == 'admin' || role == 'super_admin';
      }

      return false;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error checking admin status: $e');
      return false;
    }
  }

  /// Remove the oldest session of the specified device type
  Future<void> _removeOldestSession(String userId, String deviceType) async {
    try {
      final sessions = await _getUserActiveSessions(userId);
      final typeSessions = sessions.where((s) => s['deviceType'] == deviceType).toList();

      if (typeSessions.isNotEmpty) {
        // Sort by creation time (oldest first)
        typeSessions.sort((a, b) {
          final timeA = a['sessionCreatedAt'] ?? '';
          final timeB = b['sessionCreatedAt'] ?? '';
          return timeA.compareTo(timeB);
        });

        final oldestSession = typeSessions.first;
        final sessionId = oldestSession['sessionId'];

        if (sessionId != null) {
          final database = FirebaseDatabase.instance;
          await database.ref('users/$userId/sessions/$sessionId').remove();
          debugPrint('[SessionManager] 🗑️ Removed oldest $deviceType session: $sessionId');
        }
      }
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error removing oldest session: $e');
    }
  }

  /// Store session in Firebase for device limit tracking
  Future<void> _storeSessionInFirebase(UserSession session) async {
    try {
      if (session.userId == null) return;

      // Only store if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != session.userId) {
        debugPrint('[SessionManager] ❌ Cannot store session: Authentication mismatch');
        return;
      }

      final database = FirebaseDatabase.instance;
      // Store under users/{userId}/sessions/{deviceId} for proper permission access
      final sessionRef = database.ref('users/${session.userId}/sessions/${session.deviceId}');
      
      final sessionData = {
        'deviceId': session.deviceId,
        'deviceType': session.deviceType,
        'deviceInfo': session.deviceInfo,
        'userRole': session.userRole,
        'isPremium': session.isPremium,
        'sessionCreatedAt': session.sessionCreatedAt.toIso8601String(),
        'sessionExpiresAt': session.sessionExpiresAt.toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
        'premiumExpiryDate': session.premiumExpiryDate?.toIso8601String(),
      };

      await sessionRef.set(sessionData);
      debugPrint('[SessionManager] 💾 Session stored in Firebase under users/${session.userId}/sessions/${session.deviceId}');
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error storing session in Firebase: $e');
      // Don't throw - session storage failure shouldn't block login
    }
  }

  /// Get device session info for admin view
  Future<Map<String, dynamic>> getDeviceSessionInfo(String userId) async {
    try {
      final sessions = await _getUserActiveSessions(userId);
      final sessionsByType = <String, List<Map<String, dynamic>>>{};
      
      for (final session in sessions) {
        final type = session['deviceType'] ?? 'unknown';
        sessionsByType[type] = (sessionsByType[type] ?? [])..add(session);
      }

      return {
        'totalSessions': sessions.length,
        'phoneCount': sessionsByType['phone']?.length ?? 0,
        'tabletCount': sessionsByType['tablet']?.length ?? 0,
        'webCount': sessionsByType['web']?.length ?? 0,
        'sessions': sessions,
        'limits': {
          'maxPhones': _maxPhoneSessions,
          'maxTablets': _maxTabletSessions,
          'maxWeb': _maxWebSessions,
        },
      };
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error getting device session info: $e');
      return {'error': e.toString()};
    }
  }

  /// Remove all sessions for a user (admin function)
  Future<bool> removeAllUserSessions(String userId) async {
    try {
      // Check admin permissions
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[SessionManager] ❌ No authenticated user for session removal');
        return false;
      }

      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin && currentUser.uid != userId) {
        debugPrint('[SessionManager] ❌ Permission denied: Only admins can remove other users\' sessions');
        return false;
      }

      final database = FirebaseDatabase.instance;
      await database.ref('users/$userId/sessions').remove();
      debugPrint('[SessionManager] 🗑️ Removed all sessions for user: $userId');
      return true;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error removing user sessions: $e');
      return false;
    }
  }

  /// Remove specific session (admin function)
  Future<bool> removeUserSession(String userId, String deviceId) async {
    try {
      // Check admin permissions
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[SessionManager] ❌ No authenticated user for session removal');
        return false;
      }

      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin && currentUser.uid != userId) {
        debugPrint('[SessionManager] ❌ Permission denied: Only admins can remove other users\' sessions');
        return false;
      }

      final database = FirebaseDatabase.instance;
      await database.ref('users/$userId/sessions/$deviceId').remove();
      debugPrint('[SessionManager] 🗑️ Removed session for user $userId on device $deviceId');
      return true;
    } catch (e) {
      debugPrint('[SessionManager] ❌ Error removing user session: $e');
      return false;
    }
  }
}
