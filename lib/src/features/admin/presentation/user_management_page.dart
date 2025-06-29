// lib/src/features/admin/presentation/user_management_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final usersList = usersData.entries.map((entry) {
          final userData = Map<String, dynamic>.from(entry.value as Map);
          userData['uid'] = entry.key;
          return userData;
        }).toList();

        // Sort by role (admins first) then by email
        usersList.sort((a, b) {
          final roleA = a['role'] ?? 'user';
          final roleB = b['role'] ?? 'user';

          if (roleA == roleB) {
            return (a['email'] ?? '').compareTo(b['email'] ?? '');
          }

          // Admin roles first
          if (roleA == 'admin' || roleA == 'super_admin') return -1;
          if (roleB == 'admin' || roleB == 'super_admin') return 1;
          return 0;
        });

        setState(() {
          _users = usersList;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');

      await userRef.update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _showMessage('Role updated successfully', Colors.green);
      _loadUsers(); // Refresh the list
    } catch (e) {
      _showMessage('Error updating role: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final role = user['role'] ?? 'user';
                  final isCurrentUser =
                      user['uid'] == FirebaseAuth.instance.currentUser?.uid;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(role),
                        child: Icon(
                          _getRoleIcon(role),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(user['email'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${role.toUpperCase()}'),
                          if (isCurrentUser)
                            const Text('(You)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newRole) {
                          if (newRole != role) {
                            _showRoleChangeDialog(user, newRole);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('User'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'admin',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Admin'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'super_admin',
                            child: Row(
                              children: [
                                Icon(Icons.security, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Super Admin'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showRoleChangeDialog(Map<String, dynamic> user, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${user['email']}'),
            const SizedBox(height: 8),
            Text('Current role: ${user['role'] ?? 'user'}'),
            Text('New role: $newRole'),
            const SizedBox(height: 16),
            if (newRole == 'admin' || newRole == 'super_admin')
              const Text(
                '⚠️ This will grant administrative privileges',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateUserRole(user['uid'], newRole);
            },
            child: const Text('Change Role'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'super_admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'super_admin':
        return Icons.security;
      default:
        return Icons.person;
    }
  }
}
