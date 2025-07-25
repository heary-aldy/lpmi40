// Test to verify that songs load properly after the caching fix
// Run with: dart test_song_loading_fix.dart

import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

void main() async {
  print('🧪 Testing Song Loading Fix');
  print('===========================');
  
  try {
    final repository = SongRepository();
    
    print('\n📥 Loading collections...');
    final collections = await repository.getCollectionsSeparated();
    
    print('\n📊 Results:');
    print('Collections found: ${collections.keys.length}');
    
    for (final entry in collections.entries) {
      print('  ${entry.key}: ${entry.value.length} songs');
    }
    
    // Check if we have the expected collections
    final expectedCollections = ['All', 'LPMI', 'SRD', 'Lagu_belia'];
    final missingCollections = expectedCollections.where(
      (expected) => !collections.containsKey(expected)
    ).toList();
    
    if (missingCollections.isNotEmpty) {
      print('\n⚠️ Missing expected collections: $missingCollections');
    } else {
      print('\n✅ All expected collections found');
    }
    
    // Check if we have any songs at all
    final totalSongs = collections.values
        .fold(0, (sum, songList) => sum + songList.length);
    
    if (totalSongs == 0) {
      print('\n❌ CRITICAL: No songs found in any collection!');
      print('This indicates the loading fix may not be working properly.');
    } else {
      print('\n✅ SUCCESS: Found $totalSongs total songs across all collections');
      
      // Check LPMI specifically since that's the default
      final lpmiSongs = collections['LPMI']?.length ?? 0;
      final allSongs = collections['All']?.length ?? 0;
      
      print('\nDetailed analysis:');
      print('  All collection: $allSongs songs');
      print('  LPMI collection: $lpmiSongs songs');
      
      if (lpmiSongs > 0) {
        print('✅ LPMI collection has $lpmiSongs songs - UI should show songs now');
      } else if (allSongs > 0) {
        print('⚠️ LPMI collection is empty but All has $allSongs songs');
        print('💡 This suggests legacy songs are not being distributed to LPMI properly');
      } else {
        print('❌ Both LPMI and All collections are empty - this is a critical issue');
      }
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}