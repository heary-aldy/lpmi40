// Test script for the new robust caching system
// Run with: dart test_caching_system.dart

import 'package:lpmi40/src/features/songbook/services/collection_cache_manager.dart';

void main() async {
  print('🚀 Testing Enhanced Collection Caching System');
  print('===============================================');

  try {
    final cacheManager = CollectionCacheManager.instance;

    // Test 1: Get cache statistics
    print('\n📊 Cache Statistics:');
    final stats = await cacheManager.getCacheStats();
    stats.forEach((key, value) {
      print('  $key: $value');
    });

    // Test 2: Get available collections (should work offline)
    print('\n📋 Available Collections:');
    final collections = await cacheManager.getAvailableCollections();
    print('  Found ${collections.length} collections: $collections');

    // Test 3: Test single collection retrieval
    if (collections.isNotEmpty) {
      final firstCollection = collections.first;
      print('\n🎵 Testing collection: $firstCollection');

      final songs = await cacheManager.getCollection(firstCollection);
      print('  Songs loaded: ${songs.length}');

      if (songs.isNotEmpty) {
        final firstSong = songs.first;
        print('  First song: "${firstSong.title}" (#${firstSong.number})');
      }
    }

    // Test 4: Test Christmas collection with retry
    print('\n🎄 Testing Christmas Collection with Retry:');
    try {
      final christmasSongs =
          await cacheManager.getCollectionWithRetry('lagu_krismas_26346');
      print('  Christmas songs loaded: ${christmasSongs.length}');
    } catch (e) {
      print('  Christmas collection test failed: $e');
    }

    // Test 5: Clear cache test
    print('\n🧹 Testing Cache Clear:');
    await cacheManager.clearCache();
    print('  Cache cleared successfully');

    final statsAfterClear = await cacheManager.getCacheStats();
    print(
        '  Cached collections after clear: ${statsAfterClear['cached_collections']}');

    print('\n✅ All caching system tests completed successfully!');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
