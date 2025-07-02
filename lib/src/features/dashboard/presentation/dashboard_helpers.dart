// dashboard_helpers.dart - Helper functions and utilities

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

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

  // ✅ Updated to use AuthorizationService
  Future<Map<String, bool>> checkAdminStatusFromFirebase(
    User currentUser,
    String userEmail,
  ) async {
    try {
      debugPrint('🔍 Checking admin status for: $userEmail');

      final authService = AuthorizationService();
      final adminStatus = await authService.checkAdminStatus();

      debugPrint('👤 Admin status from AuthorizationService');
      debugPrint('🎭 Is Admin: ${adminStatus['isAdmin']}');
      debugPrint('🎭 Is Super Admin: ${adminStatus['isSuperAdmin']}');

      return adminStatus;
    } catch (e) {
      debugPrint('❌ Admin status check failed: $e');
      return {'isAdmin': false, 'isSuperAdmin': false};
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
