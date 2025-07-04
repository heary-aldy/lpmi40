// lib/src/core/services/announcement_service.dart

import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:lpmi40/src/features/announcements/models/announcement_model.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  FirebaseDatabase? get _database =>
      _isFirebaseInitialized ? FirebaseDatabase.instance : null;

  FirebaseStorage? get _storage =>
      _isFirebaseInitialized ? FirebaseStorage.instance : null;

  /// Get the announcements reference in Firebase
  DatabaseReference get _announcementsRef =>
      _database!.ref('app_config/announcements');

  /// Get all announcements from Firebase
  Future<List<Announcement>> getAllAnnouncements() async {
    if (!_isFirebaseInitialized) {
      debugPrint(
          'Firebase not initialized, returning empty announcements list');
      return [];
    }

    try {
      debugPrint('🔄 Fetching announcements from Firebase...');

      final snapshot = await _announcementsRef.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ Announcements fetch timed out');
          throw Exception('Firebase query timeout');
        },
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final announcements = <Announcement>[];

        for (final entry in data.entries) {
          try {
            final announcement = Announcement.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
              entry.key,
            );
            announcements.add(announcement);
          } catch (e) {
            debugPrint('⚠️ Error parsing announcement ${entry.key}: $e');
          }
        }

        debugPrint(
            '✅ Loaded ${announcements.length} announcements from Firebase');
        return announcements;
      } else {
        debugPrint('📭 No announcements found in Firebase');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching announcements: $e');
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  /// Get only active and valid announcements for display
  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final allAnnouncements = await getAllAnnouncements();
      final activeAnnouncements = allAnnouncements
          .where((announcement) => announcement.isValid)
          .toList();

      // Sort by priority (lower number = higher priority)
      activeAnnouncements.sort((a, b) => a.priority.compareTo(b.priority));

      debugPrint('✅ Found ${activeAnnouncements.length} active announcements');
      return activeAnnouncements;
    } catch (e) {
      debugPrint('❌ Error fetching active announcements: $e');
      return [];
    }
  }

  /// Create a new announcement
  Future<String> createAnnouncement(Announcement announcement,
      [File? imageFile]) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Creating new announcement: ${announcement.title}');

      // Generate unique ID for the announcement
      final announcementRef = _announcementsRef.push();
      final announcementId = announcementRef.key!;

      // Handle image upload if provided
      String imageUrl = '';
      if (imageFile != null && announcement.type == 'image') {
        imageUrl = await _uploadImage(announcementId, imageFile);
      }

      // Create announcement data
      final announcementData = announcement.copyWith(
        id: announcementId,
        imageUrl: imageUrl,
      );

      // Save to Firebase
      await announcementRef.set(announcementData.toJson()).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⏰ Announcement creation timed out');
          throw Exception('Firebase write timeout');
        },
      );

      debugPrint('✅ Announcement created successfully: $announcementId');
      return announcementId;
    } catch (e) {
      debugPrint('❌ Error creating announcement: $e');
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(String announcementId, File imageFile) async {
    if (_storage == null) {
      throw Exception('Firebase Storage not initialized');
    }

    try {
      debugPrint('🔄 Uploading image for announcement: $announcementId');

      // Create reference with organized path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'announcement_${announcementId}_$timestamp.jpg';
      final storageRef = _storage!.ref().child('announcements').child(fileName);

      // Set metadata for better organization
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'announcementId': announcementId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload progress (optional - for future progress indicators)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          debugPrint('⏰ Image upload timed out');
          throw Exception('Image upload timeout');
        },
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Update announcement status (active/inactive)
  Future<void> toggleAnnouncementStatus(
      String announcementId, bool isActive) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint(
          '🔄 Toggling announcement status: $announcementId -> $isActive');

      await _announcementsRef.child(announcementId).update({
        'isActive': isActive,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ Status update timed out');
          throw Exception('Firebase update timeout');
        },
      );

      debugPrint('✅ Announcement status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating announcement status: $e');
      throw Exception('Failed to update announcement status: $e');
    }
  }

  /// Delete announcement and its associated image
  Future<void> deleteAnnouncement(String announcementId) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint('🔄 Deleting announcement: $announcementId');

      // Get announcement data first to check for image
      final snapshot = await _announcementsRef.child(announcementId).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final imageUrl = data['imageUrl']?.toString();

        // Delete image from storage if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _deleteImageFromUrl(imageUrl);
        }
      }

      // Delete announcement from database
      await _announcementsRef.child(announcementId).remove().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ Announcement deletion timed out');
          throw Exception('Firebase delete timeout');
        },
      );

      debugPrint('✅ Announcement deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting announcement: $e');
      throw Exception('Failed to delete announcement: $e');
    }
  }

  /// Delete image from Firebase Storage using download URL
  Future<void> _deleteImageFromUrl(String downloadUrl) async {
    if (_storage == null) return;

    try {
      debugPrint('🔄 Deleting image from storage: $downloadUrl');

      // Extract storage path from download URL
      final storageRef = _storage!.refFromURL(downloadUrl);
      await storageRef.delete();

      debugPrint('✅ Image deleted from storage successfully');
    } catch (e) {
      debugPrint('⚠️ Error deleting image from storage: $e');
      // Don't throw - announcement deletion should continue even if image deletion fails
    }
  }

  /// Update announcement priority
  Future<void> updateAnnouncementPriority(
      String announcementId, int priority) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }

    try {
      debugPrint(
          '🔄 Updating announcement priority: $announcementId -> $priority');

      await _announcementsRef.child(announcementId).update({
        'priority': priority,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ Priority update timed out');
          throw Exception('Firebase update timeout');
        },
      );

      debugPrint('✅ Announcement priority updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating announcement priority: $e');
      throw Exception('Failed to update announcement priority: $e');
    }
  }

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(String announcementId) async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized');
      return null;
    }

    try {
      debugPrint('🔄 Fetching announcement by ID: $announcementId');

      final snapshot =
          await _announcementsRef.child(announcementId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ Announcement fetch timed out');
          throw Exception('Firebase query timeout');
        },
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final announcement = Announcement.fromJson(data, announcementId);

        debugPrint('✅ Announcement found: ${announcement.title}');
        return announcement;
      } else {
        debugPrint('📭 Announcement not found: $announcementId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching announcement by ID: $e');
      return null;
    }
  }

  /// Clean up expired announcements (utility method for maintenance)
  Future<int> cleanupExpiredAnnouncements() async {
    try {
      final allAnnouncements = await getAllAnnouncements();
      final expiredAnnouncements = allAnnouncements
          .where((announcement) => announcement.isExpired)
          .toList();

      int deletedCount = 0;
      for (final announcement in expiredAnnouncements) {
        try {
          await deleteAnnouncement(announcement.id);
          deletedCount++;
        } catch (e) {
          debugPrint(
              '⚠️ Error deleting expired announcement ${announcement.id}: $e');
        }
      }

      debugPrint('✅ Cleaned up $deletedCount expired announcements');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
      return 0;
    }
  }

  /// Test Firebase connection for debugging
  Future<bool> testConnection() async {
    if (!_isFirebaseInitialized) {
      debugPrint('❌ Firebase not initialized');
      return false;
    }

    try {
      debugPrint('🔄 Testing Firebase connection...');

      // Test database connection
      final ref = _database!.ref('.info/connected');
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));
      final isConnected = snapshot.value as bool? ?? false;

      debugPrint(isConnected
          ? '✅ Firebase Database connected'
          : '❌ Firebase Database not connected');

      return isConnected;
    } catch (e) {
      debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }
}
