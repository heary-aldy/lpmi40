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

  // ✅ SECURITY FIX: Disabled self-admin promotion
  Future<void> _grantAdminRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showErrorMessage('❌ No user logged in');
      return;
    }

    // ✅ SECURITY FIX: Self-admin promotion disabled
    _showErrorMessage('🔒 Self-admin promotion disabled for security.\n'
        'Contact existing super admin for role assignment.\n\n'
        'Current super admins:\n'
        '• heary@hopetv.asia\n'
        '• heary_aldy@hotmail.com');
    return;
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
          duration: const Duration(seconds: 5),
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
                    // ✅ SECURITY FIX: Updated messaging
                    const Text(
                      'Admin role assignment has been secured. Contact existing super administrators for role changes.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This prevents unauthorized privilege escalation.',
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
                              ? 'Checking Access...'
                              : 'Request Admin Role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Please log in first to check admin privileges.',
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
                      'Admin users have access to:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.add_circle, 'Add new songs'),
                    _buildFeatureItem(Icons.edit_note, 'Edit existing songs'),
                    _buildFeatureItem(Icons.delete, 'Delete songs'),
                    _buildFeatureItem(Icons.report, 'Manage song reports'),
                    _buildFeatureItem(
                        Icons.bug_report, 'Firebase debugging tools'),
                    _buildFeatureItem(
                        Icons.people, 'User management (Super Admin only)'),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
