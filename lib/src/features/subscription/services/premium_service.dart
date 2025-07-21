// lib/src/features/subscription/services/premium_service.dart
// Premium subscription service for offline audio functionality

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

enum PremiumTier {
  basic,
  premium,
  premium_plus,
}

class PremiumStatus {
  final bool isPremium;
  final PremiumTier tier;
  final DateTime? expiryDate;
  final List<String> features;
  final int? audioDownloadLimit;
  final bool hasOfflineAccess;

  const PremiumStatus({
    required this.isPremium,
    required this.tier,
    this.expiryDate,
    required this.features,
    this.audioDownloadLimit,
    required this.hasOfflineAccess,
  });

  factory PremiumStatus.free() {
    return const PremiumStatus(
      isPremium: false,
      tier: PremiumTier.basic,
      features: ['favorites', 'basic_search'],
      hasOfflineAccess: false,
    );
  }

  factory PremiumStatus.premium() {
    return const PremiumStatus(
      isPremium: true,
      tier: PremiumTier.premium,
      features: [
        'favorites',
        'advanced_search',
        'offline_audio',
        'unlimited_downloads',
        'custom_playlists'
      ],
      audioDownloadLimit: 100,
      hasOfflineAccess: true,
    );
  }

  factory PremiumStatus.premiumPlus() {
    return const PremiumStatus(
      isPremium: true,
      tier: PremiumTier.premium_plus,
      features: [
        'favorites',
        'advanced_search',
        'offline_audio',
        'unlimited_downloads',
        'custom_playlists',
        'ad_free',
        'priority_support'
      ],
      hasOfflineAccess: true,
    );
  }

  bool hasFeature(String feature) => features.contains(feature);
}

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // Constants
  static const String _prefsPremiumStatus = 'premium_status';
  static const String _prefsPremiumTier = 'premium_tier';
  static const String _prefsPremiumExpiry = 'premium_expiry';
  static const Duration _cacheValidityDuration = Duration(hours: 1);

  // Cache
  PremiumStatus? _cachedStatus;
  DateTime? _lastCacheUpdate;

  /// Check if user has premium access
  Future<PremiumStatus> getPremiumStatus() async {
    try {
      // Return cached status if still valid
      if (_cachedStatus != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) <
              _cacheValidityDuration) {
        return _cachedStatus!;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return await _getLocalPremiumStatus();
      }

      // Check Firebase for premium status
      final premiumStatus = await _checkFirebasePremiumStatus(user.uid);

      // Cache the result
      _cachedStatus = premiumStatus;
      _lastCacheUpdate = DateTime.now();

      // Save to local storage for offline access
      await _savePremiumStatusLocally(premiumStatus);

      return premiumStatus;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return await _getLocalPremiumStatus();
    }
  }

  /// Check Firebase for premium subscription status
  Future<PremiumStatus> _checkFirebasePremiumStatus(String userId) async {
    try {
      // First check if user is admin or super admin - they get automatic premium access
      final authService = AuthorizationService();
      final adminStatus = await authService.checkAdminStatus();

      if (adminStatus['isAdmin'] == true ||
          adminStatus['isSuperAdmin'] == true) {
        debugPrint('🎭 Admin/SuperAdmin detected - granting premium access');
        return PremiumStatus.premiumPlus(); // Admins get highest tier
      }

      final dbRef = FirebaseDatabase.instance.ref();
      final snapshot = await dbRef.child('users/$userId/subscription').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final isActive = data['is_active'] ?? false;
        final tierString = data['tier'] ?? 'basic';
        final expiryTimestamp = data['expires_at'];

        if (!isActive) {
          return PremiumStatus.free();
        }

        // Check if subscription has expired
        if (expiryTimestamp != null) {
          final expiryDate =
              DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
          if (DateTime.now().isAfter(expiryDate)) {
            return PremiumStatus.free();
          }
        }

        // Return appropriate premium tier
        switch (tierString.toLowerCase()) {
          case 'premium':
            return PremiumStatus.premium();
          case 'premium_plus':
            return PremiumStatus.premiumPlus();
          default:
            return PremiumStatus.free();
        }
      }

      // For testing purposes - check if user email contains 'premium'
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email?.contains('premium') == true) {
        return PremiumStatus.premium();
      }

      return PremiumStatus.free();
    } catch (e) {
      debugPrint('Error checking Firebase premium status: $e');
      return PremiumStatus.free();
    }
  }

  /// Get premium status from local storage (for offline access)
  Future<PremiumStatus> _getLocalPremiumStatus() async {
    try {
      // First check if user is admin (this works offline with cached roles)
      final authService = AuthorizationService();
      final adminStatus = await authService.checkAdminStatus();

      if (adminStatus['isAdmin'] == true ||
          adminStatus['isSuperAdmin'] == true) {
        debugPrint(
            '🎭 Admin/SuperAdmin detected (offline) - granting premium access');
        return PremiumStatus.premiumPlus(); // Admins get highest tier
      }

      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool(_prefsPremiumStatus) ?? false;
      final tierString = prefs.getString(_prefsPremiumTier) ?? 'basic';
      final expiryString = prefs.getString(_prefsPremiumExpiry);

      if (!isPremium) {
        return PremiumStatus.free();
      }

      // Check if locally stored subscription has expired
      if (expiryString != null) {
        final expiryDate = DateTime.tryParse(expiryString);
        if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
          return PremiumStatus.free();
        }
      }

      switch (tierString.toLowerCase()) {
        case 'premium':
          return PremiumStatus.premium();
        case 'premium_plus':
          return PremiumStatus.premiumPlus();
        default:
          return PremiumStatus.free();
      }
    } catch (e) {
      debugPrint('Error getting local premium status: $e');
      return PremiumStatus.free();
    }
  }

  /// Save premium status to local storage
  Future<void> _savePremiumStatusLocally(PremiumStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsPremiumStatus, status.isPremium);
      await prefs.setString(
          _prefsPremiumTier, status.tier.toString().split('.').last);

      if (status.expiryDate != null) {
        await prefs.setString(
            _prefsPremiumExpiry, status.expiryDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving premium status locally: $e');
    }
  }

  /// Check if user can download audio files
  Future<bool> canDownloadAudio() async {
    final status = await getPremiumStatus();
    return status.hasOfflineAccess;
  }

  /// Check if user has reached download limit
  Future<bool> hasReachedDownloadLimit(int currentDownloads) async {
    final status = await getPremiumStatus();
    if (status.audioDownloadLimit == null) return false;
    return currentDownloads >= status.audioDownloadLimit!;
  }

  /// Get available storage locations for premium users
  Future<List<String>> getAvailableStorageOptions() async {
    final status = await getPremiumStatus();
    if (!status.hasOfflineAccess) {
      return [];
    }

    return [
      'Internal Storage',
      'SD Card (if available)',
      'Custom Location',
    ];
  }

  /// Clear cached premium status (useful for testing or after subscription changes)
  void clearCache() {
    _cachedStatus = null;
    _lastCacheUpdate = null;
  }

  /// For demo/testing purposes - temporarily grant premium access
  Future<void> grantTemporaryPremium(
      {Duration duration = const Duration(days: 7)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsPremiumStatus, true);
      await prefs.setString(_prefsPremiumTier, 'premium');

      final expiryDate = DateTime.now().add(duration);
      await prefs.setString(_prefsPremiumExpiry, expiryDate.toIso8601String());

      clearCache(); // Clear cache so new status is loaded

      debugPrint('Granted temporary premium access until: $expiryDate');
    } catch (e) {
      debugPrint('Error granting temporary premium: $e');
    }
  }

  /// Remove premium access (for testing)
  Future<void> revokeTemporaryPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsPremiumStatus);
      await prefs.remove(_prefsPremiumTier);
      await prefs.remove(_prefsPremiumExpiry);

      clearCache();

      debugPrint('Revoked temporary premium access');
    } catch (e) {
      debugPrint('Error revoking temporary premium: $e');
    }
  }
}
