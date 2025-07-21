// lib/src/features/admin/presentation/user_management_page.dart
// ✅ RE-ENGINEERED: `role` and `isPremium` are now separate, independent properties.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedStates = {};
  final Map<String, String> _selectedRoles = {};
  // ✅ NEW: State map for the premium status switch
  final Map<String, bool> _selectedPremiumStatus = {};
  final Map<String, List<String>> _selectedPermissions = {};
  String _filterStatus = 'all';
  String _sortOrder = 'role';

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

  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  @override
  void initState() {
    super.initState();
    _logOperation('initState');
    _checkSuperAdminAccess();
  }

  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    _operationTimestamps[operation] = DateTime.now();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

    debugPrint(
        '[UserManagementPage] 🔧 Operation: $operation (count: ${_operationCounts[operation]})');
    if (details != null) {
      debugPrint('[UserManagementPage] 📊 Details: $details');
    }
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to access user data. Please check your permissions.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _checkSuperAdminAccess() async {
    _logOperation('checkSuperAdminAccess');

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

  String _getUserEmail(Map<String, dynamic> user) {
    return user['email']?.toString() ?? '';
  }

  bool _isDuplicateEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _users
            .where((user) =>
                user['email']?.toString().toLowerCase() == email.toLowerCase())
            .length >
        1;
  }

  Future<void> _loadUsers() async {
    _logOperation('loadUsers');

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

        setState(() {
          _users = usersList;
          _filteredUsers = usersList;
          _isLoading = false;
        });

        _logOperation('loadUsersSuccess', {
          'totalUsers': usersList.length,
          'hasData': snapshot.exists,
        });

        _applySortingAndFiltering();
      } else {
        setState(() {
          _users = [];
          _filteredUsers = [];
          _isLoading = false;
        });

        _logOperation('loadUsersEmpty');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _logOperation('loadUsersError', {'error': e.toString()});
      _showErrorMessage(_getUserFriendlyErrorMessage(e));
    }
  }

  void _applySortingAndFiltering() {
    _logOperation('applySortingAndFiltering', {
      'filterStatus': _filterStatus,
      'sortOrder': _sortOrder,
    });

    List<Map<String, dynamic>> filtered = List.from(_users);

    // ✅ UPDATED: Filtering logic now handles the 'premium' case separately
    if (_filterStatus != 'all') {
      filtered = filtered.where((user) {
        if (_filterStatus == 'premium') {
          return user['isPremium'] == true;
        }
        final role = user['role']?.toString().toLowerCase() ?? 'user';
        return role == _filterStatus;
      }).toList();
    }

    filtered.sort((a, b) {
      switch (_sortOrder) {
        case 'role':
          final roleA = a['role']?.toString().toLowerCase() ?? 'user';
          final roleB = b['role']?.toString().toLowerCase() ?? 'user';
          final priorityA =
              roleA == 'super_admin' ? 3 : (roleA == 'admin' ? 2 : 1);
          final priorityB =
              roleB == 'super_admin' ? 3 : (roleB == 'admin' ? 2 : 1);
          return priorityB.compareTo(priorityA);
        case 'name':
          final nameA = a['displayName']?.toString().toLowerCase() ?? '';
          final nameB = b['displayName']?.toString().toLowerCase() ?? '';
          return nameA.compareTo(nameB);
        case 'email':
          final emailA = a['email']?.toString().toLowerCase() ?? '';
          final emailB = b['email']?.toString().toLowerCase() ?? '';
          return emailA.compareTo(emailB);
        default:
          return 0;
      }
    });

    // Sorting applied: $_sortOrder, filtered count: ${filtered.length}

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _cycleSortOrder() {
    _logOperation('cycleSortOrder', {'oldOrder': _sortOrder});

    setState(() {
      switch (_sortOrder) {
        case 'role':
          _sortOrder = 'name';
          break;
        case 'name':
          _sortOrder = 'email';
          break;
        case 'email':
          _sortOrder = 'role';
          break;
        default:
          _sortOrder = 'role';
      }
    });

    // Sort changed from $oldSortOrder to $_sortOrder
    _applySortingAndFiltering();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _sortOrder == 'role'
                  ? Icons.admin_panel_settings
                  : _sortOrder == 'name'
                      ? Icons.person
                      : Icons.email,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('Sorted by: ${_sortOrder.toUpperCase()}'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ✅ UPDATED: Now saves both `role` and `isPremium` status.
  Future<void> _saveUserChanges(String userId) async {
    _logOperation('saveUserChanges', {'userId': userId});

    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');

      final updates = <String, dynamic>{};

      if (_selectedRoles.containsKey(userId)) {
        updates['role'] = _selectedRoles[userId];
      }

      if (_selectedPremiumStatus.containsKey(userId)) {
        updates['isPremium'] = _selectedPremiumStatus[userId];
      }

      updates['updatedAt'] = DateTime.now().toIso8601String();

      await userRef.update(updates);

      setState(() {
        _expandedStates[userId] = false;
      });

      _showSuccessMessage('User updated successfully');
      _loadUsers();
    } catch (e) {
      _logOperation(
          'saveUserChangesError', {'userId': userId, 'error': e.toString()});

      _showErrorMessage(_getUserFriendlyErrorMessage(e));
    }
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> user) async {
    _logOperation('deleteUser', {'userId': userId});

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this user?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user['displayName'] ?? 'Unknown'}'),
                  Text('Email: ${user['email'] ?? 'No email'}'),
                  Text('Role: ${user['role'] ?? 'user'}'),
                  Text('UID: $userId'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This only removes the user from the database. The Firebase Auth account will remain.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final database = FirebaseDatabase.instance;
        final userRef = database.ref('users/$userId');
        await userRef.remove();

        _showSuccessMessage('User deleted successfully');
        _loadUsers();
      } catch (e) {
        _logOperation(
            'deleteUserError', {'userId': userId, 'error': e.toString()});

        _showErrorMessage(_getUserFriendlyErrorMessage(e));
      }
    }
  }

  // ✅ UPDATED: Merge logic now considers both role and premium status.
  Future<void> _mergeDuplicateUsers(
      List<Map<String, dynamic>> duplicateUsers) async {
    _logOperation('mergeDuplicateUsers', {'count': duplicateUsers.length});

    final shouldMerge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Duplicate Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Found duplicate users with the same email:'),
            const SizedBox(height: 16),
            ...duplicateUsers.map((user) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UID: ${user['uid']}'),
                      Text('Role: ${user['role'] ?? 'user'}'),
                      Text('Premium: ${user['isPremium'] == true}'),
                      Text('Created: ${_formatDate(user['createdAt'])}'),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text(
              'This will keep the user with the highest role and premium status, then remove others.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Merge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldMerge == true) {
      try {
        final database = FirebaseDatabase.instance;

        duplicateUsers.sort((a, b) {
          final roleA = a['role']?.toString().toLowerCase() ?? 'user';
          final roleB = b['role']?.toString().toLowerCase() ?? 'user';
          final isPremiumA = a['isPremium'] == true;
          final isPremiumB = b['isPremium'] == true;

          final priorityA =
              (roleA == 'super_admin' ? 3 : (roleA == 'admin' ? 2 : 1)) +
                  (isPremiumA ? 0.5 : 0);
          final priorityB =
              (roleB == 'super_admin' ? 3 : (roleB == 'admin' ? 2 : 1)) +
                  (isPremiumB ? 0.5 : 0);

          return priorityB.compareTo(priorityA);
        });

        final keepUser = duplicateUsers.first;
        final removeUsers = duplicateUsers.skip(1).toList();

        for (final user in removeUsers) {
          final userRef = database.ref('users/${user['uid']}');
          await userRef.remove();
        }

        _showSuccessMessage(
            'Duplicate users merged. Kept user with role "${keepUser['role']}" and premium status ${keepUser['isPremium'] == true}.');
        _loadUsers();
      } catch (e) {
        _logOperation('mergeDuplicateUsersError', {'error': e.toString()});
        _showErrorMessage(_getUserFriendlyErrorMessage(e));
      }
    }
  }

  void _findAndShowDuplicates() {
    _logOperation('findAndShowDuplicates');

    final emailGroups = <String, List<Map<String, dynamic>>>{};

    for (final user in _users) {
      final email = user['email']?.toString().toLowerCase();
      if (email != null && email.isNotEmpty) {
        emailGroups[email] = emailGroups[email] ?? [];
        emailGroups[email]!.add(user);
      }
    }

    final duplicates =
        emailGroups.entries.where((entry) => entry.value.length > 1).toList();

    if (duplicates.isEmpty) {
      _showSuccessMessage('No duplicate users found');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Users Found'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Found ${duplicates.length} duplicate email(s):'),
              const SizedBox(height: 16),
              ...duplicates.map((duplicate) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${duplicate.key}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...duplicate.value.map((user) => Container(
                              margin:
                                  const EdgeInsets.only(left: 16, bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('UID: ${user['uid']}'),
                                  Text('Role: ${user['role'] ?? 'user'}'),
                                  Text(
                                      'Created: ${_formatDate(user['createdAt'])}'),
                                ],
                              ),
                            )),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (duplicates.isNotEmpty) {
                _mergeDuplicateUsers(duplicates.first.value);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Merge First Duplicate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
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

  void _showErrorMessage(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AdminHeader(
                title: 'User Management',
                subtitle:
                    'Manage user roles and permissions - Sort: ${_sortOrder.toUpperCase()}',
                icon: Icons.people,
                primaryColor: Colors.indigo,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    tooltip: 'Find Duplicates',
                    onPressed: _findAndShowDuplicates,
                  ),
                  IconButton(
                    icon: Icon(_sortOrder == 'role'
                        ? Icons.admin_panel_settings
                        : _sortOrder == 'name'
                            ? Icons.person
                            : Icons.email),
                    tooltip:
                        'Sort by ${_sortOrder.toUpperCase()} (tap to change)',
                    onPressed: _cycleSortOrder,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
                    tooltip: 'Refresh Users',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Text('Filter: '),
                            // ✅ UPDATED: Dropdown now includes a 'Premium' filter option
                            DropdownButton<String>(
                              value: _filterStatus,
                              onChanged: (value) {
                                setState(() {
                                  _filterStatus = value ?? 'all';
                                });
                                _applySortingAndFiltering();
                              },
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('All')),
                                DropdownMenuItem(
                                    value: 'user', child: Text('Users')),
                                DropdownMenuItem(
                                    value: 'premium', child: Text('Premium')),
                                DropdownMenuItem(
                                    value: 'admin', child: Text('Admins')),
                                DropdownMenuItem(
                                    value: 'super_admin',
                                    child: Text('Super Admins')),
                              ],
                            ),
                            const SizedBox(width: 16),
                            const Text('Sort: '),
                            GestureDetector(
                              onTap: _cycleSortOrder,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _sortOrder.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.sort,
                                        size: 16, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${_users.length} users | Showing: ${_filteredUsers.length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_filteredUsers.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _filterStatus == 'all'
                                ? 'No users found'
                                : 'No $_filterStatus users found',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (_filterStatus != 'all')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterStatus = 'all';
                                });
                                _applySortingAndFiltering();
                              },
                              child: const Text('Show all users'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = _filteredUsers[index];
                      final userId = user['uid'] as String;
                      final isExpanded = _expandedStates[userId] ?? false;
                      final isCurrentUserSuperAdmin =
                          _isCurrentUserSuperAdmin();

                      // ✅ UPDATED: Initialize both role and premium status from user data
                      _selectedRoles[userId] ??=
                          user['role']?.toString().toLowerCase() ?? 'user';
                      _selectedPremiumStatus[userId] ??=
                          user['isPremium'] as bool? ?? false;
                      _selectedPermissions[userId] ??=
                          List<String>.from(user['permissions'] ?? []);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Card(
                          elevation: 1,
                          child: ExpansionTile(
                            key: Key(userId),
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedStates[userId] = expanded;
                                if (expanded) {
                                  _selectedRoles[userId] =
                                      user['role']?.toString().toLowerCase() ??
                                          'user';
                                  _selectedPremiumStatus[userId] =
                                      user['isPremium'] as bool? ?? false;
                                  _selectedPermissions[userId] =
                                      List<String>.from(
                                          user['permissions'] ?? []);
                                }
                              });
                            },
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: _getUserRoleColor(user['role']),
                              child: Icon(
                                _getUserRoleIcon(user['role']),
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              user['displayName']?.toString() ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['email']?.toString() ?? 'No email',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getUserRoleColor(user['role'])
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                _getUserRoleColor(user['role'])
                                                    .withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        user['role']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'USER',
                                        style: TextStyle(
                                          color:
                                              _getUserRoleColor(user['role']),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // ✅ UPDATED: Premium badge now checks the `isPremium` flag
                                    if (user['isPremium'] == true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.purple
                                                  .withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.music_note,
                                              size: 10,
                                              color: Colors.purple,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'AUDIO',
                                              style: TextStyle(
                                                color: Colors.purple,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    if (user['emailVerified'] == true)
                                      const Icon(Icons.verified,
                                          color: Colors.green, size: 16),
                                    if (user['emailVerified'] != true)
                                      const Icon(Icons.mail_outline,
                                          color: Colors.orange, size: 16),
                                    if (_isDuplicateEmail(
                                        user['email']?.toString())) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3)),
                                        ),
                                        child: const Text(
                                          'DUP',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('UID', userId),
                                    _buildInfoRow('Created',
                                        _formatDate(user['createdAt'])),
                                    _buildInfoRow('Last Sign In',
                                        _formatDate(user['lastSignIn'])),
                                    // ✅ UPDATED: Audio access row now checks `isPremium`
                                    if (user['isPremium'] == true)
                                      _buildInfoRow(
                                          'Audio Access', 'Enabled ✅'),
                                    if (_isDuplicateEmail(
                                        user['email']?.toString())) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning,
                                                color: Colors.red, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Duplicate Email Detected',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'This email exists in multiple accounts. Use "Find Duplicates" to merge.',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    if (isCurrentUserSuperAdmin) ...[
                                      const Text('Role:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Column(
                                        children: [
                                          RadioListTile<String>(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('User'),
                                            value: 'user',
                                            groupValue: _selectedRoles[userId],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedRoles[userId] = value!;
                                              });
                                            },
                                          ),
                                          RadioListTile<String>(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('Admin'),
                                            value: 'admin',
                                            groupValue: _selectedRoles[userId],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedRoles[userId] = value!;
                                              });
                                            },
                                          ),
                                          if (_isEligibleForSuperAdmin(
                                              _getUserEmail(user)))
                                            RadioListTile<String>(
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                              title: const Text('Super Admin'),
                                              value: 'super_admin',
                                              groupValue:
                                                  _selectedRoles[userId],
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedRoles[userId] =
                                                      value!;
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // ✅ NEW: Separate Switch for Premium Access
                                      SwitchListTile(
                                        title: const Text('Premium Access',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        subtitle: const Text(
                                            'Grants access to all audio features.'),
                                        value: _selectedPremiumStatus[userId] ??
                                            false,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPremiumStatus[userId] =
                                                value;
                                          });
                                        },
                                        secondary: const Icon(Icons.star,
                                            color: Colors.purple),
                                      ),
                                      if (_selectedRoles[userId] == 'admin' ||
                                          _selectedRoles[userId] ==
                                              'super_admin') ...[
                                        const SizedBox(height: 16),
                                        const Text('Admin Permissions:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Column(
                                          children: _availablePermissions
                                              .map((permission) =>
                                                  CheckboxListTile(
                                                    dense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    title: Text(permission),
                                                    value: _selectedPermissions[
                                                                userId]
                                                            ?.contains(
                                                                permission) ??
                                                        false,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        if (value == true) {
                                                          _selectedPermissions[
                                                              userId] = [
                                                            ...(_selectedPermissions[
                                                                    userId] ??
                                                                []),
                                                            permission
                                                          ];
                                                        } else {
                                                          _selectedPermissions[
                                                                  userId] =
                                                              (_selectedPermissions[
                                                                          userId] ??
                                                                      [])
                                                                  .where((p) =>
                                                                      p !=
                                                                      permission)
                                                                  .toList();
                                                        }
                                                      });
                                                    },
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                    ],
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.red
                                                    .withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete,
                                                  size: 16, color: Colors.red),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Delete User',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                flex: 0,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      _deleteUser(userId, user),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    backgroundColor: Colors.red
                                                        .withOpacity(0.1),
                                                    minimumSize:
                                                        const Size(60, 32),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (isCurrentUserSuperAdmin) ...[
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.blue
                                                      .withOpacity(0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _expandedStates[
                                                            userId] = false;
                                                      });
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.grey,
                                                      minimumSize:
                                                          const Size(0, 32),
                                                    ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        _saveUserChanges(
                                                            userId),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      minimumSize:
                                                          const Size(0, 32),
                                                    ),
                                                    child: const Text('Save'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _filteredUsers.length,
                  ),
                ),
            ],
          ),
          // ✅ RESPONSIVE FIX: Back button only shows on mobile devices to avoid double back buttons
          if (MediaQuery.of(context).size.width < 768.0)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Colors.white,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const RevampedDashboardPage()),
                  (route) => false,
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

  // ✅ UPDATED: Role color no longer has a 'premium' case
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

  // ✅ UPDATED: Role icon no longer has a 'premium' case
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

  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'userStats': {
        'totalUsers': _users.length,
        'filteredUsers': _filteredUsers.length,
        'expandedUsers': _expandedStates.length,
        'currentFilter': _filterStatus,
        'currentSort': _sortOrder,
      },
    };
  }
}
