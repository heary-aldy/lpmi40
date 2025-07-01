// lib/src/core/services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Check if Firebase is initialized
  bool get isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      return false;
    }
  }

  // Safe getters that return null if Firebase not initialized
  FirebaseAuth? get _auth =>
      isFirebaseInitialized ? FirebaseAuth.instance : null;
  FirebaseDatabase? get _database =>
      isFirebaseInitialized ? FirebaseDatabase.instance : null;

  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => currentUser != null;

  // Email/Password authentication
  Future<User?> signInWithEmailPassword(String email, String password) async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign in');
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Attempting sign in for: $email');

      final UserCredential userCredential =
          await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Email sign-in successful for: ${user.email}');

        // Update last sign-in time using proper structure
        await _updateUserSignInTime(user);

        return user;
      } else {
        debugPrint('❌ Sign-in failed: User is null');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuth Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Sign-In Error: $e');
      throw Exception('Sign-in failed: ${e.toString()}');
    }
  }

  // User creation with EXACT data structure from your export
  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot create user');
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Creating user account for: $email');

      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        debugPrint('✅ User account created: ${user.email}');

        try {
          // Update the user's display name in Firebase Auth
          await user.updateDisplayName(displayName);
          debugPrint('✅ Display name updated in Firebase Auth: $displayName');

          // Create user document with EXACT structure from your export
          await _createUserDocumentWithProperStructure(user, displayName);
          debugPrint('✅ User document created with proper structure');

          // Reload user to get updated information
          await user.reload();
          final updatedUser = _auth!.currentUser;

          debugPrint('✅ User creation process completed successfully');
          return updatedUser;
        } catch (profileError) {
          debugPrint(
              '⚠️ Profile setup failed but account was created: $profileError');
          return user;
        }
      } else {
        debugPrint('❌ User creation failed: User is null');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuth Create User Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Create User Error: $e');
      throw Exception('Account creation failed: ${e.toString()}');
    }
  }

  // Anonymous sign-in with proper structure
  Future<User?> signInAsGuest() async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign in as guest');
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Signing in as guest...');
      final UserCredential userCredential = await _auth!.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName('Guest User');
        await _createUserDocumentWithProperStructure(user, 'Guest User');
        debugPrint('✅ Guest sign-in successful');
        return user;
      } else {
        debugPrint('❌ Guest sign-in failed: User is null');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ FirebaseAuth Guest Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Guest Sign-In Error: $e');
      throw Exception('Guest sign-in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign out');
      return;
    }

    try {
      await _auth?.signOut();
      debugPrint('✅ Successfully signed out');
    } catch (e) {
      debugPrint('❌ Sign Out Error: $e');
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // ✅ FIXED: Create user document with EXACT structure from your Firebase export
  Future<void> _createUserDocumentWithProperStructure(User user,
      [String? displayName]) async {
    if (!isFirebaseInitialized) {
      debugPrint(
          '⚠️ Firebase not initialized, skipping user document creation');
      return;
    }

    try {
      final database = _database!;
      final userRef = database.ref('users/${user.uid}');

      // Check if user document already exists
      final snapshot = await userRef.get();
      final currentTime = DateTime.now().toIso8601String();

      // EXACT structure matching your Firebase export
      final userData = <String, dynamic>{
        'uid': user.uid,
        'displayName': displayName ??
            user.displayName ??
            (user.isAnonymous ? 'Guest User' : 'LPMI User'),
        'email': user.email ??
            (user.isAnonymous ? 'anonymous@guest.com' : 'no-email@unknown.com'),
        'role': 'user', // Default role - exactly as in your export
        'lastSignIn': currentTime,
      };

      if (!snapshot.exists) {
        // NEW USER: Add createdAt and initialize empty favorites
        userData['createdAt'] = currentTime;
        userData['favorites'] =
            <String, dynamic>{}; // Initialize empty favorites object

        await userRef.set(userData);
        debugPrint('✅ NEW user document created with structure: $userData');
      } else {
        // EXISTING USER: Only update lastSignIn and displayName if provided
        final updateData = <String, dynamic>{
          'lastSignIn': currentTime,
        };

        if (displayName != null) {
          updateData['displayName'] = displayName;
        }

        await userRef.update(updateData);
        debugPrint('✅ EXISTING user document updated: $updateData');
      }
    } catch (e) {
      debugPrint('❌ Create/Update User Document Error: $e');
      rethrow; // Throw error so calling code knows something went wrong
    }
  }

  // Update sign-in time with proper structure
  Future<void> _updateUserSignInTime(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = _database!;
      final userRef = database.ref('users/${user.uid}');

      await userRef.update({
        'lastSignIn': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Updated sign-in time for: ${user.email}');
    } catch (e) {
      debugPrint('⚠️ Failed to update sign-in time: $e');
      // Don't throw as this is not critical
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Sending password reset email to: $email');
      await _auth!.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected password reset error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Get current user info
  Map<String, dynamic>? getCurrentUserInfo() {
    try {
      final user = currentUser;
      if (user == null) return null;

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'isEmailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'photoURL': user.photoURL,
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting user info: $e');
      return null;
    }
  }

  // Check if user is admin with proper role checking
  Future<bool> isUserAdmin() async {
    if (!isFirebaseInitialized || !isSignedIn) return false;

    try {
      final database = _database!;
      final userRef = database.ref('users/${currentUser!.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final role = userData['role']?.toString().toLowerCase();
        return role == 'admin' || role == 'super_admin';
      }

      // Fallback: Check by email for known admin emails
      final adminEmails = [
        'heary_aldy@hotmail.com',
        'heary@hopetv.asia',
        'admin@hopetv.asia',
        'admin@lpmi.com',
        'admin@haweeinc.com'
      ];

      final userEmail = currentUser?.email?.toLowerCase();
      if (userEmail != null && adminEmails.contains(userEmail)) {
        debugPrint('✅ Admin status granted via fallback email check');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Admin check error: $e');
      return false;
    }
  }

  // ✅ COMPLETELY FIXED: Update user role with proper type handling
  Future<bool> updateUserRole(String userId, String role,
      {List<String>? permissions}) async {
    if (!isFirebaseInitialized || !isSignedIn) {
      throw Exception('Not authenticated');
    }

    // Validate role
    const validRoles = ['user', 'admin', 'super_admin'];
    if (!validRoles.contains(role.toLowerCase())) {
      throw Exception('Invalid role: $role');
    }

    try {
      final database = _database!;
      final userRef = database.ref('users/$userId');
      final currentTime = DateTime.now().toIso8601String();

      // Create update data with proper types
      final updateData = <String, dynamic>{
        'role': role.toLowerCase(),
        'updatedAt': currentTime,
        'updatedBy': currentUser!.uid,
      };

      // Handle admin-specific fields
      if (role.toLowerCase() == 'admin' ||
          role.toLowerCase() == 'super_admin') {
        updateData['adminGrantedAt'] = currentTime;
        // ✅ FIXED: Ensure permissions is properly typed
        final permissionsList = permissions ??
            <String>['manage_songs', 'view_analytics', 'access_debug'];
        updateData['permissions'] = permissionsList;
      }

      // Apply the update
      await userRef.update(updateData);

      // ✅ FIXED: Handle removal of admin fields separately for regular users
      if (role.toLowerCase() == 'user') {
        // Remove admin-specific fields for regular users
        await userRef.child('adminGrantedAt').remove();
        await userRef.child('permissions').remove();
      }

      debugPrint('✅ User role updated to $role for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Update user role error: $e');
      rethrow;
    }
  }

  // Initialize favorites for existing users
  Future<void> initializeFavoritesForUser(String userId) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = _database!;
      final userRef = database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);

        // Only initialize if favorites don't exist
        if (userData['favorites'] == null) {
          await userRef.update({
            'favorites': <String, dynamic>{},
            'updatedAt': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ Initialized empty favorites for user: $userId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing favorites: $e');
    }
  }

  // Get user by UID with full data structure
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (!isFirebaseInitialized) return null;

    try {
      final database = _database!;
      final userRef = database.ref('users/$userId');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  // Refresh current user
  Future<void> refreshCurrentUser() async {
    try {
      await currentUser?.reload();
      debugPrint('✅ Current user refreshed');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh current user: $e');
    }
  }

  // Check Firebase connection
  Future<bool> checkConnection() async {
    if (!isFirebaseInitialized) return false;

    try {
      final database = _database!;
      final ref = database.ref('.info/connected');
      final snapshot = await ref.get();
      return snapshot.value as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Connection check failed: $e');
      return false;
    }
  }
}
