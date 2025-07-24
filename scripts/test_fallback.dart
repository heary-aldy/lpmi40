import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    print('🧪 Testing fallback JSON parsing...');

    // Read the JSON file
    final file = File('assets/data/lpmi.json');
    final jsonString = await file.readAsString();

    // Test parsing
    final dynamic jsonData = json.decode(jsonString);

    if (jsonData is Map) {
      final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonData);
      print('✅ Successfully parsed as object format');
      print('📊 Total songs: ${songMap.length}');

      // Test first few songs
      final firstKeys = songMap.keys.take(3).toList();
      for (final key in firstKeys) {
        final songData = songMap[key];
        if (songData is Map) {
          final song = Map<String, dynamic>.from(songData);
          print('🎵 Song $key: ${song['song_title']} (${song['song_number']})');
          print(
              '   🎵 Audio URL: ${song['url'] != null ? 'Available' : 'Missing'}');
          print('   📝 Verses: ${song['verses']?.length ?? 0}');
        }
      }

      print('\n✅ Fallback JSON structure is valid and ready for use!');
    } else {
      print('❌ Unexpected format: ${jsonData.runtimeType}');
    }
  } catch (e) {
    print('❌ Error testing fallback: $e');
  }
}
