// lib/src/features/premium/presentation/premium_audio_gate.dart
// Premium access gate for audio features - blocks non-premium users

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/premium/presentation/premium_upgrade_dialog.dart';

class PremiumAudioGate extends StatefulWidget {
  final Widget child;
  final String feature;
  final Widget? fallbackWidget;
  final bool showUpgradeButton;
  final String? customUpgradeMessage;

  const PremiumAudioGate({
    super.key,
    required this.child,
    required this.feature,
    this.fallbackWidget,
    this.showUpgradeButton = true,
    this.customUpgradeMessage,
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
        customMessage: widget.customUpgradeMessage,
      ),
    );
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

    // If user is premium, show the actual content
    if (_isPremium) {
      return widget.child;
    }

    // If user is not premium, show fallback or upgrade prompt
    if (widget.fallbackWidget != null) {
      return widget.fallbackWidget!;
    }

    // Default upgrade prompt
    return widget.showUpgradeButton
        ? _buildUpgradePrompt()
        : const SizedBox.shrink();
  }

  Widget _buildUpgradePrompt() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Required',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.customUpgradeMessage ??
                'Upgrade to Premium to access ${_getFeatureName()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showUpgradeDialog,
              icon: const Icon(Icons.star, size: 16),
              label: const Text(
                'Upgrade Now',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureName() {
    switch (widget.feature) {
      case 'audio_playback':
        return 'audio playback';
      case 'mini_player':
        return 'mini player';
      case 'full_screen_player':
        return 'full screen player';
      case 'audio_controls':
        return 'audio controls';
      case 'player_settings':
        return 'player settings';
      default:
        return 'this feature';
    }
  }
}

// Convenience wrapper for quick premium checks in UI
class PremiumFeatureWrapper extends StatelessWidget {
  final Widget premiumChild;
  final Widget? freeChild;
  final String feature;
  final bool showUpgradePrompt;

  const PremiumFeatureWrapper({
    super.key,
    required this.premiumChild,
    required this.feature,
    this.freeChild,
    this.showUpgradePrompt = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PremiumService().isPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final isPremium = snapshot.data ?? false;

        if (isPremium) {
          return premiumChild;
        }

        if (freeChild != null) {
          return freeChild!;
        }

        return showUpgradePrompt
            ? PremiumAudioGate(
                feature: feature,
                child: premiumChild,
              )
            : const SizedBox.shrink();
      },
    );
  }
}
