// lib/src/core/services/premium_service.dart
// Clean premium service without conflicts

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

class PremiumService {
  static const String _whatsappNumber = '60135453900';
  static const String _contactEmail = 'haweeinc@gmail.com';
  static const String _paypalEmail = 'heary_aldy@hotmail.com';
  static const String _paypalUrl =
      'https://www.paypal.com/paypalme/hearysairin';

  final AuthorizationService _authService = AuthorizationService();
  final FirebaseService _firebaseService = FirebaseService();

  /// Check if current user has premium access
  Future<bool> isPremium() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userRole = await _authService.getCurrentUserRole();
      return userRole == UserRole.premium ||
          userRole == UserRole.admin ||
          userRole == UserRole.superAdmin;
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Check if user can access audio features
  Future<bool> canAccessAudio() async {
    return await isPremium();
  }

  /// Get premium features list
  List<String> getPremiumFeatures() {
    return [
      '🎵 Unlimited audio playback',
      '🎛️ Advanced player controls',
      '📱 Mini-player with quick access',
      '🔄 Loop and repeat modes',
      '⏯️ Background audio playback',
      '🎚️ Audio quality settings',
      '📋 Premium song collections',
      '💬 Priority support',
    ];
  }

  /// Handle upgrade flow
  Future<bool> initiateUpgrade() async {
    debugPrint('[PremiumService] 🔧 initiateUpgrade');

    try {
      final uri = Uri.parse(_paypalUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('[PremiumService] ❌ Cannot launch PayPal URL: $_paypalUrl');
        return false;
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error launching PayPal: $e');
      return false;
    }
  }

  /// Contact admin for verification
  Future<bool> contactAdminForVerification() async {
    debugPrint('[PremiumService] 🔧 contactAdminForVerification');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? 'unknown';
      final userName = currentUser?.displayName ?? 'User';

      String message = '''
Hello Admin,

I have completed payment for Premium upgrade and would like to request verification.

User Details:
- Name: $userName
- Email: $userEmail
- User ID: ${currentUser?.uid ?? 'unknown'}
- Date: ${DateTime.now().toString().split('.')[0]}

Please verify my payment and activate my premium account.

Payment Instructions Followed:
1. ✅ Completed payment via PayPal/QR Code
2. ✅ Payment receipt will be sent to $_contactEmail
3. ⏳ Awaiting premium activation

Thank you for your assistance!

Best regards,
$userName''';

      // Try WhatsApp first
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
      final emailSubject = 'Premium Upgrade Request';
      final emailUrl =
          'mailto:$_contactEmail?subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(message)}';
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

  /// Admin helpers
  Future<bool> assignPremiumToUser(String userId) async {
    try {
      return await _firebaseService.updateUserRole(userId, 'premium');
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error assigning premium: $e');
      return false;
    }
  }

  Future<bool> removePremiumFromUser(String userId) async {
    try {
      return await _firebaseService.updateUserRole(userId, 'user');
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error removing premium: $e');
      return false;
    }
  }
}
