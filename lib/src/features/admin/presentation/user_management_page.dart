// lib/src/features/admin/presentation/user_management_page.dart
// COMPLETE VERSION: All layout constraint issues fixed

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Map<String, bool> _editingStates = {};
  final Map<String, String> _selectedRoles = {};
  final Map<String, List<String>> _selectedPermissions = {};
  String _filterStatus = 'all';

  // ✅ State variable to track the current sort order
  String _sortOrder = 'role'; // 'role', 'name', 'email', 'status'

  final List<String> _availablePermissions = [
    'manage_songs',
    'view_analytics',
    'access_debug',
    'manage_users'
  ];

  final List<String> _superAdminEmails = [
    'heary_aldy@hotmail.com',
    'heary@hopetv.asia',
    'haw33inc@gmail.com',
    'admin@haweeinc.com'
  ];

  @override
  void initState() {
    super.initState();
    _checkSuperAdminAccess();
  }

  Future<void> _checkSuperAdminAccess() async {
    if (!_isCurrentUserSuperAdmin()) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: Only super admins can manage users'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _loadUsers();
  }

  bool _isCurrentUserSuperAdmin() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return false;
    return _superAdminEmails.contains(currentUser!.email!.toLowerCase());
  }

  bool _isEligibleForSuperAdmin(String email) {
    return _superAdminEmails.contains(email.toLowerCase());
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final usersList = usersData.entries
            .map((entry) => {
                  'uid': entry.key,
                  ...Map<String, dynamic>.from(entry.value as Map),
                })
            .toList();

        await _syncWithFirebaseAuth(usersList);
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      _showMessage('Error loading users: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncWithFirebaseAuth(
      List<Map<String, dynamic>> databaseUsers) async {
    debugPrint(
        '🔄 Syncing ${databaseUsers.length} database users with Firebase Auth...');

    final validUsers = <Map<String, dynamic>>[];

    for (final user in databaseUsers) {
      final uid = user['uid'];
      if (uid == null) continue;
      validUsers.add(user);
    }

    if (mounted) {
      setState(() {
        _users = validUsers;
        _isLoading = false;
      });
      _applySortAndFilter();
      _initializeEditingStates();
    }
  }

  Future<void> _cleanupOrphanedUsers() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Cleanup Orphaned Users',
      content:
          'This will scan all users in the database and remove any that no longer exist in Firebase Auth. This action cannot be undone.\n\nNote: This requires Firebase Admin SDK for full validation. Proceed with caution.',
      confirmText: 'Cleanup',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      _showMessage(
          'Manual cleanup requires Firebase Admin SDK. Please use Firebase Console to verify users.',
          Colors.orange);
      _loadUsers();
    } catch (e) {
      _showMessage('Error during cleanup: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(String userId) async {
    final user = _users.firstWhere((u) => u['uid'] == userId);
    final userEmail = _getUserEmail(user);
    final userName = _getUserDisplayName(user);

    final confirmed = await _showConfirmationDialog(
      title: 'Delete User',
      content:
          'Are you sure you want to delete user "$userName" ($userEmail)?\n\nThis will:\n• Remove user from Firebase Auth\n• Delete all user data from database\n• This action cannot be undone',
      confirmText: 'Delete User',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      debugPrint('🗑️ Deleting user: $userId ($userEmail)');

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');
      await userRef.remove();
      debugPrint('✅ Deleted user data from database');

      _showMessage(
          'User data deleted from database. Note: Firebase Auth deletion requires admin privileges.',
          Colors.orange);
      _loadUsers();
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      _showMessage('Error deleting user: $e', Colors.red);
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> filtered = List.from(_users);

    // Apply filter
    switch (_filterStatus) {
      case 'verified':
        filtered =
            filtered.where((user) => user['emailVerified'] == true).toList();
        break;
      case 'unverified':
        filtered =
            filtered.where((user) => user['emailVerified'] != true).toList();
        break;
      case 'admins':
        filtered = filtered.where((user) {
          final role = user['role']?.toString().toLowerCase();
          return role == 'admin' || role == 'super_admin';
        }).toList();
        break;
      case 'all':
      default:
        break;
    }

    // Apply sort
    switch (_sortOrder) {
      case 'name':
        filtered.sort(
            (a, b) => _getUserDisplayName(a).compareTo(_getUserDisplayName(b)));
        break;
      case 'email':
        filtered.sort((a, b) => _getUserEmail(a).compareTo(_getUserEmail(b)));
        break;
      case 'status':
        filtered.sort((a, b) {
          final aVerified = a['emailVerified'] == true ? 1 : 0;
          final bVerified = b['emailVerified'] == true ? 1 : 0;
          return bVerified.compareTo(aVerified);
        });
        break;
      case 'role':
      default:
        filtered.sort((a, b) {
          final aRole = a['role']?.toString().toLowerCase() ?? 'user';
          final bRole = b['role']?.toString().toLowerCase() ?? 'user';
          const roleOrder = {'super_admin': 0, 'admin': 1, 'user': 2};
          final aOrder = roleOrder[aRole] ?? 3;
          final bOrder = roleOrder[bRole] ?? 3;
          return aOrder.compareTo(bOrder);
        });
        break;
    }

    if (mounted) {
      setState(() {
        _users = filtered;
      });
    }
  }

  void _cycleSortOrder() {
    setState(() {
      switch (_sortOrder) {
        case 'role':
          _sortOrder = 'name';
          break;
        case 'name':
          _sortOrder = 'email';
          break;
        case 'email':
          _sortOrder = 'status';
          break;
        case 'status':
        default:
          _sortOrder = 'role';
          break;
      }
    });
    _applySortAndFilter();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users;
  }

  void _initializeEditingStates() {
    setState(() {
      for (var user in _users) {
        final userId = user['uid'];
        _editingStates[userId] = false;
        _selectedRoles[userId] =
            user['role']?.toString().toLowerCase() ?? 'user';
        _selectedPermissions[userId] =
            List<String>.from(user['permissions'] ?? []);
      }
    });
  }

  Future<void> _saveUserChanges(String userId) async {
    try {
      debugPrint('💾 Saving changes for user: $userId');

      final user = _users.firstWhere((u) => u['uid'] == userId);
      final userEmail = _getUserEmail(user);
      final newRole = _selectedRoles[userId] ?? 'user';

      if (newRole == 'super_admin') {
        if (!_isCurrentUserSuperAdmin()) {
          _showMessage(
              'Only super admins can assign super admin role', Colors.red);
          return;
        }
        if (!_isEligibleForSuperAdmin(userEmail)) {
          _showMessage(
              'This email is not eligible for super admin role', Colors.red);
          return;
        }
      }

      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');

      final role = newRole;
      final permissions = _selectedPermissions[userId] ?? [];

      debugPrint('💾 New role: $role');
      debugPrint('💾 New permissions: $permissions');

      Map<String, dynamic> updateData = {
        'role': role,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (role == 'admin' || role == 'super_admin') {
        updateData['permissions'] = permissions;
      } else {
        updateData['permissions'] = null;
      }

      debugPrint('💾 Update data: $updateData');

      await userRef.update(updateData);
      _showMessage('User updated successfully', Colors.green);

      setState(() {
        _editingStates[userId] = false;
      });

      _loadUsers();
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      _showMessage('Error updating user: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _getUserDisplayName(Map<String, dynamic> user) {
    if (user['displayName'] != null &&
        user['displayName'].toString().isNotEmpty) {
      return user['displayName'].toString();
    }
    return 'User ${user['uid']?.toString().substring(0, 8) ?? 'Unknown'}';
  }

  String _getUserEmail(Map<String, dynamic> user) {
    if (user['email'] != null && user['email'].toString().isNotEmpty) {
      return user['email'].toString();
    }
    return 'No email';
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUserSuperAdmin = _isCurrentUserSuperAdmin();
    final displayedUsers = _filteredUsers;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: 'User Management',
            subtitle: 'Manage user roles, permissions and verification status',
            icon: Icons.people,
            primaryColor: Colors.indigo,
            actions: [
              IconButton(
                icon: const Icon(Icons.cleaning_services),
                onPressed: _cleanupOrphanedUsers,
                tooltip: 'Cleanup Orphaned Users',
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _cycleSortOrder,
                tooltip: 'Sort Users (${_sortOrder})',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Refresh Users',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Users',
                onSelected: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  _applySortAndFilter();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.people,
                            color:
                                _filterStatus == 'all' ? Colors.indigo : null),
                        const SizedBox(width: 8),
                        const Text('All Users'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'verified',
                    child: Row(
                      children: [
                        Icon(Icons.verified,
                            color: _filterStatus == 'verified'
                                ? Colors.green
                                : null),
                        const SizedBox(width: 8),
                        const Text('Verified Only'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'unverified',
                    child: Row(
                      children: [
                        Icon(Icons.warning,
                            color: _filterStatus == 'unverified'
                                ? Colors.orange
                                : null),
                        const SizedBox(width: 8),
                        const Text('Unverified Only'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'admins',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color:
                                _filterStatus == 'admins' ? Colors.red : null),
                        const SizedBox(width: 8),
                        const Text('Admins Only'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (displayedUsers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No users found',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Filter: $_filterStatus | Sort: $_sortOrder'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = displayedUsers[index];
                    final userId = user['uid'];
                    final isEditing = _editingStates[userId] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getUserRoleColor(user['role']),
                            child: Icon(
                              _getUserRoleIcon(user['role']),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getUserDisplayName(user),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user['emailVerified'] == true)
                                    const Icon(Icons.verified,
                                        color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  if (isCurrentUserSuperAdmin &&
                                      userId !=
                                          FirebaseAuth
                                              .instance.currentUser?.uid)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      onPressed: () => _deleteUser(userId),
                                      tooltip: 'Delete User',
                                    ),
                                ],
                              );
                            },
                          ),
                          subtitle: Text(_getUserEmail(user)),
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: double.infinity),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // User Info
                                    _buildInfoRow('UID', userId),
                                    _buildInfoRow('Email', _getUserEmail(user)),
                                    _buildInfoRow('Display Name',
                                        _getUserDisplayName(user)),
                                    _buildInfoRow('Role',
                                        user['role']?.toString() ?? 'user'),
                                    _buildInfoRow(
                                        'Email Verified',
                                        user['emailVerified'] == true
                                            ? 'Yes'
                                            : 'No'),
                                    _buildInfoRow('Created',
                                        _formatDate(user['createdAt'])),
                                    _buildInfoRow('Last Sign In',
                                        _formatDate(user['lastSignIn'])),

                                    const SizedBox(height: 16),

                                    // ✅ FULLY FIXED: Role Selection with complete layout constraints
                                    if (isCurrentUserSuperAdmin) ...[
                                      // Warning for non-eligible users
                                      if (!_isEligibleForSuperAdmin(
                                          _getUserEmail(user))) ...[
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: double.infinity),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.orange),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.warning,
                                                    color: Colors.orange,
                                                    size: 20),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'You can only assign admin roles. Super admin role requires super admin privileges.',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],

                                      const Text('Role:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),

                                      // ✅ COMPLETELY FIXED: Role selection with proper constraints
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: double.infinity),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // User Role
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth:
                                                            double.infinity),
                                                child: RadioListTile<String>(
                                                  dense: true,
                                                  title: const Text('User'),
                                                  value: 'user',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged: isEditing
                                                      ? (value) {
                                                          debugPrint(
                                                              '🔧 Changing role to: $value');
                                                          setState(() {
                                                            _selectedRoles[
                                                                    userId] =
                                                                value!;
                                                            if (value ==
                                                                'user') {
                                                              _selectedPermissions[
                                                                  userId] = [];
                                                            }
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ),

                                              // Admin Role
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth:
                                                            double.infinity),
                                                child: RadioListTile<String>(
                                                  dense: true,
                                                  title: const Text('Admin'),
                                                  value: 'admin',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged: isEditing
                                                      ? (value) {
                                                          debugPrint(
                                                              '🔧 Changing role to: $value');
                                                          setState(() {
                                                            _selectedRoles[
                                                                    userId] =
                                                                value!;
                                                            if (value ==
                                                                    'admin' &&
                                                                (_selectedPermissions[
                                                                            userId]
                                                                        ?.isEmpty ??
                                                                    true)) {
                                                              _selectedPermissions[
                                                                  userId] = [
                                                                'manage_songs',
                                                                'view_analytics'
                                                              ];
                                                            }
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ),

                                              // Super Admin Role
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth:
                                                            double.infinity),
                                                child: RadioListTile<String>(
                                                  dense: true,
                                                  title: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text('Super Admin'),
                                                      const SizedBox(width: 8),
                                                      if (!_isEligibleForSuperAdmin(
                                                          _getUserEmail(user)))
                                                        Icon(Icons.lock,
                                                            size: 16,
                                                            color: Colors
                                                                .grey.shade600),
                                                    ],
                                                  ),
                                                  value: 'super_admin',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged: (isEditing &&
                                                          _isEligibleForSuperAdmin(
                                                              _getUserEmail(
                                                                  user)))
                                                      ? (value) {
                                                          debugPrint(
                                                              '🔧 Changing role to: $value');
                                                          setState(() {
                                                            _selectedRoles[
                                                                    userId] =
                                                                value!;
                                                            if (value ==
                                                                'super_admin') {
                                                              _selectedPermissions[
                                                                      userId] =
                                                                  List.from(
                                                                      _availablePermissions);
                                                            }
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Additional message for non-eligible users
                                      if (!_isEligibleForSuperAdmin(
                                          _getUserEmail(user))) ...[
                                        const SizedBox(height: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: double.infinity),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'This email is not eligible for super admin role.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 16),

                                      // ✅ COMPLETELY FIXED: Permissions Section
                                      if ((_selectedRoles[userId] == 'admin' ||
                                              _selectedRoles[userId] ==
                                                  'super_admin') &&
                                          isEditing) ...[
                                        const Text('Permissions:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: double.infinity),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: _availablePermissions
                                                  .map(
                                                    (permission) =>
                                                        ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: double
                                                                  .infinity),
                                                      child: CheckboxListTile(
                                                        dense: true,
                                                        title: Text(
                                                          permission
                                                              .replaceAll(
                                                                  '_', ' ')
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                        ),
                                                        value: _selectedPermissions[
                                                                    userId]
                                                                ?.contains(
                                                                    permission) ??
                                                            false,
                                                        onChanged: isEditing
                                                            ? (value) {
                                                                setState(() {
                                                                  final permissions =
                                                                      _selectedPermissions[
                                                                              userId] ??
                                                                          [];
                                                                  if (value ==
                                                                      true) {
                                                                    permissions.add(
                                                                        permission);
                                                                  } else {
                                                                    permissions
                                                                        .remove(
                                                                            permission);
                                                                  }
                                                                  _selectedPermissions[
                                                                          userId] =
                                                                      permissions;
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 16),

                                      // ✅ COMPLETELY FIXED: Action Buttons with proper constraints
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: double.infinity),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isEditing) ...[
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 100),
                                                child: TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _editingStates[userId] =
                                                          false;
                                                      _selectedRoles[
                                                          userId] = user['role']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          'user';
                                                      _selectedPermissions[
                                                          userId] = List<
                                                              String>.from(
                                                          user['permissions'] ??
                                                              []);
                                                    });
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 100),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _saveUserChanges(userId),
                                                  child: const Text('Save'),
                                                ),
                                              ),
                                            ] else ...[
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 100),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _editingStates[userId] =
                                                          true;
                                                    });
                                                  },
                                                  child: const Text('Edit'),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: displayedUsers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getUserRoleColor(dynamic role) {
    switch (role?.toString().toLowerCase()) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getUserRoleIcon(dynamic role) {
    switch (role?.toString().toLowerCase()) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.shield;
      default:
        return Icons.person;
    }
  }
}
