// lib/src/features/dashboard/presentation/dashboard_header.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lpmi40/src/core/services/settings_notifier.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DashboardHeader extends StatefulWidget {
  final String greeting;
  final IconData greetingIcon;
  final String userName;
  final User? currentUser;
  final bool isAdmin;
  final bool isSuperAdmin;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.greetingIcon,
    required this.userName,
    required this.currentUser,
    required this.isAdmin,
    required this.isSuperAdmin,
    required this.onProfileTap,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(covariant DashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser?.uid != oldWidget.currentUser?.uid) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    if (widget.currentUser == null) {
      if (mounted) setState(() => _profileImageFile = null);
      return;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagePath = p.join(appDir.path, 'profile_photo.jpg');
      final imageFile = File(imagePath);
      if (await imageFile.exists() && mounted) {
        // Adding a cache-busting query parameter to the file path
        // This forces the FileImage provider to reload the image
        final updatedFile = File(
            '${imageFile.path}?v=${DateTime.now().millisecondsSinceEpoch}');
        setState(() => _profileImageFile = updatedFile);
      } else {
        if (mounted) setState(() => _profileImageFile = null);
      }
    } catch (e) {
      debugPrint('Error loading profile image in header: $e');
      if (mounted) setState(() => _profileImageFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsNotifier>(context, listen: false);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/header_image.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(widget.greetingIcon,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(widget.greeting,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            if (widget.isSuperAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('SUPER ADMIN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ] else if (widget.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('ADMIN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Text(widget.userName,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white70),
                              overflow: TextOverflow.ellipsis),
                        )
                      ],
                    ),
                  ),
                  _buildProfileAvatar(context, settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, SettingsNotifier settings) {
    ImageProvider? backgroundImage;
    Widget? child;

    if (_profileImageFile != null) {
      backgroundImage = FileImage(_profileImageFile!);
    } else if (widget.currentUser?.photoURL != null) {
      backgroundImage = NetworkImage(widget.currentUser!.photoURL!);
    } else {
      child = Icon(
        widget.currentUser == null ? Icons.login : Icons.person,
        color: widget.currentUser == null
            ? Theme.of(context).colorScheme.primary
            : widget.isSuperAdmin
                ? Colors.red
                : widget.isAdmin
                    ? Colors.orange
                    : null,
        size: (widget.isSuperAdmin || widget.isAdmin) ? 28 : 24,
      );
    }

    return InkWell(
      onTap: widget.onProfileTap,
      borderRadius: BorderRadius.circular(24),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: widget.currentUser == null
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : widget.isSuperAdmin
                ? Colors.red.withOpacity(0.3)
                : widget.isAdmin
                    ? Colors.orange.withOpacity(0.3)
                    : Theme.of(context).colorScheme.surfaceVariant,
        backgroundImage: backgroundImage,
        child: child,
      ),
    );
  }
}
