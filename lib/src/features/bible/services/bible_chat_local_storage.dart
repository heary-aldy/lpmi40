// 💬 Bible Chat Local Storage
// Local storage for Bible chat conversations when Firebase is unavailable

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_chat_models.dart';

class BibleChatLocalStorage {
  static const String _conversationsKey = 'bible_chat_conversations';
  static const String _settingsKey = 'bible_chat_settings';

  /// Get all conversations from local storage
  Future<List<BibleChatConversation>> getConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((data) => BibleChatConversation.fromMap(data)).toList();
    } catch (e) {
      print('Error getting conversations from local storage: $e');
      return [];
    }
  }

  /// Save conversation to local storage
  Future<void> saveConversation(BibleChatConversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getConversations();
      
      // Update existing or add new
      final existingIndex = conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex >= 0) {
        conversations[existingIndex] = conversation;
      } else {
        conversations.add(conversation);
      }
      
      // Sort by updated date (newest first)
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      final List<Map<String, dynamic>> data = 
          conversations.map((c) => c.toMap()).toList();
      await prefs.setString(_conversationsKey, json.encode(data));
      
      print('Conversation saved locally: ${conversation.id}');
    } catch (e) {
      print('Error saving conversation to local storage: $e');
      rethrow;
    }
  }

  /// Get specific conversation by ID
  Future<BibleChatConversation?> getConversation(String conversationId) async {
    final conversations = await getConversations();
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  /// Delete conversation from local storage
  Future<void> deleteConversation(String conversationId) async {
    try {
      final conversations = await getConversations();
      conversations.removeWhere((c) => c.id == conversationId);
      
      final List<Map<String, dynamic>> data = 
          conversations.map((c) => c.toMap()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_conversationsKey, json.encode(data));
    } catch (e) {
      print('Error deleting conversation from local storage: $e');
      rethrow;
    }
  }

  /// Save chat settings
  Future<void> saveSettings(BibleChatSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json.encode(settings.toMap()));
    } catch (e) {
      print('Error saving chat settings: $e');
      rethrow;
    }
  }

  /// Get chat settings
  Future<BibleChatSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return BibleChatSettings(); // Return default settings
      }
      
      final Map<String, dynamic> data = json.decode(jsonString);
      return BibleChatSettings.fromMap(data);
    } catch (e) {
      print('Error getting chat settings: $e');
      return BibleChatSettings(); // Return default settings
    }
  }

  /// Clear all local chat data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conversationsKey);
    await prefs.remove(_settingsKey);
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    final conversations = await getConversations();
    return conversations.length;
  }
}