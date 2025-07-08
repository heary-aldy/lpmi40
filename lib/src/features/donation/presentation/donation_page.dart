// lib/src/features/donation/presentation/donation_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  // --- Download QR Code Logic ---
  Future<void> _downloadQrCode(BuildContext context) async {
    try {
      // Load the image from assets
      final ByteData byteData =
          await rootBundle.load('assets/images/TNG QR.JPG');
      final Uint8List buffer = byteData.buffer.asUint8List();

      // Save the image to the gallery
      final result = await ImageGallerySaver.saveImage(buffer);

      if (context.mounted) {
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code saved to gallery!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to save QR code.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not save QR Code. ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Upload Bank Slip Logic ---
  Future<void> _uploadBankSlip(BuildContext context) async {
    // 1. Pick the image file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) return; // User canceled the picker

    // 2. Prepare the email
    final Email email = Email(
      body:
          'Dear Ministry Team,\n\nPlease find attached my proof of donation.\n\nThank you and God bless.',
      subject: 'Proof of Donation',
      recipients: ['haw33inc@gmail.com'], // Your email address here
      attachmentPaths: [result.files.single.path!], // Attach the selected file
      isHTML: false,
    );

    // 3. Send the email
    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not open email app. Please ensure you have an email app configured. Error: ${e.toString()}'),
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
      appBar: AppBar(
        title: const Text('Support Our Ministry'),
      ),
      body: SingleChildScrollView(
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
                      Text(accountHolder, style: const TextStyle(fontSize: 16)),
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
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      // ✅ Download QR Code Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download QR'),
                        onPressed: () => _downloadQrCode(context),
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
                // ✅ Upload Bank Slip Button
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
    );
  }
}
