// lib/src/core/services/admin_config_service.dart
// Service for managing admin and super admin configuration

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class AdminConfigService {
  static final AdminConfigService _instance = AdminConfigService._internal();
  factory AdminConfigService() => _instance;
  AdminConfigService._internal();

  // Cache for admin emails to avoid repeated Firebase calls
  final Map<String, bool> _adminCache = {};
  final Map<String, bool> _superAdminCache = {};
  DateTime? _lastCacheUpdate;

  // Cache timeout
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Hardcoded super admin emails (backup method)
  static const List<String> _hardcodedSuperAdmins = [
    'admin@haweeinc.com',
    'superadmin@lpmi40.com',
    // Add your super admin emails here
  ];

  // Hardcoded admin emails (backup method)
  static const List<String> _hardcodedAdmins = [
    'admin@haweeinc.com',
    'moderator@lpmi40.com',
    // Add your admin emails here
  ];

  /// Check if email is a super admin
  Future<bool> isSuperAdmin(String email) async {
    final emailLower = email.toLowerCase().trim();

    // Check cache first
    if (_isCacheValid() && _superAdminCache.containsKey(emailLower)) {
      debugPrint(
          '🔄 Using cached super admin status for $emailLower: ${_superAdminCache[emailLower]}');
      return _superAdminCache[emailLower]!;
    }

    try {
      // Try Firebase first
      final isFirebaseSuperAdmin = await _checkFirebaseSuperAdmin(emailLower);
      if (isFirebaseSuperAdmin) {
        _superAdminCache[emailLower] = true;
        _lastCacheUpdate = DateTime.now();
        return true;
      }

      // Fallback to hardcoded list
      final isHardcodedSuperAdmin = _hardcodedSuperAdmins.contains(emailLower);
      _superAdminCache[emailLower] = isHardcodedSuperAdmin;
      _lastCacheUpdate = DateTime.now();

      debugPrint(
          '✅ Super admin check for $emailLower: $isHardcodedSuperAdmin (fallback)');
      return isHardcodedSuperAdmin;
    } catch (e) {
      debugPrint('❌ Error checking super admin status: $e');

      // Fallback to hardcoded list
      final isHardcodedSuperAdmin = _hardcodedSuperAdmins.contains(emailLower);
      debugPrint(
          '⚠️ Using hardcoded super admin list for $emailLower: $isHardcodedSuperAdmin');
      return isHardcodedSuperAdmin;
    }
  }

  /// Check if email is an admin
  Future<bool> isAdmin(String email) async {
    final emailLower = email.toLowerCase().trim();

    // Super admins are also admins
    if (await isSuperAdmin(emailLower)) {
      return true;
    }

    // Check cache first
    if (_isCacheValid() && _adminCache.containsKey(emailLower)) {
      debugPrint(
          '🔄 Using cached admin status for $emailLower: ${_adminCache[emailLower]}');
      return _adminCache[emailLower]!;
    }

    try {
      // Try Firebase first
      final isFirebaseAdmin = await _checkFirebaseAdmin(emailLower);
      if (isFirebaseAdmin) {
        _adminCache[emailLower] = true;
        _lastCacheUpdate = DateTime.now();
        return true;
      }

      // Fallback to hardcoded list
      final isHardcodedAdmin = _hardcodedAdmins.contains(emailLower);
      _adminCache[emailLower] = isHardcodedAdmin;
      _lastCacheUpdate = DateTime.now();

      debugPrint('✅ Admin check for $emailLower: $isHardcodedAdmin (fallback)');
      return isHardcodedAdmin;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');

      // Fallback to hardcoded list
      final isHardcodedAdmin = _hardcodedAdmins.contains(emailLower);
      debugPrint(
          '⚠️ Using hardcoded admin list for $emailLower: $isHardcodedAdmin');
      return isHardcodedAdmin;
    }
  }

  /// Check Firebase for super admin status
  Future<bool> _checkFirebaseSuperAdmin(String email) async {
    try {
      final database = FirebaseDatabase.instance;
      final configRef = database.ref('admin_config/super_admins');
      final snapshot = await configRef.get().timeout(
            const Duration(seconds: 5),
          );

      if (snapshot.exists && snapshot.value != null) {
        final superAdmins = List<String>.from(snapshot.value as List);
        final isSuper =
            superAdmins.any((admin) => admin.toLowerCase() == email);
        debugPrint('🔍 Firebase super admin check for $email: $isSuper');
        return isSuper;
      }

      debugPrint('⚠️ No super admin config found in Firebase');
      return false;
    } catch (e) {
      debugPrint('❌ Firebase super admin check failed: $e');
      return false;
    }
  }

  /// Check Firebase for admin status
  Future<bool> _checkFirebaseAdmin(String email) async {
    try {
      final database = FirebaseDatabase.instance;
      final configRef = database.ref('admin_config/admins');
      final snapshot = await configRef.get().timeout(
            const Duration(seconds: 5),
          );

      if (snapshot.exists && snapshot.value != null) {
        final admins = List<String>.from(snapshot.value as List);
        final isAdmin = admins.any((admin) => admin.toLowerCase() == email);
        debugPrint('🔍 Firebase admin check for $email: $isAdmin');
        return isAdmin;
      }

      debugPrint('⚠️ No admin config found in Firebase');
      return false;
    } catch (e) {
      debugPrint('❌ Firebase admin check failed: $e');
      return false;
    }
  }

  /// Get all super admin emails
  Future<List<String>> getSuperAdminEmails() async {
    try {
      final database = FirebaseDatabase.instance;
      final configRef = database.ref('admin_config/super_admins');
      final snapshot = await configRef.get().timeout(
            const Duration(seconds: 5),
          );

      if (snapshot.exists && snapshot.value != null) {
        final firebaseSuperAdmins = List<String>.from(snapshot.value as List);

        // Combine Firebase and hardcoded lists
        final allSuperAdmins = <String>{
          ...firebaseSuperAdmins.map((e) => e.toLowerCase()),
          ..._hardcodedSuperAdmins,
        }.toList();

        debugPrint('📋 Super admin emails: $allSuperAdmins');
        return allSuperAdmins;
      }

      debugPrint('📋 Using hardcoded super admin emails only');
      return List.from(_hardcodedSuperAdmins);
    } catch (e) {
      debugPrint('❌ Error getting super admin emails: $e');
      return List.from(_hardcodedSuperAdmins);
    }
  }

  /// Get all admin emails
  Future<List<String>> getAdminEmails() async {
    try {
      final database = FirebaseDatabase.instance;
      final configRef = database.ref('admin_config/admins');
      final snapshot = await configRef.get().timeout(
            const Duration(seconds: 5),
          );

      if (snapshot.exists && snapshot.value != null) {
        final firebaseAdmins = List<String>.from(snapshot.value as List);

        // Combine Firebase and hardcoded lists
        final allAdmins = <String>{
          ...firebaseAdmins.map((e) => e.toLowerCase()),
          ..._hardcodedAdmins,
        }.toList();

        debugPrint('📋 Admin emails: $allAdmins');
        return allAdmins;
      }

      debugPrint('📋 Using hardcoded admin emails only');
      return List.from(_hardcodedAdmins);
    } catch (e) {
      debugPrint('❌ Error getting admin emails: $e');
      return List.from(_hardcodedAdmins);
    }
  }

  /// Add super admin email to Firebase
  Future<bool> addSuperAdmin(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();
      final database = FirebaseDatabase.instance;

      // Get current list
      final superAdmins = await getSuperAdminEmails();

      if (!superAdmins.contains(emailLower)) {
        superAdmins.add(emailLower);

        // Update Firebase
        final configRef = database.ref('admin_config/super_admins');
        await configRef.set(superAdmins);

        // Clear cache
        clearCache();

        debugPrint('✅ Added super admin: $emailLower');
        return true;
      }

      debugPrint('⚠️ Email $emailLower is already a super admin');
      return false;
    } catch (e) {
      debugPrint('❌ Error adding super admin: $e');
      return false;
    }
  }

  /// Add admin email to Firebase
  Future<bool> addAdmin(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();
      final database = FirebaseDatabase.instance;

      // Get current list
      final admins = await getAdminEmails();

      if (!admins.contains(emailLower)) {
        admins.add(emailLower);

        // Update Firebase
        final configRef = database.ref('admin_config/admins');
        await configRef.set(admins);

        // Clear cache
        clearCache();

        debugPrint('✅ Added admin: $emailLower');
        return true;
      }

      debugPrint('⚠️ Email $emailLower is already an admin');
      return false;
    } catch (e) {
      debugPrint('❌ Error adding admin: $e');
      return false;
    }
  }

  /// Remove super admin email from Firebase
  Future<bool> removeSuperAdmin(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();
      final database = FirebaseDatabase.instance;

      // Get current list
      final superAdmins = await getSuperAdminEmails();

      if (superAdmins.contains(emailLower) &&
          !_hardcodedSuperAdmins.contains(emailLower)) {
        superAdmins.remove(emailLower);

        // Update Firebase
        final configRef = database.ref('admin_config/super_admins');
        await configRef.set(superAdmins);

        // Clear cache
        clearCache();

        debugPrint('✅ Removed super admin: $emailLower');
        return true;
      }

      debugPrint('⚠️ Cannot remove hardcoded super admin: $emailLower');
      return false;
    } catch (e) {
      debugPrint('❌ Error removing super admin: $e');
      return false;
    }
  }

  /// Remove admin email from Firebase
  Future<bool> removeAdmin(String email) async {
    try {
      final emailLower = email.toLowerCase().trim();
      final database = FirebaseDatabase.instance;

      // Get current list
      final admins = await getAdminEmails();

      if (admins.contains(emailLower) &&
          !_hardcodedAdmins.contains(emailLower)) {
        admins.remove(emailLower);

        // Update Firebase
        final configRef = database.ref('admin_config/admins');
        await configRef.set(admins);

        // Clear cache
        clearCache();

        debugPrint('✅ Removed admin: $emailLower');
        return true;
      }

      debugPrint('⚠️ Cannot remove hardcoded admin: $emailLower');
      return false;
    } catch (e) {
      debugPrint('❌ Error removing admin: $e');
      return false;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    final isValid =
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
    return isValid;
  }

  /// Clear the cache
  void clearCache() {
    _adminCache.clear();
    _superAdminCache.clear();
    _lastCacheUpdate = null;
    debugPrint('🔄 Cleared admin config cache');
  }

  /// Get configuration summary
  Map<String, dynamic> getConfigSummary() {
    return {
      'hardcodedSuperAdmins': List.from(_hardcodedSuperAdmins),
      'hardcodedAdmins': List.from(_hardcodedAdmins),
      'cacheSize': {
        'superAdmins': _superAdminCache.length,
        'admins': _adminCache.length,
      },
      'cacheValid': _isCacheValid(),
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
    };
  }

  /// Initialize Firebase admin configuration (call once during app setup)
  Future<void> initializeFirebaseConfig() async {
    try {
      final database = FirebaseDatabase.instance;

      // Initialize super admins if not exists
      final superAdminRef = database.ref('admin_config/super_admins');
      final superAdminSnapshot = await superAdminRef.get();

      if (!superAdminSnapshot.exists) {
        await superAdminRef.set(_hardcodedSuperAdmins);
        debugPrint('🔧 Initialized Firebase super admin config');
      }

      // Initialize admins if not exists
      final adminRef = database.ref('admin_config/admins');
      final adminSnapshot = await adminRef.get();

      if (!adminSnapshot.exists) {
        await adminRef.set(_hardcodedAdmins);
        debugPrint('🔧 Initialized Firebase admin config');
      }

      debugPrint('✅ Firebase admin configuration ready');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase admin config: $e');
    }
  }
}
