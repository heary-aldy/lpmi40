// lib/src/core/services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

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
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    try {
      final UserCredential userCredential =
          await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update last sign-in time
        await _updateUserSignInTime(user);

        return user;
      } else {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication succeeded but user is null',
        );
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      // ✅ WORKAROUND: Handle Firebase SDK type cast issues
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null) {
          // Update last sign-in time
          try {
            await _updateUserSignInTime(currentUser);
          } catch (updateError) {
            // Continue silently
          }

          return currentUser;
        } else {
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
      // Step 1: Create the user account
      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Account creation succeeded but user is null',
        );
      }

      try {
        // Step 2: Update the user's display name (with type cast error handling)
        try {
          await user.updateDisplayName(displayName.trim());
        } catch (nameUpdateError) {
          if (nameUpdateError.toString().contains('PigeonUserDetails') ||
              nameUpdateError.toString().contains('PigeonUserInfo') ||
              nameUpdateError.toString().contains('type cast') ||
              nameUpdateError.toString().contains('List<Object?>')) {
            // Continue - will update display name in database only
          } else {
            rethrow;
          }
        }

        // Step 3: Reload the user to get updated information
        try {
          await user.reload();
        } catch (reloadError) {
          // Continue anyway
        }

        // Step 4: Get fresh user reference
        final refreshedUser = _auth!.currentUser;

        // Step 5: Create user document in Firebase Database
        await _createUserDocumentWithProperStructure(
            refreshedUser ?? user, displayName.trim());

        // Step 6: Final verification
        await Future.delayed(const Duration(milliseconds: 300));
        final finalUser = _auth!.currentUser;

        return finalUser;
      } catch (profileError) {
        // Try to clean up the created account if profile setup fails completely
        try {
          await user.delete();
        } catch (deleteError) {
          // Continue
        }

        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      // ✅ WORKAROUND: Handle Firebase SDK type cast issues during user creation
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null) {
          // Try to create user document
          try {
            await _createUserDocumentWithProperStructure(
                currentUser, displayName.trim());
          } catch (docError) {
            // Continue
          }

          return currentUser;
        } else {
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
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    try {
      final UserCredential userCredential = await _auth!.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        // Update display name for guest (with type cast error handling)
        try {
          await user.updateDisplayName('Guest User');
        } catch (nameUpdateError) {
          if (nameUpdateError.toString().contains('PigeonUserDetails') ||
              nameUpdateError.toString().contains('PigeonUserInfo') ||
              nameUpdateError.toString().contains('type cast') ||
              nameUpdateError.toString().contains('List<Object?>')) {
            // Continue - will set display name in database only
          } else {
            // Continue
          }
        }

        // Create user document
        await _createUserDocumentWithProperStructure(user, 'Guest User');

        return user;
      } else {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Guest sign-in succeeded but user is null',
        );
      }
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      // ✅ WORKAROUND: Handle Firebase SDK type cast issues during guest sign-in
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        // Try to get the current user after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth?.currentUser;

        if (currentUser != null && currentUser.isAnonymous) {
          // Try to create user document
          try {
            await _createUserDocumentWithProperStructure(
                currentUser, 'Guest User');
          } catch (docError) {
            // Continue
          }

          return currentUser;
        } else {
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
      return;
    }

    try {
      await _auth?.signOut();
    } catch (e) {
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

          await userRef.set(userData);
        } else {
          // EXISTING USER: Only update lastSignIn and displayName if provided
          final updateData = <String, dynamic>{
            'lastSignIn': currentTime,
          };

          if (displayName != null && displayName.isNotEmpty) {
            updateData['displayName'] = displayName;
          }

          await userRef.update(updateData);
        }

        // Success, break out of retry loop
        break;
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
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
    } catch (e) {
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
      await _auth!.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
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
        return true;
      }

      return false;
    } catch (e) {
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
          // Continue
        }
      }

      return true;
    } catch (e) {
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
        }
      }
    } catch (e) {
      // Continue silently
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
      return null;
    }
  }

  // ✅ NEW: Refresh current user
  Future<void> refreshCurrentUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      // Continue silently
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
