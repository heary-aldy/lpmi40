// 🧪 Test script for Gemini quota system
// Run with: dart test_gemini_quota.dart

import 'dart:io';
import 'lib/src/core/services/gemini_smart_service.dart';

void main() async {
  print('🧪 Testing Gemini Quota System...\n');
  
  try {
    // Test 1: Get current quota info
    print('📊 Getting current quota info...');
    final quotaInfo = await GeminiSmartService.getQuotaInfo();
    
    print('Requests used: ${quotaInfo.requestsUsed}/${quotaInfo.requestsLimit}');
    print('Tokens used: ${quotaInfo.tokensUsed}/${quotaInfo.tokensLimit}');
    print('Has personal token: ${quotaInfo.hasPersonalToken}');
    print('Near limit: ${quotaInfo.isNearLimit}');
    print('Exceeded: ${quotaInfo.isExceeded}');
    print('Remaining requests: ${quotaInfo.remainingRequests}');
    print('Remaining tokens: ${quotaInfo.remainingTokens}\n');
    
    // Test 2: Try generating a response
    print('🤖 Testing AI response generation...');
    try {
      final response = await GeminiSmartService.generateResponse(
        userMessage: 'What is love according to the Bible?',
        systemPrompt: 'You are a helpful Bible study assistant. Answer questions about Christianity and the Bible.',
      );
      
      print('✅ Response generated successfully!');
      print('Content length: ${response.content.length} characters');
      print('Tokens used: ${response.tokensUsed}');
      print('Personal token: ${response.isPersonalToken}');
      print('Quota status: ${response.quotaStatus}');
      print('Remaining requests: ${response.remainingRequests}');
      print('Remaining tokens: ${response.remainingTokens}');
      print('\nResponse preview:');
      print(response.content.length > 200 
          ? '${response.content.substring(0, 200)}...' 
          : response.content);
      
    } catch (e) {
      if (e is GeminiQuotaExceededException) {
        print('⚠️ Quota exceeded: ${e.message}');
        print('Quota type: ${e.quotaType}');
      } else {
        print('❌ Error: $e');
      }
    }
    
    // Test 3: Check quota after request
    print('\n📊 Quota after request...');
    final updatedQuota = await GeminiSmartService.getQuotaInfo();
    print('Requests used: ${updatedQuota.requestsUsed}/${updatedQuota.requestsLimit}');
    print('Tokens used: ${updatedQuota.tokensUsed}/${updatedQuota.tokensLimit}');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    exit(1);
  }
  
  print('\n✅ All tests completed!');
}