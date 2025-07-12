// lib/src/core/services/user_migration_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

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
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _migrateUserDataStructure(user);
    } catch (e) {
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
      }
    } else {
      // Initialize empty favorites object
      needsMigration = true;
      migrationUpdates['favorites'] = <String, dynamic>{};
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
      }
    }

    // Apply migration if needed
    if (needsMigration) {
      migrationUpdates['migrationVersion'] = '2.0.0';
      migrationUpdates['migratedAt'] = DateTime.now().toIso8601String();

      await userRef.update(migrationUpdates);
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

    try {
      final usersRef = _database!.ref('users');
      final snapshot = await usersRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return;
      }

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in usersData.entries) {
        final uid = entry.key;
        final userData = Map<String, dynamic>.from(entry.value as Map);

        try {
          await _migrateSpecificUser(uid, userData);
        } catch (e) {
          // Continue with next user
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Migrate a specific user by UID
  Future<void> _migrateSpecificUser(
      String uid, Map<String, dynamic> userData) async {
    if (_database == null) return;

    // TODO: Implement specific user migration logic
    // This method currently serves as a placeholder for individual user migrations
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
      return false;
    }
  }
}
