import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkLocalStorage {
  static const String _key = 'bible_bookmarks';

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> addBookmark(Map<String, dynamic> bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    bookmarks.add(bookmark);
    await prefs.setString(_key, json.encode(bookmarks));
  }

  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
