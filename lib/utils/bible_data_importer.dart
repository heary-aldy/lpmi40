// 📖 Bible Data Import Helper
// Script to set up basic Bible structure in Firebase Realtime Database

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Sample Bible data importer
class BibleDataImporter {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Initialize Firebase and set up basic Bible structure
  static Future<void> setupBibleStructure() async {
    try {
      print('🔥 Setting up Bible structure in Firebase...');

      // Create Bible collections
      await _setupCollections();

      // Set up user data structure examples
      await _setupUserDataExamples();

      print('✅ Bible structure setup completed!');
    } catch (e) {
      print('❌ Error setting up Bible structure: $e');
    }
  }

  /// Create Bible collection metadata
  static Future<void> _setupCollections() async {
    final collectionsRef = _database.ref('bible/collections');

    // Indonesian Terjemahan Baru
    await collectionsRef.child('indo_tm').set({
      'name': 'Alkitab Terjemahan Baru',
      'language': 'indonesian',
      'translation': 'Terjemahan Baru',
      'description': 'Alkitab Bahasa Indonesia - Terjemahan Baru',
      'isPremium': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Indonesian Terjemahan Lama
    await collectionsRef.child('indo_tb').set({
      'name': 'Alkitab Terjemahan Lama',
      'language': 'indonesian',
      'translation': 'Terjemahan Lama',
      'description': 'Alkitab Bahasa Indonesia - Terjemahan Lama',
      'isPremium': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    print('✅ Bible collections created');
  }

  /// Set up user data examples (for testing)
  static Future<void> _setupUserDataExamples() async {
    // Bible Chat Settings example structure
    final chatSettingsRef = _database.ref('bibleChat/settings');

    // AI Chat Conversations example structure
    final conversationsRef = _database.ref('bibleChat/conversations');

    print('✅ User data examples set up');
  }

  /// Create sample user with premium access for testing
  static Future<void> createSamplePremiumUser(String userId) async {
    try {
      final userRef = _database.ref('users/$userId');

      await userRef.set({
        'email': 'test@example.com',
        'displayName': 'Test User',
        'isPremium': true,
        'role': 'premium',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      // Set up Bible preferences
      final preferencesRef = _database.ref('bible/preferences/$userId');
      await preferencesRef.set({
        'userId': userId,
        'defaultCollection': 'indo_tm',
        'fontSize': 16,
        'theme': 'light',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Set up AI Chat settings
      final chatSettingsRef = _database.ref('bibleChat/settings/$userId');
      await chatSettingsRef.set({
        'language': 'indonesian',
        'responseStyle': 'balanced',
        'enableContextAwareness': true,
        'maxConversationLength': 50,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Sample premium user created: $userId');
    } catch (e) {
      print('❌ Error creating sample user: $e');
    }
  }

  /// Test Bible data loading from Firebase Storage
  static Future<void> testBibleDataLoading() async {
    try {
      print('🔍 Testing Bible data loading from Firebase Storage...');

      // This would test loading from your Firebase Storage URLs:
      // gs://lmpi-c5c5c.firebasestorage.app/bible/malay_indo/indo_tm.json
      // gs://lmpi-c5c5c.firebasestorage.app/bible/malay_indo/indo_tb.json

      print('📋 Bible JSON files should be available at:');
      print(
          '  - indo_tm.json: gs://lmpi-c5c5c.firebasestorage.app/bible/malay_indo/indo_tm.json');
      print(
          '  - indo_tb.json: gs://lmpi-c5c5c.firebasestorage.app/bible/malay_indo/indo_tb.json');

      print('✅ Bible data loading test completed');
    } catch (e) {
      print('❌ Error testing Bible data loading: $e');
    }
  }
}

/// Sample usage function
Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up basic Bible structure
  await BibleDataImporter.setupBibleStructure();

  // Create a sample premium user for testing
  // Replace with your actual user ID
  await BibleDataImporter.createSamplePremiumUser('YOUR_USER_ID_HERE');

  // Test Bible data loading
  await BibleDataImporter.testBibleDataLoading();
}
