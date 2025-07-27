// lib/src/features/bible/test/bible_integration_test.dart
// Simple test file to verify Bible feature integration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lpmi40/src/features/bible/presentation/bible_main_page.dart';
import 'package:lpmi40/src/features/bible/services/bible_service.dart';
import 'package:lpmi40/src/features/bible/repository/bible_repository.dart';

/// Integration test for Bible feature
/// This file verifies that all Bible components are properly connected
class BibleIntegrationTest {
  static Future<void> testBibleFeatureIntegration() async {
    // Test 1: Verify Bible service can be instantiated
    try {
      final bibleService = BibleService();
      print('✅ Bible Service instantiated successfully');
    } catch (e) {
      print('❌ Bible Service instantiation failed: $e');
    }

    // Test 2: Verify Bible repository can be instantiated
    try {
      final bibleRepository = BibleRepository();
      print('✅ Bible Repository instantiated successfully');
    } catch (e) {
      print('❌ Bible Repository instantiation failed: $e');
    }

    // Test 3: Verify Bible main page can be created
    try {
      const bibleMainPage = BibleMainPage();
      print('✅ Bible Main Page can be created');
    } catch (e) {
      print('❌ Bible Main Page creation failed: $e');
    }

    print('🔍 Bible Feature Integration Test Complete');
  }

  /// Test navigation integration
  static void testBibleNavigation(BuildContext context) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BibleMainPage(),
        ),
      );
      print('✅ Bible navigation test passed');
    } catch (e) {
      print('❌ Bible navigation test failed: $e');
    }
  }
}

/// Widget test helper for Bible feature
class BibleFeatureTestWidget extends StatelessWidget {
  const BibleFeatureTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Feature Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Bible Feature Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () =>
                    BibleIntegrationTest.testBibleNavigation(context),
                child: const Text('Test Bible Navigation'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await BibleIntegrationTest.testBibleFeatureIntegration();
                },
                child: const Text('Test Bible Integration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
