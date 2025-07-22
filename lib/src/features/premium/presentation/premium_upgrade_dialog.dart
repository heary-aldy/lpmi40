// lib/src/features/premium/presentation/premium_upgrade_dialog.dart
// Premium upgrade dialog for audio access

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';
import 'package:lpmi40/utils/constants.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  final String feature;
  final String? customMessage;
  final VoidCallback? onUpgradeComplete;

  const PremiumUpgradeDialog({
    super.key,
    required this.feature,
    this.customMessage,
    this.onUpgradeComplete,
  });

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog>
    with SingleTickerProviderStateMixin {
  final PremiumService _premiumService = PremiumService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to donation page for payment
      if (mounted) {
        Navigator.of(context).pop(); // Close the premium dialog
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DonationPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Unable to open payment page. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUploadReceipt() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Close dialog first
      Navigator.of(context).pop();

      // Navigate to donation page with receipt upload focus
      // This would need to be implemented based on your navigation structure
      final success = await _premiumService.navigateToReceiptUpload();

      if (success) {
        if (mounted) {
          _showReceiptUploadMessage();
        }
      } else {
        if (mounted) {
          _showErrorMessage(
              'Unable to open receipt upload. Please contact admin directly.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showReceiptUploadMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.upload_file, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Upload your payment receipt (RM 15.00) for premium verification.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleContactAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _premiumService.contactAdminForVerification();

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          _showContactSuccessMessage();
        }
      } else {
        if (mounted) {
          _showErrorMessage(
              'Unable to open contact app. Please contact admin manually.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showContactSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.message, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Contact app opened. Send your payment receipt (RM 15.00) to admin for verification.'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getFeatureTitle() {
    switch (widget.feature) {
      case 'audio_playback':
        return 'Audio Playback';
      case 'mini_player':
        return 'Mini Player';
      case 'full_screen_player':
        return 'Full Screen Player';
      case 'audio_controls':
        return 'Audio Controls';
      case 'player_settings':
        return 'Player Settings';
      default:
        return 'Premium Feature';
    }
  }

  IconData _getFeatureIcon() {
    switch (widget.feature) {
      case 'audio_playback':
        return Icons.play_circle_fill;
      case 'mini_player':
        return Icons.music_note;
      case 'full_screen_player':
        return Icons.fullscreen;
      case 'audio_controls':
        return Icons.control_point;
      case 'player_settings':
        return Icons.settings;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing * 0.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFeatureIcon(),
                      color: Colors.white,
                      size: 24 * scale,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Required',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                (theme.textTheme.titleLarge?.fontSize ?? 22) *
                                    scale,
                          ),
                        ),
                        Text(
                          'For ${_getFeatureTitle()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                            fontSize:
                                (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                                    scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium price and custom message
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.15),
                            Colors.purple.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Premium price banner - Enhanced visibility
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing,
                              vertical: spacing * 0.75,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade600,
                                  Colors.purple.shade800
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.yellow.shade300,
                                      size: 24 * scale,
                                    ),
                                    SizedBox(width: spacing * 0.25),
                                    Flexible(
                                      child: Text(
                                        'Premium Access',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: (theme.textTheme.titleLarge
                                                      ?.fontSize ??
                                                  20) *
                                              scale,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: spacing * 0.25),
                                    Icon(
                                      Icons.star,
                                      color: Colors.yellow.shade300,
                                      size: 24 * scale,
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing * 0.5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing * 0.75,
                                    vertical: spacing * 0.25,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'RM 15.00',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: (theme.textTheme.headlineSmall
                                                  ?.fontSize ??
                                              24) *
                                          scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spacing),

                          // Custom message or default message
                          Text(
                            widget.customMessage ??
                                'Upgrade to Premium to access ${_getFeatureTitle().toLowerCase()} and enjoy unlimited audio features!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize:
                                  (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                                      scale,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing * 1.5),

                    // Premium features list
                    Text(
                      'Premium Features:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 16) *
                                scale,
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    Column(
                        children: [
                      '🎵 Unlimited audio playback',
                      '🎛️ Advanced player controls',
                      '📱 Mini-player with quick access',
                      '🖥️ Full-screen player experience',
                      '⚙️ Premium audio settings',
                      '🎧 High-quality audio streaming',
                    ]
                            .map((feature) => Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: spacing * 0.25),
                                  child: Row(
                                    children: [
                                      Text(
                                        feature.split(' ')[0],
                                        style: TextStyle(fontSize: 16 * scale),
                                      ),
                                      SizedBox(width: spacing * 0.5),
                                      Expanded(
                                        child: Text(
                                          feature.split(' ').skip(1).join(' '),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: (theme.textTheme.bodySmall
                                                        ?.fontSize ??
                                                    14) *
                                                scale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList()),

                    SizedBox(height: spacing * 1.5),

                    // Payment options
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: Colors.green,
                                size: 16 * scale,
                              ),
                              SizedBox(width: spacing * 0.5),
                              Flexible(
                                child: Text(
                                  'Payment Options:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize:
                                        (theme.textTheme.titleSmall?.fontSize ??
                                                12) *
                                            scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 0.5),
                          Text(
                            '📱 Option 1: Scan QR Code (Banking/eWallet)\n'
                            '💳 Option 2: PayPal (heary_aldy@hotmail.com)\n'
                            '💰 Amount: RM 15.00',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontSize:
                                  (theme.textTheme.bodySmall?.fontSize ?? 12) *
                                      scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Upgrade instructions
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue,
                                size: 16 * scale,
                              ),
                              SizedBox(width: spacing * 0.5),
                              Flexible(
                                child: Text(
                                  'How to Upgrade:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize:
                                        (theme.textTheme.titleSmall?.fontSize ??
                                                12) *
                                            scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 0.5),
                          Text(
                            '1. Click "Upgrade Now" to open donation page\n'
                            '2. Choose: Scan QR Code OR use PayPal\n'
                            '3. Complete payment (RM 15.00)\n'
                            '4. Send payment receipt to admin\n'
                            '5. Premium access activated within 24 hours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                              fontSize:
                                  (theme.textTheme.bodySmall?.fontSize ?? 12) *
                                      scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Contact information
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_support,
                                color: Colors.orange,
                                size: 16 * scale,
                              ),
                              SizedBox(width: spacing * 0.5),
                              Flexible(
                                child: Text(
                                  'Send Payment Receipt To:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize:
                                        (theme.textTheme.titleSmall?.fontSize ??
                                                12) *
                                            scale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 0.5),
                          Text(
                            '📧 Email: heary_aldy@hotmail.com\n'
                            '📱 WhatsApp: 013-545-3900\n'
                            '💳 PayPal: heary_aldy@hotmail.com\n'
                            '⏱️ Response: Within 24 hours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontSize:
                                  (theme.textTheme.bodySmall?.fontSize ?? 12) *
                                      scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),

                // Upload receipt button
                TextButton(
                  onPressed: _isLoading ? null : _handleUploadReceipt,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file, size: 16 * scale),
                      SizedBox(width: spacing * 0.25),
                      Text(
                        'Upload Receipt',
                        style: TextStyle(fontSize: 14 * scale),
                      ),
                    ],
                  ),
                ),

                // Contact admin button
                TextButton(
                  onPressed: _isLoading ? null : _handleContactAdmin,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16 * scale,
                          height: 16 * scale,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.message, size: 16 * scale),
                            SizedBox(width: spacing * 0.25),
                            Text(
                              'Contact Admin',
                              style: TextStyle(fontSize: 14 * scale),
                            ),
                          ],
                        ),
                ),

                // Go to payment button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing * 1.5,
                      vertical: spacing * 0.75,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16 * scale,
                          height: 16 * scale,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payment, size: 18 * scale),
                            SizedBox(width: spacing * 0.5),
                            Text(
                              'Pay RM 15.00 Now',
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Convenience methods for showing upgrade dialogs
class PremiumUpgradeDialogs {
  static Future<void> showAudioPlaybackUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_playback',
        customMessage:
            'Upgrade to Premium (RM 15.00) to enjoy unlimited audio playback with high-quality sound!',
      ),
    );
  }

  static Future<void> showMiniPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'mini_player',
        customMessage:
            'Upgrade to Premium (RM 15.00) to access the convenient mini-player with quick controls!',
      ),
    );
  }

  static Future<void> showFullScreenPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'full_screen_player',
        customMessage:
            'Upgrade to Premium (RM 15.00) to enjoy the immersive full-screen player experience!',
      ),
    );
  }

  static Future<void> showAudioControlsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_controls',
        customMessage:
            'Upgrade to Premium (RM 15.00) to access advanced audio controls including seek, loop, and more!',
      ),
    );
  }

  static Future<void> showPlayerSettingsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'player_settings',
        customMessage:
            'Upgrade to Premium (RM 15.00) to customize your audio experience with premium player settings!',
      ),
    );
  }

  static Future<void> showGenericUpgrade(
    BuildContext context, {
    String? feature,
    String? customMessage,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: feature ?? 'premium_feature',
        customMessage: customMessage ??
            'Upgrade to Premium (RM 15.00) to unlock all audio features and enhance your experience!',
      ),
    );
  }
}
