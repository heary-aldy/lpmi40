// lib/src/features/donation/presentation/donation_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:lpmi40/src/features/songbook/presentation/pages/main_page.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  // --- Upload Bank Slip Logic ---
  Future<void> _uploadBankSlip(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return; // User canceled the picker

    final Email email = Email(
      body:
          'Dear Ministry Team,\n\nPlease find attached my proof of donation.\n\nThank you and God bless.',
      subject: 'Proof of Donation',
      recipients: ['haw33inc@gmail.com'],
      attachmentPaths: [result.files.single.path!], // Attach the selected file
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app. Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const String accountHolder = 'HEARY HEALDY SAIRIN';
    const String ewalletName = 'Touch \'n Go eWallet';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            foregroundColor: Colors.white,
            leading: BackButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) =>
                          const MainPage(initialFilter: 'All')),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Support Our Ministry',
                  style: TextStyle(color: Colors.white)),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/header_image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: theme.colorScheme.primary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Your Support Matters',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your generous donations help us continue our ministry and development of this application. Thank you for your support and may God bless you.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(ewalletName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(accountHolder,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset('assets/images/TNG QR.JPG',
                                  width: 250, height: 250),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Scan with any of your banking apps or eWallets.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 32),
                      Text(
                        'Already Donated?',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If you have already made a donation, you can send us the receipt. This helps us with our records.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Receipt'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onPrimary,
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () => _uploadBankSlip(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
