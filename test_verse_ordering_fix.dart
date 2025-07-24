#!/usr/bin/env dart

// Test script to verify verse ordering fixes
import 'lib/src/features/songbook/models/song_model.dart';

void main() {
  print('=== Testing Verse Ordering Fix ===\n');

  // Test 1: Create song with verses in wrong order (as would happen in UI)
  print('🧪 Test 1: Creating song with verses in different order');
  final versesInWrongOrder = [
    Verse(number: '1', lyrics: 'First verse lyrics', order: 0),
    Verse(number: 'Korus', lyrics: 'Chorus lyrics', order: 2),
    Verse(number: '2', lyrics: 'Second verse lyrics', order: 1),
    Verse(number: '3', lyrics: 'Third verse lyrics', order: 3),
  ];

  final song1 = Song(
    number: '123',
    title: 'Test Song',
    verses: versesInWrongOrder,
  );

  print('📝 Original order (in constructor):');
  for (int i = 0; i < versesInWrongOrder.length; i++) {
    print(
        '   $i: ${versesInWrongOrder[i].number} (order: ${versesInWrongOrder[i].order})');
  }

  print('\n✅ After Song constructor (should be sorted):');
  for (int i = 0; i < song1.verses.length; i++) {
    print('   $i: ${song1.verses[i].number} (order: ${song1.verses[i].order})');
  }

  print('\n🔄 Using sortedVerses getter:');
  for (int i = 0; i < song1.sortedVerses.length; i++) {
    print(
        '   $i: ${song1.sortedVerses[i].number} (order: ${song1.sortedVerses[i].order})');
  }

  // Test 2: Simulate JSON deserialization (as would happen loading from Firebase)
  print('\n\n🧪 Test 2: JSON serialization/deserialization');
  final jsonData = song1.toJson();
  print('📤 Serialized to JSON:');
  print('   verses: ${jsonData['verses']}');

  final song2 = Song.fromJson(jsonData);
  print('\n📥 Deserialized from JSON (should maintain order):');
  for (int i = 0; i < song2.verses.length; i++) {
    print('   $i: ${song2.verses[i].number} (order: ${song2.verses[i].order})');
  }

  // Test 3: Simulate drag-and-drop reordering (as would happen in add/edit page)
  print('\n\n🧪 Test 3: Simulate drag-and-drop reordering');
  final reorderedVerses = [
    Verse(number: 'Korus', lyrics: 'Chorus lyrics', order: 0), // Moved to start
    Verse(number: '1', lyrics: 'First verse lyrics', order: 1),
    Verse(number: '2', lyrics: 'Second verse lyrics', order: 2),
    Verse(number: '3', lyrics: 'Third verse lyrics', order: 3),
  ];

  final song3 = Song(
    number: '123',
    title: 'Test Song Reordered',
    verses: reorderedVerses,
  );

  print('📝 User reordered to (Korus first):');
  for (int i = 0; i < song3.verses.length; i++) {
    print('   $i: ${song3.verses[i].number} (order: ${song3.verses[i].order})');
  }

  // Test 4: Legacy verse without order field
  print('\n\n🧪 Test 4: Legacy compatibility (verses without order)');
  final legacyJson = {
    'song_number': '456',
    'song_title': 'Legacy Song',
    'verses': [
      {'verse_number': '1', 'lyrics': 'First verse'},
      {'verse_number': 'Korus', 'lyrics': 'Chorus'},
      {'verse_number': '2', 'lyrics': 'Second verse'},
    ]
  };

  final legacySong = Song.fromJson(legacyJson);
  print('📥 Legacy song loaded (should auto-assign order):');
  for (int i = 0; i < legacySong.verses.length; i++) {
    print(
        '   $i: ${legacySong.verses[i].number} (order: ${legacySong.verses[i].order})');
  }

  print('\n=== All Tests Completed ===');
  print(
      '✅ If verses are consistently ordered by their "order" field, the fix is working!');
}
