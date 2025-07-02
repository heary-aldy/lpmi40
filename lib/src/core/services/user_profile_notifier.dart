// lib/src/core/services/user_profile_notifier.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lpmi40/src/core/services/user_profile_service.dart';

class UserProfileNotifier extends ChangeNotifier {
  File? _profileImage;
  bool _isLoading = false;

  // Public getters
  File? get profileImage => _profileImage;
  bool get isLoading => _isLoading;
  bool get hasProfileImage => _profileImage != null;

  UserProfileNotifier() {
    _loadProfileImage();
  }

  // Load profile image from storage
  Future<void> _loadProfileImage() async {
    try {
      _isLoading = true;
      notifyListeners();

      _profileImage = await UserProfileService.getProfileImage();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile image from image picker
  Future<bool> updateProfileImage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final savedImage =
          await UserProfileService.saveProfileImage(pickedFile.path);

      if (savedImage != null) {
        _profileImage = savedImage;
        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Profile image updated successfully');
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating profile image: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await UserProfileService.deleteProfileImage();

      if (success) {
        _profileImage = null;
        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Profile image deleted successfully');
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting profile image: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh profile image (useful for manual refresh)
  Future<void> refreshProfileImage() async {
    await _loadProfileImage();
  }

  // Get profile image path for widgets that need string path
  String? get profileImagePath => _profileImage?.path;
}
