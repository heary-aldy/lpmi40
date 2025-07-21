// lib/src/features/premium/presentation/premium_upgrade_dialog.dart
// ✅ FIXED: Properly centered modal with close button and no overlap

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
        return 'Audio Settings';
      default:
        return 'Premium Feature';
    }
  }

  String _getFeatureDescription() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }

    switch (widget.feature) {
      case 'audio_playback':
        return 'Enjoy high-quality audio playback for all songs with premium access!';
      case 'mini_player':
        return 'Access the convenient mini-player with quick controls!';
      case 'full_screen_player':
        return 'Experience the immersive full-screen player!';
      case 'audio_controls':
        return 'Get advanced audio controls and settings!';
      case 'player_settings':
        return 'Customize your audio experience with premium settings!';
      default:
        return 'Upgrade to Premium to access this feature!';
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
        return Icons.tune;
      case 'player_settings':
        return Icons.settings;
      default:
        return Icons.star;
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate upgrade process
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
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
    Navigator.of(context).pop();
    _showContactAdminMessage();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Premium upgrade initiated! Contact admin to complete.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showContactAdminMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact admin at: admin@haweeincorporation.com'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Copy',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Copy email to clipboard
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        return Material(
          type: MaterialType.transparency,
          child: Container(
            // ✅ FIXED: Full screen overlay with proper backdrop
            width: double.infinity,
            height: double.infinity,
            color: Colors.black
                .withValues(alpha: 0.5), // Semi-transparent backdrop
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    // ✅ FIXED: Constrained width and proper margins
                    margin: EdgeInsets.symmetric(horizontal: spacing * 2),
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dialogBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ NEW: Header with close button
                        Container(
                          padding: EdgeInsets.all(spacing),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Premium icon
                              Container(
                                padding: EdgeInsets.all(spacing * 0.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getFeatureIcon(),
                                  color: Colors.white,
                                  size: 24 * scale,
                                ),
                              ),
                              SizedBox(width: spacing),

                              // Title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Premium Required',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18 * scale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _getFeatureTitle(),
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14 * scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ✅ NEW: Close button
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24 * scale,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  padding: EdgeInsets.all(spacing * 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ FIXED: Content with proper spacing
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(spacing * 1.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Feature description
                                Text(
                                  _getFeatureDescription(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 16 * scale,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: spacing * 1.5),

                                // Premium features list
                                Container(
                                  padding: EdgeInsets.all(spacing),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Colors.purple.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.purple,
                                            size: 20 * scale,
                                          ),
                                          SizedBox(width: spacing * 0.5),
                                          Text(
                                            'Premium Features:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16 * scale,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing * 0.75),
                                      ...[
                                        '🎵 High-quality audio playback',
                                        '🎛️ Advanced audio controls',
                                        '📱 Mini-player & full-screen modes',
                                        '⚙️ Customizable audio settings',
                                        '❤️ Enhanced favorites management',
                                        '🔄 Background audio playback',
                                      ].map((feature) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: spacing * 0.5,
                                            ),
                                            child: Text(
                                              feature,
                                              style: TextStyle(
                                                fontSize: 14 * scale,
                                                height: 1.3,
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ),

                                SizedBox(height: spacing * 1.5),

                                // Contact info
                                Container(
                                  padding: EdgeInsets.all(spacing),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue,
                                            size: 16 * scale,
                                          ),
                                          SizedBox(width: spacing * 0.5),
                                          Text(
                                            'How to upgrade:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14 * scale,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing * 0.5),
                                      Text(
                                        'Contact admin for premium access:\nadmin@haweeincorporation.com',
                                        style: TextStyle(
                                          fontSize: 13 * scale,
                                          color: Colors.blue.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ✅ FIXED: Action buttons with proper spacing
                        Container(
                          padding: EdgeInsets.all(spacing * 1.5),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Primary upgrade button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleUpgrade,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: spacing * 0.75,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20 * scale,
                                          width: 20 * scale,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.star, size: 20 * scale),
                                            SizedBox(width: spacing * 0.5),
                                            Text(
                                              'Upgrade to Premium',
                                              style: TextStyle(
                                                fontSize: 16 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              SizedBox(height: spacing * 0.75),

                              // Secondary contact button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed:
                                      _isLoading ? null : _handleContactAdmin,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: BorderSide(color: Colors.blue),
                                    padding: EdgeInsets.symmetric(
                                      vertical: spacing * 0.75,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.email_outlined,
                                          size: 18 * scale),
                                      SizedBox(width: spacing * 0.5),
                                      Text(
                                        'Contact Admin',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ IMPROVED: Helper methods for showing specific upgrade dialogs
class PremiumUpgradeDialogs {
  static Future<void> showAudioPlaybackUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_playback',
      ),
    );
  }

  static Future<void> showMiniPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'mini_player',
      ),
    );
  }

  static Future<void> showFullScreenPlayerUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'full_screen_player',
      ),
    );
  }

  static Future<void> showAudioControlsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'audio_controls',
      ),
    );
  }

  static Future<void> showPlayerSettingsUpgrade(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PremiumUpgradeDialog(
        feature: 'player_settings',
      ),
    );
  }
}
