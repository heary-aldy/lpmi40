// lib/src/features/premium/presentation/premium_upgrade_dialog.dart
// Premium upgrade dialog for audio access

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
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
      final success = await _premiumService.initiateUpgrade();

      if (success) {
        // Show success message and close dialog
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage();
        }
      } else {
        // Show error message
        if (mounted) {
          _showErrorMessage('Unable to open payment page. Please try again.');
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

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Payment page opened. Complete your payment and contact admin for verification.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
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
                  'Contact app opened. Send your payment confirmation to admin.'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
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
                    // Custom message or default message
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.customMessage ??
                            'Upgrade to Premium to access ${_getFeatureTitle().toLowerCase()} and enjoy unlimited audio features!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize:
                              (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                                  scale,
                        ),
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

                    ...(_premiumService
                        .getPremiumFeatures()
                        .map(
                          (feature) => Padding(
                            padding: EdgeInsets.only(bottom: spacing * 0.25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: spacing * 0.25),
                                  width: 6 * scale,
                                  height: 6 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: spacing * 0.5),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: (theme.textTheme.bodyMedium
                                                  ?.fontSize ??
                                              14) *
                                          scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList()),

                    SizedBox(height: spacing * 1.5),

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
                              Text(
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
                            ],
                          ),
                          SizedBox(height: spacing * 0.5),
                          Text(
                            '1. Click "Upgrade Now" to proceed to payment\n'
                            '2. Complete your payment securely\n'
                            '3. Contact admin with payment confirmation\n'
                            '4. Premium access activated within 24 hours',
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

                // Upgrade now button
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
                            Icon(Icons.star, size: 16 * scale),
                            SizedBox(width: spacing * 0.25),
                            Text(
                              'Upgrade Now',
                              style: TextStyle(
                                fontSize: 14 * scale,
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
            'Upgrade to Premium to enjoy unlimited audio playback with high-quality sound!',
      ),
    );
  }

  static Future<void> showMiniPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'mini_player',
        customMessage:
            'Upgrade to Premium to access the convenient mini-player with quick controls!',
      ),
    );
  }

  static Future<void> showFullScreenPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'full_screen_player',
        customMessage:
            'Upgrade to Premium to enjoy the immersive full-screen player experience!',
      ),
    );
  }

  static Future<void> showAudioControlsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_controls',
        customMessage:
            'Upgrade to Premium to access advanced audio controls including seek, loop, and more!',
      ),
    );
  }

  static Future<void> showPlayerSettingsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'player_settings',
        customMessage:
            'Upgrade to Premium to customize your audio experience with premium player settings!',
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
        customMessage: customMessage,
      ),
    );
  }
}
