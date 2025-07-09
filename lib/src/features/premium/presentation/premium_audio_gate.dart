// lib/src/features/premium/presentation/premium_audio_gate.dart
// Premium audio gate component for controlling access to audio features

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';
import 'package:lpmi40/utils/constants.dart';

class PremiumAudioGate extends StatefulWidget {
  final Widget child;
  final Widget? premiumChild;
  final String feature;
  final String? upgradeMessage;
  final VoidCallback? onUpgradePressed;
  final bool showUpgradeButton;
  final bool showUpgradeHint;

  const PremiumAudioGate({
    super.key,
    required this.child,
    this.premiumChild,
    required this.feature,
    this.upgradeMessage,
    this.onUpgradePressed,
    this.showUpgradeButton = true,
    this.showUpgradeHint = false,
  });

  @override
  State<PremiumAudioGate> createState() => _PremiumAudioGateState();
}

class _PremiumAudioGateState extends State<PremiumAudioGate> {
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
      final canAccess = await _premiumService.canAccessAudio();
      if (mounted) {
        setState(() {
          _isPremium = canAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    if (widget.onUpgradePressed != null) {
      widget.onUpgradePressed!();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: widget.feature,
        customMessage: widget.upgradeMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_isPremium) {
      return widget.premiumChild ?? widget.child;
    }

    return _buildUpgradePrompt();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    final theme = Theme.of(context);
    final deviceType = AppConstants.getDeviceTypeFromContext(context);
    final scale = AppConstants.getTypographyScale(deviceType);
    final spacing = AppConstants.getSpacing(deviceType);

    if (!widget.showUpgradeButton && !widget.showUpgradeHint) {
      // Just show disabled version of the original widget
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(
          child: widget.child,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
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
          // Premium icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing * 0.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 20 * scale,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Feature',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 16) *
                                scale,
                      ),
                    ),
                    Text(
                      'Audio Access Required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade700,
                        fontSize:
                            (theme.textTheme.bodySmall?.fontSize ?? 12) * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: spacing),

          // Upgrade message
          Text(
            widget.upgradeMessage ??
                'Upgrade to Premium to access audio features and enjoy unlimited song playback!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.showUpgradeButton) ...[
            SizedBox(height: spacing * 1.5),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showUpgradeDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: spacing * 0.75,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16 * scale),
                    SizedBox(width: spacing * 0.5),
                    Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (widget.showUpgradeHint && !widget.showUpgradeButton) ...[
            SizedBox(height: spacing),

            // Upgrade hint
            GestureDetector(
              onTap: _showUpgradeDialog,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing,
                  vertical: spacing * 0.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14 * scale,
                      color: Colors.purple,
                    ),
                    SizedBox(width: spacing * 0.25),
                    Text(
                      'Tap to upgrade',
                      style: TextStyle(
                        fontSize: 12 * scale,
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
  }
}

// Specialized audio gate widgets for common use cases
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
      upgradeMessage:
          'Upgrade to Premium to enjoy unlimited audio playback with high-quality sound!',
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
      upgradeMessage:
          'Upgrade to Premium to access the convenient mini-player with quick controls!',
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
      upgradeMessage:
          'Upgrade to Premium to access advanced audio controls including seek, loop, and more!',
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
      upgradeMessage:
          'Upgrade to Premium to enjoy the immersive full-screen player experience!',
      onUpgradePressed: onUpgradePressed,
      child: child,
    );
  }
}

// Premium button wrapper that shows upgrade prompt when tapped
class PremiumAudioButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String feature;
  final Color? color;
  final double? size;

  const PremiumAudioButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.feature,
    this.color,
    this.size,
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
      final canAccess = await _premiumService.canAccessAudio();
      if (mounted) {
        setState(() {
          _isPremium = canAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: widget.feature,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size ?? 24,
        height: widget.size ?? 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color ?? Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return IconButton(
      icon: Stack(
        children: [
          Icon(
            widget.icon,
            color: _isPremium
                ? widget.color
                : (widget.color ?? Theme.of(context).primaryColor)
                    .withOpacity(0.5),
            size: widget.size,
          ),
          if (!_isPremium)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: _isPremium ? widget.onPressed : _showUpgradeDialog,
      tooltip:
          _isPremium ? widget.tooltip : 'Premium Required - ${widget.tooltip}',
    );
  }
}

// Premium floating action button
class PremiumFloatingActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String feature;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const PremiumFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.feature,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  State<PremiumFloatingActionButton> createState() =>
      _PremiumFloatingActionButtonState();
}

class _PremiumFloatingActionButtonState
    extends State<PremiumFloatingActionButton> {
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
      final canAccess = await _premiumService.canAccessAudio();
      if (mounted) {
        setState(() {
          _isPremium = canAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        feature: widget.feature,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: widget.backgroundColor,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: _isPremium ? widget.onPressed : _showUpgradeDialog,
      backgroundColor: _isPremium
          ? widget.backgroundColor
          : (widget.backgroundColor ?? Theme.of(context).primaryColor)
              .withOpacity(0.7),
      foregroundColor: widget.foregroundColor,
      tooltip: _isPremium ? widget.tooltip : 'Premium Required',
      child: Stack(
        children: [
          Icon(widget.icon),
          if (!_isPremium)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.star,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
