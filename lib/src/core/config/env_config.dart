// 🔐 Environment Configuration
// Secure configuration management for API keys and sensitive data

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/ai_token_manager.dart';
import '../services/global_ai_token_service.dart';

class EnvConfig {
  // Initialize dotenv
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
    // Debug logging
    print('🔐 Environment loaded - OpenAI key available: $hasOpenAIKey');
    print('🔐 Environment loaded - Gemini key available: $hasGeminiKey');
    print('🔐 Environment loaded - GitHub token available: $hasGitHubToken');
    print('🔐 Environment loaded - AI Chat enabled: $enableAIChat');
    print('🔐 Environment loaded - Best AI provider: $bestAIProvider');
  }

  // AI Service API Keys (with admin token management integration)
  static String get openAIApiKey =>
      dotenv.env['OPENAI_API_KEY'] ??
      const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get githubToken =>
      dotenv.env['GITHUB_TOKEN'] ??
      const String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');

  // Get AI tokens with priority: Global > Local Admin > Environment
  static Future<String> getOpenAIApiKey() async {
    // 1. Try global token first (affects all users)
    try {
      final globalToken = await GlobalAITokenService.getGlobalToken('openai');
      if (globalToken != null && globalToken.isNotEmpty) return globalToken;
    } catch (e) {
      // Ignore global token errors, continue to fallbacks
    }

    // 2. Try local admin token manager
    try {
      final managerToken = await AITokenManager.getToken('openai');
      if (managerToken != null && managerToken.isNotEmpty) return managerToken;
    } catch (e) {
      // Ignore token manager errors, fall back to env
    }

    // 3. Fallback to environment variables
    return openAIApiKey;
  }

  static Future<String> getGeminiApiKey() async {
    // 1. Try global token first (affects all users)
    try {
      final globalToken = await GlobalAITokenService.getGlobalToken('gemini');
      if (globalToken != null && globalToken.isNotEmpty) return globalToken;
    } catch (e) {
      // Ignore global token errors, continue to fallbacks
    }

    // 2. Try local admin token manager
    try {
      final managerToken = await AITokenManager.getToken('gemini');
      if (managerToken != null && managerToken.isNotEmpty) return managerToken;
    } catch (e) {
      // Ignore token manager errors, fall back to env
    }

    // 3. Fallback to environment variables
    return geminiApiKey;
  }

  static Future<String> getGithubToken() async {
    // 1. Try global token first (affects all users)
    try {
      final globalToken = await GlobalAITokenService.getGlobalToken('github');
      if (globalToken != null && globalToken.isNotEmpty) return globalToken;
    } catch (e) {
      // Ignore global token errors, continue to fallbacks
    }

    // 2. Try local admin token manager
    try {
      final managerToken = await AITokenManager.getToken('github');
      if (managerToken != null && managerToken.isNotEmpty) return managerToken;
    } catch (e) {
      // Ignore token manager errors, fall back to env
    }

    // 3. Fallback to environment variables
    return githubToken;
  }

  // AI Service Configuration
  static bool get enableAIChat =>
      (dotenv.env['ENABLE_AI_CHAT'] ??
          const String.fromEnvironment('ENABLE_AI_CHAT',
              defaultValue: 'false')) ==
      'true';

  static String get preferredAIProvider =>
      dotenv.env['PREFERRED_AI_PROVIDER'] ??
      const String.fromEnvironment('PREFERRED_AI_PROVIDER',
          defaultValue: 'github');

  // Validation methods
  static bool get hasOpenAIKey => openAIApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  static bool get hasGitHubToken => githubToken.isNotEmpty;
  static bool get hasAnyAIKey => hasOpenAIKey || hasGeminiKey || hasGitHubToken;

  // Get the best available AI provider
  static String get bestAIProvider {
    if (preferredAIProvider == 'github' && hasGitHubToken) return 'github';
    if (preferredAIProvider == 'openai' && hasOpenAIKey) return 'openai';
    if (preferredAIProvider == 'gemini' && hasGeminiKey) return 'gemini';
    if (hasGitHubToken) return 'github';
    if (hasOpenAIKey) return 'openai';
    if (hasGeminiKey) return 'gemini';
    return 'none';
  }

  // Generic method to get any environment variable
  static String? getValue(String key) {
    return dotenv.env[key];
  }

  // FCM Server Key
  static String get fcmServerKey =>
      dotenv.env['FCM_SERVER_KEY'] ??
      const String.fromEnvironment('FCM_SERVER_KEY', defaultValue: '');
  
  static bool get hasFCMServerKey => fcmServerKey.isNotEmpty;
}

/* 
To use with API keys, run your app with:

flutter run --dart-define=GITHUB_TOKEN=your_github_token_here
flutter run --dart-define=OPENAI_API_KEY=your_openai_key_here
flutter run --dart-define=GEMINI_API_KEY=your_gemini_key_here
flutter run --dart-define=ENABLE_AI_CHAT=true
flutter run --dart-define=PREFERRED_AI_PROVIDER=github

Or add to launch.json in VSCode:
{
  "configurations": [
    {
      "name": "Flutter with GitHub AI",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=GITHUB_TOKEN=github_pat_your_token_here",
        "--dart-define=PREFERRED_AI_PROVIDER=github",
        "--dart-define=ENABLE_AI_CHAT=true"
      ]
    }
  ]
}
*/
