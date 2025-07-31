// 🧠 Smart AI Service with Intelligent Provider Selection
// Automatically selects best available provider based on quotas and limits

import 'package:flutter/material.dart';
import 'ai_service.dart';
import 'global_ai_token_service.dart';
import 'ai_token_manager.dart';
import 'ai_usage_tracker.dart';

class SmartAIService {
  static final AIUsageTracker _usageTracker = AIUsageTracker();
  
  // Daily limits for each provider's free tier
  static const Map<String, ProviderLimits> _providerLimits = {
    'gemini': ProviderLimits(
      dailyRequests: 1500,
      dailyTokens: 1000000,
      requestsPerMinute: 15,
      isFree: true,
    ),
    'github': ProviderLimits(
      dailyRequests: 100,
      dailyTokens: 50000,
      requestsPerMinute: 10,
      isFree: true, // For personal use
    ),
    'openai': ProviderLimits(
      dailyRequests: 200, // Depends on credit
      dailyTokens: 40000,
      requestsPerMinute: 3,
      isFree: false,
    ),
  };

  /// Generate AI response with intelligent provider selection
  static Future<AIResponse> generateSmartResponse({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
    String? preferredProvider,
  }) async {
    
    // Check if user has personal tokens
    final hasPersonalTokens = await _hasPersonalTokens();
    
    if (hasPersonalTokens) {
      // User has personal tokens - use their preferred provider
      return await _generateWithPersonalTokens(
        userMessage: userMessage,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
        preferredProvider: preferredProvider,
      );
    }
    
    // Use global tokens with intelligent selection
    return await _generateWithGlobalTokens(
      userMessage: userMessage,
      systemPrompt: systemPrompt,
      conversationHistory: conversationHistory,
    );
  }

  /// Check if user has configured personal tokens
  static Future<bool> _hasPersonalTokens() async {
    final statuses = await AITokenManager.getTokenStatuses();
    return statuses.values.any((status) => status.hasToken && !status.isExpired);
  }

  /// Generate response using user's personal tokens
  static Future<AIResponse> _generateWithPersonalTokens({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
    String? preferredProvider,
  }) async {
    
    final providers = preferredProvider != null 
        ? [preferredProvider, 'gemini', 'openai', 'github']
        : ['gemini', 'openai', 'github']; // Gemini first (most generous)
    
    for (final provider in providers) {
      try {
        final hasToken = await _hasValidToken(provider, isPersonal: true);
        if (!hasToken) continue;
        
        final response = await _callProvider(
          provider: provider,
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          conversationHistory: conversationHistory,
          isPersonal: true,
        );
        
        return AIResponse(
          content: response,
          provider: provider,
          isPersonalToken: true,
          quotaStatus: QuotaStatus.available,
        );
      } catch (e) {
        debugPrint('❌ Provider $provider failed: $e');
        continue;
      }
    }
    
    throw Exception('No available providers with personal tokens');
  }

  /// Generate response using global tokens with smart quotas
  static Future<AIResponse> _generateWithGlobalTokens({
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
  }) async {
    
    // Check quota status for each provider
    final quotaStatuses = await _checkAllProviderQuotas();
    
    // Priority: Gemini (free) > GitHub (free) > OpenAI (paid)
    final providers = ['gemini', 'github', 'openai'];
    
    for (final provider in providers) {
      final quotaStatus = quotaStatuses[provider] ?? QuotaStatus.exceeded;
      
      if (quotaStatus == QuotaStatus.exceeded) {
        debugPrint('⚠️ $provider quota exceeded, skipping');
        continue;
      }
      
      try {
        final hasToken = await _hasValidToken(provider, isPersonal: false);
        if (!hasToken) continue;
        
        final response = await _callProvider(
          provider: provider,
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          conversationHistory: conversationHistory,
          isPersonal: false,
        );
        
        return AIResponse(
          content: response,
          provider: provider,
          isPersonalToken: false,
          quotaStatus: quotaStatus,
        );
      } catch (e) {
        debugPrint('❌ Provider $provider failed: $e');
        continue;
      }
    }
    
    // All providers exhausted - show upgrade prompt
    throw QuotaExceededException();
  }

  /// Check quota status for all providers
  static Future<Map<String, QuotaStatus>> _checkAllProviderQuotas() async {
    final results = <String, QuotaStatus>{};
    
    for (final provider in _providerLimits.keys) {
      results[provider] = await _checkProviderQuota(provider);
    }
    
    return results;
  }

  /// Check quota status for a specific provider
  static Future<QuotaStatus> _checkProviderQuota(String provider) async {
    final limits = _providerLimits[provider];
    if (limits == null) return QuotaStatus.exceeded;
    
    final usage = await _usageTracker.getProviderUsage(provider);
    final dailyRequests = usage['dailyRequests'] as int? ?? 0;
    final dailyTokens = usage['dailyTokens'] as int? ?? 0;
    
    // Check if exceeded
    if (dailyRequests >= limits.dailyRequests || 
        dailyTokens >= limits.dailyTokens) {
      return QuotaStatus.exceeded;
    }
    
    // Check if near limit (80%)
    if (dailyRequests >= (limits.dailyRequests * 0.8) || 
        dailyTokens >= (limits.dailyTokens * 0.8)) {
      return QuotaStatus.nearLimit;
    }
    
    return QuotaStatus.available;
  }

  /// Check if provider has valid token
  static Future<bool> _hasValidToken(String provider, {required bool isPersonal}) async {
    if (isPersonal) {
      final token = await AITokenManager.getToken(provider);
      return token != null && token.isNotEmpty;
    } else {
      final token = await GlobalAITokenService.getGlobalToken(provider);
      return token != null && token.isNotEmpty;
    }
  }

  /// Call specific provider
  static Future<String> _callProvider({
    required String provider,
    required String userMessage,
    required String systemPrompt,
    List<Map<String, String>>? conversationHistory,
    required bool isPersonal,
  }) async {
    switch (provider) {
      case 'gemini':
        return await AIService.generateGeminiResponse(
          userMessage: userMessage,
          systemPrompt: systemPrompt,
        );
      case 'openai':
        return await AIService.generateOpenAIResponse(
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          conversationHistory: conversationHistory,
        );
      case 'github':
        return await AIService.generateGitHubModelsResponse(
          userMessage: userMessage,
          systemPrompt: systemPrompt,
          conversationHistory: conversationHistory,
        );
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  /// Get quota status for UI display
  static Future<Map<String, QuotaInfo>> getQuotaInfoForUI() async {
    final results = <String, QuotaInfo>{};
    
    for (final entry in _providerLimits.entries) {
      final provider = entry.key;
      final limits = entry.value;
      
      final usage = await _usageTracker.getProviderUsage(provider);
      final dailyRequests = usage['dailyRequests'] ?? 0;
      final dailyTokens = usage['dailyTokens'] ?? 0;
      
      results[provider] = QuotaInfo(
        provider: provider,
        requestsUsed: dailyRequests,
        requestsLimit: limits.dailyRequests,
        tokensUsed: dailyTokens,
        tokensLimit: limits.dailyTokens,
        isFree: limits.isFree,
        status: await _checkProviderQuota(provider),
      );
    }
    
    return results;
  }

  /// Show upgrade dialog when quotas exceeded
  static Future<bool> showUpgradeDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _UpgradeDialog(),
    ) ?? false;
  }
}

// Data classes
class ProviderLimits {
  final int dailyRequests;
  final int dailyTokens;
  final int requestsPerMinute;
  final bool isFree;

  const ProviderLimits({
    required this.dailyRequests,
    required this.dailyTokens,
    required this.requestsPerMinute,
    required this.isFree,
  });
}

class AIResponse {
  final String content;
  final String provider;
  final bool isPersonalToken;
  final QuotaStatus quotaStatus;

  AIResponse({
    required this.content,
    required this.provider,
    required this.isPersonalToken,
    required this.quotaStatus,
  });
}

class QuotaInfo {
  final String provider;
  final int requestsUsed;
  final int requestsLimit;
  final int tokensUsed;
  final int tokensLimit;
  final bool isFree;
  final QuotaStatus status;

  QuotaInfo({
    required this.provider,
    required this.requestsUsed,
    required this.requestsLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.isFree,
    required this.status,
  });

  double get requestsPercentage => 
      requestsLimit > 0 ? (requestsUsed / requestsLimit * 100) : 0;
  
  double get tokensPercentage => 
      tokensLimit > 0 ? (tokensUsed / tokensLimit * 100) : 0;
}

enum QuotaStatus { available, nearLimit, exceeded }

class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException([this.message = 'All provider quotas exceeded']);
}

// Upgrade Dialog Widget
class _UpgradeDialog extends StatelessWidget {
  const _UpgradeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.upgrade, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Upgrade to Continue'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You\'ve reached the daily limit for free AI usage.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text('To continue chatting, you can:'),
          const SizedBox(height: 12),
          _buildUpgradeOption(
            icon: Icons.key,
            title: 'Add Your Own API Keys',
            subtitle: 'Get unlimited usage with your own tokens',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildUpgradeOption(
            icon: Icons.schedule,
            title: 'Wait Until Tomorrow',
            subtitle: 'Free usage resets daily at midnight',
            color: Colors.blue,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            Navigator.of(context).pushNamed('/token-setup');
          },
          child: const Text('Add API Keys'),
        ),
      ],
    );
  }

  Widget _buildUpgradeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}