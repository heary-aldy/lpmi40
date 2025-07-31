// 🤖 AI Service for Bible Chat
// Integrates with AI providers (OpenAI, Gemini, etc.)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

class AIService {
  static const String _openAIApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const String _githubModelsUrl = 'https://models.inference.ai.azure.com';
  
  // Get API keys from environment configuration (with global token support)
  static Future<String> get _openAIApiKey => EnvConfig.getOpenAIApiKey();
  static Future<String> get _geminiApiKey => EnvConfig.getGeminiApiKey();
  static Future<String> get _githubToken => EnvConfig.getGithubToken();
  
  /// Generate AI response using OpenAI GPT
  static Future<String> generateOpenAIResponse({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Get API key (supports global tokens)
      final apiKey = await _openAIApiKey;
      if (apiKey.isEmpty) {
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
          'Authorization': 'Bearer $apiKey',
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
        
        // Validate response structure
        if (data['choices'] == null || (data['choices'] as List).isEmpty) {
          throw Exception('OpenAI API returned empty choices array');
        }
        
        final choice = data['choices'][0];
        if (choice['message'] == null || choice['message']['content'] == null) {
          throw Exception('OpenAI API returned invalid message structure');
        }
        
        return choice['message']['content'].toString().trim();
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
      // Get API key (supports global tokens)
      final apiKey = await _geminiApiKey;
      if (apiKey.isEmpty) {
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

      debugPrint('🔍 Gemini API Request: ${_geminiApiUrl}?key=${apiKey.substring(0, 8)}...');
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('🔍 Gemini API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate response structure
        if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
          throw Exception('Gemini API returned empty candidates array');
        }
        
        final candidate = data['candidates'][0];
        if (candidate['content'] == null || 
            candidate['content']['parts'] == null ||
            (candidate['content']['parts'] as List).isEmpty) {
          throw Exception('Gemini API returned invalid content structure');
        }
        
        final part = candidate['content']['parts'][0];
        if (part['text'] == null) {
          throw Exception('Gemini API returned no text content');
        }
        
        return part['text'].toString().trim();
      } else {
        debugPrint('❌ Gemini API Error Body: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      rethrow;
    }
  }

  /// Generate AI response using GitHub Models
  static Future<String> generateGitHubModelsResponse({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
    String model = 'DeepSeek-R1', // Available: DeepSeek-R1, gpt-4o-mini, o1-mini, Meta-Llama-3.1-70B-Instruct, etc.
  }) async {
    try {
      // Get GitHub token (supports global tokens)
      final token = await _githubToken;
      if (token.isEmpty) {
        throw Exception('GitHub token not configured');
      }

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        if (conversationHistory != null) ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http.post(
        Uri.parse('$_githubModelsUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      debugPrint('🔍 GitHub Models API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🔍 GitHub Models Response Data: ${data.toString().substring(0, 200)}...');
        
        // Validate response structure
        if (data['choices'] == null || (data['choices'] as List).isEmpty) {
          throw Exception('GitHub Models API returned empty choices array');
        }
        
        final choicesLength = (data['choices'] as List).length;
        debugPrint('🔍 GitHub Models Choices Length: $choicesLength');
        
        final choice = data['choices'][0];
        if (choice['message'] == null || choice['message']['content'] == null) {
          throw Exception('GitHub Models API returned invalid message structure');
        }
        
        final content = choice['message']['content'].toString().trim();
        debugPrint('🔍 GitHub Models Content Length: ${content.length}');
        return content;
      } else {
        debugPrint('❌ GitHub Models API Error Body: ${response.body}');
        throw Exception('GitHub Models API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ GitHub Models API error: $e');
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