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
      debugPrint('Firebase not initialized, cannot sign in');
      return null;
    }

    try {
      final UserCredential userCredential =
          await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Email sign-in successful');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email Sign-In Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Handle casting errors but check if login actually succeeded
      debugPrint('❌ Unexpected Sign-In Error: $e');

      // Check if user is actually signed in despite the error
      if (_auth?.currentUser != null) {
        debugPrint('✅ User signed in despite error');
        return _auth!.currentUser;
      }
      return null;
    }
  }

  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot create user');
      return null;
    }

    try {
      final UserCredential userCredential =
          await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await _createUserDocument(user);
        debugPrint('✅ User created successfully');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Create User Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected Create User Error: $e');
      return null;
    }
  }

  // ✅ FIXED: Proper guest sign-in method
  Future<User?> signInAsGuest() async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot sign in as guest');
      return null;
    }

    try {
      debugPrint('🔄 Signing in as guest...');
      final UserCredential userCredential = await _auth!.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName('Guest User');
        await _createUserDocument(user);
        debugPrint('✅ Guest sign-in successful');
      }

      return user;
    } catch (e) {
      debugPrint('❌ Guest Sign-In Error: $e');
      return null;
    }
  }

  // ✅ REMOVED: Google Sign-In (no longer needed)

  Future<void> signOut() async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase not initialized, cannot sign out');
      return;
    }

    try {
      await _auth?.signOut();
      debugPrint('✅ Successfully signed out');
    } catch (e) {
      debugPrint('❌ Sign Out Error: $e');
    }
  }

  // User document creation
  Future<void> _createUserDocument(User user) async {
    if (!isFirebaseInitialized) return;

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${user.uid}');

      // Check if user document already exists
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? 'anonymous@example.com',
          'displayName': user.displayName ?? 'Anonymous User',
          'createdAt': DateTime.now().toIso8601String(),
          'lastSignIn': DateTime.now().toIso8601String(),
          'role': 'user', // Default role
        });
        debugPrint('✅ User document created');
      } else {
        // Update last sign-in time
        await userRef.update({
          'lastSignIn': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ User document updated');
      }
    } catch (e) {
      debugPrint('❌ Create/Update User Document Error: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    if (!isFirebaseInitialized) return false;

    try {
      await _auth!.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent');
      return true;
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      return false;
    }
  }

  // Get current user info
  Map<String, dynamic>? getCurrentUserInfo() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'isEmailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
    };
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    if (!isFirebaseInitialized || !isSignedIn) return false;

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser!.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final role = userData['role']?.toString().toLowerCase();
        return role == 'admin' || role == 'super_admin';
      }

      return false;
    } catch (e) {
      debugPrint('❌ Admin check error: $e');
      return false;
    }
  }

  // Update user role (admin functionality)
  Future<bool> updateUserRole(String userId, String role) async {
    if (!isFirebaseInitialized || !isSignedIn) return false;

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');

      await userRef.update({
        'role': role,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': currentUser!.uid,
      });

      debugPrint('✅ User role updated to $role');
      return true;
    } catch (e) {
      debugPrint('❌ Update user role error: $e');
      return false;
    }
  }
}
