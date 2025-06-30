import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:lpmi40/src/features/authentication/repository/sync_repository.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SyncRepository _syncRepository;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isSyncEnabled = true;
  DateTime? _lastSyncTime;

  File? _profileImageFile;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _syncRepository = await SyncRepository.init();
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
    if (mounted) {
      setState(() {
        _isSyncEnabled = _syncRepository.isSyncEnabled();
        _lastSyncTime = _syncRepository.getLastSyncTime();
        _isLoading = false;
      });
    }
    await _loadProfileImage();
  }

  // --- Profile Logic ---
  Future<void> _loadProfileImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagePath = p.join(appDir.path, 'profile_photo.jpg');
    final imageFile = File(imagePath);
    if (await imageFile.exists() && mounted) {
      setState(() => _profileImageFile = imageFile);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final newPath = p.join(appDir.path, 'profile_photo.jpg');
    final newImage = await File(pickedFile.path).copy(newPath);

    if (mounted) setState(() => _profileImageFile = newImage);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')));
    }
  }

  Future<void> _showEditNameDialog() async {
    final currentName = _nameController.text;
    final dialogNameController = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Display Name'),
        content: TextField(
          controller: dialogNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(dialogNameController.text),
              child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await _auth.currentUser?.updateDisplayName(newName);
      setState(() {
        _nameController.text = newName;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Display name updated!')));
      }
    }
  }

  // ✅ NEW: Change Password Function
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(() =>
                          obscureCurrentPassword = !obscureCurrentPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => obscureNewPassword = !obscureNewPassword),
                    ),
                    border: const OutlineInputBorder(),
                    helperText: 'Minimum 6 characters',
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),

                // Error Message
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Loading Indicator
                if (isLoading) ...[
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
                      Text('Updating password...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate inputs
                      if (currentPasswordController.text.isEmpty) {
                        setDialogState(() => errorMessage =
                            'Please enter your current password');
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        setDialogState(() => errorMessage =
                            'New password must be at least 6 characters');
                        return;
                      }

                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        setDialogState(
                            () => errorMessage = 'New passwords do not match');
                        return;
                      }

                      if (currentPasswordController.text ==
                          newPasswordController.text) {
                        setDialogState(() => errorMessage =
                            'New password must be different from current password');
                        return;
                      }

                      // Start loading
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        // Re-authenticate user with current password
                        final user = _auth.currentUser!;
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPasswordController.text,
                        );

                        await user.reauthenticateWithCredential(credential);

                        // Update password
                        await user.updatePassword(newPasswordController.text);

                        // Success
                        Navigator.of(context).pop(true);
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = _getPasswordChangeErrorMessage(e.code);
                        });
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage =
                              'An unexpected error occurred. Please try again.';
                        });
                      }
                    },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );

    // Show success message if password was changed
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Password updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ NEW: Error message helper for password changes
  String _getPasswordChangeErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Current password is incorrect';
      case 'weak-password':
        return 'New password is too weak';
      case 'requires-recent-login':
        return 'Please log out and log back in, then try again';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Failed to update password. Please try again';
    }
  }

  // --- Sign Out & Account Deletion ---
  Future<void> _signOut() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Logout',
      content: 'Are you sure you want to log out?',
    );
    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
          (Route<dynamic> route) => false,
        );
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
      // TODO: Implement account deletion logic
      // await _auth.currentUser?.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account deletion feature is not yet implemented.')));
      }
    }
  }

  // --- Helper Widgets & Dialogs ---
  Future<bool?> _showConfirmationDialog(
      {required String title,
      required String content,
      String confirmText = 'OK',
      bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Not logged in."))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 24),
                    _buildSettingsGroup(
                      title: 'Synchronization',
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Cloud Sync'),
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
                            await _syncRepository.syncToCloud();
                            if (mounted) {
                              setState(() => _lastSyncTime =
                                  _syncRepository.getLastSyncTime());
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsGroup(
                      title: 'Account',
                      children: [
                        // ✅ UPDATED: Working change password function
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          subtitle: const Text('Update your account password'),
                          onTap: () {
                            // Check if user is anonymous (guest)
                            if (user?.isAnonymous == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Guest users cannot change password. Please sign up for a full account.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Show change password dialog
                            _showChangePasswordDialog();
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.logout,
                              color: Theme.of(context).colorScheme.error),
                          title: Text('Logout',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
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
                                  color: Theme.of(context).colorScheme.error)),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageFile != null
                    ? FileImage(_profileImageFile!)
                    : null,
                child: _profileImageFile == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
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
                      : 'LPMI User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined,
                    size: 20, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
        Text(user.email ?? '',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).hintColor)),
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
