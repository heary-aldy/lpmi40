// lib/src/core/services/session_integration_service.dart
// 🔗 Integration service to connect SessionManager with existing services
// ✅ Bridges session management with PremiumService, AuthorizationService, etc.

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/session_manager.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

/// Integration service to sync session management with existing services
class SessionIntegrationService {
  static SessionIntegrationService? _instance;
  static SessionIntegrationService get instance => _instance ??= SessionIntegrationService._();
  SessionIntegrationService._();

  final SessionManager _sessionManager = SessionManager.instance;
  final PremiumService _premiumService = PremiumService();
  final AuthorizationService _authService = AuthorizationService();

  bool _isInitialized = false;

  /// Initialize session integration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[SessionIntegration] 🚀 Initializing session integration...');
      
      // Initialize session manager first
      await _sessionManager.initialize();
      
      // Listen to Firebase auth changes
      FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
      
      // Check for existing Firebase user and sync session
      await _syncWithFirebaseAuth();
      
      _isInitialized = true;
      debugPrint('[SessionIntegration] ✅ Session integration initialized');
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error initializing: $e');
    }
  }

  /// Handle Firebase authentication state changes
  Future<void> _handleAuthStateChange(User? user) async {
    try {
      if (user != null) {
        debugPrint('[SessionIntegration] 👤 Firebase user signed in: ${user.email}');
        await _createSessionFromFirebaseUser(user);
      } else {
        debugPrint('[SessionIntegration] 👋 Firebase user signed out');
        await _sessionManager.logout();
      }
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error handling auth state change: $e');
    }
  }

  /// Create session from Firebase user
  Future<void> _createSessionFromFirebaseUser(User user) async {
    try {
      // Get user role from your authorization service
      final userRole = await _authService.getUserRole(user.uid);
      
      // Check premium status (you can enhance this with Firebase Database lookup)
      final isPremium = await _checkUserPremiumStatus(user.uid);
      
      // Create user session
      await _sessionManager.createUserSession(
        userId: user.uid,
        email: user.email ?? 'user@app.com',
        userRole: userRole,
        isPremium: isPremium,
        premiumExpiryDate: isPremium ? _getPremiumExpiryDate(user.uid) : null,
      );
      
      debugPrint('[SessionIntegration] ✅ Session created for Firebase user');
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error creating session from Firebase user: $e');
    }
  }

  /// Sync session with existing Firebase auth
  Future<void> _syncWithFirebaseAuth() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _createSessionFromFirebaseUser(user);
      }
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error syncing with Firebase auth: $e');
    }
  }

  /// Check user premium status from your existing systems
  Future<bool> _checkUserPremiumStatus(String userId) async {
    try {
      // This integrates with your existing premium checking logic
      final premiumStatus = await _premiumService.checkPremiumStatus(userId);
      return premiumStatus.isPremium;
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Get premium expiry date (implement based on your premium system)
  DateTime? _getPremiumExpiryDate(String userId) {
    // TODO: Implement based on your premium subscription system
    // This could query Firebase Database for user premium subscription data
    return null; // For now, return null (indefinite premium)
  }

  // ============================================================================
  // PUBLIC API METHODS
  // ============================================================================

  /// Grant premium access to current session
  Future<bool> grantPremiumAccess({
    Duration duration = const Duration(days: 30),
    String reason = 'Manual premium grant',
  }) async {
    try {
      debugPrint('[SessionIntegration] ⭐ Granting premium access...');
      
      final session = await _sessionManager.grantDevicePremiumAccess(
        duration: duration,
        reason: reason,
      );
      
      if (session != null) {
        debugPrint('[SessionIntegration] ✅ Premium access granted');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error granting premium access: $e');
      return false;
    }
  }

  /// Check if current user has premium access
  bool get isPremium => _sessionManager.isPremium;

  /// Check if current user can access audio features
  bool get canAccessAudio => _sessionManager.canAccessAudio;

  /// Check if current user can save favorites
  bool get canSaveFavorites => _sessionManager.canSaveFavorites;

  /// Get current user role
  String get userRole => _sessionManager.userRole;

  /// Get current user email
  String? get userEmail => _sessionManager.userEmail;

  /// Get current session
  UserSession get currentSession => _sessionManager.currentSession;

  /// Check specific permission
  bool hasPermission(String permission) => _sessionManager.hasPermission(permission);

  /// Force refresh session from Firebase
  Future<void> refreshSession() async {
    try {
      await _sessionManager.refreshFromFirebase();
      await _syncWithFirebaseAuth();
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error refreshing session: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _sessionManager.logout();
      debugPrint('[SessionIntegration] 👋 User logged out');
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error during logout: $e');
    }
  }

  // ============================================================================
  // PREMIUM ACCESS MANAGEMENT
  // ============================================================================

  /// Grant temporary premium access for testing/demos
  Future<bool> grantTemporaryPremium({
    Duration duration = const Duration(hours: 24),
    String reason = 'Temporary access',
  }) async {
    return await grantPremiumAccess(duration: duration, reason: reason);
  }

  /// Grant extended premium access
  Future<bool> grantExtendedPremium({
    Duration duration = const Duration(days: 365),
    String reason = 'Extended premium access',
  }) async {
    return await grantPremiumAccess(duration: duration, reason: reason);
  }

  /// Check if user has cached premium access from previous sessions
  Future<bool> restoreCachedPremiumAccess() async {
    try {
      return await _sessionManager.checkCachedPremiumAccess();
    } catch (e) {
      debugPrint('[SessionIntegration] ❌ Error restoring cached premium: $e');
      return false;
    }
  }

  // ============================================================================
  // ADMIN FUNCTIONS
  // ============================================================================

  /// Check if current user is admin
  bool get isAdmin => _sessionManager.currentSession.isAdmin;

  /// Get session info for debugging
  Map<String, dynamic> getSessionInfo() {
    final session = _sessionManager.currentSession;
    return {
      'userRole': session.userRole,
      'isPremium': session.isPremium,
      'hasAudioAccess': session.hasAudioAccess,
      'isExpired': session.isExpired,
      'isPremiumExpired': session.isPremiumExpired,
      'sessionCreatedAt': session.sessionCreatedAt.toIso8601String(),
      'sessionExpiresAt': session.sessionExpiresAt.toIso8601String(),
      'deviceId': session.deviceId,
      'permissions': session.permissions,
    };
  }
}

/// Extension to easily access session integration
extension SessionAccess on Object {
  SessionIntegrationService get session => SessionIntegrationService.instance;
}