// lib/src/core/services/premium_service.dart
// Updated premium service with donation page integration

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';
import 'package:lpmi40/src/core/services/firebase_service.dart';

/// Premium status class to track user's premium access
class PremiumStatus {
  final bool isPremium;
  final bool hasOfflineAccess;
  final bool hasAudioAccess;
  final DateTime? expiryDate;
  final String? subscriptionType;

  const PremiumStatus({
    required this.isPremium,
    required this.hasOfflineAccess,
    required this.hasAudioAccess,
    this.expiryDate,
    this.subscriptionType,
  });

  factory PremiumStatus.free() {
    return const PremiumStatus(
      isPremium: false,
      hasOfflineAccess: false,
      hasAudioAccess: false,
    );
  }

  factory PremiumStatus.premium() {
    return const PremiumStatus(
      isPremium: true,
      hasOfflineAccess: true,
      hasAudioAccess: true,
      subscriptionType: 'premium',
    );
  }
}

class PremiumService {
  // Updated contact information to match your requirements
  static const String _whatsappNumber = '60135453900';
  static const String _contactEmail = 'heary_aldy@hotmail.com'; // Updated
  static const String _paypalEmail = 'heary_aldy@hotmail.com';
  static const String _paypalUrl =
      'https://www.paypal.com/paypalme/hearysairin';
  static const double _premiumPrice = 15.00; // RM 15.00

  final AuthorizationService _authService = AuthorizationService();
  final FirebaseService _firebaseService = FirebaseService();

  /// Check if current user has premium access
  Future<bool> isPremium() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Check both role-based and isPremium boolean field
      final userRole = await _authService.getCurrentUserRole();

      // Admin and super admin always have premium access
      if (userRole == UserRole.admin || userRole == UserRole.superAdmin) {
        return true;
      }

      // Check for premium role
      if (userRole == UserRole.premium) {
        return true;
      }

      // Check isPremium boolean field in database
      final database = FirebaseDatabase.instance;
      final userRef = database.ref('users/${currentUser.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final isPremiumFlag = userData['isPremium'] as bool?;
        debugPrint(
            '[PremiumService] 🔍 User data: role=${userData['role']}, isPremium=$isPremiumFlag');
        return isPremiumFlag == true;
      }

      return false;
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error checking premium status: $e');
      return false;
    }
  }

  /// Get detailed premium status
  Future<PremiumStatus> getPremiumStatus() async {
    try {
      final isPremiumUser = await isPremium();
      if (isPremiumUser) {
        return PremiumStatus.premium();
      } else {
        return PremiumStatus.free();
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error getting premium status: $e');
      return PremiumStatus.free();
    }
  }

  /// Grant temporary premium access for demo purposes
  Future<void> grantTemporaryPremium() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('[PremiumService] 🎁 Granting temporary premium access');
        // In a real app, this would update the user's role in the database
        // For demo purposes, we'll just log it
        await _firebaseService.updateUserRole(currentUser.uid, 'premium');
      }
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error granting temporary premium: $e');
    }
  }

  /// Check if user can access audio features
  Future<bool> canAccessAudio() async {
    try {
      // Premium users can access audio
      final isPremiumUser = await isPremium();
      if (isPremiumUser) return true;

      // Check if user has admin privileges
      final userRole = await _authService.getCurrentUserRole();

      // Allow audio access for admin and superadmin users
      if (userRole == UserRole.admin || userRole == UserRole.superAdmin) {
        debugPrint('[PremiumService] ✅ Admin user - granting audio access');
        return true;
      }

      // Production code: Only premium and admin/superadmin users can access audio
      debugPrint('[PremiumService] 🚫 Non-premium user - audio access denied');
      return false;
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error checking audio access: $e');
      // On error, deny access for security
      return false;
    }
  }

  /// Get premium features list
  List<String> getPremiumFeatures() {
    return [
      '🎵 Unlimited audio playback',
      '🎛️ Advanced player controls',
      '📱 Mini-player with quick access',
      '🖥️ Full-screen player experience',
      '⚙️ Premium audio settings',
      '🎧 High-quality audio streaming',
    ];
  }

  /// Get premium pricing information
  Map<String, dynamic> getPremiumPricing() {
    return {
      'price': _premiumPrice,
      'currency': 'RM',
      'description': 'One-time payment for lifetime premium access',
      'paymentMethods': [
        'QR Code (Banking/eWallet)',
        'PayPal ($_paypalEmail)',
      ],
    };
  }

  /// Handle upgrade flow - Navigate to donation page
  Future<bool> initiateUpgrade() async {
    debugPrint('[PremiumService] 🔧 initiateUpgrade - Opening donation page');

    try {
      // For now, we'll try to open PayPal as fallback
      // In a real app, you would navigate to the donation page using:
      // Navigator.of(context).pushNamed('/donation');

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
      debugPrint('[PremiumService] ❌ Error launching payment: $e');
      return false;
    }
  }

  /// Navigate to receipt upload (integrate with donation page)
  Future<bool> navigateToReceiptUpload() async {
    debugPrint('[PremiumService] 🔧 navigateToReceiptUpload');

    try {
      // This should navigate to your donation page with receipt upload focus
      // For now, we'll redirect to contact admin
      // In a real implementation, you would:
      // 1. Navigate to donation page
      // 2. Scroll to receipt upload section
      // 3. Or open receipt upload dialog

      return await contactAdminForVerification();
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error opening receipt upload: $e');
      return false;
    }
  }

  /// Contact admin for verification with enhanced message
  Future<bool> contactAdminForVerification() async {
    debugPrint('[PremiumService] 🔧 contactAdminForVerification');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email ?? 'unknown';
      final userName = currentUser?.displayName ?? 'User';

      String message = '''
🌟 Premium Upgrade Request - RM ${_premiumPrice.toStringAsFixed(2)}

Hello Admin,

I have completed payment for Premium upgrade and would like to request verification.

👤 User Details:
• Name: $userName
• Email: $userEmail
• User ID: ${currentUser?.uid ?? 'unknown'}
• Date: ${DateTime.now().toString().split('.')[0]}

💰 Payment Information:
• Amount: RM ${_premiumPrice.toStringAsFixed(2)}
• Payment Method: QR Code / PayPal
• PayPal Email: $_paypalEmail

📋 Next Steps:
1. ✅ Payment completed
2. 📧 Payment receipt attached/will be sent
3. ⏳ Awaiting premium activation (within 24 hours)

Please verify my payment and activate my premium account for audio features.

🎵 Premium Features Requested:
${getPremiumFeatures().join('\n')}

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
      final emailSubject =
          'Premium Upgrade Request - RM ${_premiumPrice.toStringAsFixed(2)}';
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

  /// Get contact information for display
  Map<String, String> getContactInfo() {
    return {
      'email': _contactEmail,
      'whatsapp': '+$_whatsappNumber',
      'whatsappFormatted': '013-545-3900',
      'paypalEmail': _paypalEmail,
    };
  }

  /// Get upgrade instructions for UI
  Map<String, dynamic> getUpgradeInstructions() {
    return {
      'title': 'Premium Upgrade - RM ${_premiumPrice.toStringAsFixed(2)}',
      'steps': [
        'Click "Go to Payment" to open donation page',
        'Choose: Scan QR Code OR use PayPal',
        'Complete payment (RM ${_premiumPrice.toStringAsFixed(2)})',
        'Send payment receipt to admin',
        'Premium access activated within 24 hours',
      ],
      'paymentOptions': [
        '📱 QR Code (Banking/eWallet apps)',
        '💳 PayPal ($_paypalEmail)',
      ],
      'contactInfo': getContactInfo(),
      'features': getPremiumFeatures(),
    };
  }

  /// Admin helpers
  Future<bool> assignPremiumToUser(String userId) async {
    try {
      debugPrint('[PremiumService] 🔧 Assigning premium to user: $userId');
      return await _firebaseService.updateUserRole(userId, 'premium');
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error assigning premium: $e');
      return false;
    }
  }

  Future<bool> removePremiumFromUser(String userId) async {
    try {
      debugPrint('[PremiumService] 🔧 Removing premium from user: $userId');
      return await _firebaseService.updateUserRole(userId, 'user');
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error removing premium: $e');
      return false;
    }
  }

  /// Get premium statistics for admin dashboard
  Future<Map<String, dynamic>> getPremiumStatistics() async {
    try {
      // This would query your database for actual statistics
      // For now, returning placeholder data
      return {
        'totalPremiumUsers': 0,
        'pendingVerifications': 0,
        'totalRevenue': 0.0,
        'averageUpgradeTime': '18 hours',
        'conversionRate': 0.0,
      };
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error getting statistics: $e');
      return {};
    }
  }

  /// Force refresh premium status
  Future<void> refreshPremiumStatus() async {
    debugPrint('[PremiumService] 🔧 Refreshing premium status');
    try {
      await _authService.forceRefreshCurrentUserRole();
    } catch (e) {
      debugPrint('[PremiumService] ❌ Error refreshing status: $e');
    }
  }
}
