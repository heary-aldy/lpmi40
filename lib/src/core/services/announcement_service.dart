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

  DatabaseReference get _announcementsRef =>
      _database!.ref('app_config/announcements');

  Future<List<Announcement>> getAllAnnouncements() async {
    if (!_isFirebaseInitialized) {
      debugPrint(
          'Firebase not initialized, returning empty announcements list');
      return [];
    }
    try {
      final snapshot = await _announcementsRef.get().timeout(
            const Duration(seconds: 15),
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
        return announcements;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching announcements: $e');
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final allAnnouncements = await getAllAnnouncements();
      final activeAnnouncements = allAnnouncements
          .where((announcement) => announcement.isValid)
          .toList();
      activeAnnouncements.sort((a, b) => a.priority.compareTo(b.priority));
      return activeAnnouncements;
    } catch (e) {
      debugPrint('❌ Error fetching active announcements: $e');
      return [];
    }
  }

  Future<String> createAnnouncement(Announcement announcement,
      [File? imageFile]) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }
    try {
      final announcementRef = _announcementsRef.push();
      final announcementId = announcementRef.key!;
      String imageUrl = '';
      if (imageFile != null && announcement.type == 'image') {
        imageUrl = await _uploadImage(announcementId, imageFile);
      }
      final announcementData = announcement.copyWith(
        id: announcementId,
        imageUrl: imageUrl,
      );
      await announcementRef.set(announcementData.toJson());
      return announcementId;
    } catch (e) {
      debugPrint('❌ Error creating announcement: $e');
      throw Exception('Failed to create announcement: $e');
    }
  }

  // ✅ NEW: This is the missing method to update an announcement.
  Future<void> updateAnnouncement(
      Announcement announcement, File? newImage) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }
    try {
      String imageUrl = announcement.imageUrl;
      if (newImage != null) {
        if (announcement.imageUrl.isNotEmpty) {
          try {
            await _storage!.refFromURL(announcement.imageUrl).delete();
          } catch (e) {
            debugPrint('Could not delete old image, may not exist: $e');
          }
        }
        final ref = _storage!.ref('announcements/${announcement.id}');
        await ref.putFile(newImage);
        imageUrl = await ref.getDownloadURL();
      }

      final announcementData = {
        'title': announcement.title,
        'content': announcement.content,
        'type': announcement.type,
        'imageUrl': imageUrl,
        'isActive': announcement.isActive,
        'priority': announcement.priority,
        'expiresAt': announcement.expiresAt?.toIso8601String(),
        'textColor': announcement.textColor,
        'backgroundColor': announcement.backgroundColor,
        'backgroundGradient': announcement.backgroundGradient,
        'textStyle': announcement.textStyle,
        'fontSize': announcement.fontSize,
        'selectedIcon': announcement.selectedIcon,
        'iconColor': announcement.iconColor,
      };
      announcementData.removeWhere((key, value) => value == null);
      await _announcementsRef.child(announcement.id).update(announcementData);
    } catch (e) {
      debugPrint('❌ Error updating announcement: $e');
      rethrow;
    }
  }

  Future<String> _uploadImage(String announcementId, File imageFile) async {
    if (_storage == null) {
      throw Exception('Firebase Storage not initialized');
    }
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'announcement_${announcementId}_$timestamp.jpg';
      final storageRef = _storage!.ref().child('announcements').child(fileName);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'announcementId': announcementId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> toggleAnnouncementStatus(
      String announcementId, bool isActive) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }
    try {
      await _announcementsRef.child(announcementId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('❌ Error updating announcement status: $e');
      throw Exception('Failed to update announcement status: $e');
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }
    try {
      final snapshot = await _announcementsRef.child(announcementId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final imageUrl = data['imageUrl']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _deleteImageFromUrl(imageUrl);
        }
      }
      await _announcementsRef.child(announcementId).remove();
    } catch (e) {
      debugPrint('❌ Error deleting announcement: $e');
      throw Exception('Failed to delete announcement: $e');
    }
  }

  Future<void> _deleteImageFromUrl(String downloadUrl) async {
    if (_storage == null) return;
    try {
      final storageRef = _storage!.refFromURL(downloadUrl);
      await storageRef.delete();
    } catch (e) {
      debugPrint('⚠️ Error deleting image from storage: $e');
    }
  }

  Future<void> updateAnnouncementPriority(
      String announcementId, int priority) async {
    if (!_isFirebaseInitialized) {
      throw Exception('Firebase not initialized');
    }
    try {
      await _announcementsRef.child(announcementId).update({
        'priority': priority,
      });
    } catch (e) {
      debugPrint('❌ Error updating announcement priority: $e');
      throw Exception('Failed to update announcement priority: $e');
    }
  }

  Future<Announcement?> getAnnouncementById(String announcementId) async {
    if (!_isFirebaseInitialized) {
      return null;
    }
    try {
      final snapshot = await _announcementsRef.child(announcementId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final announcement = Announcement.fromJson(data, announcementId);
        return announcement;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching announcement by ID: $e');
      return null;
    }
  }

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
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
      return 0;
    }
  }

  Future<bool> testConnection() async {
    if (!_isFirebaseInitialized) {
      return false;
    }
    try {
      final ref = _database!.ref('.info/connected');
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));
      final isConnected = snapshot.value as bool? ?? false;
      return isConnected;
    } catch (e) {
      debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }
}
