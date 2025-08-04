// lib/src/features/demo/premium_trial_demo_page.dart
// 🎯 Demo page for testing the premium trial system
// ✅ User-facing trial activation and testing

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lpmi40/src/widgets/premium_trial_widget.dart';
import 'package:lpmi40/src/core/services/session_manager.dart';

class PremiumTrialDemoPage extends StatefulWidget {
  const PremiumTrialDemoPage({super.key});

  @override
  State<PremiumTrialDemoPage> createState() => _PremiumTrialDemoPageState();
}

class _PremiumTrialDemoPageState extends State<PremiumTrialDemoPage> {
  final SessionManager _sessionManager = SessionManager.instance;
  Map<String, dynamic> _sessionInfo = {};
  Map<String, dynamic> _trialInfo = {};
  bool _isTrialEligible = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final session = _sessionManager.currentSession;
    final eligible = await _sessionManager.isTrialEligible();
    final trialInfo = _sessionManager.getTrialInfo();

    setState(() {
      _sessionInfo = {
        'userRole': session.userRole,
        'isPremium': session.isPremium,
        'hasAudioAccess': session.hasAudioAccess,
        'canAccessAudioWithTrial': _sessionManager.canAccessAudioWithTrial,
        'canAccessPremiumWithTrial': _sessionManager.canAccessPremiumWithTrial,
      };
      _trialInfo = trialInfo;
      _isTrialEligible = eligible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Trial Demo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trial Widget Demo
            const Text(
              'Premium Trial Widget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is how the trial widget appears to users:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            PremiumTrialWidget(
              onTrialActivated: () {
                _loadInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trial activated! Refreshing data...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Trial Status Badge Demo
            const Text(
              'Trial Status Badge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This badge can be shown in app bars or headers:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Text(
                    'Example App Bar:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  TrialStatusBadge(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Status
            _buildCurrentStatusCard(),

            const SizedBox(height: 24),

            // Test Actions
            _buildTestActionsCard(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Current Session Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._sessionInfo.entries.map((entry) {
              final value = entry.value.toString();
              Color? valueColor;

              if (entry.value is bool) {
                valueColor = entry.value ? Colors.green : Colors.red;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (valueColor ?? Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (valueColor ?? Colors.grey).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: valueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Trial Information:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._trialInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTestActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Test Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Use these actions to test the trial system:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadInfo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                ),
                ElevatedButton.icon(
                  onPressed: _isTrialEligible ? _startTrialManually : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clearTrialData,
                  icon: const Icon(Icons.clear),
                  label: const Text('Reset Trial Data'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ These are demo actions for testing purposes only.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'How to Use',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Implementation Steps:\n'
              '• Add PremiumTrialWidget to your main screens\n'
              '• Use TrialStatusBadge in app bars\n'
              '• Check canAccessAudioWithTrial for audio features\n'
              '• Check canAccessPremiumWithTrial for premium content\n\n'
              '2. User Experience:\n'
              '• Eligible users see "Try Premium Free!" offer\n'
              '• One-time 7-day trial per device\n'
              '• Trial status shown with countdown\n'
              '• Expired trials show upgrade messaging\n\n'
              '3. Trial Features:\n'
              '• Audio playback access\n'
              '• Premium content access\n'
              '• Unlimited favorites\n'
              '• All premium functionality\n\n'
              '4. Integration Points:\n'
              '• Settings page - Show trial widget\n'
              '• Premium content - Show trial offer\n'
              '• Audio player - Show trial when blocked\n'
              '• App header - Show trial status badge',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrialManually() async {
    final trialSession = await _sessionManager.startWeeklyTrial();

    if (trialSession != null) {
      await _loadInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Trial started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to start trial'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearTrialData() async {
    // This is a demo function to reset trial data for testing
    try {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Trial Data'),
              content: const Text(
                  'This will clear trial history and allow you to test the trial again. '
                  'This is for demo purposes only.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirmed) {
        // Clear trial data from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('trial_history_v1');
        await prefs.remove('trial_eligibility_v1');

        // Clear session and restart as guest
        await _sessionManager.logout();

        await _loadInfo();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trial data reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error resetting trial data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
