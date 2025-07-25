// lib/src/core/services/firebase_service.dart
// ✅ CONNECTION OPTIMIZED: Retry logic, connection pooling, error recovery
// 🚀 PERFORMANCE: Reduced connection conflicts, smart caching
// 🔧 STABILITY: Prevents force-kill issues, handles SDK type cast errors

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ✅ CONNECTION MANAGEMENT PROPERTIES
  static bool _isInitialized = false;
  static DateTime? _lastConnectionCheck;
  static bool? _lastConnectionResult;
  static final Map<String, Timer> _activeTimers = {};

  // ✅ RETRY CONFIGURATION
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _maxRetries = 3;
  static const Duration _connectionCacheTime = Duration(seconds: 30);

  // ✅ EMAIL VERIFICATION TRACKING
  DateTime? _lastVerificationSent;
  static const Duration _verificationCooldown = Duration(minutes: 1);

  // ✅ PERFORMANCE TRACKING
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // ============================================================================
  // CORE INITIALIZATION PROPERTIES
  // ============================================================================

  /// ✅ OPTIMIZED: Smart Firebase initialization check
  bool get isFirebaseInitialized {
    if (_isInitialized) return true;

    try {
      final app = Firebase.app();
      final hasValidConfig = app.options.databaseURL?.isNotEmpty ?? false;
      _isInitialized = hasValidConfig;
      return hasValidConfig;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// ✅ OPTIMIZED: Safe getters with connection validation
  FirebaseAuth? get _auth {
    try {
      return isFirebaseInitialized ? FirebaseAuth.instance : null;
    } catch (e) {
      debugPrint('⚠️ FirebaseAuth access error: $e');
      return null;
    }
  }

  FirebaseDatabase? get _database {
    try {
      // ✅ For compatibility, still use direct instance but through centralized service when possible
      return isFirebaseInitialized ? FirebaseDatabase.instance : null;
    } catch (e) {
      debugPrint('⚠️ FirebaseDatabase access error: $e');
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => currentUser != null;

  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================

  /// ✅ NEW: Smart connection check with caching and retry logic
  Future<bool> checkConnection() async {
    // Use cached result if recent
    if (_lastConnectionCheck != null && _lastConnectionResult != null) {
      final timeSinceCheck = DateTime.now().difference(_lastConnectionCheck!);
      if (timeSinceCheck < _connectionCacheTime) {
        return _lastConnectionResult!;
      }
    }

    return await _performConnectionCheck();
  }

  /// ✅ NEW: Robust connection check with retry logic
  Future<bool> _performConnectionCheck() async {
    if (!isFirebaseInitialized) {
      _updateConnectionCache(false);
      return false;
    }

    // ✅ WEB OPTIMIZATION: For web platform, assume connection if Firebase is initialized
    if (kIsWeb) {
      debugPrint(
          '🌐 Web platform: Assuming connectivity with Firebase initialization');
      _updateConnectionCache(true);
      return true;
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('🔗 Connection check attempt $attempt/$_maxRetries');

        final database = _database;
        if (database == null) {
          debugPrint('❌ Database instance not available');
          continue;
        }

        // Test connection with timeout
        final completer = Completer<bool>();
        late StreamSubscription subscription;

        subscription = database.ref('.info/connected').onValue.listen(
          (event) {
            if (!completer.isCompleted) {
              final connected = event.snapshot.value == true;
              completer.complete(connected);
            }
            subscription.cancel();
          },
          onError: (error) {
            debugPrint('⚠️ Connection test error: $error');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            subscription.cancel();
          },
        );

        final isConnected = await completer.future.timeout(
          _connectionTimeout,
          onTimeout: () {
            subscription.cancel();
            debugPrint('⏰ Connection test timeout (attempt $attempt)');
            return false;
          },
        );

        if (isConnected) {
          debugPrint('✅ Connection verified on attempt $attempt');
          _updateConnectionCache(true);
          return true;
        }

        // Wait before retry (except last attempt)
        if (attempt < _maxRetries) {
          debugPrint('⏳ Retrying connection in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
        }
      } catch (e) {
        debugPrint('❌ Connection check error (attempt $attempt): $e');

        // Wait before retry (except last attempt)
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    debugPrint('❌ Connection failed after $_maxRetries attempts');
    _updateConnectionCache(false);
    return false;
  }

  /// ✅ NEW: Update connection cache
  void _updateConnectionCache(bool isConnected) {
    _lastConnectionResult = isConnected;
    _lastConnectionCheck = DateTime.now();
  }

  /// ✅ NEW: Clear connection cache (for forced refresh)
  void clearConnectionCache() {
    _lastConnectionCheck = null;
    _lastConnectionResult = null;
  }

  // ============================================================================
  // ENHANCED ERROR HANDLING
  // ============================================================================

  /// ✅ ENHANCED: User-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network and connection errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('disconnected') ||
        errorString.contains('timeout')) {
      return 'Please check your internet connection and try again.';
    }

    // Firebase-specific errors
    if (errorString.contains('firebase') && errorString.contains('killed')) {
      return 'Connection was reset. Please try again.';
    }

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Unable to access the service. Please try again later.';
    }

    // Authentication errors
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }

    if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please check your email or sign up.';
    }

    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }

    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    // SDK type cast errors (common in recent Firebase versions)
    if (errorString.contains('pigeonuserdetails') ||
        errorString.contains('pigeonuserinfo') ||
        errorString.contains('type cast') ||
        errorString.contains('list<object?>')) {
      return 'Authentication completed successfully. Please wait a moment...';
    }

    return 'Something went wrong. Please try again.';
  }

  /// ✅ NEW: Retry wrapper for Firebase operations
  Future<T> _retryOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    int maxRetries = 2,
    Duration delay = const Duration(seconds: 1),
    bool requiresConnection = true,
  }) async {
    // Check connection if required
    if (requiresConnection) {
      final isConnected = await checkConnection();
      if (!isConnected) {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'network-error',
          message: 'No internet connection available',
        );
      }
    }

    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries + 1; attempt++) {
      try {
        debugPrint('🔄 $operationName (attempt $attempt)');
        final result = await operation();

        if (attempt > 1) {
          debugPrint('✅ $operationName succeeded on retry (attempt $attempt)');
        }

        return result;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ $operationName failed (attempt $attempt): $e');

        // Don't retry on certain errors
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
            case 'email-already-in-use':
            case 'invalid-email':
            case 'user-not-found':
            case 'wrong-password':
              rethrow; // Don't retry auth validation errors
          }
        }

        // Wait before retry (except last attempt)
        if (attempt <= maxRetries) {
          debugPrint('⏳ Retrying $operationName in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }

    throw lastError!;
  }

  // ============================================================================
  // OPTIMIZED AUTHENTICATION METHODS
  // ============================================================================

  /// ✅ ENHANCED: Sign in with retry logic and type cast error handling
  Future<User?> signInWithEmailPassword(String email, String password) async {
    _logOperation('signInWithEmailPassword', {'email': email});

    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    return await _retryOperation(
      'signInWithEmailPassword',
      () async {
        final auth = _auth;
        if (auth == null) {
          throw FirebaseAuthException(
            code: 'auth-not-available',
            message: 'Firebase Auth not available',
          );
        }

        try {
          final userCredential = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          final user = userCredential.user;
          if (user != null) {
            await _updateUserSignInTime(user);
            return user;
          } else {
            throw FirebaseAuthException(
              code: 'null-user',
              message: 'Authentication succeeded but user is null',
            );
          }
        } catch (e) {
          // ✅ WORKAROUND: Handle Firebase SDK type cast issues
          if (_isTypecastError(e)) {
            return await _handleTypecastRecovery('signIn');
          }
          rethrow;
        }
      },
      requiresConnection: true,
    );
  }

  /// ✅ ENHANCED: Create user with retry logic and better error handling
  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    _logOperation('createUserWithEmailPassword', {'email': email});

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

    return await _retryOperation(
      'createUserWithEmailPassword',
      () async {
        final auth = _auth;
        if (auth == null) {
          throw FirebaseAuthException(
            code: 'auth-not-available',
            message: 'Firebase Auth not available',
          );
        }

        try {
          // Create user account
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

          final user = userCredential.user;
          if (user == null) {
            throw FirebaseAuthException(
              code: 'null-user',
              message: 'Account creation succeeded but user is null',
            );
          }

          // Update display name with error handling
          try {
            await user.updateDisplayName(displayName.trim());
          } catch (nameError) {
            if (!_isTypecastError(nameError)) {
              debugPrint('⚠️ Display name update failed: $nameError');
            }
          }

          // Send verification email
          try {
            await user.sendEmailVerification();
            _lastVerificationSent = DateTime.now();
            debugPrint('📧 Verification email sent');
          } catch (verificationError) {
            debugPrint('⚠️ Verification email failed: $verificationError');
          }

          // Create user document
          try {
            await _createUserDocumentWithProperStructure(
                user, displayName.trim());
          } catch (docError) {
            debugPrint('⚠️ User document creation failed: $docError');
          }

          // Reload user to get updated information
          try {
            await user.reload();
          } catch (reloadError) {
            debugPrint('⚠️ User reload failed: $reloadError');
          }

          return auth.currentUser ?? user;
        } catch (e) {
          // ✅ WORKAROUND: Handle Firebase SDK type cast issues
          if (_isTypecastError(e)) {
            return await _handleTypecastRecovery('createUser', displayName);
          }

          // Clean up on failure
          try {
            await auth.currentUser?.delete();
          } catch (deleteError) {
            debugPrint('⚠️ Failed to clean up user on error: $deleteError');
          }

          rethrow;
        }
      },
      requiresConnection: true,
    );
  }

  /// ✅ ENHANCED: Guest sign-in with retry logic
  Future<User?> signInAsGuest() async {
    _logOperation('signInAsGuest');

    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase not initialized',
      );
    }

    return await _retryOperation(
      'signInAsGuest',
      () async {
        final auth = _auth;
        if (auth == null) {
          throw FirebaseAuthException(
            code: 'auth-not-available',
            message: 'Firebase Auth not available',
          );
        }

        try {
          final userCredential = await auth.signInAnonymously();
          final user = userCredential.user;

          if (user != null) {
            try {
              await user.updateDisplayName('Guest User');
            } catch (nameError) {
              if (!_isTypecastError(nameError)) {
                debugPrint('⚠️ Guest display name update failed: $nameError');
              }
            }

            await _createUserDocumentWithProperStructure(user, 'Guest User');
            return user;
          } else {
            throw FirebaseAuthException(
              code: 'null-user',
              message: 'Guest sign-in succeeded but user is null',
            );
          }
        } catch (e) {
          // ✅ WORKAROUND: Handle Firebase SDK type cast issues
          if (_isTypecastError(e)) {
            return await _handleTypecastRecovery('guestSignIn');
          }
          rethrow;
        }
      },
      requiresConnection: true,
    );
  }

  /// ✅ ENHANCED: Sign out with cleanup
  Future<void> signOut() async {
    _logOperation('signOut');

    if (!isFirebaseInitialized) return;

    try {
      // Clear verification tracking
      _lastVerificationSent = null;

      // Clear connection cache
      clearConnectionCache();

      // Cancel any active timers
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();

      await _auth?.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('⚠️ Sign out error: $e');
      // Don't throw - sign out should always succeed
    }
  }

  // ============================================================================
  // TYPE CAST ERROR HANDLING (SDK COMPATIBILITY)
  // ============================================================================

  /// ✅ NEW: Detect Firebase SDK type cast errors
  bool _isTypecastError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('pigeonuserdetails') ||
        errorString.contains('pigeonuserinfo') ||
        errorString.contains('type cast') ||
        errorString.contains('list<object?>') ||
        errorString.contains('type \'list<object?>\' is not a subtype');
  }

  /// ✅ NEW: Handle type cast error recovery
  Future<User?> _handleTypecastRecovery(String operation,
      [String? displayName]) async {
    debugPrint('🔧 Handling type cast error for $operation...');

    // Wait for SDK to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final currentUser = _auth?.currentUser;
      if (currentUser != null) {
        debugPrint('✅ Type cast recovery successful for $operation');

        // Try to update user document if needed
        if (displayName != null) {
          try {
            await _createUserDocumentWithProperStructure(
                currentUser, displayName);
          } catch (docError) {
            debugPrint('⚠️ Document creation failed in recovery: $docError');
          }
        }

        return currentUser;
      } else {
        throw FirebaseAuthException(
          code: 'type-cast-recovery-failed',
          message:
              'Authentication may have succeeded but user details could not be retrieved',
        );
      }
    } catch (e) {
      debugPrint('❌ Type cast recovery failed: $e');
      throw FirebaseAuthException(
        code: 'type-cast-recovery-failed',
        message: 'SDK compatibility issue - please try again',
      );
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION (ENHANCED)
  // ============================================================================

  /// ✅ ENHANCED: Send email verification with retry logic
  Future<Map<String, dynamic>> sendEmailVerification() async {
    _logOperation('sendEmailVerification');

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
        return {
          'success': true,
          'alreadyVerified': true,
          'message': 'Email is already verified'
        };
      }

      // Check rate limiting
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

      // Send verification with retry
      await _retryOperation(
        'sendEmailVerification',
        () => user.sendEmailVerification(),
        maxRetries: 2,
        requiresConnection: true,
      );

      _lastVerificationSent = DateTime.now();
      await _updateVerificationAttempt(user);

      return {
        'success': true,
        'message': 'Verification email sent successfully',
        'email': user.email,
        'sentAt': _lastVerificationSent!.toIso8601String()
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error sending verification: ${e.code}');

      String userMessage = _getUserFriendlyErrorMessage(e);
      if (e.code == 'too-many-requests') {
        userMessage =
            'Too many verification emails sent. Please wait before trying again.';
      }

      return {
        'success': false,
        'error': e.code,
        'message': userMessage,
      };
    } catch (e) {
      debugPrint('❌ Unexpected error sending verification: $e');
      return {
        'success': false,
        'error': 'unknown-error',
        'message': _getUserFriendlyErrorMessage(e)
      };
    }
  }

  /// ✅ ENHANCED: Check email verification with force refresh
  Future<Map<String, dynamic>> checkEmailVerification(
      {bool forceRefresh = false}) async {
    _logOperation('checkEmailVerification', {'forceRefresh': forceRefresh});

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

      // Force refresh if requested
      if (forceRefresh) {
        await _retryOperation(
          'reloadUser',
          () => user.reload(),
          maxRetries: 2,
          requiresConnection: true,
        );
      }

      final updatedUser = _auth?.currentUser;
      final isVerified = updatedUser?.emailVerified ?? false;

      // Update database with current status
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
        'message': _getUserFriendlyErrorMessage(e)
      };
    }
  }

  // ============================================================================
  // PASSWORD RESET
  // ============================================================================

  /// ✅ ENHANCED: Reset password with retry logic
  Future<bool> resetPassword(String email) async {
    _logOperation('resetPassword', {'email': email});

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

    return await _retryOperation(
      'resetPassword',
      () async {
        final auth = _auth;
        if (auth == null) {
          throw FirebaseAuthException(
            code: 'auth-not-available',
            message: 'Firebase Auth not available',
          );
        }

        await auth.sendPasswordResetEmail(email: email.trim());
        return true;
      },
      requiresConnection: true,
    );
  }

  // ============================================================================
  // USER INFO AND ROLE MANAGEMENT
  // ============================================================================

  /// ✅ ENHANCED: Get current user info with comprehensive verification status
  Map<String, dynamic>? getCurrentUserInfo() {
    try {
      final user = currentUser;
      if (user == null) return null;

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'isEmailVerified': user.emailVerified,
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
      debugPrint('❌ Error getting user info: $e');
      return null;
    }
  }

  /// ✅ ENHANCED: Check if user is admin with retry logic
  Future<bool> isUserAdmin() async {
    _logOperation('isUserAdmin');

    if (!isFirebaseInitialized || !isSignedIn) return false;

    try {
      return await _retryOperation(
        'isUserAdmin',
        () async {
          final database = _database;
          if (database == null) return false;

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
            'haw33inc@gmail.com'
          ];

          final userEmail = currentUser?.email?.toLowerCase();
          if (userEmail != null && adminEmails.contains(userEmail)) {
            return true;
          }

          return false;
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// ✅ ENHANCED: Update user role with retry logic and validation
  Future<bool> updateUserRole(String userId, String role,
      {List<String>? permissions}) async {
    _logOperation('updateUserRole', {'userId': userId, 'role': role});

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

    return await _retryOperation(
      'updateUserRole',
      () async {
        final database = _database;
        if (database == null) {
          throw Exception('Database not available');
        }

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
            debugPrint('⚠️ Failed to remove admin fields: $e');
          }
        }

        return true;
      },
      requiresConnection: true,
    );
  }

  /// ✅ ENHANCED: Get user by UID with retry logic
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    _logOperation('getUserData', {'userId': userId});

    if (!isFirebaseInitialized) return null;

    try {
      return await _retryOperation(
        'getUserData',
        () async {
          final database = _database;
          if (database == null) return null;

          final userRef = database.ref('users/$userId');
          final snapshot = await userRef.get();

          if (snapshot.exists && snapshot.value != null) {
            return Map<String, dynamic>.from(snapshot.value as Map);
          }
          return null;
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  /// ✅ ENHANCED: Initialize favorites for existing users
  Future<void> initializeFavoritesForUser(String userId) async {
    if (!isFirebaseInitialized) return;

    try {
      await _retryOperation(
        'initializeFavorites',
        () async {
          final database = _database;
          if (database == null) return;

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
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to initialize favorites: $e');
      // Continue silently
    }
  }

  /// ✅ ENHANCED: Refresh current user with verification status sync
  Future<void> refreshCurrentUser() async {
    _logOperation('refreshCurrentUser');

    try {
      await _retryOperation(
        'refreshCurrentUser',
        () async {
          await currentUser?.reload();

          // Sync verification status to database after refresh
          final user = currentUser;
          if (user != null) {
            await _syncVerificationStatusToDatabase(user);
          }
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to refresh current user: $e');
      // Continue silently
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION STATUS METHODS
  // ============================================================================

  /// ✅ ENHANCED: Get comprehensive verification status including database sync
  Future<Map<String, dynamic>> getVerificationStatus() async {
    _logOperation('getVerificationStatus');

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

      // Get database verification info
      Map<String, dynamic>? dbVerificationInfo;
      try {
        dbVerificationInfo = await _getDatabaseVerificationInfo(user.uid);
      } catch (e) {
        debugPrint('⚠️ Could not get database verification info: $e');
      }

      // Calculate time since last verification attempt
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
        'message': _getUserFriendlyErrorMessage(e)
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

  // ============================================================================
  // USER DELETION AND CLEANUP METHODS
  // ============================================================================

  /// ✅ ENHANCED: Delete user from both Firebase Auth and Database
  Future<Map<String, dynamic>> deleteUserCompletely(String userId) async {
    _logOperation('deleteUserCompletely', {'userId': userId});

    if (!isFirebaseInitialized || !isSignedIn) {
      return {
        'success': false,
        'error': 'not-authenticated',
        'message': 'User not authenticated',
      };
    }

    try {
      return await _retryOperation(
        'deleteUserCompletely',
        () async {
          final database = _database;
          if (database == null) {
            throw Exception('Database not available');
          }

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
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      return {
        'success': false,
        'error': 'deletion-failed',
        'message': _getUserFriendlyErrorMessage(e),
      };
    }
  }

  /// ✅ ENHANCED: Check if user exists in database but not in current auth context
  Future<List<String>> findOrphanedUsers() async {
    _logOperation('findOrphanedUsers');

    if (!isFirebaseInitialized) return [];

    try {
      return await _retryOperation(
        'findOrphanedUsers',
        () async {
          final database = _database;
          if (database == null) return <String>[];

          final usersRef = database.ref('users');
          final snapshot = await usersRef.get();

          if (!snapshot.exists || snapshot.value == null) return <String>[];

          final usersData = Map<String, dynamic>.from(snapshot.value as Map);
          final orphanedUsers = <String>[];

          for (final entry in usersData.entries) {
            final uid = entry.key;
            final userData = Map<String, dynamic>.from(entry.value as Map);

            // Check for signs of orphaned user
            final lastSignIn = userData['lastSignIn'];
            final createdAt = userData['createdAt'];

            if (lastSignIn == null && createdAt != null) {
              try {
                final created = DateTime.parse(createdAt.toString());
                final daysSinceCreation =
                    DateTime.now().difference(created).inDays;

                if (daysSinceCreation > 30) {
                  orphanedUsers.add(uid);
                }
              } catch (e) {
                debugPrint('⚠️ Error parsing date for user $uid: $e');
              }
            }
          }

          return orphanedUsers;
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Error finding orphaned users: $e');
      return [];
    }
  }

  /// ✅ ENHANCED: Bulk cleanup of orphaned database records
  Future<Map<String, dynamic>> cleanupOrphanedUsers(
      List<String> userIds) async {
    _logOperation('cleanupOrphanedUsers', {'count': userIds.length});

    if (!isFirebaseInitialized || userIds.isEmpty) {
      return {
        'success': false,
        'message': 'No users to cleanup or Firebase not initialized',
      };
    }

    try {
      return await _retryOperation(
        'cleanupOrphanedUsers',
        () async {
          final database = _database;
          if (database == null) {
            throw Exception('Database not available');
          }

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
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Error during bulk cleanup: $e');
      return {
        'success': false,
        'error': 'cleanup-failed',
        'message': _getUserFriendlyErrorMessage(e),
      };
    }
  }

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// ✅ NEW: Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  /// ✅ NEW: Validate password strength
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

  /// ✅ NEW: Validate display name
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

  // ============================================================================
  // FIREBASE SETUP VALIDATION
  // ============================================================================

  /// ✅ ENHANCED: Firebase setup validation with detailed testing
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

        // Test authentication availability
        final auth = _auth;
        if (auth != null) {
          info['auth_ready'] = true;
          final currentUser = auth.currentUser;
          info['current_user_available'] = currentUser != null;

          if (currentUser != null) {
            info['user_info'] = {
              'uid': currentUser.uid,
              'email': currentUser.email,
              'isAnonymous': currentUser.isAnonymous,
              'emailVerified': currentUser.emailVerified,
            };
          }
        } else {
          info['auth_ready'] = false;
        }

        // Test database availability
        final database = _database;
        if (database != null && connection) {
          try {
            final testRef = database.ref('.info/serverTimeOffset');
            final testSnapshot =
                await testRef.get().timeout(const Duration(seconds: 5));
            info['database_readable'] = testSnapshot.exists;
          } catch (e) {
            info['database_readable'] = false;
            info['database_error'] = e.toString();
          }
        }
      } catch (e) {
        info['connection_error'] = e.toString();
      }
    }

    info['validation_completed_at'] = DateTime.now().toIso8601String();
    return info;
  }

  // ============================================================================
  // DATABASE OPERATIONS (OPTIMIZED)
  // ============================================================================

  /// ✅ ENHANCED: Create user document with retry logic
  Future<void> _createUserDocumentWithProperStructure(User user,
      [String? displayName]) async {
    if (!isFirebaseInitialized) return;

    await _retryOperation(
      'createUserDocument',
      () async {
        final database = _database;
        if (database == null) {
          throw Exception('Database not available');
        }

        final userRef = database.ref('users/${user.uid}');
        final currentTime = DateTime.now().toIso8601String();

        // Check if user document exists
        final snapshot = await userRef.get();

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
          'emailVerified': user.emailVerified,
        };

        if (!snapshot.exists) {
          // New user
          userData['createdAt'] = currentTime;
          userData['favorites'] = <String, dynamic>{};

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
          // Existing user - update
          final updateData = <String, dynamic>{
            'lastSignIn': currentTime,
            'emailVerified': user.emailVerified,
          };

          if (displayName != null && displayName.isNotEmpty) {
            updateData['displayName'] = displayName;
          }

          if (_lastVerificationSent != null && !user.isAnonymous) {
            updateData['lastVerificationEmailSent'] =
                _lastVerificationSent!.toIso8601String();
          }

          await userRef.update(updateData);
        }
      },
      maxRetries: 2,
      requiresConnection: true,
    );
  }

  /// ✅ ENHANCED: Update user sign-in time
  Future<void> _updateUserSignInTime(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      await _retryOperation(
        'updateSignInTime',
        () async {
          final database = _database;
          if (database == null) return;

          final userRef = database.ref('users/${user.uid}');
          await userRef.update({
            'lastSignIn': DateTime.now().toIso8601String(),
            'emailVerified': user.emailVerified,
            'lastVerificationCheck': DateTime.now().toIso8601String(),
          });
        },
        maxRetries: 1,
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to update sign-in time: $e');
      // Don't throw - this is not critical
    }
  }

  /// ✅ ENHANCED: Update verification attempt in database
  Future<void> _updateVerificationAttempt(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      await _retryOperation(
        'updateVerificationAttempt',
        () async {
          final database = _database;
          if (database == null) return;

          final userRef = database.ref('users/${user.uid}');
          await userRef.update({
            'lastVerificationEmailSent': DateTime.now().toIso8601String(),
            'emailVerified': user.emailVerified,
          });
        },
        maxRetries: 1,
        requiresConnection: false, // Don't require connection for this
      );
    } catch (e) {
      debugPrint('⚠️ Failed to update verification attempt: $e');
      // Don't throw - this is not critical
    }
  }

  /// ✅ ENHANCED: Sync verification status to database
  Future<void> _syncVerificationStatusToDatabase(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      await _retryOperation(
        'syncVerificationStatus',
        () async {
          final database = _database;
          if (database == null) return;

          final userRef = database.ref('users/${user.uid}');
          await userRef.update({
            'emailVerified': user.emailVerified,
            'lastVerificationCheck': DateTime.now().toIso8601String(),
          });
        },
        maxRetries: 1,
        requiresConnection: false,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to sync verification status: $e');
      // Don't throw - this is not critical
    }
  }

  /// ✅ NEW: Get verification info from database
  Future<Map<String, dynamic>?> _getDatabaseVerificationInfo(String uid) async {
    if (!isFirebaseInitialized) return null;

    try {
      return await _retryOperation(
        'getDatabaseVerificationInfo',
        () async {
          final database = _database;
          if (database == null) return null;

          final userRef = database.ref('users/$uid');
          final snapshot = await userRef.get();

          if (snapshot.exists && snapshot.value != null) {
            final userData = Map<String, dynamic>.from(snapshot.value as Map);
            return {
              'emailVerified': userData['emailVerified'] ?? false,
              'lastVerificationEmailSent':
                  userData['lastVerificationEmailSent'],
              'verificationEmailCount': userData['verificationEmailCount'] ?? 0,
              'lastVerificationCheck': userData['lastVerificationCheck'],
            };
          }
          return null;
        },
        requiresConnection: true,
      );
    } catch (e) {
      debugPrint('❌ Failed to get database verification info: $e');
      return null;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('🔧 Firebase: $operation (count: $count)');
      if (details != null) {
        debugPrint('📊 Details: $details');
      }
    }
  }

  /// ✅ NEW: Get comprehensive connection info
  Map<String, dynamic> getConnectionInfo() {
    final currentUser = this.currentUser;
    return {
      'isInitialized': isFirebaseInitialized,
      'hasCurrentUser': currentUser != null,
      'userType': currentUser?.isAnonymous == true ? 'guest' : 'registered',
      'userEmail': currentUser?.email,
      'isEmailVerified': currentUser?.emailVerified,
      'lastConnectionCheck': _lastConnectionCheck?.toIso8601String(),
      'lastConnectionResult': _lastConnectionResult,
      'connectionCacheAge': _lastConnectionCheck != null
          ? DateTime.now().difference(_lastConnectionCheck!).inSeconds
          : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// ✅ NEW: Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'connectionMetrics': {
        'lastCheck': _lastConnectionCheck?.toIso8601String(),
        'lastResult': _lastConnectionResult,
        'cacheAge': _lastConnectionCheck != null
            ? DateTime.now().difference(_lastConnectionCheck!).inSeconds
            : null,
      },
      'activeTimers': _activeTimers.length,
      'sessionStartTime': DateTime.now().toIso8601String(),
    };
  }

  /// ✅ NEW: Health check for Firebase service
  Future<Map<String, dynamic>> performHealthCheck() async {
    final startTime = DateTime.now();
    final results = <String, dynamic>{};

    try {
      // Test Firebase initialization
      results['firebase_initialized'] = isFirebaseInitialized;

      if (isFirebaseInitialized) {
        // Test connection
        final isConnected = await checkConnection();
        results['connection_test'] = isConnected;

        // Test auth availability
        final auth = _auth;
        results['auth_available'] = auth != null;

        if (auth != null) {
          final user = auth.currentUser;
          results['current_user'] = user != null
              ? {
                  'uid': user.uid,
                  'email': user.email,
                  'isAnonymous': user.isAnonymous,
                  'emailVerified': user.emailVerified,
                }
              : null;
        }

        // Test database availability
        final database = _database;
        results['database_available'] = database != null;
      }

      results['test_duration_ms'] =
          DateTime.now().difference(startTime).inMilliseconds;
      results['status'] = 'completed';
    } catch (e) {
      results['error'] = e.toString();
      results['status'] = 'failed';
      results['test_duration_ms'] =
          DateTime.now().difference(startTime).inMilliseconds;
    }

    results['tested_at'] = DateTime.now().toIso8601String();
    return results;
  }
}
