// lib/src/features/premium/presentation/premium_upgrade_dialog.dart
// Clean premium upgrade dialog with price and donation page link

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/donation/presentation/donation_page.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  final String feature;
  final String? customMessage;

  const PremiumUpgradeDialog({
    super.key,
    required this.feature,
    this.customMessage,
  });

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  final PremiumService _premiumService = PremiumService();
  bool _isLoading = false;
  int _currentStep = 0; // 0: Overview, 1: Payment, 2: Contact

  // TODO: Set your premium price here
  static const String _premiumPrice =
      "RM 15"; // Change this to your preferred price
  static const String _currency = "RM";
  static const double _priceAmount =
      15.0; // Change this to your preferred price

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Unlock all audio features',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Only ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                Text(
                  _premiumPrice,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  ' one-time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case 0:
        return _buildOverviewStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildContactStep();
      default:
        return _buildOverviewStep();
    }
  }

  Widget _buildOverviewStep() {
    return Column(
      children: [
        Text(
          widget.customMessage ??
              'Get unlimited access to audio playback, advanced controls, and premium features!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Clean feature list
        ...[
          '🎵 Unlimited audio playback',
          '🎛️ Advanced player controls',
          '📱 Mini-player access',
          '🔄 Loop & repeat modes'
        ].map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        Text(
          'Choose Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Pay $_premiumPrice to unlock premium features',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // PayPal Option
        _buildPaymentOption(
          icon: Icons.payment,
          title: 'PayPal',
          subtitle: 'Pay securely online',
          color: const Color(0xFF0070BA),
          onTap: _handlePayPalPayment,
        ),

        const SizedBox(height: 16),

        // QR Code Option
        _buildPaymentOption(
          icon: Icons.qr_code_scanner,
          title: 'Touch \'n Go QR Code',
          subtitle: 'Scan QR code to pay',
          color: const Color(0xFF059669),
          onTap: _handleQRPayment,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return Column(
      children: [
        Text(
          'Send Payment Receipt',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'After paying RM 15, send your receipt for verification',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Email Contact
        _buildContactOption(
          icon: Icons.email,
          title: 'Email Receipt',
          value: 'haweeinc@gmail.com',
          color: const Color(0xFF0EA5E9),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: 'haweeinc@gmail.com'));
            _showMessage('Email copied to clipboard!');
          },
        ),

        const SizedBox(width: 16),

        // WhatsApp Contact
        _buildContactOption(
          icon: Icons.chat,
          title: 'WhatsApp',
          value: '+60 13-545 3900',
          color: const Color(0xFF059669),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '+60135453900'));
            _showMessage('WhatsApp number copied!');
          },
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.content_copy, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            TextButton.icon(
              onPressed:
                  _isLoading ? null : () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: _buildMainAction()),
        ],
      ),
    );
  }

  Widget _buildMainAction() {
    switch (_currentStep) {
      case 0:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Choose Payment', style: TextStyle(fontSize: 16)),
        );
      case 1:
        return TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        );
      case 2:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleContactAdmin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.chat, size: 18),
          label: Text(_isLoading ? 'Opening...' : 'Contact Admin',
              style: const TextStyle(fontSize: 16)),
        );
      default:
        return Container();
    }
  }

  Future<void> _handlePayPalPayment() async {
    setState(() => _isLoading = true);
    try {
      final success = await _premiumService.initiateUpgrade();
      if (success && mounted) {
        _showMessage('PayPal opened! Complete payment and send receipt.');
        setState(() => _currentStep = 2);
      } else if (mounted) {
        _showMessage('Unable to open PayPal. Please try again.');
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQRPayment() async {
    // Navigate to donation page with QR code
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const DonationPage(),
      ),
    )
        .then((_) {
      // After returning from donation page, move to contact step
      if (mounted) {
        setState(() => _currentStep = 2);
      }
    });
  }

  Future<void> _handleContactAdmin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _premiumService.contactAdminForVerification();
      if (success && mounted) {
        Navigator.of(context).pop();
        _showMessage('Contact app opened. Send your payment receipt.');
      } else if (mounted) {
        _showMessage('Unable to open contact app. Please contact manually.');
      }
    } catch (e) {
      if (mounted) _showMessage('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
