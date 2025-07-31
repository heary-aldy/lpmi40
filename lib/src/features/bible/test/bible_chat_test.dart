/// 🧪 Bible Chat Test
/// Simple test to verify Bible chat functionality
library;

import 'dart:io';
import '../services/bible_chat_service.dart';
import '../models/bible_chat_models.dart';

void main() async {
  print('🧪 Testing Bible Chat Service...');

  try {
    final chatService = BibleChatService();
    await chatService.initialize();
    print('✅ Bible Chat Service initialized');

    // Test AI availability
    final isAvailable = await chatService.isAIChatAvailable();
    print('AI Chat Available: $isAvailable');

    // Test conversation creation (mock)
    final context = BibleChatContext(
      collectionId: 'indo_tb',
      bookId: 'kejadian',
      chapter: 1,
      verses: [1, 2, 3],
    );

    print('Context: ${context.getContextDescription()}');
    print('✅ Bible Chat test completed successfully');
  } catch (e) {
    print('❌ Bible Chat test failed: $e');
    exit(1);
  }
}
