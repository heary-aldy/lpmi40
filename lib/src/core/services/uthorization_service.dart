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

  // Cache to avoid repeated Firebase calls
  final Map<String, UserRole> _roleCache = {};
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

  /// Get user role from Firebase with caching
  Future<UserRole> _getUserRole(String uid) async {
    // Check cache
    if (_roleCache.containsKey(uid) && _isCacheValid()) {
      return _roleCache[uid]!;
    }

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
      }

      // Update cache
      _roleCache[uid] = role;
      _lastCacheUpdate = DateTime.now();

      return role;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user role: $e');
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
    } else {
      _roleCache.clear();
      _lastCacheUpdate = null;
    }
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
}
