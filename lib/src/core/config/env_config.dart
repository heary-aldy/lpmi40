// 🔐 Environment Configuration
// Secure configuration management for API keys and sensitive data

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Initialize dotenv
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
    // Debug logging
    print('🔐 Environment loaded - OpenAI key available: ${hasOpenAIKey}');
    print('🔐 Environment loaded - Gemini key available: ${hasGeminiKey}');
    print('🔐 Environment loaded - AI Chat enabled: $enableAIChat');
  }

  // AI Service API Keys
  static String get openAIApiKey => 
      dotenv.env['OPENAI_API_KEY'] ?? 
      const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  
  static String get geminiApiKey => 
      dotenv.env['GEMINI_API_KEY'] ?? 
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  // AI Service Configuration
  static bool get enableAIChat => 
      (dotenv.env['ENABLE_AI_CHAT'] ?? 
       const String.fromEnvironment('ENABLE_AI_CHAT', defaultValue: 'false')) == 'true';
  
  static String get preferredAIProvider => 
      dotenv.env['PREFERRED_AI_PROVIDER'] ?? 
      const String.fromEnvironment('PREFERRED_AI_PROVIDER', defaultValue: 'openai');
  
  // Validation methods
  static bool get hasOpenAIKey => openAIApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  static bool get hasAnyAIKey => hasOpenAIKey || hasGeminiKey;
  
  // Get the best available AI provider
  static String get bestAIProvider {
    if (preferredAIProvider == 'openai' && hasOpenAIKey) return 'openai';
    if (preferredAIProvider == 'gemini' && hasGeminiKey) return 'gemini';
    if (hasOpenAIKey) return 'openai';
    if (hasGeminiKey) return 'gemini';
    return 'none';
  }
}

/* 
To use with API keys, run your app with:

flutter run --dart-define=OPENAI_API_KEY=your_openai_key_here
flutter run --dart-define=GEMINI_API_KEY=your_gemini_key_here
flutter run --dart-define=ENABLE_AI_CHAT=true

Or add to launch.json in VSCode:
{
  "configurations": [
    {
      "name": "Flutter with AI",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your_key_here",
        "--dart-define=ENABLE_AI_CHAT=true"
      ]
    }
  ]
}
*/