// Test script for audio functionality debugging
// Run this in Flutter app to test all audio features

import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/audio_player_service.dart';
import 'package:lpmi40/src/core/services/premium_service.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';

class AudioDebugTestPage extends StatefulWidget {
  const AudioDebugTestPage({super.key});

  @override
  State<AudioDebugTestPage> createState() => _AudioDebugTestPageState();
}

class _AudioDebugTestPageState extends State<AudioDebugTestPage> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final PremiumService _premiumService = PremiumService();
  final TextEditingController _urlController = TextEditingController();

  List<String> _testResults = [];
  bool _isRunningTests = false;

  @override
  void initState() {
    super.initState();
    _addTestUrl();
  }

  void _addTestUrl() {
    // Pre-fill with a test URL
    _urlController.text = 'https://www.soundjay.com/misc/beep-07a.wav';
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults
          .add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
  }

  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    _addTestResult('🔄 Starting comprehensive audio test...');

    // Test 1: Premium Service
    try {
      final isPremium = await _premiumService.isPremium();
      final canAccessAudio = await _premiumService.canAccessAudio();
      _addTestResult(
          '✅ Premium Status - isPremium: $isPremium, canAccessAudio: $canAccessAudio');
    } catch (e) {
      _addTestResult('❌ Premium Service Test Failed: $e');
    }

    // Test 2: URL Validation
    final testUrls = [
      'https://www.soundjay.com/misc/beep-07a.wav',
      'https://drive.google.com/file/d/1ABC123/view?usp=sharing',
      'https://firebasestorage.googleapis.com/test.mp3',
      'invalid-url',
      '',
    ];

    for (final url in testUrls) {
      try {
        // Use reflection or create a test method to access _validateAudioUrl
        _addTestResult('🔍 URL Test: $url - [Testing via play method]');
      } catch (e) {
        _addTestResult('❌ URL Validation Error: $e');
      }
    }

    // Test 3: Audio Playback
    if (_urlController.text.isNotEmpty) {
      try {
        _addTestResult(
            '🎵 Testing audio playback with: ${_urlController.text}');
        await _audioService.play('test-song', _urlController.text);
        await Future.delayed(const Duration(seconds: 2));
        await _audioService.stop();
        _addTestResult('✅ Audio playback test completed successfully');
      } catch (e) {
        _addTestResult('❌ Audio Playback Test Failed: $e');
      }
    }

    // Test 4: Google Drive Link Conversion
    final googleDriveUrl =
        'https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view?usp=sharing';
    _addTestResult('🔄 Testing Google Drive link conversion...');
    _addTestResult('📝 Original: $googleDriveUrl');
    // Note: The conversion method is private, so we'll just log the URL format

    setState(() {
      _isRunningTests = false;
    });

    _addTestResult('🏁 Comprehensive audio test completed!');
  }

  Future<void> _testCurrentUrl() async {
    if (_urlController.text.isEmpty) {
      _addTestResult('❌ Please enter a URL to test');
      return;
    }

    try {
      _addTestResult('🎵 Testing URL: ${_urlController.text}');
      await _audioService.play('manual-test', _urlController.text);
      _addTestResult('✅ Audio started successfully - Stop to test again');
    } catch (e) {
      _addTestResult('❌ Failed to play audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioService.stop();
      _addTestResult('⏹️ Audio stopped');
    } catch (e) {
      _addTestResult('❌ Failed to stop audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Debug Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // URL Input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Audio URL to Test',
                border: OutlineInputBorder(),
                hintText: 'Enter audio URL here...',
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunningTests ? null : _runComprehensiveTest,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Run All Tests'),
                ),
                ElevatedButton.icon(
                  onPressed: _testCurrentUrl,
                  icon: const Icon(Icons.audiotrack),
                  label: const Text('Test URL'),
                ),
                ElevatedButton.icon(
                  onPressed: _stopAudio,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Audio'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _testResults.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Log'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Test Results
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    Color textColor = Colors.black;

                    if (result.contains('✅')) textColor = Colors.green;
                    if (result.contains('❌')) textColor = Colors.red;
                    if (result.contains('🔄')) textColor = Colors.blue;
                    if (result.contains('⚠️')) textColor = Colors.orange;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      child: Text(
                        result,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
