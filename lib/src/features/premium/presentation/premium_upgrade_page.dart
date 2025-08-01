// lib/src/features/premium/presentation/premium_upgrade_page.dart
// Clean and user-friendly premium upgrade page

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';
import 'package:lpmi40/utils/constants.dart';

class PremiumUpgradePage extends StatefulWidget {
  final String feature;
  final String? customMessage;
  final VoidCallback? onUpgradeComplete;

  const PremiumUpgradePage({
    super.key,
    required this.feature,
    this.customMessage,
    this.onUpgradeComplete,
  });

  @override
  State<PremiumUpgradePage> createState() => _PremiumUpgradePageState();
}

class _PremiumUpgradePageState extends State<PremiumUpgradePage>
    with SingleTickerProviderStateMixin {
  final PremiumService _premiumService = PremiumService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

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

  Future<void> _handleContactAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _premiumService.contactAdminForVerification();

      if (success) {
        if (mounted) {
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

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Premium Header
            SliverAppBar(
              expandedHeight: 200.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Premium Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20 * scale,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade600,
                        Colors.purple.shade800,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.star,
                          size: 80 * scale,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(spacing * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature highlight
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(spacing * 1.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.1),
                            Colors.purple.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(spacing),
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
                                  size: 32 * scale,
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unlock ${_getFeatureTitle()}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: (theme.textTheme.titleLarge
                                                    ?.fontSize ??
                                                22) *
                                            scale,
                                      ),
                                    ),
                                    SizedBox(height: spacing * 0.25),
                                    Text(
                                      widget.customMessage ??
                                          'Upgrade to Premium to access ${_getFeatureTitle().toLowerCase()} and enjoy unlimited features!',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontSize: (theme.textTheme.bodyMedium
                                                    ?.fontSize ??
                                                14) *
                                            scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 1.5),
                          
                          // Premium price banner
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(spacing * 1.5),
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
                                      size: 24,
                                    ),
                                    SizedBox(width: spacing * 0.25),
                                    Flexible(
                                      child: Text(
                                        'Premium Access',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: spacing * 0.25),
                                    Icon(
                                      Icons.star,
                                      color: Colors.yellow.shade300,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing,
                                    vertical: spacing * 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'RM 15.00',
                                    style: TextStyle(
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28 * scale,
                                    ),
                                  ),
                                ),
                                SizedBox(height: spacing * 0.5),
                                Text(
                                  'One-time payment for lifetime access',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14 * scale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing * 2),

                    // Premium features
                    Text(
                      'All Premium Features:',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) *
                            scale,
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Features list
                    Column(
                      children: [
                        '📖 Unlimited Bible features',
                        '🔍 Advanced Bible search',
                        '🏷️ Unlimited bookmarks & highlights',
                        '🤖 AI Bible chat assistance',
                        '🎵 Unlimited audio playback',
                        '🎛️ Advanced player controls',
                        '📱 Mini-player with quick access',
                        '🖥️ Full-screen player experience',
                        '⚙️ Premium audio settings',
                        '🎧 High-quality audio streaming',
                      ]
                          .map((feature) => Container(
                                width: double.infinity,
                                margin: EdgeInsets.only(bottom: spacing * 0.75),
                                padding: EdgeInsets.all(spacing * 1.2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Emoji
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          feature.split(' ')[0],
                                          style: TextStyle(fontSize: 22 * scale),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing),
                                    // Feature text
                                    Expanded(
                                      child: Text(
                                        feature.split(' ').skip(1).join(' '),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * scale,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing * 0.5),
                                    // Check icon
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18 * scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),

                    SizedBox(height: spacing * 2),

                    // Payment information
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(spacing * 1.5),
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
                                size: 20 * scale,
                              ),
                              SizedBox(width: spacing * 0.5),
                              Text(
                                'How to Upgrade:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: (theme.textTheme.titleMedium
                                              ?.fontSize ??
                                          16) *
                                      scale,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing),
                          Text(
                            '1. Click "Pay Now" to open donation page\n'
                            '2. Choose: Scan QR Code OR use PayPal\n'
                            '3. Complete payment (RM 15.00)\n'
                            '4. Send payment receipt to admin\n'
                            '5. Premium access activated within 24 hours',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                              fontSize:
                                  (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                                      scale,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing * 3),

                    // Action buttons
                    Column(
                      children: [
                        // Main upgrade button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleUpgrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment, size: 24 * scale),
                                      SizedBox(width: spacing * 0.5),
                                      Text(
                                        'Pay RM 15.00 Now',
                                        style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        SizedBox(height: spacing),

                        // Secondary buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleUploadReceipt,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(Icons.upload_file, size: 18 * scale),
                                label: Text(
                                  'Upload Receipt',
                                  style: TextStyle(fontSize: 14 * scale),
                                ),
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleContactAdmin,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(Icons.message, size: 18 * scale),
                                label: Text(
                                  'Contact Admin',
                                  style: TextStyle(fontSize: 14 * scale),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: spacing * 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}