import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onSyncComplete;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onSyncComplete,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final PreferencesService _preferencesService = PreferencesService();

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _syncEnabled = true;
  bool _isPremium = false;
  int _favoriteCount = 0;
  DateTime? _lastSyncTime;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      _syncEnabled = await _preferencesService.isSyncEnabled();
      _lastSyncTime = await _preferencesService.getLastSyncTime();
      _isPremium = await _firebaseService.isPremiumUser();

      final favorites = await _preferencesService.getFavoriteSongs();
      _favoriteCount = favorites.length;
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      await _preferencesService.syncToCloud();
      await _preferencesService.setLastSyncTime(DateTime.now());

      setState(() {
        _lastSyncTime = DateTime.now();
      });

      widget.onSyncComplete();
      _showSnackBar('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
      _showSnackBar('Sync failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _toggleSync(bool enabled) async {
    await _preferencesService.setSyncEnabled(enabled);
    setState(() {
      _syncEnabled = enabled;
    });

    if (enabled) {
      await _syncData();
    }
  }

  Future<void> _signOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text(
            'Are you sure you want to sign out? Your favorites will remain saved locally.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.signOut();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
            'This action cannot be undone. All your cloud data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showSnackBar('Account deletion is not yet implemented');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return 'Never';

    final difference = DateTime.now().difference(_lastSyncTime!);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser?.photoURL == null
                          ? Text(
                              _currentUser?.displayName?.substring(0, 1) ?? 'U',
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _currentUser?.displayName ?? 'User',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPremium ? Colors.amber : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isPremium ? 'Premium' : 'Free',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Stats Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                            'Favorites', '$_favoriteCount', Icons.favorite),
                        _buildStatItem('Sync Status',
                            _syncEnabled ? 'Enabled' : 'Disabled', Icons.sync),
                        _buildStatItem(
                            'Last Sync', _formatLastSync(), Icons.access_time),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Settings Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Auto Sync'),
                    subtitle: Text('Automatically sync favorites to cloud'),
                    value: _syncEnabled,
                    onChanged: _toggleSync,
                    secondary: Icon(Icons.cloud_sync),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('Sync Now'),
                    subtitle: Text('Manually sync your data'),
                    trailing: _isSyncing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.arrow_forward_ios),
                    onTap: _isSyncing ? null : _syncData,
                  ),
                  if (!_isPremium) ...[
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.star, color: Colors.amber),
                      title: Text('Upgrade to Premium'),
                      subtitle: Text('Unlock unlimited favorites and more'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showSnackBar('Premium upgrade coming soon!');
                      },
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 20),

            // Account Actions Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Help & Support'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showSnackBar('Help & Support coming soon!');
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showSnackBar('Privacy Policy coming soon!');
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.orange),
                    title: Text('Sign Out'),
                    onTap: _signOut,
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
