import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_models.dart';

class HighlightLocalStorage {
  static const String _key = 'bible_highlights';

  Future<List<BibleHighlight>> getHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null || jsonString.isEmpty) return [];
      
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((data) => BibleHighlight.fromMap(data)).toList();
    } catch (e) {
      print('Error getting highlights: $e');
      return [];
    }
  }

  Future<void> addHighlight(BibleHighlight highlight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final highlights = await getHighlights();
      
      // Check for existing highlight and replace
      final existingIndex = highlights.indexWhere((h) => h.id == highlight.id);
      
      if (existingIndex >= 0) {
        highlights[existingIndex] = highlight;
      } else {
        highlights.add(highlight);
      }
      
      final List<Map<String, dynamic>> data = highlights.map((h) => h.toMap()).toList();
      await prefs.setString(_key, json.encode(data));
      print('Highlight saved locally: ${highlight.id}');
    } catch (e) {
      print('Error adding highlight: $e');
      rethrow;
    }
  }

  Future<void> removeHighlight(String highlightId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final highlights = await getHighlights();
      
      highlights.removeWhere((h) => h.id == highlightId);
      
      final List<Map<String, dynamic>> data = highlights.map((h) => h.toMap()).toList();
      await prefs.setString(_key, json.encode(data));
    } catch (e) {
      print('Error removing highlight: $e');
      rethrow;
    }
  }

  Future<List<BibleHighlight>> getHighlightsForChapter(String bookId, int chapterNumber) async {
    final highlights = await getHighlights();
    return highlights.where((h) => 
      h.bookId == bookId && h.chapterNumber == chapterNumber
    ).toList();
  }

  Future<void> clearHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<int> getHighlightCount() async {
    final highlights = await getHighlights();
    return highlights.length;
  }
}