// lib/src/core/services/user_profile_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class UserProfileService {
  static const String _profileImageFileName = 'profile_photo.jpg';

  // Get the profile image file if it exists
  static Future<File?> getProfileImage() async {
    try {
      // ✅ WEB FIX: Path provider not available on web
      if (kIsWeb) {
        debugPrint('ℹ️ Profile images not supported on web platform');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagePath = p.join(appDir.path, _profileImageFileName);
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        debugPrint('✅ Profile image found: $imagePath');
        return imageFile;
      } else {
        debugPrint('📭 No profile image found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting profile image: $e');
      return null;
    }
  }

  // Save a new profile image
  static Future<File?> saveProfileImage(String sourcePath) async {
    try {
      // ✅ WEB FIX: Path provider not available on web
      if (kIsWeb) {
        debugPrint('ℹ️ Profile image saving not supported on web platform');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final newPath = p.join(appDir.path, _profileImageFileName);
      final newImage = await File(sourcePath).copy(newPath);

      debugPrint('✅ Profile image saved: $newPath');
      return newImage;
    } catch (e) {
      debugPrint('❌ Error saving profile image: $e');
      return null;
    }
  }

  // Delete the profile image
  static Future<bool> deleteProfileImage() async {
    try {
      // ✅ WEB FIX: Path provider not available on web
      if (kIsWeb) {
        debugPrint('ℹ️ Profile image deletion not supported on web platform');
        return true; // Return success since there's nothing to delete on web
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagePath = p.join(appDir.path, _profileImageFileName);
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('✅ Profile image deleted');
        return true;
      }
      return true; // Already doesn't exist
    } catch (e) {
      debugPrint('❌ Error deleting profile image: $e');
      return false;
    }
  }

  // Get profile image path (for display purposes)
  static Future<String?> getProfileImagePath() async {
    final imageFile = await getProfileImage();
    return imageFile?.path;
  }
}
