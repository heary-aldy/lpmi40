// 🤖 AI Service for Bible Chat
// Integrates with AI providers (OpenAI, Gemini, etc.)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

class AIService {
  static const String _openAIApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // Get API keys from environment configuration
  static String get _openAIApiKey => EnvConfig.openAIApiKey;
  static String get _geminiApiKey => EnvConfig.geminiApiKey;
  
  /// Generate AI response using OpenAI GPT
  static Future<String> generateOpenAIResponse({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Check if API key is available
      if (_openAIApiKey.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        if (conversationHistory != null) ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse(_openAIApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      debugPrint('🔍 OpenAI API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        debugPrint('❌ OpenAI API Error Body: ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ OpenAI API error: $e');
      rethrow;
    }
  }

  /// Generate AI response using Google Gemini
  static Future<String> generateGeminiResponse({
    required String userMessage,
    required String systemPrompt,
  }) async {
    try {
      // Check if API key is available
      if (_geminiApiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      final prompt = '$systemPrompt\n\nUser: $userMessage\nAssistant:';
      
      final requestBody = jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        }
      });

      debugPrint('🔍 Gemini API Request: ${_geminiApiUrl}?key=${_geminiApiKey.substring(0, 8)}...');
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('🔍 Gemini API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      } else {
        debugPrint('❌ Gemini API Error Body: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      rethrow;
    }
  }

  /// Get system prompt for Bible chat
  static String getBibleChatSystemPrompt() {
    return '''
You are a knowledgeable and compassionate AI Bible study assistant. Your role is to:

1. Help users understand Biblical concepts and teachings
2. Provide relevant Bible verses and references
3. Offer spiritual guidance based on Christian principles
4. Answer questions about faith, theology, and Biblical history
5. Maintain a respectful, encouraging, and faith-building tone

Guidelines:
- Always base your responses on Biblical truth
- Be respectful of different Christian denominations
- Provide accurate Biblical references when possible
- Offer comfort and encouragement when appropriate
- Avoid controversial theological debates
- Use simple, accessible language
- Include relevant Bible verses to support your points

Respond in Bahasa Malaysia/Indonesian when the user writes in that language.
''';
  }
}