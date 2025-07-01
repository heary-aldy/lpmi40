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

  // ✅ IMPROVED: Email/Password sign in with better error handling for type cast issues
  Future<User?> signInWithEmailPassword(String email, String password) async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign in');
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
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

        // Update last sign-in time
        await _updateUserSignInTime(user);

        return user;
      } else {
        debugPrint('❌ Sign-in failed: User is null');
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication succeeded but user is null',
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuth Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Sign-In Error: $e');

      // ✅ WORKAROUND: Handle Firebase SDK type cast issues
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint(
            '⚠️ Known Firebase SDK type cast issue detected during sign-in');
        debugPrint('🔄 Attempting to recover user from current auth state...');

        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null) {
          debugPrint(
              '✅ Successfully recovered user from auth state: ${currentUser.email}');

          // Update last sign-in time
          try {
            await _updateUserSignInTime(currentUser);
          } catch (updateError) {
            debugPrint('⚠️ Could not update sign-in time: $updateError');
          }

          return currentUser;
        } else {
          debugPrint('❌ Could not recover user from auth state');
          throw FirebaseAuthException(
            code: 'type-cast-recovery-failed',
            message:
                'Authentication may have succeeded but user details could not be retrieved due to SDK compatibility issue',
          );
        }
      }

      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Sign-in failed: ${e.toString()}',
      );
    }
  }

  // ✅ COMPLETELY REWRITTEN: User creation with robust error handling and type cast workarounds
  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot create user');
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    // Input validation
    if (email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Email cannot be empty',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password cannot be empty',
      );
    }

    if (displayName.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Display name cannot be empty',
      );
    }

    try {
      debugPrint('🔄 Creating user account for: $email');

      // Step 1: Create the user account
      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        debugPrint('❌ User creation failed: User is null');
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Account creation succeeded but user is null',
        );
      }

      debugPrint('✅ User account created: ${user.email}');

      try {
        // Step 2: Update the user's display name (with type cast error handling)
        debugPrint('🔄 Updating display name in Firebase Auth...');
        try {
          await user.updateDisplayName(displayName.trim());
          debugPrint('✅ Display name updated in Firebase Auth: $displayName');
        } catch (nameUpdateError) {
          if (nameUpdateError.toString().contains('PigeonUserDetails') ||
              nameUpdateError.toString().contains('PigeonUserInfo') ||
              nameUpdateError.toString().contains('type cast') ||
              nameUpdateError.toString().contains('List<Object?>')) {
            debugPrint(
                '⚠️ Firebase Auth display name update failed due to SDK type cast issue');
            debugPrint('📝 Will update display name in database only');
          } else {
            debugPrint('❌ Display name update failed: $nameUpdateError');
            rethrow;
          }
        }

        // Step 3: Reload the user to get updated information
        debugPrint('🔄 Reloading user...');
        try {
          await user.reload();
          debugPrint('✅ User reloaded successfully');
        } catch (reloadError) {
          debugPrint('⚠️ User reload failed (continuing anyway): $reloadError');
        }

        // Step 4: Get fresh user reference
        final refreshedUser = _auth!.currentUser;
        if (refreshedUser == null) {
          debugPrint(
              '⚠️ Warning: User is null after reload, using original user');
        } else {
          debugPrint(
              '✅ User reloaded, display name: ${refreshedUser.displayName}');
        }

        // Step 5: Create user document in Firebase Database
        debugPrint('🔄 Creating user document in database...');
        await _createUserDocumentWithProperStructure(
            refreshedUser ?? user, displayName.trim());
        debugPrint('✅ User document created successfully');

        // Step 6: Final verification
        await Future.delayed(const Duration(milliseconds: 300));
        final finalUser = _auth!.currentUser;

        debugPrint('✅ User creation process completed successfully');
        debugPrint(
            '✅ Final user: ${finalUser?.email}, display name: ${finalUser?.displayName ?? displayName}');

        return finalUser;
      } catch (profileError) {
        debugPrint(
            '⚠️ Profile setup failed but account was created: $profileError');

        // Try to clean up the created account if profile setup fails completely
        try {
          await user.delete();
          debugPrint('🔄 Cleaned up incomplete account');
        } catch (deleteError) {
          debugPrint('⚠️ Could not clean up account: $deleteError');
        }

        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuth Create User Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Create User Error: $e');

      // ✅ WORKAROUND: Handle Firebase SDK type cast issues during user creation
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint(
            '⚠️ Known Firebase SDK type cast issue detected during user creation');
        debugPrint('🔄 Attempting to recover user from current auth state...');

        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null) {
          debugPrint(
              '✅ Successfully recovered user from auth state: ${currentUser.email}');

          // Try to create user document
          try {
            await _createUserDocumentWithProperStructure(
                currentUser, displayName.trim());
            debugPrint('✅ User document created after recovery');
          } catch (docError) {
            debugPrint('⚠️ Could not create user document: $docError');
          }

          return currentUser;
        } else {
          debugPrint('❌ Could not recover user from auth state');
          throw FirebaseAuthException(
            code: 'type-cast-recovery-failed',
            message:
                'Account creation may have succeeded but user details could not be retrieved due to SDK compatibility issue',
          );
        }
      }

      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Account creation failed: ${e.toString()}',
      );
    }
  }

  // ✅ IMPROVED: Anonymous sign-in with better error handling for type cast issues
  Future<User?> signInAsGuest() async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign in as guest');
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    try {
      debugPrint('🔄 Signing in as guest...');
      final UserCredential userCredential = await _auth!.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Guest sign-in successful: ${user.uid}');

        // Update display name for guest (with type cast error handling)
        try {
          await user.updateDisplayName('Guest User');
          debugPrint('✅ Guest display name updated');
        } catch (nameUpdateError) {
          if (nameUpdateError.toString().contains('PigeonUserDetails') ||
              nameUpdateError.toString().contains('PigeonUserInfo') ||
              nameUpdateError.toString().contains('type cast') ||
              nameUpdateError.toString().contains('List<Object?>')) {
            debugPrint(
                '⚠️ Guest display name update failed due to SDK type cast issue');
            debugPrint('📝 Will set display name in database only');
          } else {
            debugPrint('❌ Guest display name update failed: $nameUpdateError');
          }
        }

        // Create user document
        await _createUserDocumentWithProperStructure(user, 'Guest User');

        debugPrint('✅ Guest user setup completed');
        return user;
      } else {
        debugPrint('❌ Guest sign-in failed: User is null');
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Guest sign-in succeeded but user is null',
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ FirebaseAuth Guest Sign-In Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected Guest Sign-In Error: $e');

      // ✅ WORKAROUND: Handle Firebase SDK type cast issues during guest sign-in
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint(
            '⚠️ Known Firebase SDK type cast issue detected during guest sign-in');
        debugPrint('🔄 Attempting to recover user from current auth state...');

        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null && currentUser.isAnonymous) {
          debugPrint('✅ Successfully recovered guest user from auth state');

          // Try to create user document
          try {
            await _createUserDocumentWithProperStructure(
                currentUser, 'Guest User');
            debugPrint('✅ Guest user document created after recovery');
          } catch (docError) {
            debugPrint('⚠️ Could not create guest user document: $docError');
          }

          return currentUser;
        } else {
          debugPrint('❌ Could not recover guest user from auth state');
          throw FirebaseAuthException(
            code: 'type-cast-recovery-failed',
            message:
                'Guest sign-in may have succeeded but user details could not be retrieved due to SDK compatibility issue',
          );
        }
      }

      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Guest sign-in failed: ${e.toString()}',
      );
    }
  }

  // ✅ IMPROVED: Sign out with error handling
  Future<void> signOut() async {
    if (!isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized, cannot sign out');
      return;
    }

    try {
      debugPrint('🔄 Signing out...');
      await _auth?.signOut();
      debugPrint('✅ Successfully signed out');
    } catch (e) {
      debugPrint('❌ Sign Out Error: $e');
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Sign out failed: ${e.toString()}',
      );
    }
  }

  // ✅ FIXED: Create user document with proper error handling and retry logic
  Future<void> _createUserDocumentWithProperStructure(User user,
      [String? displayName]) async {
    if (!isFirebaseInitialized) {
      debugPrint(
          '⚠️ Firebase not initialized, skipping user document creation');
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final database = _database!;
        final userRef = database.ref('users/${user.uid}');
        final currentTime = DateTime.now().toIso8601String();

        // Check if user document already exists
        debugPrint('🔄 Checking if user document exists...');
        final snapshot = await userRef.get();

        // Prepare user data with exact structure
        final userData = <String, dynamic>{
          'uid': user.uid,
          'displayName': displayName ??
              user.displayName ??
              (user.isAnonymous ? 'Guest User' : 'LPMI User'),
          'email': user.email ??
              (user.isAnonymous
                  ? 'anonymous@guest.com'
                  : 'no-email@unknown.com'),
          'role': 'user',
          'lastSignIn': currentTime,
        };

        if (!snapshot.exists) {
          // NEW USER: Add createdAt and initialize empty favorites
          userData['createdAt'] = currentTime;
          userData['favorites'] = <String, dynamic>{};

          debugPrint('🔄 Creating new user document...');
          await userRef.set(userData);
          debugPrint('✅ NEW user document created: ${userData['displayName']}');
        } else {
          // EXISTING USER: Only update lastSignIn and displayName if provided
          final updateData = <String, dynamic>{
            'lastSignIn': currentTime,
          };

          if (displayName != null && displayName.isNotEmpty) {
            updateData['displayName'] = displayName;
          }

          debugPrint('🔄 Updating existing user document...');
          await userRef.update(updateData);
          debugPrint(
              '✅ EXISTING user document updated: ${updateData['displayName'] ?? 'no name update'}');
        }

        // Success, break out of retry loop
        break;
      } catch (e) {
        retryCount++;
        debugPrint(
            '❌ User document error (attempt $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          debugPrint(
              '❌ Failed to create/update user document after $maxRetries attempts');
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  // ✅ IMPROVED: Update sign-in time with retry logic
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

  // ✅ IMPROVED: Reset password with proper validation
  Future<bool> resetPassword(String email) async {
    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    if (email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Email cannot be empty',
      );
    }

    try {
      debugPrint('🔄 Sending password reset email to: $email');
      await _auth!.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected password reset error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  // ✅ IMPROVED: Get current user info with error handling
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
        'phoneNumber': user.phoneNumber,
        'tenantId': user.tenantId,
      };
    } catch (e) {
      debugPrint('❌ Error getting user info: $e');
      return null;
    }
  }

  // ✅ IMPROVED: Check if user is admin with fallback logic
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
      const adminEmails = [
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

  // ✅ FIXED: Update user role with proper type handling and validation
  Future<bool> updateUserRole(String userId, String role,
      {List<String>? permissions}) async {
    if (!isFirebaseInitialized || !isSignedIn) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not authenticated',
      );
    }

    // Validate role
    const validRoles = ['user', 'admin', 'super_admin'];
    if (!validRoles.contains(role.toLowerCase())) {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Invalid role: $role',
      );
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
        final permissionsList = permissions ??
            <String>['manage_songs', 'view_analytics', 'access_debug'];
        updateData['permissions'] = permissionsList;
      }

      // Apply the update
      await userRef.update(updateData);

      // Remove admin-specific fields for regular users
      if (role.toLowerCase() == 'user') {
        try {
          await userRef.child('adminGrantedAt').remove();
          await userRef.child('permissions').remove();
        } catch (e) {
          debugPrint('⚠️ Could not remove admin fields: $e');
        }
      }

      debugPrint('✅ User role updated to $role for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Update user role error: $e');
      rethrow;
    }
  }

  // ✅ NEW: Initialize favorites for existing users
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

  // ✅ NEW: Get user by UID with full data structure
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

  // ✅ NEW: Refresh current user
  Future<void> refreshCurrentUser() async {
    try {
      await currentUser?.reload();
      debugPrint('✅ Current user refreshed');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh current user: $e');
    }
  }

  // ✅ NEW: Check Firebase connection
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

  // ✅ NEW: Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  // ✅ NEW: Validate password strength
  Map<String, dynamic> validatePassword(String password) {
    final errors = <String>[];
    final warnings = <String>[];
    bool isValid = true;

    if (password.isEmpty) {
      isValid = false;
      errors.add('Password cannot be empty');
      return {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'strength': 'weak',
      };
    }

    if (password.length < 6) {
      isValid = false;
      errors.add('Password must be at least 6 characters');
    }

    // Check for strength indicators
    int strengthScore = 0;

    if (password.length >= 8) strengthScore++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[a-z]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[0-9]').hasMatch(password)) strengthScore++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strengthScore++;

    // Determine strength
    String strength;
    if (strengthScore >= 4) {
      strength = 'strong';
    } else if (strengthScore >= 2) {
      strength = 'medium';
    } else {
      strength = 'weak';
      if (isValid) {
        warnings.add('Consider using a stronger password');
      }
    }

    return {
      'isValid': isValid,
      'errors': errors,
      'warnings': warnings,
      'strength': strength,
    };
  }

  // ✅ NEW: Validate display name
  Map<String, dynamic> validateDisplayName(String name) {
    final errors = <String>[];
    bool isValid = true;

    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      isValid = false;
      errors.add('Name cannot be empty');
      return {
        'isValid': isValid,
        'errors': errors,
      };
    }

    if (trimmedName.length < 2) {
      isValid = false;
      errors.add('Name must be at least 2 characters');
    }

    if (trimmedName.length > 50) {
      isValid = false;
      errors.add('Name must be less than 50 characters');
    }

    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(trimmedName)) {
      isValid = false;
      errors.add(
          'Name can only contain letters, spaces, hyphens, and apostrophes');
    }

    return {
      'isValid': isValid,
      'errors': errors,
    };
  }
}
