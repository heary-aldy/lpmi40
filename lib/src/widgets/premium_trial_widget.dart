// lib/src/widgets/premium_trial_widget.dart
// 🎯 Premium Trial Widget: User-facing trial activation and status
// ✅ Self-service 1-week premium trial for users
// 🎨 Beautiful UI with trial status and countdown

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/session_manager.dart';

class PremiumTrialWidget extends StatefulWidget {
  final VoidCallback? onTrialActivated;
  final bool showAsCard;
  final bool showStatusOnly;

  const PremiumTrialWidget({
    super.key,
    this.onTrialActivated,
    this.showAsCard = true,
    this.showStatusOnly = false,
  });

  @override
  State<PremiumTrialWidget> createState() => _PremiumTrialWidgetState();
}

class _PremiumTrialWidgetState extends State<PremiumTrialWidget> {
  final SessionManager _sessionManager = SessionManager.instance;
  bool _isLoading = false;
  bool _isEligible = false;
  Map<String, dynamic> _trialInfo = {};

  @override
  void initState() {
    super.initState();
    _loadTrialStatus();
  }

  Future<void> _loadTrialStatus() async {
    setState(() => _isLoading = true);

    try {
      final eligible = await _sessionManager.isTrialEligible();
      final trialInfo = _sessionManager.getTrialInfo();

      setState(() {
        _isEligible = eligible;
        _trialInfo = trialInfo;
      });
    } catch (e) {
      debugPrint('[PremiumTrialWidget] Error loading trial status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startTrial() async {
    if (!_isEligible) return;

    setState(() => _isLoading = true);

    try {
      final trialSession = await _sessionManager.startWeeklyTrial();

      if (trialSession != null) {
        await _loadTrialStatus(); // Refresh status
        widget.onTrialActivated?.call();
        _showSuccessMessage(
            '🎉 Premium trial activated! Enjoy 7 days of premium features.');
      } else {
        _showErrorMessage(
            'Failed to start trial. You may have already used your trial.');
      }
    } catch (e) {
      _showErrorMessage('Error starting trial: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    final hasActiveTrial = _trialInfo['hasActiveTrial'] == true;
    final isTrialExpired = _trialInfo['isTrialExpired'] == true;
    final remainingDays = _trialInfo['remainingTrialDays'] ?? 0;
    final remainingHours = _trialInfo['remainingTrialHours'] ?? 0;

    if (widget.showStatusOnly && !hasActiveTrial) {
      return const SizedBox.shrink(); // Don't show anything if no active trial
    }

    Widget content;

    if (hasActiveTrial) {
      content = _buildActiveTrialWidget(remainingDays, remainingHours);
    } else if (isTrialExpired) {
      content = _buildExpiredTrialWidget();
    } else if (_isEligible) {
      content = _buildTrialOfferWidget();
    } else {
      content = _buildTrialUsedWidget();
    }

    return widget.showAsCard ? _wrapInCard(content) : content;
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildActiveTrialWidget(int remainingDays, int remainingHours) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Premium Trial Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Countdown display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  remainingDays > 0
                      ? '$remainingDays days remaining'
                      : '$remainingHours hours remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            '✨ You have access to all premium features including audio playback and exclusive content.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredTrialWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Trial Expired',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your 7-day premium trial has ended. Thank you for trying our premium features!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '💡 Contact support to learn about premium subscription options.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialOfferWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Try Premium Free!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🎵 Get 7 days of premium features:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeatureRow(
                  icon: Icons.audiotrack, text: 'Audio playback for all songs'),
              _FeatureRow(
                  icon: Icons.favorite, text: 'Save unlimited favorites'),
              _FeatureRow(
                  icon: Icons.library_music,
                  text: 'Access to premium collections'),
              _FeatureRow(
                  icon: Icons.offline_pin, text: 'Offline audio downloads'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Start Free Trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '✨ One-time offer per device • No credit card required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrialUsedWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.grey.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Trial Already Used',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve already enjoyed your free premium trial on this device.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '💡 Contact support to learn about premium subscription options.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapInCard(Widget content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: content,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact trial status widget for headers/app bars
class TrialStatusBadge extends StatefulWidget {
  const TrialStatusBadge({super.key});

  @override
  State<TrialStatusBadge> createState() => _TrialStatusBadgeState();
}

class _TrialStatusBadgeState extends State<TrialStatusBadge> {
  final SessionManager _sessionManager = SessionManager.instance;
  Map<String, dynamic> _trialInfo = {};

  @override
  void initState() {
    super.initState();
    _loadTrialInfo();
  }

  void _loadTrialInfo() {
    setState(() {
      _trialInfo = _sessionManager.getTrialInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveTrial = _trialInfo['hasActiveTrial'] == true;
    final remainingDays = _trialInfo['remainingTrialDays'] ?? 0;
    final remainingHours = _trialInfo['remainingTrialHours'] ?? 0;

    if (!hasActiveTrial) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            remainingDays > 0
                ? '${remainingDays}d trial'
                : '${remainingHours}h trial',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
