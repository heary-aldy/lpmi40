import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkLocalStorage {
  static const String _key = 'bible_bookmarks';

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  Future<void> addBookmark(Map<String, dynamic> bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = await getBookmarks();
      
      // Check for duplicates based on reference
      final existingIndex = bookmarks.indexWhere((b) => 
        b['reference'] == bookmark['reference']);
      
      if (existingIndex >= 0) {
        // Update existing bookmark
        bookmarks[existingIndex] = bookmark;
      } else {
        // Add new bookmark
        bookmarks.add(bookmark);
      }
      
      await prefs.setString(_key, json.encode(bookmarks));
      print('Bookmark saved: ${bookmark['reference']}');
    } catch (e) {
      print('Error adding bookmark: $e');
      rethrow;
    }
  }

  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Check if any bookmarks exist
  Future<bool> hasBookmarks() async {
    final bookmarks = await getBookmarks();
    return bookmarks.isNotEmpty;
  }

  /// Get bookmark count
  Future<int> getBookmarkCount() async {
    final bookmarks = await getBookmarks();
    return bookmarks.length;
  }

  /// Remove specific bookmark by index
  Future<void> removeBookmarkAt(int index) async {
    try {
      final bookmarks = await getBookmarks();
      if (index >= 0 && index < bookmarks.length) {
        bookmarks.removeAt(index);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, json.encode(bookmarks));
      }
    } catch (e) {
      print('Error removing bookmark: $e');
      rethrow;
    }
  }
}
