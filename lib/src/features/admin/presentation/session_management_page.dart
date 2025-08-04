// lib/src/features/admin/presentation/session_management_page.dart
// 👥 Admin panel for managing user sessions and premium access
// ✅ Grant/revoke premium access, view session info, manage device-based access
// ✅ Select and manage other users' sessions

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/core/services/session_integration_service.dart';
import 'package:lpmi40/src/core/services/session_manager.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  final SessionIntegrationService _sessionService = SessionIntegrationService.instance;
  final SessionManager _sessionManager = SessionManager.instance;
  final PremiumService _premiumService = PremiumService();
  final AuthorizationService _authorizationService = AuthorizationService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic> _sessionInfo = {};
  Map<String, dynamic> _trialInfo = {};
  Map<String, dynamic> _deviceSessionInfo = {};
  bool _isTrialEligible = false;
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  
  // User selection
  String? _selectedUserId;
  String? _selectedUserEmail;
  Map<String, dynamic>? _selectedUserData;
  List<Map<String, dynamic>> _users = [];
  bool _showCurrentUser = true;
  
  // Trial requests
  List<Map<String, dynamic>> _trialRequests = [];
  bool _isLoadingTrialRequests = false;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
    _loadUsers();
    _loadTrialRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSessionInfo() async {
    if (_showCurrentUser) {
      // Load current user session
      setState(() {
        _sessionInfo = _sessionService.getSessionInfo();
        _trialInfo = _sessionManager.getTrialInfo();
      });
      
      try {
        final eligible = await _sessionManager.isTrialEligible();
        setState(() {
          _isTrialEligible = eligible;
        });
      } catch (e) {
        debugPrint('Error checking trial eligibility: $e');
      }
    } else if (_selectedUserId != null) {
      // Load selected user session
      await _loadSelectedUserInfo();
    }
    
    // Load device session info for any user
    await _loadDeviceSessionInfo();
  }

  Future<void> _loadDeviceSessionInfo() async {
    try {
      final userId = _showCurrentUser 
          ? _sessionService.currentSession.userId 
          : _selectedUserId;
      
      if (userId != null) {
        final deviceInfo = await _sessionManager.getDeviceSessionInfo(userId);
        setState(() {
          _deviceSessionInfo = deviceInfo;
        });
      }
    } catch (e) {
      debugPrint('Error loading device session info: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    
    try {
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');
      final snapshot = await usersRef.get();
      
      if (snapshot.exists) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final usersList = <Map<String, dynamic>>[];
        
        usersData.forEach((uid, userData) {
          if (userData is Map) {
            final userMap = Map<String, dynamic>.from(userData);
            userMap['uid'] = uid;
            usersList.add(userMap);
          }
        });
        
        // Sort by email or display name
        usersList.sort((a, b) {
          final emailA = a['email']?.toString() ?? '';
          final emailB = b['email']?.toString() ?? '';
          return emailA.compareTo(emailB);
        });
        
        setState(() {
          _users = usersList;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      _showErrorMessage('Failed to load users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadSelectedUserInfo() async {
    if (_selectedUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$_selectedUserId');
      final snapshot = await userRef.get();
      
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        userData['uid'] = _selectedUserId;
        
        setState(() {
          _selectedUserData = userData;
          _sessionInfo = {
            'userRole': userData['role'] ?? 'user',
            'isPremium': userData['isPremium'] ?? false,
            'hasAudioAccess': userData['isPremium'] ?? false,
            'isExpired': false,
            'isPremiumExpired': false,
            'sessionCreatedAt': DateTime.now().toIso8601String(),
            'sessionExpiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'deviceId': 'admin-view',
            'permissions': userData['permissions'] ?? [],
          };
          _trialInfo = {
            'isTrialUser': false,
            'hasActiveTrial': false,
            'isTrialExpired': false,
            'trialType': 'none',
            'remainingTrialDays': 0,
            'remainingTrialHours': 0,
          };
          _isTrialEligible = true; // Admin can always start trials for users
        });
      }
    } catch (e) {
      debugPrint('Error loading selected user info: $e');
      _showErrorMessage('Failed to load user info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['uid'];
      _selectedUserEmail = user['email'];
      _selectedUserData = user;
      _showCurrentUser = false;
    });
    _loadSelectedUserInfo();
  }

  void _showCurrentUserSession() {
    setState(() {
      _selectedUserId = null;
      _selectedUserEmail = null;
      _selectedUserData = null;
      _showCurrentUser = true;
    });
    _loadSessionInfo();
  }

  Future<void> _loadTrialRequests() async {
    setState(() => _isLoadingTrialRequests = true);
    
    try {
      // First verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('[SessionManagement] ❌ User not authenticated');
        setState(() {
          _trialRequests = [];
        });
        return;
      }

      // Verify admin access with additional email check
      final adminStatus = await _authorizationService.checkAdminStatus();
      final isAdmin = adminStatus['isAdmin'] ?? false;
      final isSuperAdmin = adminStatus['isSuperAdmin'] ?? false;
      
      // Additional fallback: check if user email is in known admin list
      final userEmail = currentUser.email?.toLowerCase();
      final isSuperAdminByEmail = userEmail != null && (
        userEmail == 'heary@hopetv.asia' || 
        userEmail == 'heary_aldy@hotmail.com'
      );
      
      if (!isAdmin && !isSuperAdmin && !isSuperAdminByEmail) {
        debugPrint('[SessionManagement] ❌ Access denied: User $userEmail is not an admin');
        setState(() {
          _trialRequests = [];
        });
        return;
      }
      
      debugPrint('[SessionManagement] ✅ Admin access verified for $userEmail');
      
      final database = FirebaseDatabase.instance;
      // Try admin path first, fall back to legacy path if needed
      DatabaseReference trialRequestsRef;
      
      try {
        // Attempt to use admin-protected path
        trialRequestsRef = database.ref('admin/trial_requests');
        // Test access with a simple query first
        await trialRequestsRef.limitToFirst(1).get();
        debugPrint('[SessionManagement] ✅ Using admin/trial_requests path');
      } catch (adminError) {
        debugPrint('[SessionManagement] ⚠️ Admin path failed, trying legacy path: $adminError');
        // Fall back to legacy global path 
        trialRequestsRef = database.ref('trial_requests');
      }
      
      // Order by timestamp (most recent first)  
      final query = trialRequestsRef.orderByChild('requestedAtTimestamp');
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final requestsData = Map<String, dynamic>.from(snapshot.value as Map);
        final requestsList = <Map<String, dynamic>>[];
        
        requestsData.forEach((requestId, requestData) {
          if (requestData is Map) {
            final requestMap = Map<String, dynamic>.from(requestData);
            requestMap['id'] = requestId;
            requestsList.add(requestMap);
          }
        });
        
        // Sort by timestamp (most recent first)
        requestsList.sort((a, b) {
          final timestampA = a['requestedAtTimestamp'] ?? 0;
          final timestampB = b['requestedAtTimestamp'] ?? 0;
          return timestampB.compareTo(timestampA);
        });
        
        setState(() {
          _trialRequests = requestsList;
        });
      } else {
        setState(() {
          _trialRequests = [];
        });
      }
    } catch (e) {
      debugPrint('[SessionManagement] ❌ Error loading trial requests: $e');
      
      // Handle specific permission errors
      if (e.toString().contains('permission-denied')) {
        debugPrint('[SessionManagement] ❌ Permission denied - user may not have admin access');
        setState(() {
          _trialRequests = [];
        });
        // Don't show error message for permission denied - just show empty state
      } else {
        setState(() {
          _trialRequests = [];
        });
        _showErrorMessage('Failed to load trial requests: Network or database error');
      }
    } finally {
      setState(() => _isLoadingTrialRequests = false);
    }
  }

  Future<void> _approveTrialRequest(Map<String, dynamic> request) async {
    try {
      final requestId = request['id'];
      final userId = request['userId'];
      
      // Update request status - try admin path first, fall back to legacy
      final database = FirebaseDatabase.instance;
      DatabaseReference requestRef;
      
      try {
        requestRef = database.ref('admin/trial_requests/$requestId');
        // Test access first
        await requestRef.get();
      } catch (e) {
        debugPrint('[SessionManagement] ⚠️ Using legacy path for request update');
        requestRef = database.ref('trial_requests/$requestId');
      }
      
      await requestRef.update({
        'status': 'approved',
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedBy': FirebaseAuth.instance.currentUser?.email,
      });
      
      // Grant premium access to user if they have a userId
      if (userId != null && userId != 'null') {
        await _grantPremiumToUser(userId, true);
      }
      
      _showSuccessMessage('Trial request approved and premium access granted!');
      _loadTrialRequests(); // Refresh the list
    } catch (e) {
      _showErrorMessage('Error approving trial request: $e');
    }
  }

  Future<void> _rejectTrialRequest(Map<String, dynamic> request) async {
    try {
      final requestId = request['id'];
      
      // Update request status - try admin path first, fall back to legacy
      final database = FirebaseDatabase.instance;
      DatabaseReference requestRef;
      
      try {
        requestRef = database.ref('admin/trial_requests/$requestId');
        // Test access first
        await requestRef.get();
      } catch (e) {
        debugPrint('[SessionManagement] ⚠️ Using legacy path for request update');
        requestRef = database.ref('trial_requests/$requestId');
      }
      
      await requestRef.update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.email,
      });
      
      _showInfoMessage('Trial request rejected');
      _loadTrialRequests(); // Refresh the list
    } catch (e) {
      _showErrorMessage('Error rejecting trial request: $e');
    }
  }

  Future<void> _grantTemporaryPremium() async {
    setState(() => _isLoading = true);
    
    try {
      bool success = false;
      
      if (_showCurrentUser) {
        // Grant to current user
        success = await _sessionService.grantTemporaryPremium(
          duration: const Duration(hours: 24),
          reason: 'Admin granted - 24h trial',
        );
      } else if (_selectedUserId != null) {
        // Grant to selected user via Firebase
        success = await _grantPremiumToUser(_selectedUserId!, true);
      }
      
      if (success) {
        _showSuccessMessage('24-hour premium access granted!');
        _loadSessionInfo();
      } else {
        _showErrorMessage('Failed to grant premium access');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _grantExtendedPremium() async {
    setState(() => _isLoading = true);
    
    try {
      bool success = false;
      
      if (_showCurrentUser) {
        // Grant to current user
        success = await _sessionService.grantExtendedPremium(
          duration: const Duration(days: 365),
          reason: 'Admin granted - 1 year access',
        );
      } else if (_selectedUserId != null) {
        // Grant to selected user via Firebase
        success = await _grantPremiumToUser(_selectedUserId!, true);
      }
      
      if (success) {
        _showSuccessMessage('1-year premium access granted!');
        _loadSessionInfo();
      } else {
        _showErrorMessage('Failed to grant premium access');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _grantPremiumToUser(String userId, bool isPremium) async {
    try {
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/$userId');
      
      await userRef.update({
        'isPremium': isPremium,
        'role': isPremium ? 'premium' : 'user',
        'premiumGrantedAt': isPremium ? DateTime.now().toIso8601String() : null,
        'premiumGrantedBy': FirebaseAuth.instance.currentUser?.email,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating user premium status: $e');
      return false;
    }
  }

  Future<void> _restoreCachedPremium() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await _sessionService.restoreCachedPremiumAccess();
      
      if (success) {
        _showSuccessMessage('Cached premium access restored!');
        _loadSessionInfo();
      } else {
        _showInfoMessage('No cached premium access found');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startUserTrial() async {
    setState(() => _isLoading = true);
    
    try {
      final trialSession = await _sessionManager.startWeeklyTrial();
      
      if (trialSession != null) {
        _showSuccessMessage('1-week user trial started successfully!');
        _loadSessionInfo();
      } else {
        _showErrorMessage('Failed to start trial. User may not be eligible.');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copySessionInfo() {
    final info = _sessionInfo.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    
    Clipboard.setData(ClipboardData(text: info));
    _showInfoMessage('Session info copied to clipboard');
  }



  IconData _getUserRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'superadmin': return Icons.admin_panel_settings;
      case 'admin': return Icons.security;
      case 'premium': return Icons.star;
      default: return Icons.person;
    }
  }

  Color _getUserRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'superadmin': return Colors.red;
      case 'admin': return Colors.orange;
      case 'premium': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_showCurrentUser 
          ? 'Session Management - Current User' 
          : 'Session Management - ${_selectedUserEmail ?? 'Selected User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionInfo,
            tooltip: 'Refresh session info',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copySessionInfo,
            tooltip: 'Copy session info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Search & Selection
                  _buildUserSearchCard(theme),
                  const SizedBox(height: 16),
                  
                  // Current Session Status
                  _buildSessionStatusCard(theme),
                  const SizedBox(height: 24),
                  
                  // Trial Status
                  _buildTrialStatusCard(theme),
                  const SizedBox(height: 24),
                  
                  // Premium Access Management
                  _buildPremiumManagementCard(theme),
                  const SizedBox(height: 24),
                  
                  // Device Sessions
                  _buildDeviceSessionsCard(theme),
                  const SizedBox(height: 24),
                  
                  // Session Details
                  _buildSessionDetailsCard(theme),
                  const SizedBox(height: 24),
                  
                  // Trial Requests List
                  _buildTrialRequestsCard(theme),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActionsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildUserSearchCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User Selection & Session Management',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User dropdown selection
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _showCurrentUser ? 'current_user' : _selectedUserId,
                      isExpanded: true,
                      underline: Container(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hint: const Text('Select user', style: TextStyle(fontSize: 13)),
                      items: [
                        // Current user option
                        DropdownMenuItem<String>(
                          value: 'current_user',
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Current User (You)',
                                  style: TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Divider
                        const DropdownMenuItem<String>(
                          value: null,
                          enabled: false,
                          child: Divider(height: 1),
                        ),
                        
                        // Other users
                        ..._users.map((user) {
                          final email = user['email'] ?? user['displayName'] ?? 'Unknown User';
                          final role = user['role'] ?? 'user';
                          final isPremium = user['isPremium'] == true;
                          
                          return DropdownMenuItem<String>(
                            value: user['uid'],
                            child: Row(
                              children: [
                                Icon(
                                  _getUserRoleIcon(role),
                                  color: _getUserRoleColor(role),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        email,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '$role${isPremium ? ' • Premium' : ''}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        if (value == 'current_user') {
                          _showCurrentUserSession();
                        } else if (value != null) {
                          final user = _users.firstWhere((u) => u['uid'] == value);
                          _selectUser(user);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: _loadUsers,
                    icon: _isLoadingUsers 
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 14),
                    label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Current selection display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_showCurrentUser ? Colors.blue : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_showCurrentUser ? Colors.blue : Colors.green).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _showCurrentUser 
                      ? Icons.person 
                      : _getUserRoleIcon(_selectedUserData?['role']),
                    color: _showCurrentUser 
                      ? Colors.blue 
                      : _getUserRoleColor(_selectedUserData?['role']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showCurrentUser 
                            ? 'Viewing: Current User (You)'
                            : 'Viewing: ${_selectedUserEmail ?? 'Selected User'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (!_showCurrentUser && _selectedUserData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${_selectedUserData!['role'] ?? 'user'} | Premium: ${_selectedUserData!['isPremium'] == true ? 'Yes' : 'No'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (!_showCurrentUser) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '⚠️ Viewing another user\'s session. Actions apply to their account.',
                  style: TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildSessionStatusCard(ThemeData theme) {
    final isPremium = _sessionInfo['isPremium'] ?? false;
    final userRole = _sessionInfo['userRole'] ?? 'unknown';
    final hasAudioAccess = _sessionInfo['hasAudioAccess'] ?? false;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.person,
                  color: isPremium ? Colors.amber : theme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Session Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow('User Role', userRole.toUpperCase(), 
                userRole == 'premium' || userRole == 'admin' ? Colors.green : null),
            _buildStatusRow('Premium Access', isPremium ? 'ACTIVE' : 'INACTIVE', 
                isPremium ? Colors.green : Colors.red),
            _buildStatusRow('Audio Access', hasAudioAccess ? 'ENABLED' : 'DISABLED', 
                hasAudioAccess ? Colors.green : Colors.orange),
            _buildStatusRow('Session Type', 
                _sessionInfo['isExpired'] == true ? 'EXPIRED' : 'ACTIVE',
                _sessionInfo['isExpired'] == true ? Colors.red : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumManagementCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Premium Access Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Grant premium access to this device:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _grantTemporaryPremium,
                  icon: const Icon(Icons.access_time),
                  label: const Text('24 Hours Trial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _grantExtendedPremium,
                  icon: const Icon(Icons.star),
                  label: const Text('1 Year Access'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _restoreCachedPremium,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Cached'),
                ),
                ElevatedButton.icon(
                  onPressed: (_isLoading || !_isTrialEligible) ? null : _startUserTrial,
                  icon: const Icon(Icons.free_breakfast),
                  label: const Text('Start User Trial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'ℹ️ Premium access is stored locally on this device and persists across app restarts. It enables audio features and premium content access.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Session Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._sessionInfo.entries.map((entry) {
              String value = entry.value.toString();
              if (entry.key.contains('At') && value.contains('T')) {
                // Format datetime strings
                try {
                  final date = DateTime.parse(value);
                  value = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  // Keep original value if parsing fails
                }
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialStatusCard(ThemeData theme) {
    final isTrialUser = _trialInfo['isTrialUser'] ?? false;
    final hasActiveTrial = _trialInfo['hasActiveTrial'] ?? false;
    final isTrialExpired = _trialInfo['isTrialExpired'] ?? false;
    final trialType = _trialInfo['trialType'] ?? 'none';
    final remainingDays = _trialInfo['remainingTrialDays'] ?? 0;
    final remainingHours = _trialInfo['remainingTrialHours'] ?? 0;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (hasActiveTrial) {
      statusColor = Colors.green;
      statusIcon = Icons.star;
      statusText = 'ACTIVE TRIAL';
    } else if (isTrialExpired) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'TRIAL EXPIRED';
    } else if (_isTrialEligible) {
      statusColor = Colors.blue;
      statusIcon = Icons.local_offer;
      statusText = 'TRIAL AVAILABLE';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.block;
      statusText = 'TRIAL USED';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Trial Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow('Trial Status', statusText, statusColor),
            _buildStatusRow('Trial Type', trialType.toUpperCase(), null),
            _buildStatusRow('Eligible for Trial', _isTrialEligible ? 'YES' : 'NO', 
                _isTrialEligible ? Colors.green : Colors.red),
            
            if (hasActiveTrial) ...[
              _buildStatusRow('Remaining Time', 
                  remainingDays > 0 ? '$remainingDays days' : '$remainingHours hours',
                  Colors.green),
            ],
            
            if (isTrialUser) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  hasActiveTrial 
                    ? '🎉 User has active trial access to premium features!'
                    : '⏰ User\'s trial has ended. Consider offering subscription options.',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _sessionService.refreshSession();
                    _loadSessionInfo();
                    _showInfoMessage('Session refreshed');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Session'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _sessionService.logout();
                    _loadSessionInfo();
                    _showInfoMessage('User logged out');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (valueColor ?? Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (valueColor ?? Colors.grey).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSessionsCard(ThemeData theme) {
    final totalSessions = _deviceSessionInfo['totalSessions'] ?? 0;
    final phoneCount = _deviceSessionInfo['phoneCount'] ?? 0;
    final tabletCount = _deviceSessionInfo['tabletCount'] ?? 0;
    final webCount = _deviceSessionInfo['webCount'] ?? 0;
    final sessions = _deviceSessionInfo['sessions'] as List<Map<String, dynamic>>? ?? [];
    final limits = _deviceSessionInfo['limits'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device Sessions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$totalSessions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loadDeviceSessionInfo,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Device limits summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Device Limits (1 each)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildDeviceCountChip('📱 Phone', phoneCount, limits['maxPhones'] ?? 1),
                      _buildDeviceCountChip('📱 Tablet', tabletCount, limits['maxTablets'] ?? 1),
                      _buildDeviceCountChip('🌐 Web', webCount, limits['maxWeb'] ?? 1),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Active sessions list
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.device_unknown, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No active sessions found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'User has not signed in on any Premium devices yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Sessions:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sessions.map((session) => _buildSessionItem(session, theme)),
                ],
              ),
              
            // Admin actions
            if (!_showCurrentUser && _selectedUserId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _removeAllUserSessions(_selectedUserId!),
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Remove All Sessions', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCountChip(String label, int current, int max) {
    final isOverLimit = current > max;
    final color = isOverLimit ? Colors.red : (current == max ? Colors.orange : Colors.green);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $current/$max',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session, ThemeData theme) {
    final deviceType = session['deviceType'] ?? 'unknown';
    final deviceInfo = session['deviceInfo'] ?? 'Unknown Device';
    final lastActivity = session['lastActivity'];
    
    IconData deviceIcon;
    Color deviceColor;
    
    switch (deviceType) {
      case 'phone':
        deviceIcon = Icons.phone_android;
        deviceColor = Colors.green;
        break;
      case 'tablet':
        deviceIcon = Icons.tablet;
        deviceColor = Colors.blue;
        break;
      case 'web':
        deviceIcon = Icons.web;
        deviceColor = Colors.purple;
        break;
      default:
        deviceIcon = Icons.device_unknown;
        deviceColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(deviceIcon, color: deviceColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceInfo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Type: ${deviceType.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  if (lastActivity != null)
                    Text(
                      'Last Activity: ${_formatDateTime(lastActivity)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
            if (!_showCurrentUser && _selectedUserId != null)
              OutlinedButton.icon(
                onPressed: () => _removeUserSession(_selectedUserId!, session['deviceId']),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Remove', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeAllUserSessions(String userId) async {
    try {
      final success = await _sessionManager.removeAllUserSessions(userId);
      if (success) {
        _showSuccessMessage('All user sessions removed successfully');
        await _loadDeviceSessionInfo();
      } else {
        _showErrorMessage('Failed to remove user sessions');
      }
    } catch (e) {
      _showErrorMessage('Error removing sessions: $e');
    }
  }

  Future<void> _removeUserSession(String userId, String deviceId) async {
    try {
      final success = await _sessionManager.removeUserSession(userId, deviceId);
      if (success) {
        _showSuccessMessage('Session removed successfully');
        await _loadDeviceSessionInfo();
      } else {
        _showErrorMessage('Failed to remove session');
      }
    } catch (e) {
      _showErrorMessage('Error removing session: $e');
    }
  }

  Widget _buildTrialRequestsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title, count, and refresh button
            Row(
              children: [
                const Icon(Icons.request_page, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trial Requests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_trialRequests.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoadingTrialRequests ? null : _loadTrialRequests,
                  icon: _isLoadingTrialRequests 
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 14),
                  label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingTrialRequests)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_trialRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No trial requests found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Users haven\'t requested any premium trials yet',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Summary stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRequestStat('Pending', _trialRequests.where((r) => r['status'] == 'requested').length, Colors.orange),
                        _buildRequestStat('Approved', _trialRequests.where((r) => r['status'] == 'approved').length, Colors.green),
                        _buildRequestStat('Rejected', _trialRequests.where((r) => r['status'] == 'rejected').length, Colors.red),
                        _buildRequestStat('Activated', _trialRequests.where((r) => r['status'] == 'activated').length, Colors.purple),
                        _buildRequestStat('Expired', _trialRequests.where((r) => r['status'] == 'expired').length, Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Requests list
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _trialRequests.length,
                      itemBuilder: (context, index) {
                        final request = _trialRequests[index];
                        return _buildTrialRequestItem(request, theme);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStat(String label, int count, Color color) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrialRequestItem(Map<String, dynamic> request, ThemeData theme) {
    final status = request['status'] ?? 'unknown';
    final email = request['email'] ?? 'Unknown User';
    final trialType = request['trialType'] ?? 'unknown';
    final source = request['source'] ?? 'unknown';
    final requestedAt = request['requestedAt'];
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'activated':
        statusColor = Colors.purple;
        statusIcon = Icons.star;
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Type: ${trialType.toUpperCase()} | Source: ${source.replaceAll('_', ' ').toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            if (requestedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Requested: ${_formatDateTime(requestedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            
            if (status == 'requested') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectTrialRequest(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveTrialRequest(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}