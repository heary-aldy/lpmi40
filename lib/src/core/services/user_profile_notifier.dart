// lib/src/core/services/user_profile_notifier.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lpmi40/src/core/services/user_profile_service.dart';
import 'package:lpmi40/src/core/services/photo_picker_service.dart';

class UserProfileNotifier extends ChangeNotifier {
  File? _profileImage;
  bool _isLoading = false;

  // ✅ NEW: Email verification status management
  bool? _isEmailVerified; // null = unknown, true = verified, false = unverified
  DateTime? _lastVerificationCheck;

  // Public getters
  File? get profileImage => _profileImage;
  bool get isLoading => _isLoading;
  bool get hasProfileImage => _profileImage != null;

  // ✅ NEW: Email verification getters
  bool? get isEmailVerified => _isEmailVerified;
  DateTime? get lastVerificationCheck => _lastVerificationCheck;

  UserProfileNotifier() {
    _loadProfileImage();
    _initializeEmailVerificationStatus(); // ✅ NEW: Initialize verification status
  }

  // ✅ NEW: Initialize email verification status
  Future<void> _initializeEmailVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _isEmailVerified = user.emailVerified;
      _lastVerificationCheck = DateTime.now();
      notifyListeners();
    }
  }

  // ✅ NEW: Update email verification status
  void updateEmailVerificationStatus(bool isVerified) {
    if (_isEmailVerified != isVerified) {
      _isEmailVerified = isVerified;
      _lastVerificationCheck = DateTime.now();
      debugPrint(
          '📧 [UserProfileNotifier] Email verification status updated: $isVerified');
      notifyListeners();
    }
  }

  // ✅ NEW: Refresh email verification status
  Future<void> refreshEmailVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await user.reload(); // Refresh from Firebase
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser != null) {
        updateEmailVerificationStatus(updatedUser.emailVerified);
      }
    }
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

  // Update profile image using privacy-friendly photo picker
  Future<bool> updateProfileImage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final photoPickerService = PhotoPickerService();
      final result = await photoPickerService.pickImage(
        imageQuality: 50,
      );

      if (!result.isSuccess || result.path == null) {
        _isLoading = false;
        notifyListeners();
        debugPrint(
            '❌ [UserProfileNotifier] No image selected or error: ${result.error}');
        return false;
      }

      final savedImage =
          await UserProfileService.saveProfileImage(result.path!);

      if (savedImage != null) {
        _profileImage = savedImage;
        _isLoading = false;
        notifyListeners();
        debugPrint(
            '✅ [UserProfileNotifier] Profile image updated successfully (privacy-friendly)');
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [UserProfileNotifier] Error updating profile image: $e');
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
