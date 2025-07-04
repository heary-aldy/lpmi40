// lib/src/core/services/firebase_service.dart
// 🟢 PHASE 1: Added connection info helper, better logging, performance tracking
// 🔵 ORIGINAL: All existing methods preserved exactly

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // ✅ ADDED: For debugPrint

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ✅ NEW: Verification tracking
  DateTime? _lastVerificationSent;
  static const Duration _verificationCooldown = Duration(minutes: 1);

  // 🟢 NEW: Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

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

  // 🟢 NEW: Connection info helper (doesn't change existing methods)
  Map<String, dynamic> getConnectionInfo() {
    final currentUser = this.currentUser;
    return {
      'isInitialized': isFirebaseInitialized,
      'hasCurrentUser': currentUser != null,
      'userType': currentUser?.isAnonymous == true ? 'guest' : 'registered',
      'userEmail': currentUser?.email,
      'isEmailVerified': currentUser?.emailVerified,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // 🟢 NEW: Firebase setup validation (optional use)
  Future<Map<String, dynamic>> validateFirebaseSetup() async {
    final info = <String, dynamic>{
      'firebase_initialized': isFirebaseInitialized,
      'auth_available': _auth != null,
      'database_available': _database != null,
    };

    if (isFirebaseInitialized) {
      try {
        final connection = await checkConnection();
        info['connection_test'] = connection;
      } catch (e) {
        info['connection_error'] = e.toString();
      }
    }

    return info;
  }

  // 🟢 NEW: Performance tracking helper
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('🔧 Firebase Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('📊 Details: $details');
      }
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
      return 'Unable to complete request. Please try again later.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists. Please sign in instead.';
    } else if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please check your email or sign up.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // ✅ ENHANCED: Email verification methods with comprehensive error handling
  /// Send email verification with rate limiting and enhanced error handling
  Future<Map<String, dynamic>> sendEmailVerification() async {
    _logOperation('sendEmailVerification'); // 🟢 NEW: Performance tracking

    try {
      final user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'no-user',
          'message': 'No user is currently signed in'
        };
      }

      if (user.isAnonymous) {
        return {
          'success': false,
          'error': 'anonymous-user',
          'message': 'Anonymous users cannot verify email'
        };
      }

      if (user.email == null || user.email!.isEmpty) {
        return {
          'success': false,
          'error': 'no-email',
          'message': 'User has no email address'
        };
      }

      if (user.emailVerified) {
        debugPrint('✅ Email already verified for: ${user.email}');
        return {
          'success': true,
          'alreadyVerified': true,
          'message': 'Email is already verified'
        };
      }

      // ✅ NEW: Check rate limiting
      if (_lastVerificationSent != null) {
        final timeSinceLastSent =
            DateTime.now().difference(_lastVerificationSent!);
        if (timeSinceLastSent < _verificationCooldown) {
          final remainingSeconds =
              _verificationCooldown.inSeconds - timeSinceLastSent.inSeconds;
          return {
            'success': false,
            'error': 'rate-limited',
            'message':
                'Please wait $remainingSeconds seconds before requesting another verification email',
            'remainingSeconds': remainingSeconds
          };
        }
      }

      await user.sendEmailVerification();
      _lastVerificationSent = DateTime.now();

      debugPrint('📧 Email verification sent to: ${user.email}');

      // ✅ NEW: Update database with verification attempt
      await _updateVerificationAttempt(user);

      return {
        'success': true,
        'message': 'Verification email sent successfully',
        'email': user.email,
        'sentAt': _lastVerificationSent!.toIso8601String()
      };
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ Firebase Auth error sending verification: ${e.code} - ${e.message}');

      // 🟢 IMPROVED: User-friendly error messages
      String userMessage = _getUserFriendlyErrorMessage(e);

      // Specific cases for verification
      switch (e.code) {
        case 'too-many-requests':
          userMessage =
              'Too many verification emails sent. Please wait before trying again.';
          break;
        case 'user-disabled':
          userMessage = 'This account has been disabled.';
          break;
      }

      return {
        'success': false,
        'error': e.code,
        'message': userMessage,
        'originalMessage': e.message
      };
    } catch (e) {
      debugPrint('❌ Unexpected error sending verification: $e');
      return {
        'success': false,
        'error': 'unknown-error',
        'message':
            _getUserFriendlyErrorMessage(e) // 🟢 NEW: User-friendly message
      };
    }
  }

  /// Check email verification status with force refresh option
  Future<Map<String, dynamic>> checkEmailVerification(
      {bool forceRefresh = false}) async {
    _logOperation(
        'checkEmailVerification', {'forceRefresh': forceRefresh}); // 🟢 NEW

    try {
      final user = currentUser;
      if (user == null) {
        return {
          'isVerified': false,
          'error': 'no-user',
          'message': 'No user is currently signed in'
        };
      }

      if (user.isAnonymous) {
        return {
          'isVerified': false,
          'isAnonymous': true,
          'message': 'Anonymous users do not have email verification'
        };
      }

      // ✅ ENHANCED: Force refresh if requested or if it's been a while
      if (forceRefresh || _shouldRefreshVerificationStatus()) {
        await user.reload();
        debugPrint('🔄 Refreshed user verification status');
      }

      final updatedUser = _auth?.currentUser;
      final isVerified = updatedUser?.emailVerified ?? false;

      debugPrint(
          '🔍 Email verification status: $isVerified for ${updatedUser?.email}');

      // ✅ NEW: Update database with current verification status
      if (updatedUser != null) {
        await _syncVerificationStatusToDatabase(updatedUser);
      }

      return {
        'isVerified': isVerified,
        'email': updatedUser?.email,
        'lastChecked': DateTime.now().toIso8601String(),
        'user': updatedUser != null
            ? {
                'uid': updatedUser.uid,
                'email': updatedUser.email,
                'emailVerified': updatedUser.emailVerified,
                'displayName': updatedUser.displayName,
              }
            : null
      };
    } catch (e) {
      debugPrint('❌ Failed to check email verification: $e');
      return {
        'isVerified': false,
        'error': 'check-failed',
        'message':
            _getUserFriendlyErrorMessage(e) // 🟢 NEW: User-friendly message
      };
    }
  }

  /// Get comprehensive verification status including database sync
  Future<Map<String, dynamic>> getVerificationStatus() async {
    _logOperation('getVerificationStatus'); // 🟢 NEW

    try {
      final user = currentUser;
      if (user == null) {
        return {
          'hasUser': false,
          'isVerified': false,
          'canVerify': false,
          'message': 'No user signed in'
        };
      }

      final isAnonymous = user.isAnonymous;
      final hasEmail = user.email != null && user.email!.isNotEmpty;
      final isVerified = user.emailVerified;

      // ✅ NEW: Get database verification info
      Map<String, dynamic>? dbVerificationInfo;
      try {
        dbVerificationInfo = await _getDatabaseVerificationInfo(user.uid);
      } catch (e) {
        debugPrint('⚠️ Could not get database verification info: $e');
      }

      // ✅ NEW: Calculate time since last verification attempt
      String? lastVerificationAttempt;
      bool canSendVerification = true;
      int? cooldownRemaining;

      if (_lastVerificationSent != null) {
        lastVerificationAttempt = _lastVerificationSent!.toIso8601String();
        final timeSinceLastSent =
            DateTime.now().difference(_lastVerificationSent!);
        if (timeSinceLastSent < _verificationCooldown) {
          canSendVerification = false;
          cooldownRemaining =
              _verificationCooldown.inSeconds - timeSinceLastSent.inSeconds;
        }
      }

      return {
        'hasUser': true,
        'isAnonymous': isAnonymous,
        'hasEmail': hasEmail,
        'email': user.email,
        'isVerified': isVerified,
        'canVerify': !isAnonymous && hasEmail && !isVerified,
        'canSendVerification': canSendVerification,
        'cooldownRemaining': cooldownRemaining,
        'lastVerificationAttempt': lastVerificationAttempt,
        'databaseInfo': dbVerificationInfo,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'emailVerified': user.emailVerified,
          'displayName': user.displayName,
          'creationTime': user.metadata.creationTime?.toIso8601String(),
        }
      };
    } catch (e) {
      debugPrint('❌ Failed to get verification status: $e');
      return {
        'hasUser': false,
        'isVerified': false,
        'canVerify': false,
        'error': 'status-failed',
        'message':
            _getUserFriendlyErrorMessage(e) // 🟢 NEW: User-friendly message
      };
    }
  }

  /// Convenient getter for email verification status
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Check if user requires email verification for certain features
  bool get requiresEmailVerification {
    final user = currentUser;
    if (user == null || user.isAnonymous) return false;
    return user.email != null && !user.emailVerified;
  }

  // ✅ NEW: USER DELETION AND CLEANUP METHODS

  /// Delete user from both Firebase Auth and Database
  Future<Map<String, dynamic>> deleteUserCompletely(String userId) async {
    _logOperation('deleteUserCompletely', {'userId': userId}); // 🟢 NEW

    if (!isFirebaseInitialized || !isSignedIn) {
      return {
        'success': false,
        'error': 'not-authenticated',
        'message': 'User not authenticated',
      };
    }

    try {
      final database = _database!;

      // Step 1: Get user data before deletion (for logging)
      final userRef = database.ref('users/$userId');
      final snapshot = await userRef.get();
      Map<String, dynamic>? userData;

      if (snapshot.exists && snapshot.value != null) {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Step 2: Delete from Firebase Database
      await userRef.remove();
      debugPrint('✅ Deleted user data from Firebase Database: $userId');

      // Step 3: Note about Firebase Auth deletion
      // CLIENT-SIDE LIMITATION: Cannot delete users from Firebase Auth
      // This requires Firebase Admin SDK on a server/cloud function

      return {
        'success': true,
        'deletedFromDatabase': true,
        'deletedFromAuth': false,
        'message':
            'User data deleted from database. Firebase Auth deletion requires admin privileges.',
        'userData': userData,
        'note':
            'Use Firebase Console or Admin SDK to delete from Authentication',
      };
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      return {
        'success': false,
        'error': 'deletion-failed',
        'message':
            _getUserFriendlyErrorMessage(e), // 🟢 NEW: User-friendly message
      };
    }
  }

  /// Check if user exists in database but not in current auth context
  Future<List<String>> findOrphanedUsers() async {
    _logOperation('findOrphanedUsers'); // 🟢 NEW

    if (!isFirebaseInitialized) return [];

    try {
      final database = _database!;
      final usersRef = database.ref('users');
      final snapshot = await usersRef.get();

      if (!snapshot.exists || snapshot.value == null) return [];

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      final orphanedUsers = <String>[];

      // This is a simplified check - in production you'd use Firebase Admin SDK
      for (final entry in usersData.entries) {
        final uid = entry.key;
        final userData = Map<String, dynamic>.from(entry.value as Map);

        // Check for signs of orphaned user (missing required fields, very old, etc.)
        final lastSignIn = userData['lastSignIn'];
        final createdAt = userData['createdAt'];

        if (lastSignIn == null && createdAt != null) {
          try {
            final created = DateTime.parse(createdAt.toString());
            final daysSinceCreation = DateTime.now().difference(created).inDays;

            // If user was created more than 30 days ago and never signed in,
            // they might be orphaned
            if (daysSinceCreation > 30) {
              orphanedUsers.add(uid);
            }
          } catch (e) {
            // Continue
          }
        }
      }

      return orphanedUsers;
    } catch (e) {
      debugPrint('❌ Error finding orphaned users: $e');
      return [];
    }
  }

  /// Bulk cleanup of orphaned database records
  Future<Map<String, dynamic>> cleanupOrphanedUsers(
      List<String> userIds) async {
    _logOperation('cleanupOrphanedUsers', {'count': userIds.length}); // 🟢 NEW

    if (!isFirebaseInitialized || userIds.isEmpty) {
      return {
        'success': false,
        'message': 'No users to cleanup or Firebase not initialized',
      };
    }

    try {
      final database = _database!;
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (final userId in userIds) {
        try {
          final userRef = database.ref('users/$userId');
          await userRef.remove();
          successCount++;
          debugPrint('✅ Cleaned up orphaned user: $userId');
        } catch (e) {
          errorCount++;
          errors.add('$userId: $e');
          debugPrint('❌ Error cleaning up user $userId: $e');
        }
      }

      return {
        'success': errorCount == 0,
        'totalProcessed': userIds.length,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
        'message':
            'Cleaned up $successCount of ${userIds.length} orphaned users',
      };
    } catch (e) {
      debugPrint('❌ Error during bulk cleanup: $e');
      return {
        'success': false,
        'error': 'cleanup-failed',
        'message':
            _getUserFriendlyErrorMessage(e), // 🟢 NEW: User-friendly message
      };
    }
  }

  // ✅ NEW: Private helper methods for verification management

  /// Check if we should refresh verification status
  bool _shouldRefreshVerificationStatus() {
    // Refresh every 30 seconds when checking verification
    return true; // For now, always refresh to ensure accuracy
  }

  /// Update database when verification email is sent
  Future<void> _updateVerificationAttempt(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = _database!;
      final userRef = database.ref('users/${user.uid}');

      await userRef.update({
        'lastVerificationEmailSent': DateTime.now().toIso8601String(),
        'verificationEmailCount': ServerValue.increment(1),
        'emailVerified': user.emailVerified,
      });
    } catch (e) {
      debugPrint('⚠️ Failed to update verification attempt in database: $e');
      // Don't throw as this is not critical
    }
  }

  /// Sync verification status to database
  Future<void> _syncVerificationStatusToDatabase(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = _database!;
      final userRef = database.ref('users/${user.uid}');

      await userRef.update({
        'emailVerified': user.emailVerified,
        'lastVerificationCheck': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Failed to sync verification status to database: $e');
      // Don't throw as this is not critical
    }
  }

  /// Get verification info from database
  Future<Map<String, dynamic>?> _getDatabaseVerificationInfo(String uid) async {
    if (!isFirebaseInitialized) return null;

    try {
      final database = _database!;
      final userRef = database.ref('users/$uid');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        return {
          'emailVerified': userData['emailVerified'] ?? false,
          'lastVerificationEmailSent': userData['lastVerificationEmailSent'],
          'verificationEmailCount': userData['verificationEmailCount'] ?? 0,
          'lastVerificationCheck': userData['lastVerificationCheck'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get database verification info: $e');
      return null;
    }
  }

  // ✅ IMPROVED: Email/Password sign in with better error handling for type cast issues
  Future<User?> signInWithEmailPassword(String email, String password) async {
    _logOperation('signInWithEmailPassword', {'email': email}); // 🟢 NEW

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
        // Update last sign-in time and verification status
        await _updateUserSignInTime(user);

        return user;
      } else {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication succeeded but user is null',
        );
      }
    } on FirebaseAuthException {
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

  // ✅ ENHANCED: User creation with comprehensive email verification
  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    _logOperation('createUserWithEmailPassword',
        {'email': email, 'displayName': displayName}); // 🟢 NEW

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

        // Step 3: Send email verification with enhanced tracking
        try {
          await user.sendEmailVerification();
          _lastVerificationSent = DateTime.now();
          debugPrint('📧 Email verification sent to: ${user.email}');
        } catch (verificationError) {
          debugPrint('⚠️ Email verification failed: $verificationError');
          // Don't fail the entire registration for verification errors
        }

        // Step 4: Reload the user to get updated information
        try {
          await user.reload();
        } catch (reloadError) {
          // Continue anyway
        }

        // Step 5: Get fresh user reference
        final refreshedUser = _auth!.currentUser;

        // Step 6: Create user document in Firebase Database with verification tracking
        await _createUserDocumentWithProperStructure(
            refreshedUser ?? user, displayName.trim());

        // Step 7: Final verification
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
    } on FirebaseAuthException {
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
          // Try to send verification and create user document
          try {
            await currentUser.sendEmailVerification();
            _lastVerificationSent = DateTime.now();
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
    _logOperation('signInAsGuest'); // 🟢 NEW

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
    } on FirebaseAuthException {
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
    _logOperation('signOut'); // 🟢 NEW

    if (!isFirebaseInitialized) {
      return;
    }

    try {
      // ✅ NEW: Clear verification tracking on sign out
      _lastVerificationSent = null;

      await _auth?.signOut();
    } catch (e) {
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Sign out failed: ${e.toString()}',
      );
    }
  }

  // ✅ ENHANCED: Create user document with comprehensive email verification tracking
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

        // Prepare user data with exact structure including comprehensive email verification
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
          'emailVerified': user.emailVerified, // ✅ Track verification status
        };

        if (!snapshot.exists) {
          // NEW USER: Add createdAt, initialize empty favorites, and verification tracking
          userData['createdAt'] = currentTime;
          userData['favorites'] = <String, dynamic>{};

          // ✅ NEW: Initialize verification tracking for non-anonymous users
          if (!user.isAnonymous && user.email != null) {
            userData['verificationEmailCount'] =
                _lastVerificationSent != null ? 1 : 0;
            if (_lastVerificationSent != null) {
              userData['lastVerificationEmailSent'] =
                  _lastVerificationSent!.toIso8601String();
            }
          }

          await userRef.set(userData);
        } else {
          // EXISTING USER: Update lastSignIn, displayName if provided, and verification status
          final updateData = <String, dynamic>{
            'lastSignIn': currentTime,
            'emailVerified':
                user.emailVerified, // ✅ Always update verification status
          };

          if (displayName != null && displayName.isNotEmpty) {
            updateData['displayName'] = displayName;
          }

          // ✅ NEW: Update verification tracking if this is a verification email send
          if (_lastVerificationSent != null && !user.isAnonymous) {
            updateData['lastVerificationEmailSent'] =
                _lastVerificationSent!.toIso8601String();
            updateData['verificationEmailCount'] = ServerValue.increment(1);
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

  // ✅ ENHANCED: Update sign-in time with comprehensive verification status
  Future<void> _updateUserSignInTime(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = _database!;
      final userRef = database.ref('users/${user.uid}');

      await userRef.update({
        'lastSignIn': DateTime.now().toIso8601String(),
        'emailVerified':
            user.emailVerified, // ✅ Update verification status on sign-in
        'lastVerificationCheck': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't throw as this is not critical
    }
  }

  // ✅ IMPROVED: Reset password with proper validation
  Future<bool> resetPassword(String email) async {
    _logOperation('resetPassword', {'email': email}); // 🟢 NEW

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
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  // ✅ ENHANCED: Get current user info with comprehensive verification status
  Map<String, dynamic>? getCurrentUserInfo() {
    try {
      final user = currentUser;
      if (user == null) return null;

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'isEmailVerified': user.emailVerified, // ✅ Include verification status
        'requiresVerification':
            !user.isAnonymous && user.email != null && !user.emailVerified,
        'canSendVerification':
            !user.isAnonymous && user.email != null && !user.emailVerified,
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
    _logOperation('isUserAdmin'); // 🟢 NEW

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
    _logOperation('updateUserRole', {'userId': userId, 'role': role}); // 🟢 NEW

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
    _logOperation('getUserData', {'userId': userId}); // 🟢 NEW

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

  // ✅ ENHANCED: Refresh current user with verification status sync
  Future<void> refreshCurrentUser() async {
    _logOperation('refreshCurrentUser'); // 🟢 NEW

    try {
      await currentUser?.reload();

      // ✅ NEW: Sync verification status to database after refresh
      final user = currentUser;
      if (user != null) {
        await _syncVerificationStatusToDatabase(user);
      }
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

  // 🟢 NEW: Get performance metrics (for debugging)
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'sessionStartTime': DateTime.now().toIso8601String(),
    };
  }
}
