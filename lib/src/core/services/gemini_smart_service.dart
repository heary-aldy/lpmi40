// 🎯 Gemini-Only Smart AI Service
// Uses Gemini free tier with intelligent quota management

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_token_manager.dart';
import 'global_ai_token_service.dart';
import '../config/production_config.dart';

class GeminiSmartService {
  static const String _geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // Production quota limits (configurable via Firebase)
  static int get _dailyRequestLimit => ProductionConfig.globalQuotaLimits['daily_requests'] ?? 1000;
  static int get _dailyTokenLimit => ProductionConfig.globalQuotaLimits['daily_tokens'] ?? 800000;
  static int get _requestsPerMinute => ProductionConfig.globalQuotaLimits['requests_per_minute'] ?? 10;
  
  static const String _usageKey = 'gemini_daily_usage';
  static const String _lastResetKey = 'gemini_last_reset';

  /// Generate AI response with smart quota management
  static Future<GeminiResponse> generateResponse({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    
    // Check if user has personal Gemini token
    final hasPersonalToken = await _hasPersonalGeminiToken();
    
    if (hasPersonalToken) {
      // Use personal token - unlimited usage
      return await _generateWithPersonalToken(
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );
    }
    
    // Use global token with quota management
    return await _generateWithGlobalQuota(
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
    );
  }

  /// Check if user has personal Gemini token
  static Future<bool> _hasPersonalGeminiToken() async {
    final token = await AITokenManager.getToken('gemini');
    return token != null && token.isNotEmpty;
  }

  /// Generate with personal token (unlimited)
  static Future<GeminiResponse> _generateWithPersonalToken({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final token = await AITokenManager.getToken('gemini');
      if (token == null || token.isEmpty) {
        throw Exception('Personal Gemini token not found');
      }

      final response = await _callGeminiAPI(
        token: token,
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );

      return GeminiResponse(
        content: response.content,
        tokensUsed: response.tokensUsed,
        isPersonalToken: true,
        quotaStatus: QuotaStatus.unlimited,
        remainingRequests: -1, // Unlimited
        remainingTokens: -1,   // Unlimited
      );
    } catch (e) {
      debugPrint('❌ Personal Gemini token failed: $e');
      // Fallback to global quota
      return await _generateWithGlobalQuota(
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );
    }
  }

  /// Generate with global token and quota limits
  static Future<GeminiResponse> _generateWithGlobalQuota({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    
    // Reset daily usage if needed
    await _resetDailyUsageIfNeeded();
    
    // Check current usage
    final usage = await _getCurrentUsage();
    final requestsUsed = usage['requests'] as int;
    final tokensUsed = usage['tokens'] as int;
    
    // Check if quota exceeded
    if (requestsUsed >= _dailyRequestLimit) {
      throw GeminiQuotaExceededException(
        'Daily request limit exceeded',
        QuotaType.requests,
      );
    }
    
    if (tokensUsed >= _dailyTokenLimit) {
      throw GeminiQuotaExceededException(
        'Daily token limit exceeded', 
        QuotaType.tokens,
      );
    }
    
    // Get global token (production-ready)
    final token = await _getProductionToken();
    if (token == null) {
      throw Exception('Global Gemini token not configured - add via admin panel');
    }

    try {
      // Make API call
      final response = await _callGeminiAPI(
        token: token,
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );

      // Update usage tracking
      await _updateUsage(1, response.tokensUsed);
      
      // Calculate remaining quota
      final newUsage = await _getCurrentUsage();
      final remainingRequests = _dailyRequestLimit - (newUsage['requests'] as int);
      final remainingTokens = _dailyTokenLimit - (newUsage['tokens'] as int);
      
      // Determine quota status
      QuotaStatus status = QuotaStatus.available;
      if (remainingRequests <= 5 || remainingTokens <= 10000) {
        status = QuotaStatus.nearLimit;
      }
      
      return GeminiResponse(
        content: response.content,
        tokensUsed: response.tokensUsed,
        isPersonalToken: false,
        quotaStatus: status,
        remainingRequests: remainingRequests,
        remainingTokens: remainingTokens,
      );
      
    } catch (e) {
      debugPrint('❌ Gemini API call failed: $e');
      rethrow;
    }
  }

  /// Call Gemini API
  static Future<_GeminiAPIResponse> _callGeminiAPI({
    required String token,
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    
    // Build conversation context
    String fullPrompt = systemPrompt;
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      fullPrompt += '\n\nConversation History:\n';
      for (final msg in conversationHistory.take(10)) { // Limit history
        fullPrompt += '${msg['role']}: ${msg['content']}\n';
      }
    }
    fullPrompt += '\n\nUser: $userMessage\n\nAssistant:';

    final response = await http.post(
      Uri.parse('$_geminiApiUrl?key=$token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': fullPrompt}]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
          'topP': 0.8,
          'topK': 10,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH', 
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ],
      }),
    );

    debugPrint('🔍 Gemini API Response: ${response.statusCode}');

    if (response.statusCode != 200) {
      final errorBody = response.body;
      debugPrint('❌ Gemini API Error: $errorBody');
      
      // Check for quota exceeded error
      if (errorBody.contains('quota') || errorBody.contains('limit')) {
        throw GeminiQuotaExceededException(
          'Gemini API quota exceeded',
          QuotaType.api,
        );
      }
      
      throw Exception('Gemini API error: ${response.statusCode} - $errorBody');
    }

    final data = jsonDecode(response.body);
    
    // Validate response structure
    if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
      throw Exception('Gemini API returned empty candidates');
    }

    final candidate = data['candidates'][0];
    if (candidate['content'] == null || 
        candidate['content']['parts'] == null ||
        (candidate['content']['parts'] as List).isEmpty) {
      throw Exception('Gemini API returned invalid content structure');
    }

    final content = candidate['content']['parts'][0]['text']?.toString().trim() ?? '';
    
    // Estimate token usage (Gemini doesn't provide exact counts)
    final estimatedTokens = _estimateTokens(fullPrompt + content);
    
    return _GeminiAPIResponse(
      content: content,
      tokensUsed: estimatedTokens,
    );
  }

  /// Reset daily usage if it's a new day
  static Future<void> _resetDailyUsageIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    if (lastReset != today) {
      // New day - reset usage
      await prefs.setString(_usageKey, jsonEncode({'requests': 0, 'tokens': 0}));
      await prefs.setString(_lastResetKey, today);
      debugPrint('✅ Gemini daily usage reset for $today');
    }
  }

  /// Get current daily usage
  static Future<Map<String, int>> _getCurrentUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString(_usageKey);
    
    if (usageJson == null) {
      return {'requests': 0, 'tokens': 0};
    }
    
    try {
      final usage = jsonDecode(usageJson) as Map<String, dynamic>;
      return {
        'requests': usage['requests'] as int? ?? 0,
        'tokens': usage['tokens'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error parsing usage data: $e');
      return {'requests': 0, 'tokens': 0};
    }
  }

  /// Update usage tracking
  static Future<void> _updateUsage(int requests, int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsage = await _getCurrentUsage();
    
    final newUsage = {
      'requests': currentUsage['requests']! + requests,
      'tokens': currentUsage['tokens']! + tokens,
    };
    
    await prefs.setString(_usageKey, jsonEncode(newUsage));
    debugPrint('📊 Updated Gemini usage: ${newUsage['requests']} requests, ${newUsage['tokens']} tokens');
  }

  /// Get quota info for UI display
  static Future<GeminiQuotaInfo> getQuotaInfo() async {
    await _resetDailyUsageIfNeeded();
    final usage = await _getCurrentUsage();
    final hasPersonalToken = await _hasPersonalGeminiToken();
    
    return GeminiQuotaInfo(
      requestsUsed: usage['requests']!,
      requestsLimit: _dailyRequestLimit,
      tokensUsed: usage['tokens']!,
      tokensLimit: _dailyTokenLimit,
      hasPersonalToken: hasPersonalToken,
    );
  }

  /// Get production token with fallback support
  static Future<String?> _getProductionToken() async {
    // First try: Production config (runtime configurable)
    final productionToken = ProductionConfig.getGlobalToken('gemini');
    if (productionToken != null && productionToken.isNotEmpty) {
      return productionToken;
    }
    
    // Fallback: Old global service for backward compatibility
    try {
      final fallbackToken = await GlobalAITokenService.getGlobalToken('gemini');
      if (fallbackToken != null && fallbackToken.isNotEmpty) {
        debugPrint('⚠️ Using fallback token - consider migrating to production config');
        return fallbackToken;
      }
    } catch (e) {
      debugPrint('❌ Fallback token service failed: $e');
    }
    
    return null;
  }

  /// Estimate token count (rough approximation)
  static int _estimateTokens(String text) {
    // Rough estimate: 1 token ≈ 4 characters for English text
    return (text.length / 4).ceil();
  }

  /// Get simple status message when quota exceeded
  static String getQuotaExceededMessage(QuotaType quotaType) {
    switch (quotaType) {
      case QuotaType.requests:
        return 'Daily request limit reached (1000 requests). Quota resets tomorrow.';
      case QuotaType.tokens:
        return 'Daily token limit reached (800K tokens). Quota resets tomorrow.';
      case QuotaType.api:
        return 'Gemini API quota exceeded. Please try again later.';
    }
  }
}

// Data classes
class GeminiResponse {
  final String content;
  final int tokensUsed;
  final bool isPersonalToken;
  final QuotaStatus quotaStatus;
  final int remainingRequests;
  final int remainingTokens;

  GeminiResponse({
    required this.content,
    required this.tokensUsed,
    required this.isPersonalToken,
    required this.quotaStatus,
    required this.remainingRequests,
    required this.remainingTokens,
  });
}

class GeminiQuotaInfo {
  final int requestsUsed;
  final int requestsLimit;
  final int tokensUsed;
  final int tokensLimit;
  final bool hasPersonalToken;

  GeminiQuotaInfo({
    required this.requestsUsed,
    required this.requestsLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.hasPersonalToken,
  });

  double get requestsPercentage => 
      requestsLimit > 0 ? (requestsUsed / requestsLimit * 100) : 0;
  
  double get tokensPercentage => 
      tokensLimit > 0 ? (tokensUsed / tokensLimit * 100) : 0;
  
  int get remainingRequests => requestsLimit - requestsUsed;
  int get remainingTokens => tokensLimit - tokensUsed;
  
  bool get isNearLimit => requestsPercentage >= 80 || tokensPercentage >= 80;
  bool get isExceeded => requestsUsed >= requestsLimit || tokensUsed >= tokensLimit;
}

class _GeminiAPIResponse {
  final String content;
  final int tokensUsed;

  _GeminiAPIResponse({required this.content, required this.tokensUsed});
}

enum QuotaStatus { available, nearLimit, unlimited }
enum QuotaType { requests, tokens, api }

class GeminiQuotaExceededException implements Exception {
  final String message;
  final QuotaType quotaType;

  GeminiQuotaExceededException(this.message, this.quotaType);

  @override
  String toString() => message;
}

