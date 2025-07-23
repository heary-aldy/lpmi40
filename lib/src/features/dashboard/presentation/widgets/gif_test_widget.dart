import 'package:flutter/material.dart';

/// Test widget to debug GIF loading issues
class GifTestWidget extends StatelessWidget {
  const GifTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIF Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Testing GIF Loading:'),
            const SizedBox(height: 20),

            // Test 1: Direct Image.asset
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Image.asset(
                'assets/dashboard_icons/all_song.gif',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 32,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Text('Direct Image.asset test'),

            const SizedBox(height: 40),

            // Test 2: Using our GifIconWidget
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
              ),
              child: const GifIconWidget(
                gifAssetPath: 'assets/dashboard_icons/settings.gif',
                fallbackIcon: Icons.settings,
                size: 64,
              ),
            ),

            const SizedBox(height: 20),
            const Text('GifIconWidget test'),

            const SizedBox(height: 40),

            // Test 3: Alternative approach with explicit animation
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
              ),
              child: Image.asset(
                'assets/dashboard_icons/debug.gif',
                width: 64,
                height: 64,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.bug_report,
                    color: Colors.orange,
                    size: 32,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Text('Enhanced Image.asset test'),
          ],
        ),
      ),
    );
  }
}

class GifIconWidget extends StatelessWidget {
  final String? gifAssetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;

  const GifIconWidget({
    super.key,
    this.gifAssetPath,
    required this.fallbackIcon,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (gifAssetPath != null) {
      return Image.asset(
        gifAssetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            fallbackIcon,
            size: size,
            color: color,
          );
        },
      );
    }

    return Icon(
      fallbackIcon,
      size: size,
      color: color,
    );
  }
}
