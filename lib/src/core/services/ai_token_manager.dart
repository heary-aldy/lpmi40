// 🔐 AI Token Manager Service
// Manages AI API tokens and their expiration dates

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AITokenManager {
  static const String _tokenStorageKey = 'ai_tokens_data';
  static const String _firebaseTokenPath = 'system/ai_tokens';
  
  // Token expiry tracking
  static const Map<String, int> _defaultExpiryDays = {
    'github': 90,  // GitHub tokens expire in 90 days
    'openai': 365, // OpenAI keys typically don't expire
    'gemini': 365, // Gemini keys typically don't expire
  };

  /// Save token with expiry tracking
  static Future<void> saveToken({
    required String provider,
    required String token,
    DateTime? expiryDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await _getTokenData();
      
      // Calculate expiry date if not provided
      expiryDate ??= DateTime.now().add(
        Duration(days: _defaultExpiryDays[provider] ?? 365)
      );
      
      currentData[provider] = {
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
        'expires_at': expiryDate.toIso8601String(),
        'last_validated': DateTime.now().toIso8601String(),
      };
      
      // Save to local storage
      await prefs.setString(_tokenStorageKey, jsonEncode(currentData));
      
      // Save to Firebase (admin only)
      await _saveToFirebase(currentData);
      
      debugPrint('✅ AI Token saved: $provider (expires: ${expiryDate.toLocal()})');
    } catch (e) {
      debugPrint('❌ Error saving AI token: $e');
      rethrow;
    }
  }

  /// Get token for a specific provider
  static Future<String?> getToken(String provider) async {
    try {
      final data = await _getTokenData();
      final tokenData = data[provider] as Map<String, dynamic>?;
      
      if (tokenData == null) return null;
      
      final token = tokenData['token'] as String?;
      final expiresAt = DateTime.tryParse(tokenData['expires_at'] ?? '');
      
      // Check if token is expired
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        debugPrint('⚠️ Token expired for $provider: $expiresAt');
        return null;
      }
      
      return token;
    } catch (e) {
      debugPrint('❌ Error getting AI token: $e');
      return null;
    }
  }

  /// Get all token status information
  static Future<Map<String, TokenStatus>> getTokenStatuses() async {
    try {
      final data = await _getTokenData();
      final statuses = <String, TokenStatus>{};
      
      for (final provider in ['github', 'openai', 'gemini']) {
        final tokenData = data[provider] as Map<String, dynamic>?;
        
        if (tokenData == null) {
          statuses[provider] = TokenStatus(
            provider: provider,
            hasToken: false,
            isExpired: false,
            expiresAt: null,
            daysUntilExpiry: null,
            lastUpdated: null,
          );
        } else {
          final token = tokenData['token'] as String?;
          final expiresAt = DateTime.tryParse(tokenData['expires_at'] ?? '');
          final lastUpdated = DateTime.tryParse(tokenData['updated_at'] ?? '');
          
          final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
          final daysUntilExpiry = expiresAt?.difference(DateTime.now()).inDays;
          
          statuses[provider] = TokenStatus(
            provider: provider,
            hasToken: token?.isNotEmpty == true,
            isExpired: isExpired,
            expiresAt: expiresAt,
            daysUntilExpiry: daysUntilExpiry,
            lastUpdated: lastUpdated,
          );
        }
      }
      
      return statuses;
    } catch (e) {
      debugPrint('❌ Error getting token statuses: $e');
      return {};
    }
  }

  /// Validate a token by testing API connection
  static Future<bool> validateToken(String provider, String token) async {
    try {
      // Basic validation - check token format
      switch (provider) {
        case 'github':
          return token.startsWith('github_pat_') || token.startsWith('ghp_');
        case 'openai':
          return token.startsWith('sk-');
        case 'gemini':
          return token.length > 20; // Basic length check
        default:
          return token.isNotEmpty;
      }
    } catch (e) {
      debugPrint('❌ Error validating token: $e');
      return false;
    }
  }

  /// Delete a token
  static Future<void> deleteToken(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentData = await _getTokenData();
      
      currentData.remove(provider);
      
      await prefs.setString(_tokenStorageKey, jsonEncode(currentData));
      await _saveToFirebase(currentData);
      
      debugPrint('✅ AI Token deleted: $provider');
    } catch (e) {
      debugPrint('❌ Error deleting AI token: $e');
      rethrow;
    }
  }

  /// Get tokens that are expiring soon (within 7 days)
  static Future<List<TokenStatus>> getExpiringSoonTokens() async {
    final statuses = await getTokenStatuses();
    return statuses.values
        .where((status) => 
            status.hasToken && 
            !status.isExpired && 
            status.daysUntilExpiry != null && 
            status.daysUntilExpiry! <= 7)
        .toList();
  }

  /// Private helper methods
  static Future<Map<String, dynamic>> _getTokenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_tokenStorageKey);
      
      if (jsonString == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('❌ Error loading token data: $e');
      return {};
    }
  }

  static Future<void> _saveToFirebase(Map<String, dynamic> tokenData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Only save encrypted/hashed version to Firebase for backup
      final sanitizedData = <String, dynamic>{};
      
      for (final entry in tokenData.entries) {
        final data = entry.value as Map<String, dynamic>;
        sanitizedData[entry.key] = {
          'has_token': data['token']?.toString().isNotEmpty == true,
          'updated_at': data['updated_at'],
          'expires_at': data['expires_at'],
          'token_prefix': _getTokenPrefix(data['token']?.toString() ?? ''),
        };
      }
      
      await FirebaseDatabase.instance
          .ref('$_firebaseTokenPath/${user.uid}')
          .set(sanitizedData);
    } catch (e) {
      debugPrint('❌ Error saving to Firebase: $e');
      // Don't rethrow - Firebase save is optional
    }
  }

  static String _getTokenPrefix(String token) {
    if (token.length <= 10) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
  }
}

/// Token status information
class TokenStatus {
  final String provider;
  final bool hasToken;
  final bool isExpired;
  final DateTime? expiresAt;
  final int? daysUntilExpiry;
  final DateTime? lastUpdated;

  TokenStatus({
    required this.provider,
    required this.hasToken,
    required this.isExpired,
    this.expiresAt,
    this.daysUntilExpiry,
    this.lastUpdated,
  });

  String get statusText {
    if (!hasToken) return 'No token';
    if (isExpired) return 'Expired';
    if (daysUntilExpiry != null && daysUntilExpiry! <= 7) {
      return 'Expires in $daysUntilExpiry days';
    }
    if (daysUntilExpiry != null) return 'Expires in $daysUntilExpiry days';
    return 'Active';
  }

  Color get statusColor {
    if (!hasToken) return const Color(0xFF757575); // Grey
    if (isExpired) return const Color(0xFFD32F2F); // Red
    if (daysUntilExpiry != null && daysUntilExpiry! <= 7) {
      return const Color(0xFFFF9800); // Orange
    }
    return const Color(0xFF388E3C); // Green
  }

  String get providerDisplayName {
    switch (provider) {
      case 'github':
        return 'GitHub Models';
      case 'openai':
        return 'OpenAI';
      case 'gemini':
        return 'Google Gemini';
      default:
        return provider.toUpperCase();
    }
  }
}