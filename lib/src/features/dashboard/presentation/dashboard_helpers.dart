// dashboard_helpers.dart - Helper functions and utilities

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

mixin DashboardHelpers {
  // ✅ Safer way to get current user to avoid potential type cast issues
  User? getSafeCurrentUser() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('✅ Current user retrieved safely: ${user.email}');
      }
      return user;
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');

      // Check if it's a type cast error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('PigeonUserInfo') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        debugPrint(
            '⚠️ Known Firebase SDK type cast issue detected in dashboard');
        return null;
      }

      return null;
    }
  }

  // Get greeting based on time of day
  Map<String, dynamic> getGreetingData() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return {
        'greeting': 'Good Morning',
        'icon': Icons.wb_sunny_outlined,
      };
    } else if (hour < 17) {
      return {
        'greeting': 'Good Afternoon',
        'icon': Icons.wb_sunny,
      };
    } else {
      return {
        'greeting': 'Good Evening',
        'icon': Icons.nightlight_round,
      };
    }
  }

  // Check admin status from Firebase
  Future<Map<String, bool>> checkAdminStatusFromFirebase(
    FirebaseService firebaseService,
    User currentUser,
    String userEmail,
    List<String> fallbackAdmins,
    List<String> superAdminEmails,
  ) async {
    try {
      if (firebaseService.isFirebaseInitialized) {
        debugPrint('🔍 Checking admin status for: $userEmail');

        final database = FirebaseDatabase.instance;
        final userRef = database.ref('users/${currentUser.uid}');

        final snapshot = await userRef.get().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('⏰ Firebase user check timed out, using fallback');
            throw TimeoutException('User check timeout');
          },
        );

        if (snapshot.exists && snapshot.value != null) {
          Map<String, dynamic> userData;
          try {
            userData = Map<String, dynamic>.from(snapshot.value as Map);
          } catch (castError) {
            debugPrint('❌ Error casting user data: $castError');
            if (snapshot.value is Map) {
              userData = <String, dynamic>{};
              final rawMap = snapshot.value as Map;
              for (final entry in rawMap.entries) {
                userData[entry.key.toString()] = entry.value;
              }
            } else {
              throw Exception('Invalid user data format');
            }
          }

          final userRole = userData['role']?.toString().toLowerCase();
          final isAdminFromFirebase =
              userRole == 'admin' || userRole == 'super_admin';
          final isSuperAdminFromFirebase = userRole == 'super_admin';

          debugPrint('👤 User data found in Firebase');
          debugPrint('🎭 User role: $userRole');

          return {
            'isAdmin': isAdminFromFirebase,
            'isSuperAdmin': isSuperAdminFromFirebase,
          };
        } else {
          debugPrint('📭 No user data found in Firebase, using fallback');
          throw Exception('No user data in Firebase');
        }
      } else {
        debugPrint('❌ Firebase not initialized, using fallback');
        throw Exception('Firebase not initialized');
      }
    } catch (e) {
      debugPrint('❌ Firebase admin check failed: $e');
      debugPrint('🔄 Using fallback admin list');

      final isAdminFromFallback = fallbackAdmins.contains(userEmail);
      final isSuperAdminFromFallback = superAdminEmails.contains(userEmail);

      return {
        'isAdmin': isAdminFromFallback,
        'isSuperAdmin': isSuperAdminFromFallback,
      };
    }
  }
}

// Utility functions for showing messages
void showSuccessMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ),
  );
}

void showErrorMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ),
  );
}

void showInfoMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ),
  );
}
