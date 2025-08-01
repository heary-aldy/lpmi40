// lib/src/features/premium/presentation/premium_audio_gate.dart
// ✅ ENHANCED: Added dismissible banner with close button and compact indicator
// ✅ USER CONTROL: Users can dismiss the banner and restore it via compact chip

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/utils/constants.dart';

/// A widget that gates premium audio features and shows upgrade prompts for non-premium users
class PremiumAudioGate extends StatefulWidget {
  final Widget child;
  final String feature;
  final String? upgradeMessage;
  final bool showUpgradeButton;
  final bool showUpgradeHint;
  final VoidCallback? onUpgradePressed;

  const PremiumAudioGate({
    super.key,
    required this.child,
    required this.feature,
    this.upgradeMessage,
    this.showUpgradeButton = true,
    this.showUpgradeHint = false,
    this.onUpgradePressed,
  });

  @override
  State<PremiumAudioGate> createState() => _PremiumAudioGateState();
}

class _PremiumAudioGateState extends State<PremiumAudioGate>
    with TickerProviderStateMixin {
  final PremiumService _premiumService = PremiumService();

  bool _isPremium = false;
  bool _isLoading = true;
  bool _isDismissed = false; // ✅ NEW: Track dismiss state

  // ✅ NEW: Animation controllers for smooth transitions
  late AnimationController _bannerAnimationController;
  late AnimationController _chipAnimationController;
  late Animation<double> _bannerSlideAnimation;
  late Animation<double> _chipScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    _chipAnimationController.dispose();
    super.dispose();
  }

  // ✅ NEW: Setup smooth animations
  void _setupAnimations() {
    _bannerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bannerSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.easeInOut,
    ));

    _chipScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chipAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NEW: Dismiss banner with animation
  Future<void> _dismissBanner() async {
    await _bannerAnimationController.forward();
    if (mounted) {
      setState(() {
        _isDismissed = true;
      });
      await _chipAnimationController.forward();
    }
  }

  // ✅ NEW: Restore banner with animation
  Future<void> _restoreBanner() async {
    await _chipAnimationController.reverse();
    if (mounted) {
      setState(() {
        _isDismissed = false;
      });
      await _bannerAnimationController.reverse();
    }
  }

  Future<void> _showUpgradeDialog() async {
    if (widget.onUpgradePressed != null) {
      widget.onUpgradePressed!();
      return;
    }

    await PremiumUpgradeDialogs.showFullUpgradePage(
      context,
      feature: widget.feature,
    );

    // Refresh premium status after potential upgrade
    await _checkPremiumStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isPremium) {
      return widget.child;
    }

    // ✅ NEW: Show compact chip if dismissed, full banner if not
    return _isDismissed ? _buildCompactIndicator() : _buildDismissibleBanner();
  }

  // ✅ NEW: Compact indicator when banner is dismissed
  Widget _buildCompactIndicator() {
    return ScaleTransition(
      scale: _chipScaleAnimation,
      child: Center(
        child: GestureDetector(
          onTap: _restoreBanner,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.purple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Premium Required',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.purple,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ENHANCED: Banner with close button and animations
  Widget _buildDismissibleBanner() {
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final theme = Theme.of(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1),
      ).animate(_bannerSlideAnimation),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width * 0.8;

          return Container(
            width: availableWidth,
            constraints: BoxConstraints(
              maxWidth: availableWidth,
              minWidth: 200,
            ),
            padding: EdgeInsets.all(spacing),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.indigo.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ NEW: Header with close button
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.purple,
                      size: 20 * scale,
                    ),
                    SizedBox(width: spacing * 0.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Premium Feature',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12 * scale,
                            ),
                          ),
                          Text(
                            'Audio Access Required',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.purple.shade700,
                              fontSize: 10 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ NEW: Close button
                    GestureDetector(
                      onTap: _dismissBanner,
                      child: Container(
                        padding: EdgeInsets.all(spacing * 0.25),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16 * scale,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: spacing * 0.75),

                // Upgrade message
                Text(
                  widget.upgradeMessage ??
                      'Upgrade to Premium to access audio features!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.8),
                    fontSize: 11 * scale,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                if (widget.showUpgradeButton) ...[
                  SizedBox(height: spacing),

                  // Upgrade button
                  SizedBox(
                    width: availableWidth - (spacing * 2),
                    child: ElevatedButton(
                      onPressed: _showUpgradeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: spacing * 0.5,
                          horizontal: spacing * 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 14 * scale),
                          SizedBox(width: spacing * 0.25),
                          Text(
                            'Upgrade',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (widget.showUpgradeHint && !widget.showUpgradeButton) ...[
                  SizedBox(height: spacing * 0.5),

                  // Upgrade hint
                  GestureDetector(
                    onTap: _showUpgradeDialog,
                    child: Container(
                      width: availableWidth - (spacing * 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing * 0.5,
                        vertical: spacing * 0.25,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12 * scale,
                            color: Colors.purple,
                          ),
                          SizedBox(width: spacing * 0.25),
                          Text(
                            'Tap to upgrade',
                            style: TextStyle(
                              fontSize: 10 * scale,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ✅ Specialized audio gate widgets for common use cases (unchanged)
class AudioPlaybackGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const AudioPlaybackGate({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumAudioGate(
      feature: 'audio_playback',
      upgradeMessage: 'Upgrade to Premium to enjoy unlimited audio playback!',
      onUpgradePressed: onUpgradePressed,
      child: child,
    );
  }
}

class MiniPlayerGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const MiniPlayerGate({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumAudioGate(
      feature: 'mini_player',
      upgradeMessage: 'Upgrade to Premium to access the mini-player!',
      onUpgradePressed: onUpgradePressed,
      child: child,
    );
  }
}

class AudioControlsGate extends StatelessWidget {
  final Widget child;
  final bool showUpgradeButton;
  final bool showUpgradeHint;
  final VoidCallback? onUpgradePressed;

  const AudioControlsGate({
    super.key,
    required this.child,
    this.showUpgradeButton = true,
    this.showUpgradeHint = false,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumAudioGate(
      feature: 'audio_controls',
      upgradeMessage: 'Upgrade to Premium to access advanced audio controls!',
      showUpgradeButton: showUpgradeButton,
      showUpgradeHint: showUpgradeHint,
      onUpgradePressed: onUpgradePressed,
      child: child,
    );
  }
}

class FullScreenPlayerGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const FullScreenPlayerGate({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumAudioGate(
      feature: 'full_screen_player',
      upgradeMessage: 'Upgrade to Premium to enjoy the full-screen player!',
      onUpgradePressed: onUpgradePressed,
      child: child,
    );
  }
}

class PremiumAudioButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String feature;
  final Color? color;
  final double? size;
  final bool enabled;

  const PremiumAudioButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.feature,
    this.color,
    this.size,
    this.enabled = true,
  });

  @override
  State<PremiumAudioButton> createState() => _PremiumAudioButtonState();
}

class _PremiumAudioButtonState extends State<PremiumAudioButton> {
  final PremiumService _premiumService = PremiumService();

  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await _premiumService.isPremium();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    await PremiumUpgradeDialogs.showFullUpgradePage(
      context,
      feature: widget.feature,
    );

    await _checkPremiumStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size ?? 24,
        height: widget.size ?? 24,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isPremium) {
      return IconButton(
        icon: Icon(widget.icon),
        onPressed: widget.enabled ? widget.onPressed : null,
        tooltip: widget.tooltip,
        color: widget.color,
        iconSize: widget.size,
      );
    }

    return IconButton(
      icon: const Icon(Icons.star_outline),
      onPressed: _showUpgradeDialog,
      tooltip: 'Upgrade to Premium',
      color: Colors.orange,
      iconSize: widget.size,
    );
  }
}

class CompactPremiumGate extends StatelessWidget {
  final Widget child;
  final String feature;

  const CompactPremiumGate({
    super.key,
    required this.child,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumAudioGate(
      feature: feature,
      showUpgradeButton: false,
      showUpgradeHint: true,
      child: child,
    );
  }
}
