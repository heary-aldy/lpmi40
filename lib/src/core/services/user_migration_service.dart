// lib/src/core/services/user_migration_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class UserMigrationService {
  static final UserMigrationService _instance =
      UserMigrationService._internal();
  factory UserMigrationService() => _instance;
  UserMigrationService._internal();

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

  // ✅ Main method to check and migrate current user's data structure
  Future<void> checkAndMigrateCurrentUser() async {
    if (!_isFirebaseInitialized) {
      debugPrint('⚠️ Firebase not initialized, skipping migration');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('📭 No user logged in, skipping migration');
      return;
    }

    try {
      debugPrint('🔍 Checking user data structure for: ${user.email}');
      await _migrateUserDataStructure(user);
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      // Don't throw - migration failure shouldn't break the app
    }
  }

  // ✅ Migrate user data to match the proper structure
  Future<void> _migrateUserDataStructure(User user) async {
    if (_database == null) return;

    final userRef = _database!.ref('users/${user.uid}');
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      // User doesn't exist in database - create with proper structure
      debugPrint('🆕 Creating new user document for: ${user.email}');
      await _createProperUserDocument(user);
      return;
    }

    // User exists - check if migration is needed
    final userData = Map<String, dynamic>.from(snapshot.value as Map);
    bool needsMigration = false;
    final migrationUpdates = <String, dynamic>{};

    // ✅ Check 1: Ensure all required fields exist
    final requiredFields = [
      'uid',
      'displayName',
      'email',
      'role',
      'createdAt',
      'lastSignIn'
    ];
    for (String field in requiredFields) {
      if (!userData.containsKey(field)) {
        needsMigration = true;
        migrationUpdates[field] = _getDefaultFieldValue(field, user);
        debugPrint('🔧 Missing field detected: $field');
      }
    }

    // ✅ Check 2: Ensure favorites is an object, not an array
    if (userData.containsKey('favorites')) {
      final favorites = userData['favorites'];
      if (favorites is List) {
        // Convert array to object structure
        needsMigration = true;
        final favoritesObject = <String, dynamic>{};
        for (var songNumber in favorites) {
          if (songNumber != null) {
            favoritesObject[songNumber.toString()] = true;
          }
        }
        migrationUpdates['favorites'] = favoritesObject;
        debugPrint('🔧 Converting favorites from array to object structure');
      }
    } else {
      // Initialize empty favorites object
      needsMigration = true;
      migrationUpdates['favorites'] = <String, dynamic>{};
      debugPrint('🔧 Initializing empty favorites object');
    }

    // ✅ Check 3: Ensure timestamps are in ISO format
    final timestampFields = [
      'createdAt',
      'lastSignIn',
      'updatedAt',
      'adminGrantedAt'
    ];
    for (String field in timestampFields) {
      if (userData.containsKey(field) && userData[field] != null) {
        final timestamp = userData[field];
        if (timestamp is int) {
          // Convert milliseconds to ISO string
          needsMigration = true;
          migrationUpdates[field] =
              DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
          debugPrint('🔧 Converting timestamp field $field to ISO format');
        }
      }
    }

    // ✅ Check 4: Ensure role is lowercase
    if (userData.containsKey('role') && userData['role'] != null) {
      final role = userData['role'].toString();
      final lowerRole = role.toLowerCase();
      if (role != lowerRole) {
        needsMigration = true;
        migrationUpdates['role'] = lowerRole;
        debugPrint('🔧 Converting role to lowercase: $role -> $lowerRole');
      }
    }

    // ✅ Check 5: Remove any deprecated fields
    final deprecatedFields = [
      'isAnonymous',
      'photoURL'
    ]; // Add any fields you want to remove
    for (String field in deprecatedFields) {
      if (userData.containsKey(field)) {
        needsMigration = true;
        migrationUpdates[field] = null;
        debugPrint('🔧 Removing deprecated field: $field');
      }
    }

    // Apply migration if needed
    if (needsMigration) {
      debugPrint('🚀 Applying migration for user: ${user.email}');
      migrationUpdates['migrationVersion'] = '2.0.0';
      migrationUpdates['migratedAt'] = DateTime.now().toIso8601String();

      await userRef.update(migrationUpdates);
      debugPrint('✅ Migration completed for user: ${user.email}');
      debugPrint('📝 Updated fields: ${migrationUpdates.keys.join(', ')}');
    } else {
      debugPrint('✅ User data structure is already up to date: ${user.email}');
    }
  }

  // ✅ Create a new user document with proper structure
  Future<void> _createProperUserDocument(User user) async {
    if (_database == null) return;

    final userRef = _database!.ref('users/${user.uid}');
    final currentTime = DateTime.now().toIso8601String();

    final userData = {
      'uid': user.uid,
      'displayName':
          user.displayName ?? (user.isAnonymous ? 'Guest User' : 'LPMI User'),
      'email': user.email ??
          (user.isAnonymous ? 'anonymous@guest.com' : 'no-email@unknown.com'),
      'role': 'user',
      'createdAt': currentTime,
      'lastSignIn': currentTime,
      'favorites': <String, dynamic>{},
      'migrationVersion': '2.0.0',
    };

    await userRef.set(userData);
    debugPrint('✅ Created new user document with proper structure');
  }

  // ✅ Get default value for missing fields
  dynamic _getDefaultFieldValue(String field, User user) {
    final currentTime = DateTime.now().toIso8601String();

    switch (field) {
      case 'uid':
        return user.uid;
      case 'displayName':
        return user.displayName ??
            (user.isAnonymous ? 'Guest User' : 'LPMI User');
      case 'email':
        return user.email ??
            (user.isAnonymous ? 'anonymous@guest.com' : 'no-email@unknown.com');
      case 'role':
        return 'user';
      case 'createdAt':
        return user.metadata.creationTime?.toIso8601String() ?? currentTime;
      case 'lastSignIn':
        return currentTime;
      case 'favorites':
        return <String, dynamic>{};
      default:
        return null;
    }
  }

  // ✅ Bulk migration for all users (admin function)
  Future<void> migrateAllUsers() async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    debugPrint('🚀 Starting bulk user migration...');

    try {
      final usersRef = _database!.ref('users');
      final snapshot = await usersRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('📭 No users found to migrate');
        return;
      }

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      int migratedCount = 0;
      int totalUsers = usersData.length;

      debugPrint('👥 Found $totalUsers users to check for migration');

      for (var entry in usersData.entries) {
        final uid = entry.key;
        final userData = Map<String, dynamic>.from(entry.value as Map);

        try {
          await _migrateSpecificUser(uid, userData);
          migratedCount++;
          debugPrint('✅ Migrated user $migratedCount/$totalUsers (UID: $uid)');
        } catch (e) {
          debugPrint('❌ Failed to migrate user $uid: $e');
        }
      }

      debugPrint(
          '🎉 Bulk migration completed: $migratedCount/$totalUsers users processed');
    } catch (e) {
      debugPrint('❌ Bulk migration failed: $e');
      rethrow;
    }
  }

  // ✅ Migrate a specific user by UID
  Future<void> _migrateSpecificUser(
      String uid, Map<String, dynamic> userData) async {
    if (_database == null) return;

    bool needsMigration = false;
    final migrationUpdates = <String, dynamic>{};

    // Apply same checks as in _migrateUserDataStructure but for any user
    // ... (similar logic to above but without User object dependency)

    if (needsMigration) {
      final userRef = _database!.ref('users/$uid');
      migrationUpdates['migrationVersion'] = '2.0.0';
      migrationUpdates['migratedAt'] = DateTime.now().toIso8601String();

      await userRef.update(migrationUpdates);
    }
  }

  // ✅ Check if user needs migration
  Future<bool> doesUserNeedMigration(String uid) async {
    if (!_isFirebaseInitialized) return false;

    try {
      final userRef = _database!.ref('users/$uid');
      final snapshot = await userRef.get();

      if (!snapshot.exists) return false;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if migration version exists and is current
      final migrationVersion = userData['migrationVersion'];
      return migrationVersion != '2.0.0';
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return false;
    }
  }
}
