// Firebase Update Script for Song 029 Google Drive URL
// Run this script to update the Firebase database with the converted URL

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/firebase_options.dart';

void main() async {
  print('🔧 Firebase Song URL Update Script');
  print('=====================================');
  
  try {
    // Initialize Firebase
    print('🔄 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    final database = FirebaseDatabase.instance;
    
    // Song details
    const songNumber = '029';
    const songTitle = 'Teguhlah Alasan';
    const collectionId = 'LPMI';
    const originalUrl = 'https://drive.google.com/file/d/1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs/view?usp=drivesdk';
    const convertedUrl = 'https://drive.google.com/uc?export=download&id=1zvKVRnVO24XHTpywvOsTERAY4cQNDVBs';
    
    print('');
    print('📋 Update Details:');
    print('   Song: #$songNumber "$songTitle"');
    print('   Collection: $collectionId');
    print('   From: $originalUrl');
    print('   To: $convertedUrl');
    print('');

    // Path to the song in Firebase
    final songPath = 'song_collection/$collectionId/songs/$songNumber';
    
    print('🔍 Checking current song data...');
    final songRef = database.ref(songPath);
    final currentSnapshot = await songRef.get();
    
    if (!currentSnapshot.exists) {
      print('❌ Song not found in Firebase at path: $songPath');
      print('🔍 Checking alternative paths...');
      
      // Try alternative paths
      final altPaths = [
        'song_collection/LPMI/songs/029',
        'LPMI/029',
        'songs/029'
      ];
      
      bool found = false;
      for (final altPath in altPaths) {
        final altRef = database.ref(altPath);
        final altSnapshot = await altRef.get();
        if (altSnapshot.exists) {
          print('✅ Found song at: $altPath');
          found = true;
          break;
        }
      }
      
      if (!found) {
        print('❌ Song not found in any expected Firebase location');
        print('💡 Please check your Firebase structure manually');
        return;
      }
    }
    
    final currentData = currentSnapshot.value as Map<dynamic, dynamic>?;
    if (currentData != null) {
      final currentUrl = currentData['url'];
      print('✅ Current URL in Firebase: $currentUrl');
      
      if (currentUrl == convertedUrl) {
        print('ℹ️  URL is already converted in Firebase - no update needed!');
        return;
      }
    }
    
    print('');
    print('🔄 Updating Firebase database...');
    
    // Update only the URL field
    await songRef.child('url').set(convertedUrl);
    
    print('✅ Firebase update completed successfully!');
    
    // Verify the update
    print('🔍 Verifying update...');
    final verifySnapshot = await songRef.get();
    if (verifySnapshot.exists) {
      final updatedData = verifySnapshot.value as Map<dynamic, dynamic>;
      final updatedUrl = updatedData['url'];
      
      if (updatedUrl == convertedUrl) {
        print('✅ Verification successful - URL updated in Firebase');
        print('🎉 Song #029 Google Drive URL conversion complete!');
      } else {
        print('❌ Verification failed - URL not updated properly');
        print('   Expected: $convertedUrl');
        print('   Found: $updatedUrl');
      }
    } else {
      print('❌ Verification failed - song not found after update');
    }
    
    print('');
    print('📱 Next Steps:');
    print('   1. Restart your app to see the changes');
    print('   2. Test audio playback for song #029');
    print('   3. Verify the converted URL works properly');
    
  } catch (e) {
    print('❌ Error updating Firebase: $e');
    print('💡 Make sure you have proper Firebase permissions');
  }
  
  print('');
  print('Script completed. Press any key to exit...');
  stdin.readLineSync();
}
