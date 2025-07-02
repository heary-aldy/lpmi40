// lib/src/core/services/authorization_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

enum UserRole { user, admin, superAdmin }

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

  // Hardcoded admin emails for fallback
  static const List<String> _superAdminEmails = [
    'heary_aldy@hotmail.com',
    'heary@hopetv.asia',
    'haw33inc@gmail.com',
    'admin@haweeinc.com'
  ];

  static const List<String> _adminEmails = [
    'heary_aldy@hotmail.com',
    'heary@hopetv.asia',
    'admin@lpmi.com',
    'admin@haweeinc.com'
  ];

  // Cache to avoid repeated Firebase calls
  final Map<String, UserRole> _roleCache = {};
  final Map<String, List<String>> _permissionCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Check if current user has required role
  Future<AuthorizationResult> checkUserRole(UserRole requiredRole) async {
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
      }
    } catch (e) {
      return AuthorizationResult.unauthorized('Authorization check failed: $e');
    }
  }

  /// Get user role from Firebase with fallback to hardcoded emails
  Future<UserRole> _getUserRole(String uid) async {
    // Check cache
    if (_roleCache.containsKey(uid) && _isCacheValid()) {
      return _roleCache[uid]!;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email?.toLowerCase();

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$uid');
      final snapshot = await userRef.get();

      UserRole role = UserRole.user;
      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final roleString = userData['role']?.toString().toLowerCase();

        switch (roleString) {
          case 'super_admin':
            role = UserRole.superAdmin;
            break;
          case 'admin':
            role = UserRole.admin;
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

      return role;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase role check failed: $e, using fallback');
      }

      // Fallback to hardcoded email checking
      if (userEmail != null) {
        if (_superAdminEmails.contains(userEmail)) {
          return UserRole.superAdmin;
        }
        if (_adminEmails.contains(userEmail)) {
          return UserRole.admin;
        }
      }

      return UserRole.user;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  /// Clear role cache (call when user role changes)
  void clearCache([String? specificUid]) {
    if (specificUid != null) {
      _roleCache.remove(specificUid);
      _permissionCache.remove(specificUid);
    } else {
      _roleCache.clear();
      _permissionCache.clear();
      _lastCacheUpdate = null;
    }
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    // Super admins have all permissions
    if (await isSuperAdmin()) return true;

    // Check cached permissions
    if (_permissionCache.containsKey(currentUser.uid) && _isCacheValid()) {
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

  /// Integration method - matches existing dashboard helper signature
  Future<Map<String, bool>> checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {'isAdmin': false, 'isSuperAdmin': false};
    }

    final userRole = await _getUserRole(currentUser.uid);

    return {
      'isAdmin': userRole == UserRole.admin || userRole == UserRole.superAdmin,
      'isSuperAdmin': userRole == UserRole.superAdmin,
    };
  }

  /// Check if user is eligible for super admin (email whitelist)
  bool isEligibleForSuperAdmin(String email) {
    return _superAdminEmails.contains(email.toLowerCase());
  }

  /// Get all super admin emails (for UI display)
  List<String> getSuperAdminEmails() {
    return List.unmodifiable(_superAdminEmails);
  }

  /// Get all admin emails (for UI display)
  List<String> getAdminEmails() {
    return List.unmodifiable(_adminEmails);
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

  /// Check access to Firebase Debug page
  Future<AuthorizationResult> canAccessFirebaseDebug() async {
    return await checkUserRole(UserRole.superAdmin);
  }

  /// Convenient method for navigation guards
  Future<bool> canNavigateToPage(String pageName) async {
    switch (pageName.toLowerCase()) {
      case 'user_management':
        return (await canAccessUserManagement()).isAuthorized;
      case 'song_management':
        return (await canAccessSongManagement()).isAuthorized;
      case 'reports_management':
        return (await canAccessReportsManagement()).isAuthorized;
      case 'firebase_debug':
        return (await canAccessFirebaseDebug()).isAuthorized;
      default:
        return false;
    }
  }

  /// Debug method - get detailed user info
  Future<Map<String, dynamic>> getUserDebugInfo() async {
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
      'eligibleForSuperAdmin':
          userEmail != null ? isEligibleForSuperAdmin(userEmail) : false,
      'cacheStatus': {
        'hasCachedRole': _roleCache.containsKey(currentUser.uid),
        'hasCachedPermissions': _permissionCache.containsKey(currentUser.uid),
        'cacheValid': _isCacheValid(),
        'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      }
    };
  }
}
