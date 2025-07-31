// 🌍 Global AI Token Service
// Manages AI tokens globally for all app users

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalAITokenService {
  static const String _firebaseGlobalTokenPath = 'system/global_ai_tokens';
  static const String _localCacheKey = 'cached_global_tokens';
  static const String _lastUpdateKey = 'global_tokens_last_update';
  
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get token for all users (admin updates affect everyone)
  static Future<String?> getGlobalToken(String provider) async {
    try {
      // Try to get fresh token from Firebase first
      final firebaseToken = await _getTokenFromFirebase(provider);
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        await _cacheTokenLocally(provider, firebaseToken);
        return firebaseToken;
      }

      // Fallback to local cache
      final cachedToken = await _getCachedToken(provider);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        return cachedToken;
      }

      debugPrint('⚠️ No global token available for $provider');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting global token for $provider: $e');
      // Try local cache as last resort
      return await _getCachedToken(provider);
    }
  }

  /// Update global token (admin only)
  static Future<bool> updateGlobalToken({
    required String provider,
    required String token,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated for global token update');
        return false;
      }

      // Check if user is admin (you can implement admin check here)
      // For now, we'll allow any authenticated user to update
      // In production, add proper admin role checking

      expiryDate ??= DateTime.now().add(
        Duration(days: _getDefaultExpiryDays(provider))
      );

      final tokenData = {
        'token': token,
        'provider': provider,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': user.email ?? user.uid,
        'expires_at': expiryDate.toIso8601String(),
        'is_active': true,
      };

      // Save to Firebase (global)
      await _database.ref('$_firebaseGlobalTokenPath/$provider').set(tokenData);

      // Cache locally for offline access
      await _cacheTokenLocally(provider, token, expiryDate);

      debugPrint('✅ Global token updated for $provider by ${user.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating global token: $e');
      return false;
    }
  }

  /// Get token status for admin dashboard
  static Future<GlobalTokenStatus> getGlobalTokenStatus(String provider) async {
    try {
      final snapshot = await _database.ref('$_firebaseGlobalTokenPath/$provider').get();
      
      if (!snapshot.exists) {
        return GlobalTokenStatus(
          provider: provider,
          hasToken: false,
          isExpired: false,
          expiresAt: null,
          updatedBy: null,
          lastUpdated: null,
        );
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final expiresAt = DateTime.tryParse(data['expires_at'] ?? '');
      final lastUpdated = DateTime.tryParse(data['updated_at'] ?? '');
      final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);

      return GlobalTokenStatus(
        provider: provider,
        hasToken: data['token']?.toString().isNotEmpty == true,
        isExpired: isExpired,
        expiresAt: expiresAt,
        updatedBy: data['updated_by']?.toString(),
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      debugPrint('❌ Error getting global token status: $e');
      return GlobalTokenStatus(
        provider: provider,
        hasToken: false,
        isExpired: false,
        expiresAt: null,
        updatedBy: null,
        lastUpdated: null,
      );
    }
  }

  /// Get all global token statuses
  static Future<Map<String, GlobalTokenStatus>> getAllGlobalTokenStatuses() async {
    final providers = ['github', 'openai', 'gemini'];
    final statuses = <String, GlobalTokenStatus>{};

    for (final provider in providers) {
      statuses[provider] = await getGlobalTokenStatus(provider);
    }

    return statuses;
  }

  /// Check if any tokens are expiring soon (within 7 days)
  static Future<List<GlobalTokenStatus>> getExpiringSoonTokens() async {
    final statuses = await getAllGlobalTokenStatuses();
    return statuses.values
        .where((status) => 
            status.hasToken && 
            !status.isExpired && 
            status.expiresAt != null &&
            status.expiresAt!.difference(DateTime.now()).inDays <= 7)
        .toList();
  }

  /// Delete global token (admin only)
  static Future<bool> deleteGlobalToken(String provider) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database.ref('$_firebaseGlobalTokenPath/$provider').remove();
      await _removeCachedToken(provider);

      debugPrint('✅ Global token deleted for $provider by ${user.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting global token: $e');
      return false;
    }
  }

  /// Private helper methods
  static Future<String?> _getTokenFromFirebase(String provider) async {
    try {
      final snapshot = await _database.ref('$_firebaseGlobalTokenPath/$provider').get();
      
      if (!snapshot.exists) return null;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final token = data['token']?.toString();
      final expiresAt = DateTime.tryParse(data['expires_at'] ?? '');
      final isActive = data['is_active'] == true;

      // Check if token is expired or inactive
      if (!isActive || (expiresAt != null && DateTime.now().isAfter(expiresAt))) {
        debugPrint('⚠️ Global token expired for $provider');
        return null;
      }

      return token;
    } catch (e) {
      debugPrint('❌ Error fetching token from Firebase: $e');
      return null;
    }
  }

  static Future<void> _cacheTokenLocally(String provider, String token, [DateTime? expiryDate]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'token': token,
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': expiryDate?.toIso8601String(),
      };
      
      await prefs.setString('${_localCacheKey}_$provider', jsonEncode(cacheData));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error caching token locally: $e');
    }
  }

  static Future<String?> _getCachedToken(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('${_localCacheKey}_$provider');
      
      if (cacheJson == null) return null;
      
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      final token = cacheData['token']?.toString();
      final expiresAt = DateTime.tryParse(cacheData['expires_at'] ?? '');
      
      // Check if cached token is expired
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        await _removeCachedToken(provider);
        return null;
      }
      
      return token;
    } catch (e) {
      debugPrint('❌ Error getting cached token: $e');
      return null;
    }
  }

  static Future<void> _removeCachedToken(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_localCacheKey}_$provider');
    } catch (e) {
      debugPrint('❌ Error removing cached token: $e');
    }
  }

  static int _getDefaultExpiryDays(String provider) {
    switch (provider) {
      case 'github':
        return 90;  // GitHub tokens expire in 90 days
      case 'openai':
        return 365; // OpenAI keys typically don't expire
      case 'gemini':
        return 365; // Gemini keys typically don't expire
      default:
        return 90;
    }
  }

  /// Check if current user can manage global tokens (admin check)
  static Future<bool> canManageGlobalTokens() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Implement your admin check logic here
    // For now, checking against known admin emails
    final adminEmails = [
      'heary@hopetv.asia',
      'heary_aldy@hotmail.com',
    ];

    return adminEmails.contains(user.email?.toLowerCase());
  }
}

/// Global token status information
class GlobalTokenStatus {
  final String provider;
  final bool hasToken;
  final bool isExpired;
  final DateTime? expiresAt;
  final String? updatedBy;
  final DateTime? lastUpdated;

  GlobalTokenStatus({
    required this.provider,
    required this.hasToken,
    required this.isExpired,
    this.expiresAt,
    this.updatedBy,
    this.lastUpdated,
  });

  String get statusText {
    if (!hasToken) return 'No global token';
    if (isExpired) return 'Expired';
    
    final daysUntilExpiry = expiresAt?.difference(DateTime.now()).inDays;
    if (daysUntilExpiry != null && daysUntilExpiry <= 7) {
      return 'Expires in $daysUntilExpiry days';
    }
    if (daysUntilExpiry != null) return 'Expires in $daysUntilExpiry days';
    return 'Active globally';
  }

  Color get statusColor {
    if (!hasToken) return const Color(0xFF757575); // Grey
    if (isExpired) return const Color(0xFFD32F2F); // Red
    
    final daysUntilExpiry = expiresAt?.difference(DateTime.now()).inDays;
    if (daysUntilExpiry != null && daysUntilExpiry <= 7) {
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