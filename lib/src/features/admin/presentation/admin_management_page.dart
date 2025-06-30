// lib/src/features/admin/presentation/admin_management_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  bool _isGrantingAdminRole = false;

  Future<void> _grantAdminRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showErrorMessage('❌ No user logged in');
      return;
    }

    setState(() {
      _isGrantingAdminRole = true;
    });

    try {
      debugPrint('🔧 Granting admin role to current user...');
      debugPrint('👤 User: ${currentUser.email}');
      debugPrint('🆔 User ID: ${currentUser.uid}');

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');

      // Get existing user data first
      final snapshot = await userRef.get();
      Map<String, dynamic> userData = {};

      if (snapshot.exists && snapshot.value != null) {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('📖 Existing user data found');
      } else {
        debugPrint('📝 Creating new user data');
        userData = {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName ?? 'Admin User',
          'createdAt': DateTime.now().toIso8601String(),
        };
      }

      // Add admin role and permissions
      userData['role'] = 'admin';
      userData['permissions'] = [
        'manage_songs',
        'view_analytics',
        'access_debug'
      ];
      userData['updatedAt'] = DateTime.now().toIso8601String();
      userData['adminGrantedAt'] = DateTime.now().toIso8601String();

      // Save updated user data
      await userRef.set(userData);

      debugPrint('✅ Admin role granted successfully!');
      debugPrint('🎭 Role: admin');
      debugPrint('📋 Permissions: ${userData['permissions'].join(", ")}');

      _showSuccessMessage(
          'Admin role granted successfully! Please restart the app.');

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.green),
                SizedBox(width: 8),
                Text('Admin Role Granted!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Admin role granted to: ${currentUser.email}'),
                const SizedBox(height: 8),
                const Text('🔄 Please restart the app to see admin features'),
                const SizedBox(height: 8),
                const Text(
                    '🎯 You will now see admin buttons in the dashboard'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous page
                },
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to grant admin role: $e');
      _showErrorMessage('Failed to grant admin role: $e');
    } finally {
      setState(() {
        _isGrantingAdminRole = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
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
  }

  void _showErrorMessage(String message) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.purple.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Admin Access",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (currentUser != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.purple, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Logged in as: ${currentUser.email}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Need admin access? You can grant yourself admin privileges for testing and development.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This is intended for developers and testers only.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (currentUser != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGrantingAdminRole ? null : _grantAdminRole,
                          icon: _isGrantingAdminRole
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.admin_panel_settings),
                          label: Text(_isGrantingAdminRole
                              ? 'Granting Admin Role...'
                              : 'Grant Me Admin Role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Please log in first to grant admin privileges.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Go back
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Go Back to Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Once admin privileges are granted, you will have access to:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.add_circle, 'Add new songs'),
                    _buildFeatureItem(Icons.edit_note, 'Edit existing songs'),
                    _buildFeatureItem(Icons.delete, 'Delete songs'),
                    _buildFeatureItem(
                        Icons.bug_report, 'Firebase debugging tools'),
                    _buildFeatureItem(Icons.people, 'User management'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
