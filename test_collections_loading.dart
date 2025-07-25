// Diagnostic script to test song loading
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/presentation/controllers/main_page_controller.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  print('🔍 Testing song collection loading...');

  try {
    // Test 1: Check if asset file exists
    try {
      final assetData = await rootBundle.loadString('assets/data/lpmi.json');
      print('✅ Asset file found, size: ${assetData.length} characters');
    } catch (e) {
      print('❌ Asset file not found: $e');
      return;
    }

    // Test 2: Try song repository directly
    final repository = SongRepository();
    print('🔄 Testing SongRepository.getCollectionsSeparated()...');

    final collections = await repository.getCollectionsSeparated();
    print('✅ Collections loaded: ${collections.keys.toList()}');

    for (final entry in collections.entries) {
      print('📂 ${entry.key}: ${entry.value.length} songs');
    }

    // Test 3: Try main page controller
    print('🔄 Testing MainPageController...');
    final controller = MainPageController();
    await controller.initialize();

    print('✅ Controller initialized');
    print(
        '📊 Available collections: ${controller.availableCollections.length}');
    print('📊 Filtered songs: ${controller.filteredSongs.length}');
    print('📊 Error message: ${controller.errorMessage ?? "None"}');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
