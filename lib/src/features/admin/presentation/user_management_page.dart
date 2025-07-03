// lib/src/features/admin/presentation/user_management_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/widgets/admin_header.dart'; // ✅ NEW: Import admin header

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
  String _filterStatus = 'all'; // ✅ NEW: Filter by verification status

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
            .map((entry) {
              try {
                final userData = Map<String, dynamic>.from(entry.value as Map);
                userData['uid'] = entry.key;
                return userData;
              } catch (e) {
                debugPrint('❌ Error processing user ${entry.key}: $e');
                return null;
              }
            })
            .where((user) => user != null)
            .cast<Map<String, dynamic>>()
            .toList();

        usersList.sort((a, b) {
          final roleA = a['role'] ?? 'user';
          final roleB = b['role'] ?? 'user';

          if (roleA == roleB) {
            final emailA = _getUserEmail(a);
            final emailB = _getUserEmail(b);
            return emailA.compareTo(emailB);
          }

          if (roleA == 'admin' || roleA == 'super_admin') return -1;
          if (roleB == 'admin' || roleB == 'super_admin') return 1;
          return 0;
        });

        setState(() => _users = usersList);
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
    }

    setState(() => _isLoading = false);
  }

  // ✅ NEW: Filter users by verification status
  List<Map<String, dynamic>> get _filteredUsers {
    if (_filterStatus == 'all') return _users;

    return _users.where((user) {
      final isVerified = user['emailVerified'] == true;
      return _filterStatus == 'verified' ? isVerified : !isVerified;
    }).toList();
  }

  void _toggleEditMode(String userId) {
    setState(() {
      _editingStates[userId] = !(_editingStates[userId] ?? false);

      if (_editingStates[userId] == true) {
        final user = _users.firstWhere((u) => u['uid'] == userId);
        _selectedRoles[userId] = user['role'] ?? 'user';
        _selectedPermissions[userId] =
            List<String>.from(user['permissions'] ?? []);

        debugPrint('🔧 Editing user: ${_getUserEmail(user)}');
        debugPrint('🔧 Current role: ${user['role']}');
        debugPrint('🔧 Selected role: ${_selectedRoles[userId]}');
        debugPrint('🔧 Current permissions: ${user['permissions']}');
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
    final filteredUsers = _filteredUsers;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ✅ NEW: Collapsible admin header
          AdminHeader(
            title: 'User Management',
            subtitle: 'Manage user roles, permissions and verification status',
            icon: Icons.people,
            primaryColor: Colors.indigo,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Refresh Users',
              ),
              // ✅ NEW: Filter dropdown
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Users',
                onSelected: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
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
                        Text('All Users'),
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
                        Text('Verified Only'),
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
                        Text('Unverified Only'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ✅ UPDATED: Content with verification info
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(64.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _filterStatus == 'all'
                                    ? 'No users found'
                                    : _filterStatus == 'verified'
                                        ? 'No verified users found'
                                        : 'No unverified users found',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // ✅ NEW: Stats and filter info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: Colors.indigo.withOpacity(0.1),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${filteredUsers.length} ${_getFilterLabel()} found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCurrentUserSuperAdmin
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isCurrentUserSuperAdmin
                                            ? 'SUPER ADMIN'
                                            : 'ADMIN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentUserSuperAdmin
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // ✅ NEW: Verification stats
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatChip(
                                        'Verified',
                                        _users
                                            .where((u) =>
                                                u['emailVerified'] == true)
                                            .length,
                                        Colors.green),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                        'Unverified',
                                        _users
                                            .where((u) =>
                                                u['emailVerified'] != true)
                                            .length,
                                        Colors.orange),
                                    const SizedBox(width: 8),
                                    _buildStatChip(
                                        'Total', _users.length, Colors.indigo),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // User list
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final role = user['role'] ?? 'user';
                              final userId = user['uid'];
                              final isCurrentUser = userId ==
                                  FirebaseAuth.instance.currentUser?.uid;
                              final displayName = _getUserDisplayName(user);
                              final email = _getUserEmail(user);
                              final permissions =
                                  user['permissions'] as List<dynamic>? ?? [];
                              final isEditing = _editingStates[userId] ?? false;
                              final isUserEligibleForSuperAdmin =
                                  _isEligibleForSuperAdmin(email);
                              final isEmailVerified = user['emailVerified'] ==
                                  true; // ✅ NEW: Verification status

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getRoleColor(role),
                                    child: Icon(_getRoleIcon(role),
                                        color: Colors.white),
                                  ),
                                  title: Text(displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(email,
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(role)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getRoleColor(role),
                                              ),
                                            ),
                                          ),
                                          // ✅ NEW: Email verification status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isEmailVerified
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isEmailVerified
                                                      ? Icons.verified
                                                      : Icons.warning,
                                                  size: 10,
                                                  color: isEmailVerified
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  isEmailVerified
                                                      ? 'VERIFIED'
                                                      : 'UNVERIFIED',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isEmailVerified
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCurrentUser)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                'YOU',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          if (isUserEligibleForSuperAdmin)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                'SA ELIGIBLE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                        isEditing ? Icons.close : Icons.edit),
                                    color: isEditing ? Colors.red : Colors.blue,
                                    onPressed: () => _toggleEditMode(userId),
                                    tooltip: isEditing ? 'Cancel' : 'Edit User',
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!isEditing) ...[
                                            const Text('User Details:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            Text('UID: ${user['uid']}'),
                                            if (user['createdAt'] != null)
                                              Text(
                                                  'Created: ${user['createdAt']}'),
                                            if (user['lastSignIn'] != null)
                                              Text(
                                                  'Last Sign In: ${user['lastSignIn']}'),
                                            // ✅ NEW: Verification details
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  isEmailVerified
                                                      ? Icons.verified
                                                      : Icons.warning,
                                                  size: 16,
                                                  color: isEmailVerified
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Email: ${isEmailVerified ? "Verified" : "Not Verified"}',
                                                  style: TextStyle(
                                                    color: isEmailVerified
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (permissions.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              const Text('Permissions:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              ...permissions
                                                  .map((p) => Text('• $p')),
                                            ],
                                          ] else ...[
                                            // Edit Mode - same as before but with verification info
                                            const Text('Edit User:',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            const SizedBox(height: 16),

                                            if (!isCurrentUserSuperAdmin)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
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
                                                            color:
                                                                Colors.orange),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Role Selection
                                            const Text('Role:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Column(
                                              children: [
                                                RadioListTile<String>(
                                                  title: const Text('User'),
                                                  value: 'user',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged: (value) {
                                                    debugPrint(
                                                        '🔧 Changing role to: $value');
                                                    setState(() {
                                                      _selectedRoles[userId] =
                                                          value!;
                                                      if (value == 'user') {
                                                        _selectedPermissions[
                                                            userId] = [];
                                                      }
                                                    });
                                                  },
                                                ),
                                                RadioListTile<String>(
                                                  title: const Text('Admin'),
                                                  value: 'admin',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged: (value) {
                                                    debugPrint(
                                                        '🔧 Changing role to: $value');
                                                    setState(() {
                                                      _selectedRoles[userId] =
                                                          value!;
                                                      if (value == 'admin' &&
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
                                                  },
                                                ),
                                                RadioListTile<String>(
                                                  title: Row(
                                                    children: [
                                                      const Text('Super Admin'),
                                                      const SizedBox(width: 8),
                                                      if (!isCurrentUserSuperAdmin ||
                                                          !isUserEligibleForSuperAdmin)
                                                        Icon(Icons.lock,
                                                            size: 16,
                                                            color: Colors
                                                                .grey.shade600),
                                                    ],
                                                  ),
                                                  value: 'super_admin',
                                                  groupValue:
                                                      _selectedRoles[userId],
                                                  onChanged:
                                                      (isCurrentUserSuperAdmin &&
                                                              isUserEligibleForSuperAdmin)
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
                                              ],
                                            ),

                                            if (!isCurrentUserSuperAdmin ||
                                                !isUserEligibleForSuperAdmin) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                margin: const EdgeInsets.only(
                                                    top: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  !isCurrentUserSuperAdmin
                                                      ? 'Only super admins can assign super admin role'
                                                      : 'This email is not eligible for super admin role',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 16),

                                            // Permissions
                                            if (_selectedRoles[userId] ==
                                                    'admin' ||
                                                _selectedRoles[userId] ==
                                                    'super_admin') ...[
                                              const Text('Permissions:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              ..._availablePermissions.map(
                                                  (permission) =>
                                                      SwitchListTile(
                                                        title: Text(permission
                                                            .replaceAll(
                                                                '_', ' ')
                                                            .toUpperCase()),
                                                        value: _selectedPermissions[
                                                                    userId]
                                                                ?.contains(
                                                                    permission) ??
                                                            false,
                                                        onChanged: (checked) {
                                                          setState(() {
                                                            _selectedPermissions[
                                                                userId] ??= [];
                                                            if (checked) {
                                                              _selectedPermissions[
                                                                      userId]!
                                                                  .add(
                                                                      permission);
                                                            } else {
                                                              _selectedPermissions[
                                                                      userId]!
                                                                  .remove(
                                                                      permission);
                                                            }
                                                          });
                                                        },
                                                      )),
                                            ],

                                            const SizedBox(height: 16),

                                            // Save Button
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _saveUserChanges(userId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child:
                                                    const Text('Save Changes'),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build stat chips
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Get filter label
  String _getFilterLabel() {
    switch (_filterStatus) {
      case 'verified':
        return 'verified users';
      case 'unverified':
        return 'unverified users';
      default:
        return 'users';
    }
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
