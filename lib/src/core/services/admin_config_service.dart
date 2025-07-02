// lib/src/core/services/admin_config_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AdminConfigService {
  static final AdminConfigService _instance = AdminConfigService._internal();
  factory AdminConfigService() => _instance;
  AdminConfigService._internal();

  // Cache to avoid repeated Firebase calls
  List<String>? _cachedSuperAdmins;
  List<String>? _cachedAdmins;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 30);

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database =>
      _isFirebaseInitialized ? FirebaseDatabase.instance : null;

  /// Get super admin emails from Firebase users (by scanning actual roles)
  Future<List<String>> getSuperAdminEmails() async {
    // Check cache first
    if (_isCacheValid() && _cachedSuperAdmins != null) {
      return _cachedSuperAdmins!;
    }

    // Fallback emails (emergency access) - based on your actual Firebase data
    const fallbackSuperAdmins = [
      'heary_aldy@hotmail.com',
      'heary@hopetv.asia',
    ];

    if (!_isFirebaseInitialized || _database == null) {
      debugPrint('⚠️ Firebase not available, using fallback super admins');
      return fallbackSuperAdmins;
    }

    try {
      // ✅ NEW: Get super admins from actual user roles (more secure)
      final usersRef = _database!.ref('users');
      final snapshot =
          await usersRef.get().timeout(const Duration(seconds: 15));

      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final superAdminEmails = <String>[];

        // Scan all users for super_admin role
        for (final userData in usersData.values) {
          if (userData is Map) {
            final userMap = Map<String, dynamic>.from(userData);
            final role = userMap['role']?.toString();
            final email = userMap['email']?.toString();

            if (role == 'super_admin' && email != null && email.isNotEmpty) {
              superAdminEmails.add(email.toLowerCase());
            }
          }
        }

        if (superAdminEmails.isNotEmpty) {
          // Cache the result
          _cachedSuperAdmins = superAdminEmails;
          _lastCacheUpdate = DateTime.now();

          debugPrint(
              '✅ Found ${superAdminEmails.length} super admin emails from Firebase users: $superAdminEmails');
          return superAdminEmails;
        }
      }

      debugPrint('⚠️ No super admin users found in Firebase, using fallback');
      return fallbackSuperAdmins;
    } catch (e) {
      debugPrint('❌ Error loading super admin emails from users: $e');
      debugPrint('⚠️ Using fallback super admin emails');
      return fallbackSuperAdmins;
    }
  }

  /// Get admin emails from Firebase users (by scanning actual roles)
  Future<List<String>> getAdminEmails() async {
    // Check cache first
    if (_isCacheValid() && _cachedAdmins != null) {
      return _cachedAdmins!;
    }

    // Fallback emails (emergency access) - based on your actual Firebase data
    const fallbackAdmins = [
      'heary_aldy@hotmail.com',
      'heary@hopetv.asia',
      'admin@hopetv.asia',
    ];

    if (!_isFirebaseInitialized || _database == null) {
      debugPrint('⚠️ Firebase not available, using fallback admins');
      return fallbackAdmins;
    }

    try {
      // ✅ NEW: Get admins from actual user roles (includes super_admins)
      final usersRef = _database!.ref('users');
      final snapshot =
          await usersRef.get().timeout(const Duration(seconds: 15));

      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final adminEmails = <String>[];

        // Scan all users for admin or super_admin role
        for (final userData in usersData.values) {
          if (userData is Map) {
            final userMap = Map<String, dynamic>.from(userData);
            final role = userMap['role']?.toString();
            final email = userMap['email']?.toString();

            if ((role == 'admin' || role == 'super_admin') &&
                email != null &&
                email.isNotEmpty) {
              adminEmails.add(email.toLowerCase());
            }
          }
        }

        if (adminEmails.isNotEmpty) {
          // Cache the result
          _cachedAdmins = adminEmails;
          _lastCacheUpdate = DateTime.now();

          debugPrint(
              '✅ Found ${adminEmails.length} admin emails from Firebase users: $adminEmails');
          return adminEmails;
        }
      }

      debugPrint('⚠️ No admin users found in Firebase, using fallback');
      return fallbackAdmins;
    } catch (e) {
      debugPrint('❌ Error loading admin emails from users: $e');
      debugPrint('⚠️ Using fallback admin emails');
      return fallbackAdmins;
    }
  }

  /// Check if an email is a super admin
  Future<bool> isSuperAdmin(String email) async {
    if (email.isEmpty) return false;

    final superAdmins = await getSuperAdminEmails();
    return superAdmins.contains(email.toLowerCase());
  }

  /// Check if an email is an admin (includes super admins)
  Future<bool> isAdmin(String email) async {
    if (email.isEmpty) return false;

    // Check super admin first
    if (await isSuperAdmin(email)) return true;

    // Then check regular admins
    final admins = await getAdminEmails();
    return admins.contains(email.toLowerCase());
  }

  /// Clear cache (call when admin config changes)
  void clearCache() {
    _cachedSuperAdmins = null;
    _cachedAdmins = null;
    _lastCacheUpdate = null;
    debugPrint('🔄 Admin config cache cleared');
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  /// Refresh admin cache (call when user roles change)
  Future<void> refreshAdminCache() async {
    clearCache();

    // Pre-load the cache with fresh data
    await getSuperAdminEmails();
    await getAdminEmails();

    debugPrint('✅ Admin cache refreshed from Firebase users');
  }
}
