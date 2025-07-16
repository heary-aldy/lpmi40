// lib/src/core/services/authorization_service.dart
// 🟢 PHASE 1: Added premium role support for audio functionality
// 🔵 ORIGINAL: All existing methods preserved exactly
// ✅ NEW: Added canAccessCollectionManagement()

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/core/services/admin_config_service.dart';

// ✅ UPDATED: Added premium role for audio functionality
enum UserRole { user, admin, superAdmin, premium }

class AuthorizationResult {
  final bool isAuthorized;
  final UserRole userRole;
  final String? errorMessage;

  const AuthorizationResult({
    required this.isAuthorized,
    required this.userRole,
    this.errorMessage,
  });

  factory AuthorizationResult.unauthorized(String message) {
    return AuthorizationResult(
      isAuthorized: false,
      userRole: UserRole.user,
      errorMessage: message,
    );
  }

  factory AuthorizationResult.authorized(UserRole role) {
    return AuthorizationResult(
      isAuthorized: true,
      userRole: role,
    );
  }
}

class AuthorizationService {
  static final AuthorizationService _instance =
      AuthorizationService._internal();
  factory AuthorizationService() => _instance;
  AuthorizationService._internal();

  final AdminConfigService _adminConfig = AdminConfigService();

  // Cache to avoid repeated Firebase calls
  final Map<String, UserRole> _roleCache = {};
  final Map<String, List<String>> _permissionCache = {};
  DateTime? _lastCacheUpdate;

  // 🟢 NEW: Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ✅ CRITICAL FIX: Reduced from 5 minutes to 1 minute for immediate role recognition
  static const Duration _cacheTimeout = Duration(minutes: 1);

  // 🟢 NEW: Operation logging helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint(
          '[AuthorizationService] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[AuthorizationService] 📊 Details: $details');
      }
    }
  }

  // 🟢 NEW: Cache performance logging
  void _logCachePerformance(String operation, String uid, bool cacheHit) {
    if (kDebugMode) {
      final cacheAge = _lastCacheUpdate != null
          ? DateTime.now().difference(_lastCacheUpdate!).inSeconds
          : null;
      debugPrint(
          '🔄 Auth Cache: $operation for $uid - ${cacheHit ? "HIT" : "MISS"} (age: ${cacheAge}s)');
    }
  }

  // 🟢 NEW: User-friendly error message helper
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to verify permissions. Please try again later.';
    } else {
      return 'Unable to check permissions. Please try again.';
    }
  }

  /// Check if current user has required role
  Future<AuthorizationResult> checkUserRole(UserRole requiredRole) async {
    _logOperation(
        'checkUserRole', {'requiredRole': requiredRole.toString()}); // 🟢 NEW

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return AuthorizationResult.unauthorized('User not authenticated');
      }

      final userRole = await _getUserRole(currentUser.uid);

      switch (requiredRole) {
        case UserRole.user:
          return AuthorizationResult.authorized(userRole);

        case UserRole.admin:
          if (userRole == UserRole.admin || userRole == UserRole.superAdmin) {
            return AuthorizationResult.authorized(userRole);
          }
          return AuthorizationResult.unauthorized('Admin access required');

        case UserRole.superAdmin:
          if (userRole == UserRole.superAdmin) {
            return AuthorizationResult.authorized(userRole);
          }
          return AuthorizationResult.unauthorized(
              'Super admin access required');

        // ✅ NEW: Premium role checking
        case UserRole.premium:
          if (userRole == UserRole.premium ||
              userRole == UserRole.admin ||
              userRole == UserRole.superAdmin) {
            return AuthorizationResult.authorized(userRole);
          }
          return AuthorizationResult.unauthorized(
              'Premium access required for audio features');
      }
    } catch (e) {
      return AuthorizationResult.unauthorized(
          _getUserFriendlyErrorMessage(e)); // 🟢 NEW: User-friendly message
    }
  }

  /// Get user role from Firebase with fallback to admin config service
  Future<UserRole> _getUserRole(String uid) async {
    // Check cache
    final cacheHit = _roleCache.containsKey(uid) && _isCacheValid();
    _logCachePerformance('Role Check', uid, cacheHit); // 🟢 NEW

    if (cacheHit) {
      debugPrint('🔄 Using cached role for $uid: ${_roleCache[uid]}');
      return _roleCache[uid]!;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email?.toLowerCase();

    debugPrint('🔍 Checking role for UID: $uid, Email: $userEmail');

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$uid');
      final snapshot = await userRef.get();

      UserRole role = UserRole.user;
      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final roleString = userData['role']?.toString().toLowerCase();

        debugPrint('📊 Firebase role data: $roleString');

        switch (roleString) {
          case 'super_admin':
            role = UserRole.superAdmin;
            break;
          case 'admin':
            role = UserRole.admin;
            break;
          // ✅ NEW: Premium role support
          case 'premium':
            role = UserRole.premium;
            break;
          default:
            role = UserRole.user;
        }

        // Cache permissions too
        final permissions = userData['permissions'] as List<dynamic>?;
        if (permissions != null) {
          _permissionCache[uid] = permissions.cast<String>();
        }
      }

      // Update cache
      _roleCache[uid] = role;
      _lastCacheUpdate = DateTime.now();

      debugPrint('✅ Final role determined: $role (cached)');
      return role;
    } catch (e) {
      debugPrint('❌ Firebase role check failed: $e, using fallback');

      // ✅ UPDATED: Use AdminConfigService for fallback checking
      if (userEmail != null) {
        if (await _adminConfig.isSuperAdmin(userEmail)) {
          debugPrint('✅ Fallback: Email $userEmail is super admin');
          return UserRole.superAdmin;
        }
        if (await _adminConfig.isAdmin(userEmail)) {
          debugPrint('✅ Fallback: Email $userEmail is admin');
          return UserRole.admin;
        }
      }

      debugPrint('⚠️ Fallback: Email $userEmail has no admin privileges');
      return UserRole.user;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    final isValid =
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
    debugPrint(
        '🔄 Cache valid: $isValid (age: ${DateTime.now().difference(_lastCacheUpdate!).inSeconds}s)');
    return isValid;
  }

  /// ✅ ENHANCED: Clear role cache with better logging
  void clearCache([String? specificUid]) {
    _logOperation('clearCache', {'specificUid': specificUid}); // 🟢 NEW

    if (specificUid != null) {
      _roleCache.remove(specificUid);
      _permissionCache.remove(specificUid);
      debugPrint('🔄 Cleared cache for specific UID: $specificUid');
    } else {
      _roleCache.clear();
      _permissionCache.clear();
      _lastCacheUpdate = null;
      debugPrint('🔄 Cleared all authorization cache');
    }
    // ✅ NEW: Also clear admin config cache
    _adminConfig.clearCache();
  }

  /// ✅ NEW: Force refresh current user role (bypasses cache)
  Future<UserRole> forceRefreshCurrentUserRole() async {
    _logOperation('forceRefreshCurrentUserRole'); // 🟢 NEW

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return UserRole.user;

    // Clear cache for current user
    clearCache(currentUser.uid);

    // Get fresh role
    final role = await _getUserRole(currentUser.uid);
    debugPrint('🔄 Force refreshed current user role: $role');
    return role;
  }

  // 🟢 NEW: Cache warming (pre-load admin status for better UX)
  Future<void> warmCache() async {
    _logOperation('warmCache'); // 🟢 NEW

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await _getUserRole(currentUser.uid);
        debugPrint('🔥 Cache warmed for current user');
      } catch (e) {
        debugPrint('⚠️ Cache warming failed: $e');
      }
    }
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    _logOperation('hasPermission', {'permission': permission}); // 🟢 NEW

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    // Super admins have all permissions
    if (await isSuperAdmin()) return true;

    // Check cached permissions
    final cacheHit =
        _permissionCache.containsKey(currentUser.uid) && _isCacheValid();
    _logCachePerformance(
        'Permission Check', currentUser.uid, cacheHit); // 🟢 NEW

    if (cacheHit) {
      return _permissionCache[currentUser.uid]!.contains(permission);
    }

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final permissions = userData['permissions'] as List<dynamic>?;

        if (permissions != null) {
          final permissionList = permissions.cast<String>();
          _permissionCache[currentUser.uid] = permissionList;
          return permissionList.contains(permission);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Permission check failed: $e');
      }
    }

    return false;
  }

  // ✅ NEW: Premium-specific methods

  /// Check if user is premium user
  Future<bool> isPremium() async {
    _logOperation('isPremium'); // 🟢 NEW
    final result = await checkUserRole(UserRole.premium);
    return result.isAuthorized;
  }

  /// Check if user can access audio features
  Future<bool> canAccessAudio() async {
    _logOperation('canAccessAudio'); // 🟢 NEW
    return await isPremium();
  }

  /// Check premium access with detailed result
  Future<AuthorizationResult> checkPremiumAccess() async {
    _logOperation('checkPremiumAccess'); // 🟢 NEW
    return await checkUserRole(UserRole.premium);
  }

  /// Get premium upgrade message
  String getPremiumUpgradeMessage() {
    return 'Upgrade to Premium to access audio features and enjoy unlimited song playback!';
  }

  /// Integration method - matches existing dashboard helper signature
  Future<Map<String, bool>> checkAdminStatus() async {
    _logOperation('checkAdminStatus'); // 🟢 NEW

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {
        'isAdmin': false,
        'isSuperAdmin': false,
        'isPremium': false, // ✅ NEW
      };
    }

    final userRole = await _getUserRole(currentUser.uid);

    final result = {
      'isAdmin': userRole == UserRole.admin || userRole == UserRole.superAdmin,
      'isSuperAdmin': userRole == UserRole.superAdmin,
      'isPremium': userRole == UserRole.premium ||
          userRole == UserRole.admin ||
          userRole == UserRole.superAdmin, // ✅ NEW: Admins get premium access
    };

    debugPrint('🎭 Admin status check result: $result');
    return result;
  }

  /// Check if user is eligible for super admin using config service
  Future<bool> isEligibleForSuperAdmin(String email) async {
    return await _adminConfig.isSuperAdmin(email);
  }

  /// Get all super admin emails from config service
  Future<List<String>> getSuperAdminEmails() async {
    return await _adminConfig.getSuperAdminEmails();
  }

  /// Get all admin emails from config service
  Future<List<String>> getAdminEmails() async {
    return await _adminConfig.getAdminEmails();
  }

  /// Quick admin check for UI elements
  Future<bool> isAdmin() async {
    final result = await checkUserRole(UserRole.admin);
    return result.isAuthorized;
  }

  /// Quick super admin check for UI elements
  Future<bool> isSuperAdmin() async {
    final result = await checkUserRole(UserRole.superAdmin);
    return result.isAuthorized;
  }

  /// Get current user role (for UI display)
  Future<UserRole> getCurrentUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return UserRole.user;

    return await _getUserRole(currentUser.uid);
  }

  /// Check if user can manage other users
  Future<bool> canManageUsers() async {
    return await isSuperAdmin();
  }

  /// Check if user can manage songs
  Future<bool> canManageSongs() async {
    return await isAdmin();
  }

  /// Check if user can view reports
  Future<bool> canViewReports() async {
    return await isAdmin();
  }

  /// Check if user can access debug features
  Future<bool> canAccessDebug() async {
    return await isSuperAdmin();
  }

  /// Page-specific authorization guards

  /// Check access to User Management page
  Future<AuthorizationResult> canAccessUserManagement() async {
    return await checkUserRole(UserRole.superAdmin);
  }

  /// Check access to Song Management page
  Future<AuthorizationResult> canAccessSongManagement() async {
    return await checkUserRole(UserRole.admin);
  }

  /// Check access to Reports Management page
  Future<AuthorizationResult> canAccessReportsManagement() async {
    return await checkUserRole(UserRole.admin);
  }

  /// ✅ NEW: Check access to Collection Management page
  Future<AuthorizationResult> canAccessCollectionManagement() async {
    return await checkUserRole(UserRole.admin);
  }

  /// Check access to Firebase Debug page
  Future<AuthorizationResult> canAccessFirebaseDebug() async {
    return await checkUserRole(UserRole.superAdmin);
  }

  // ✅ NEW: Premium-specific authorization

  /// Check access to Premium Audio Settings
  Future<AuthorizationResult> canAccessPremiumAudioSettings() async {
    return await checkUserRole(UserRole.premium);
  }

  /// Check if user can use audio features
  Future<bool> canUseAudioFeatures() async {
    final result = await checkPremiumAccess();
    return result.isAuthorized;
  }

  /// Convenient method for navigation guards
  Future<bool> canNavigateToPage(String pageName) async {
    _logOperation('canNavigateToPage', {'pageName': pageName}); // 🟢 NEW

    switch (pageName.toLowerCase()) {
      case 'user_management':
        return (await canAccessUserManagement()).isAuthorized;
      case 'song_management':
        return (await canAccessSongManagement()).isAuthorized;
      case 'reports_management':
        return (await canAccessReportsManagement()).isAuthorized;
      case 'collection_management': // ✅ NEW
        return (await canAccessCollectionManagement()).isAuthorized;
      case 'firebase_debug':
        return (await canAccessFirebaseDebug()).isAuthorized;
      case 'premium_audio_settings': // ✅ NEW
        return (await canAccessPremiumAudioSettings()).isAuthorized;
      default:
        return false;
    }
  }

  // 🟢 NEW: Batch role checks for better performance
  Future<Map<String, bool>> getMultiplePermissions(
      List<String> permissions) async {
    _logOperation(
        'getMultiplePermissions', {'permissions': permissions}); // 🟢 NEW

    final results = <String, bool>{};
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      for (final permission in permissions) {
        results[permission] = false;
      }
      return results;
    }

    // Super admins have all permissions
    final isSuperAdminUser = await isSuperAdmin();
    if (isSuperAdminUser) {
      for (final permission in permissions) {
        results[permission] = true;
      }
      return results;
    }

    // Batch check permissions
    for (final permission in permissions) {
      results[permission] = await hasPermission(permission);
    }

    return results;
  }

  /// ✅ ENHANCED: Debug method with more detailed info
  Future<Map<String, dynamic>> getUserDebugInfo() async {
    _logOperation('getUserDebugInfo'); // 🟢 NEW

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {'error': 'No user logged in'};
    }

    final userRole = await _getUserRole(currentUser.uid);
    final adminStatus = await checkAdminStatus();
    final userEmail = currentUser.email?.toLowerCase();

    return {
      'uid': currentUser.uid,
      'email': userEmail,
      'role': userRole.toString(),
      'isAdmin': adminStatus['isAdmin'],
      'isSuperAdmin': adminStatus['isSuperAdmin'],
      'isPremium': adminStatus['isPremium'], // ✅ NEW
      'canAccessAudio': await canAccessAudio(), // ✅ NEW
      'eligibleForSuperAdmin':
          userEmail != null ? await isEligibleForSuperAdmin(userEmail) : false,
      'cacheStatus': {
        'hasCachedRole': _roleCache.containsKey(currentUser.uid),
        'hasCachedPermissions': _permissionCache.containsKey(currentUser.uid),
        'cacheValid': _isCacheValid(),
        'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      },
      'timestamps': {
        'now': DateTime.now().toIso8601String(),
        'cacheAge': _lastCacheUpdate != null
            ? DateTime.now().difference(_lastCacheUpdate!).inSeconds
            : null,
      }
    };
  }

  // 🟢 NEW: Get performance metrics (for debugging)
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'cacheStats': {
        'rolesCached': _roleCache.length,
        'permissionsCached': _permissionCache.length,
        'cacheTimeout': _cacheTimeout.inMinutes,
        'cacheValid': _isCacheValid(),
      },
    };
  }
}
