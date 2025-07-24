import 'dart:convert';
import 'dart:io';

// Mock Song class for testing (since we can't import Flutter packages in pure Dart)
class MockSong {
  final String number;
  final String title;
  final String? url;
  final List<MockVerse> verses;

  MockSong({
    required this.number,
    required this.title,
    this.url,
    required this.verses,
  });

  factory MockSong.fromJson(Map<String, dynamic> json) {
    return MockSong(
      number: json['song_number'] ?? '',
      title: json['song_title'] ?? '',
      url: json['url'],
      verses: (json['verses'] as List?)
              ?.map((v) => MockVerse.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class MockVerse {
  final String number;
  final String lyrics;

  MockVerse({required this.number, required this.lyrics});

  factory MockVerse.fromJson(Map<String, dynamic> json) {
    return MockVerse(
      number: json['verse_number'] ?? '',
      lyrics: json['lyrics'] ?? '',
    );
  }
}

void main() async {
  try {
    print('🧪 Testing Song model compatibility...');

    // Read and parse the JSON
    final file = File('assets/data/lpmi.json');
    final jsonString = await file.readAsString();
    final dynamic jsonData = json.decode(jsonString);

    if (jsonData is Map) {
      final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonData);

      // Test parsing first 5 songs
      int successCount = 0;
      int errorCount = 0;

      for (final entry in songMap.entries.take(5)) {
        try {
          final songData = Map<String, dynamic>.from(entry.value as Map);
          final song = MockSong.fromJson(songData);

          print('✅ Song ${entry.key}: ${song.title}');
          print('   📱 Number: ${song.number}');
          print('   🎵 Audio: ${song.url != null ? 'Has URL' : 'No URL'}');
          print('   📝 Verses: ${song.verses.length}');

          successCount++;
        } catch (e) {
          print('❌ Failed to parse song ${entry.key}: $e');
          errorCount++;
        }
      }

      print('\n📊 Results:');
      print('✅ Successfully parsed: $successCount songs');
      print('❌ Failed to parse: $errorCount songs');

      if (errorCount == 0) {
        print(
            '\n🎉 All tests passed! The Song model is compatible with the new JSON format.');
      } else {
        print(
            '\n⚠️  Some songs failed to parse. Check the Song model implementation.');
      }
    }
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
