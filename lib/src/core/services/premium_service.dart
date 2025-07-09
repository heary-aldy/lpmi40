// lib/src/core/services/premium_service.dart
// Premium user management service with upgrade flow support

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final AuthorizationService _authService = AuthorizationService();

  // Premium upgrade configuration
  static const String _premiumUpgradeUrl =
      'https://your-payment-gateway.com/premium-upgrade';
  static const String _contactEmail = 'admin@haweeinc.com';
  static const String _whatsappNumber =
      '+60123456789'; // Your WhatsApp number for payment verification

  // Performance tracking
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, int> _operationCounts = {};

  // Premium features list
  static const List<String> _premiumFeatures = [
    'Unlimited audio playback',
    'Mini-player controls',
    'Full-screen music player',
    'Audio seek and loop controls',
    'Premium player settings',
    'Ad-free audio experience',
  ];

  /// Log operations for debugging
  void _logOperation(String operation, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _operationTimestamps[operation] = DateTime.now();
      _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;

      final count = _operationCounts[operation];
      debugPrint('[PremiumService] 🔧 Operation: $operation (count: $count)');
      if (details != null) {
        debugPrint('[PremiumService] 📊 Details: $details');
      }
    }
  }

  /// Check if current user is premium
  Future<bool> isPremium() async {
    _logOperation('isPremium');
    return await _authService.isPremium();
  }

  /// Check if current user can access audio features
  Future<bool> canAccessAudio() async {
    _logOperation('canAccessAudio');
    return await _authService.canAccessAudio();
  }

  /// Get premium access result with details
  Future<AuthorizationResult> getPremiumAccessResult() async {
    _logOperation('getPremiumAccessResult');
    return await _authService.checkPremiumAccess();
  }

  /// Get premium features list
  List<String> getPremiumFeatures() {
    return List.from(_premiumFeatures);
  }

  /// Get upgrade message for UI
  String getUpgradeMessage() {
    return _authService.getPremiumUpgradeMessage();
  }

  /// Get current user's premium status with details
  Future<Map<String, dynamic>> getPremiumStatus() async {
    _logOperation('getPremiumStatus');

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {
        'isLoggedIn': false,
        'isPremium': false,
        'canAccessAudio': false,
        'userRole': 'none',
        'message': 'Please log in to check premium status',
      };
    }

    final isPremiumUser = await isPremium();
    final canAccess = await canAccessAudio();
    final userRole = await _authService.getCurrentUserRole();

    return {
      'isLoggedIn': true,
      'isPremium': isPremiumUser,
      'canAccessAudio': canAccess,
      'userRole': userRole.toString(),
      'message': isPremiumUser
          ? 'You have premium access to all audio features!'
          : 'Upgrade to premium for audio access',
      'features': _premiumFeatures,
    };
  }

  /// Handle premium upgrade flow
  Future<bool> initiateUpgrade() async {
    _logOperation('initiateUpgrade');

    try {
      final uri = Uri.parse(_premiumUpgradeUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint(
            '[PremiumService] ❌ Cannot launch upgrade URL: $_premiumUpgradeUrl');
        return false;
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error launching upgrade URL: $e');
      return false;
    }
  }

  /// Handle contact admin for payment verification
  Future<bool> contactAdminForVerification() async {
    _logOperation('contactAdminForVerification');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? 'unknown';
      final userName = currentUser?.displayName ?? 'User';

      final message = '''
Hello Admin,

I would like to upgrade to Premium for audio access.

User Details:
- Name: $userName
- Email: $userEmail
- User ID: ${currentUser?.uid ?? 'unknown'}

I have completed the payment and would like to verify my premium status.

Please activate my premium account.

Thank you!
''';

      final whatsappUrl =
          'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);

      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint(
            '[PremiumService] ❌ Cannot launch WhatsApp URL: $whatsappUrl');
        // Fallback to email
        return await _contactViaEmail(message);
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error contacting admin: $e');
      return false;
    }
  }

  /// Fallback contact method via email
  Future<bool> _contactViaEmail(String message) async {
    try {
      final emailUrl =
          'mailto:$_contactEmail?subject=Premium Upgrade Request&body=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(emailUrl);

      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri);
        return true;
      } else {
        debugPrint('[PremiumService] ❌ Cannot launch email URL: $emailUrl');
        return false;
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error launching email: $e');
      return false;
    }
  }

  /// Get premium upgrade instructions
  Map<String, dynamic> getUpgradeInstructions() {
    return {
      'title': 'Upgrade to Premium',
      'subtitle': 'Get unlimited access to audio features',
      'steps': [
        'Click "Upgrade Now" to proceed to payment',
        'Complete your payment securely',
        'Contact admin with payment confirmation',
        'Your premium access will be activated within 24 hours',
      ],
      'features': _premiumFeatures,
      'price': 'Contact admin for pricing',
      'paymentMethods': [
        'Bank Transfer',
        'QR Code Payment',
        'Digital Wallet',
      ],
      'contactInfo': {
        'email': _contactEmail,
        'whatsapp': _whatsappNumber,
      },
    };
  }

  /// Get premium statistics for admin
  Future<Map<String, dynamic>> getPremiumStatistics() async {
    _logOperation('getPremiumStatistics');

    // This would typically query the database for premium user stats
    // For now, return placeholder data
    return {
      'totalPremiumUsers': 0,
      'recentUpgrades': 0,
      'pendingVerifications': 0,
      'revenue': 0.0,
      'conversionRate': 0.0,
    };
  }

  /// Check if feature requires premium access
  bool requiresPremiumAccess(String feature) {
    final premiumOnlyFeatures = [
      'audio_playback',
      'mini_player',
      'full_screen_player',
      'audio_controls',
      'player_settings',
      'audio_seek',
      'audio_loop',
    ];

    return premiumOnlyFeatures.contains(feature);
  }

  /// Get feature access status
  Future<Map<String, bool>> getFeatureAccessStatus() async {
    _logOperation('getFeatureAccessStatus');

    final canAccess = await canAccessAudio();

    return {
      'audio_playback': canAccess,
      'mini_player': canAccess,
      'full_screen_player': canAccess,
      'audio_controls': canAccess,
      'player_settings': canAccess,
      'audio_seek': canAccess,
      'audio_loop': canAccess,
      'lyrics_display': true, // Always available
      'favorites': true, // Always available
      'search': true, // Always available
      'sharing': true, // Always available
    };
  }

  /// Refresh premium status (force cache refresh)
  Future<void> refreshPremiumStatus() async {
    _logOperation('refreshPremiumStatus');
    await _authService.forceRefreshCurrentUserRole();
  }

  /// Get user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Unable to access premium features. Please try again later.';
    } else {
      return 'Unable to process premium request. Please try again.';
    }
  }

  /// Get performance metrics for debugging
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationCounts': Map.from(_operationCounts),
      'lastOperationTimestamps': _operationTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'cacheStats': {
        'authServiceCached': _authService.getPerformanceMetrics(),
      },
    };
  }

  /// Premium service configuration
  static const Map<String, dynamic> _config = {
    'upgradeUrl': _premiumUpgradeUrl,
    'contactEmail': _contactEmail,
    'whatsappNumber': _whatsappNumber,
    'features': _premiumFeatures,
    'verificationRequired': true,
    'autoActivation': false,
  };

  /// Get premium service configuration
  Map<String, dynamic> getConfiguration() {
    return Map.from(_config);
  }
}
