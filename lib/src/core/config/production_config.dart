// 🏭 Production Configuration
// Manages production-ready settings and runtime token configuration

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductionConfig {
  static const String _firebaseConfigPath = 'system/production_config';
  static const String _globalTokensPath = 'system/global_tokens';
  
  // Production settings
  static const Map<String, dynamic> _defaultConfig = {
    'app_version': '1.0.0',
    'environment': 'production',
    'debug_mode': false,
    'maintenance_mode': false,
    'ai_service_enabled': true,
    'global_quota_limits': {
      'daily_requests': 1000,
      'daily_tokens': 800000,
      'requests_per_minute': 10,
    },
    'features': {
      'bible_chat': true,
      'personal_tokens': true,
      'usage_tracking': true,
    },
  };

  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static Map<String, dynamic>? _cachedConfig;
  static Map<String, String>? _cachedTokens;

  /// Initialize production configuration
  static Future<void> initialize() async {
    try {
      await _loadProductionConfig();
      await _loadGlobalTokens();
      debugPrint('✅ Production config initialized successfully');
    } catch (e) {
      debugPrint('❌ Production config initialization failed: $e');
      // Use default config on failure
      _cachedConfig = Map<String, dynamic>.from(_defaultConfig);
    }
  }

  /// Load production configuration from Firebase
  static Future<void> _loadProductionConfig() async {
    try {
      final snapshot = await _database.ref(_firebaseConfigPath).get();
      
      if (snapshot.exists) {
        _cachedConfig = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('📋 Production config loaded from Firebase');
      } else {
        // Set default config in Firebase for first time
        await _database.ref(_firebaseConfigPath).set(_defaultConfig);
        _cachedConfig = Map<String, dynamic>.from(_defaultConfig);
        debugPrint('📋 Default production config set in Firebase');
      }
    } catch (e) {
      debugPrint('❌ Error loading production config: $e');
      _cachedConfig = Map<String, dynamic>.from(_defaultConfig);
    }
  }

  /// Load global tokens from Firebase (admin-configurable after build)
  static Future<void> _loadGlobalTokens() async {
    try {
      final snapshot = await _database.ref(_globalTokensPath).get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _cachedTokens = {};
        
        // Extract active tokens
        for (final entry in data.entries) {
          final tokenData = entry.value as Map<String, dynamic>;
          if (tokenData['is_active'] == true && tokenData['token'] != null) {
            _cachedTokens![entry.key] = tokenData['token'] as String;
          }
        }
        
        debugPrint('🔑 Global tokens loaded: ${_cachedTokens!.keys.join(', ')}');
      } else {
        _cachedTokens = {};
        debugPrint('🔑 No global tokens configured');
      }
    } catch (e) {
      debugPrint('❌ Error loading global tokens: $e');
      _cachedTokens = {};
    }
  }

  /// Get global token for a provider (runtime configurable)
  static String? getGlobalToken(String provider) {
    return _cachedTokens?[provider];
  }

  /// Check if AI service is enabled
  static bool get isAIServiceEnabled {
    return _cachedConfig?['ai_service_enabled'] ?? true;
  }

  /// Check if app is in maintenance mode
  static bool get isMaintenanceMode {
    return _cachedConfig?['maintenance_mode'] ?? false;
  }

  /// Get global quota limits
  static Map<String, int> get globalQuotaLimits {
    final limits = _cachedConfig?['global_quota_limits'] as Map<String, dynamic>?;
    return {
      'daily_requests': limits?['daily_requests'] ?? 1000,
      'daily_tokens': limits?['daily_tokens'] ?? 800000,
      'requests_per_minute': limits?['requests_per_minute'] ?? 10,
    };
  }

  /// Get app version
  static String get appVersion {
    return _cachedConfig?['app_version'] ?? '1.0.0';
  }

  /// Get environment
  static String get environment {
    return _cachedConfig?['environment'] ?? 'production';
  }

  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    final features = _cachedConfig?['features'] as Map<String, dynamic>?;
    return features?[feature] ?? false;
  }

  /// Refresh configuration (for admin updates)
  static Future<void> refresh() async {
    await _loadProductionConfig();
    await _loadGlobalTokens();
    debugPrint('🔄 Production config refreshed');
  }

  /// Admin method to update global token (super admin only)
  static Future<bool> updateGlobalToken({
    required String provider,
    required String token,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is super admin
      if (!await _isSuperAdmin(user.email)) {
        debugPrint('❌ Unauthorized: Not a super admin');
        return false;
      }

      final tokenData = {
        'token': token,
        'provider': provider,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': user.email,
        'is_active': true,
        'environment': 'production',
      };

      await _database.ref('$_globalTokensPath/$provider').set(tokenData);
      
      // Refresh cached tokens
      await _loadGlobalTokens();
      
      debugPrint('✅ Global $provider token updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating global token: $e');
      return false;
    }
  }

  /// Admin method to disable global token
  static Future<bool> disableGlobalToken(String provider) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (!await _isSuperAdmin(user.email)) {
        return false;
      }

      await _database.ref('$_globalTokensPath/$provider/is_active').set(false);
      await _database.ref('$_globalTokensPath/$provider/disabled_at').set(DateTime.now().toIso8601String());
      await _database.ref('$_globalTokensPath/$provider/disabled_by').set(user.email);
      
      // Refresh cached tokens
      await _loadGlobalTokens();
      
      debugPrint('✅ Global $provider token disabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling global token: $e');
      return false;
    }
  }

  /// Check if user is super admin
  static Future<bool> _isSuperAdmin(String? email) async {
    if (email == null) return false;
    
    // Define super admin emails (you can also store this in Firebase)
    const superAdmins = [
      'heary@hopetv.asia',
      'heary_aldy@hotmail.com',
    ];
    
    return superAdmins.contains(email.toLowerCase());
  }

  /// Get production status for UI display
  static Map<String, dynamic> getProductionStatus() {
    return {
      'environment': environment,
      'version': appVersion,
      'ai_enabled': isAIServiceEnabled,
      'maintenance': isMaintenanceMode,
      'global_tokens': _cachedTokens?.keys.toList() ?? [],
      'quota_limits': globalQuotaLimits,
      'features': _cachedConfig?['features'] ?? {},
    };
  }

  /// Emergency method to enable/disable AI service
  static Future<bool> setAIServiceEnabled(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !await _isSuperAdmin(user.email)) {
        return false;
      }

      await _database.ref('$_firebaseConfigPath/ai_service_enabled').set(enabled);
      await _database.ref('$_firebaseConfigPath/ai_service_updated_at').set(DateTime.now().toIso8601String());
      await _database.ref('$_firebaseConfigPath/ai_service_updated_by').set(user.email);
      
      // Refresh config
      await _loadProductionConfig();
      
      debugPrint('✅ AI service ${enabled ? 'enabled' : 'disabled'}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating AI service status: $e');
      return false;
    }
  }

  /// Emergency method to enable/disable maintenance mode
  static Future<bool> setMaintenanceMode(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !await _isSuperAdmin(user.email)) {
        return false;
      }

      await _database.ref('$_firebaseConfigPath/maintenance_mode').set(enabled);
      await _database.ref('$_firebaseConfigPath/maintenance_updated_at').set(DateTime.now().toIso8601String());
      await _database.ref('$_firebaseConfigPath/maintenance_updated_by').set(user.email);
      
      // Refresh config
      await _loadProductionConfig();
      
      debugPrint('✅ Maintenance mode ${enabled ? 'enabled' : 'disabled'}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating maintenance mode: $e');
      return false;
    }
  }
}