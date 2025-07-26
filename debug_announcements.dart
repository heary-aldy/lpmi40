// Debug script to check announcement issues
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  print('🔧 Starting announcement debug...');

  try {
    // Initialize Firebase (you may need to adjust this)
    await Firebase.initializeApp();

    // Get announcements from Firebase
    final database = FirebaseDatabase.instance;
    final announcementsRef = database.ref('app_config/announcements');

    print('📡 Fetching announcements from Firebase...');
    final snapshot = await announcementsRef.get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      print('✅ Found ${data.length} announcements in Firebase');

      for (final entry in data.entries) {
        final announcementData = Map<String, dynamic>.from(entry.value as Map);
        final announcementId = entry.key;

        print('\n--- Announcement ID: $announcementId ---');
        print('Title: ${announcementData['title']}');
        print('Type: ${announcementData['type']}');
        print('IsActive: ${announcementData['isActive']}');
        print('ImageURL: ${announcementData['imageUrl'] ?? 'None'}');
        print('Priority: ${announcementData['priority']}');

        // Check if expires
        if (announcementData['expiresAt'] != null) {
          final expiresAt = DateTime.parse(announcementData['expiresAt']);
          final now = DateTime.now();
          final isExpired = now.isAfter(expiresAt);
          print('ExpiresAt: $expiresAt');
          print('IsExpired: $isExpired');
        } else {
          print('ExpiresAt: Never');
        }

        // Check validation
        final isActive = announcementData['isActive'] == true;
        final hasExpired = announcementData['expiresAt'] != null
            ? DateTime.now()
                .isAfter(DateTime.parse(announcementData['expiresAt']))
            : false;
        final isValid = isActive && !hasExpired;
        print('IsValid: $isValid');

        if (announcementData['type'] == 'image') {
          print('🖼️ This is an IMAGE announcement');
          if (announcementData['imageUrl'] == null ||
              announcementData['imageUrl'].toString().isEmpty) {
            print('❌ WARNING: Image announcement has no image URL!');
          } else {
            print('✅ Image URL exists: ${announcementData['imageUrl']}');
          }
        }
      }
    } else {
      print('❌ No announcements found in Firebase');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
