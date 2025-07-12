import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:lpmi40/src/features/authentication/repository/sync_repository.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/core/services/user_profile_notifier.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart'; // ✅ NEW: Import FirebaseService

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SyncRepository _syncRepository;
  final _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService =
      FirebaseService(); // ✅ NEW: Firebase service

  bool _isLoading = true;
  bool _isSyncEnabled = true;
  DateTime? _lastSyncTime;
  bool _isEmailVerified = false; // ✅ NEW: Track verification status
  bool _isCheckingVerification =
      false; // ✅ NEW: Track verification check loading
  bool _isSendingVerification = false; // ✅ NEW: Track verification send loading

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _syncRepository = await SyncRepository.init();
      final user = _auth.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _isEmailVerified =
            user.emailVerified; // ✅ NEW: Set initial verification status

        // ✅ NEW: Initialize the UserProfileNotifier with current verification status
        if (!user.isAnonymous && mounted) {
          Provider.of<UserProfileNotifier>(context, listen: false)
              .updateEmailVerificationStatus(user.emailVerified);
        }
      }
      if (mounted) {
        setState(() {
          _isSyncEnabled = _syncRepository.isSyncEnabled();
          _lastSyncTime = _syncRepository.getLastSyncTime();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing services: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ FIXED: Check email verification status
  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // ✅ FIXED: Handle Map return instead of bool
      final verificationResult =
          await _firebaseService.checkEmailVerification(forceRefresh: true);
      final isVerified = verificationResult['isVerified'] ?? false;

      if (mounted) {
        setState(() {
          _isEmailVerified = isVerified;
        });

        // ✅ NEW: Update the UserProfileNotifier with verification status
        Provider.of<UserProfileNotifier>(context, listen: false)
            .updateEmailVerificationStatus(isVerified);

        if (isVerified) {
          _showSuccessMessage('Email verified successfully!');
        } else {
          // ✅ ENHANCED: Show specific message from service
          final message =
              verificationResult['message'] ?? 'Email not yet verified';
          _showInfoMessage(message);
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to check verification status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  // ✅ FIXED: Send verification email
  Future<void> _sendVerificationEmail() async {
    if (_isSendingVerification) return;

    final user = _auth.currentUser;
    if (user == null) return;

    if (user.emailVerified) {
      _showSuccessMessage('Email is already verified!');
      return;
    }

    setState(() {
      _isSendingVerification = true;
    });

    try {
      // ✅ FIXED: Handle Map return instead of bool
      final result = await _firebaseService.sendEmailVerification();
      final success = result['success'] ?? false;

      if (mounted) {
        if (success) {
          // ✅ ENHANCED: Use specific success message from service
          final message =
              result['message'] ?? 'Verification email sent to ${user.email}';
          _showSuccessMessage(message);

          // ✅ ENHANCED: Handle special cases
          if (result['alreadyVerified'] == true) {
            setState(() {
              _isEmailVerified = true;
            });

            // ✅ NEW: Update the UserProfileNotifier with verification status
            Provider.of<UserProfileNotifier>(context, listen: false)
                .updateEmailVerificationStatus(true);
          }
        } else {
          // ✅ ENHANCED: Show specific error message from service
          final errorMessage =
              result['message'] ?? 'Failed to send verification email';

          // ✅ ENHANCED: Handle rate limiting specifically
          if (result['error'] == 'rate-limited') {
            final remainingSeconds = result['remainingSeconds'] ?? 0;
            _showInfoMessage(
                '$errorMessage ($remainingSeconds seconds remaining)');
          } else {
            _showErrorMessage(errorMessage);
          }
        }
      }
    } catch (e) {
      _showErrorMessage('Error sending verification email: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVerification = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final userProfileNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      final success = await userProfileNotifier.updateProfileImage();

      if (success) {
        _showSuccessMessage('Profile picture updated!');
      } else {
        _showErrorMessage('Failed to update profile picture');
      }
    } catch (e) {
      _showErrorMessage('Error updating profile picture: $e');
    }
  }

  Future<void> _showEditNameDialog() async {
    final currentName = _nameController.text;
    final dialogNameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Display Name'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dialogNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Name must be less than 50 characters';
                    }
                    return null;
                  },
                ),
                if (isUpdating) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Updating name...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final trimmedName = dialogNameController.text.trim();
                      if (trimmedName == currentName) {
                        Navigator.of(context).pop();
                        return;
                      }

                      setDialogState(() => isUpdating = true);

                      try {
                        final user = _auth.currentUser;
                        if (user == null) throw Exception('User not found');

                        debugPrint('🔄 Updating display name to: $trimmedName');

                        bool authUpdateSuccess = false;
                        try {
                          await user.updateDisplayName(trimmedName);
                          await user.reload();
                          authUpdateSuccess = true;
                          debugPrint(
                              '✅ Firebase Auth display name updated successfully');
                        } catch (e) {
                          debugPrint(
                              '⚠️ Firebase Auth display name update failed: $e');

                          if (e.toString().contains('PigeonUserInfo') ||
                              e.toString().contains('type cast') ||
                              e.toString().contains('List<Object?>')) {
                            debugPrint(
                                '⚠️ Known Firebase SDK type cast issue detected');
                            authUpdateSuccess = false;
                          } else {
                            rethrow;
                          }
                        }

                        debugPrint('🔄 Updating Firebase Database...');
                        final database = FirebaseDatabase.instance;
                        final userRef = database.ref('users/${user.uid}');

                        await userRef.update({
                          'displayName': trimmedName,
                          'updatedAt': DateTime.now().toIso8601String(),
                        });
                        debugPrint(
                            '✅ Database display name updated successfully');

                        String successMessage =
                            'Display name updated successfully!';
                        if (!authUpdateSuccess) {
                          successMessage +=
                              '\n(Note: Profile updated in database)';
                        }

                        if (mounted) {
                          Navigator.of(context).pop({
                            'success': true,
                            'newName': trimmedName,
                            'message': successMessage,
                          });
                        }
                      } catch (e) {
                        debugPrint('❌ Error updating name: $e');
                        setDialogState(() => isUpdating = false);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error updating name: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      setState(() {
        _nameController.text = result['newName'];
      });
      _showSuccessMessage(
          result['message'] ?? 'Display name updated successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _initializeServices();
              Provider.of<UserProfileNotifier>(context, listen: false)
                  .refreshProfileImage();
            },
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Not logged in", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Please log in to view your profile"),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _initializeServices,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildProfileHeader(user),
                      const SizedBox(height: 24),
                      // ✅ NEW: Email verification section
                      if (!user.isAnonymous) ...[
                        _buildEmailVerificationSection(user),
                        const SizedBox(height: 16),
                      ],
                      _buildSettingsGroup(
                        title: 'Synchronization',
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Cloud Sync'),
                            subtitle:
                                const Text('Sync favorites across devices'),
                            value: _isSyncEnabled,
                            onChanged: (value) {
                              setState(() => _isSyncEnabled = value);
                              _syncRepository.setSyncEnabled(value);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cloud_sync_outlined),
                            title: const Text('Sync Now'),
                            subtitle: Text(_lastSyncTime != null
                                ? 'Last sync: ${DateFormat.yMd().add_jm().format(_lastSyncTime!)}'
                                : 'Never synced'),
                            onTap: () async {
                              try {
                                await _syncRepository.syncToCloud();
                                if (mounted) {
                                  setState(() => _lastSyncTime =
                                      _syncRepository.getLastSyncTime());
                                }
                                _showSuccessMessage(
                                    'Sync completed successfully!');
                              } catch (e) {
                                _showErrorMessage('Sync failed: $e');
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsGroup(
                        title: 'Account',
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            subtitle:
                                const Text('Update your account password'),
                            onTap: () {
                              if (user.isAnonymous == true) {
                                _showInfoMessage(
                                    'Guest users cannot change password. Please sign up for a full account.');
                                return;
                              }

                              if (user.email == null || user.email!.isEmpty) {
                                _showInfoMessage(
                                    'Cannot change password for accounts without email.');
                                return;
                              }

                              _showChangePasswordDialog();
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.logout,
                                color: Theme.of(context).colorScheme.error),
                            title: Text('Logout',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                            subtitle: const Text('Sign out of your account'),
                            onTap: _signOut,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsGroup(
                        title: 'Danger Zone',
                        children: [
                          ListTile(
                            leading: Icon(Icons.delete_forever_outlined,
                                color: Theme.of(context).colorScheme.error),
                            title: Text('Delete Account',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                            subtitle:
                                const Text('Permanently delete your account'),
                            onTap: _deleteAccount,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Center(
          child: Consumer<UserProfileNotifier>(
            builder: (context, userProfileNotifier, child) {
              return Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userProfileNotifier.hasProfileImage
                        ? FileImage(userProfileNotifier.profileImage!)
                        : null,
                    child: userProfileNotifier.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (!userProfileNotifier.hasProfileImage
                            ? const Icon(Icons.person, size: 50)
                            : null),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            size: 20, color: Colors.white),
                        onPressed:
                            userProfileNotifier.isLoading ? null : _pickImage,
                        tooltip: 'Change Profile Picture',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _showEditNameDialog,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : (user.isAnonymous ? 'Guest User' : 'LPMI User'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined,
                    size: 20, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? (user.isAnonymous ? 'Anonymous User' : 'No email'),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
        if (user.isAnonymous) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Guest Account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ✅ NEW: Email verification section
  Widget _buildEmailVerificationSection(User user) {
    return _buildSettingsGroup(
      title: 'Email Verification',
      children: [
        ListTile(
          leading: Icon(
            _isEmailVerified ? Icons.verified : Icons.warning,
            color: _isEmailVerified ? Colors.green : Colors.orange,
          ),
          title:
              Text(_isEmailVerified ? 'Email Verified' : 'Email Not Verified'),
          subtitle: Text(_isEmailVerified
              ? 'Your email address has been verified'
              : 'Please verify your email address for full account security'),
          trailing: _isEmailVerified
              ? Icon(Icons.check_circle, color: Colors.green)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSendingVerification) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: _isSendingVerification
                          ? null
                          : _sendVerificationEmail,
                      child: const Text('Resend'),
                    ),
                  ],
                ),
        ),
        if (!_isEmailVerified) ...[
          ListTile(
            leading: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            title: const Text('Check Verification Status'),
            subtitle: const Text('Tap if you\'ve already verified your email'),
            trailing: _isCheckingVerification
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isCheckingVerification ? null : _checkEmailVerification,
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsGroup(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
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
        ),
      );
    }
  }

  void _showInfoMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    // Implementation placeholder - you can add this if needed
    _showInfoMessage('Password change feature coming soon');
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Logout',
      content: 'Are you sure you want to log out?',
    );
    if (confirmed == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        _showErrorMessage('Error signing out: $e');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Account',
      content:
          'This action is permanent and cannot be undone. Are you sure you want to delete your account and all associated data?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      _showInfoMessage('Account deletion feature is coming soon.');
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'OK',
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
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
