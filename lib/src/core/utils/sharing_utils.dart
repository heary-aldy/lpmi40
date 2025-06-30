// lib/src/core/utils/sharing_utils.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SharingUtils {
  /// Show a bottom sheet with sharing options
  static void showShareOptions({
    required BuildContext context,
    required String text,
    required String title,
    String? subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareOptionsSheet(
        text: text,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  /// Copy text to clipboard with feedback
  static Future<void> copyToClipboard({
    required BuildContext context,
    required String text,
    String message = 'Copied to clipboard!',
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Create a formatted email URI
  static Uri createEmailUri({
    required String subject,
    required String body,
    List<String>? recipients,
  }) {
    return Uri(
      scheme: 'mailto',
      path: recipients?.join(',') ?? '',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
  }

  /// Create a formatted SMS URI
  static Uri createSmsUri({
    required String body,
    String? phoneNumber,
  }) {
    return Uri(
      scheme: 'sms',
      path: phoneNumber ?? '',
      queryParameters: {
        'body': body,
      },
    );
  }

  /// Show instructions for manual sharing
  static void showSharingInstructions(BuildContext context, String appType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share via $appType'),
        content: Text(
          'The content has been copied to your clipboard. You can now:\n\n'
          '1. Open $appType\n'
          '2. Create a new message or email\n'
          '3. Paste the content (long press and select paste)\n'
          '4. Add recipients and send',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}

class _ShareOptionsSheet extends StatelessWidget {
  final String text;
  final String title;
  final String? subtitle;

  const _ShareOptionsSheet({
    required this.text,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share "$title"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
                const SizedBox(height: 24),

                // Share options
                _ShareOption(
                  icon: Icons.copy,
                  iconColor: Colors.blue,
                  title: 'Copy to Clipboard',
                  subtitle: 'Copy content to clipboard',
                  onTap: () {
                    Navigator.pop(context);
                    SharingUtils.copyToClipboard(
                      context: context,
                      text: text,
                      message: 'Content copied to clipboard!',
                    );
                  },
                ),

                _ShareOption(
                  icon: Icons.message,
                  iconColor: Colors.green,
                  title: 'Share via Messages',
                  subtitle: 'Copy and open messaging apps',
                  onTap: () {
                    Navigator.pop(context);
                    SharingUtils.copyToClipboard(
                      context: context,
                      text: text,
                      message: 'Content copied! Opening instructions...',
                    );
                    Future.delayed(const Duration(milliseconds: 500), () {
                      SharingUtils.showSharingInstructions(context, 'Messages');
                    });
                  },
                ),

                _ShareOption(
                  icon: Icons.email,
                  iconColor: Colors.orange,
                  title: 'Share via Email',
                  subtitle: 'Copy and open email app',
                  onTap: () {
                    Navigator.pop(context);
                    SharingUtils.copyToClipboard(
                      context: context,
                      text: text,
                      message: 'Content copied! Opening instructions...',
                    );
                    Future.delayed(const Duration(milliseconds: 500), () {
                      SharingUtils.showSharingInstructions(context, 'Email');
                    });
                  },
                ),

                _ShareOption(
                  icon: Icons.visibility,
                  iconColor: Colors.purple,
                  title: 'View Full Text',
                  subtitle: 'See complete shareable content',
                  onTap: () {
                    Navigator.pop(context);
                    _showFullTextDialog(context);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Content'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SharingUtils.copyToClipboard(
                context: context,
                text: text,
              );
              Navigator.pop(context);
            },
            child: const Text('COPY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}
