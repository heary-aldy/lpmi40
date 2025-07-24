// Add this to your main_dashboard_drawer.dart to access the audio debug page

// In the developer debug section, add this menu item:

ListTile(
  leading: const Icon(Icons.audiotrack, color: Colors.blue),
  title: const Text('Audio Debug Test'),
  subtitle: const Text('Test audio functionality'),
  onTap: () {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AudioDebugTestPage(),
      ),
    );
  },
),

// Don't forget to import:
// import 'package:lpmi40/debug_audio_test_page.dart';
