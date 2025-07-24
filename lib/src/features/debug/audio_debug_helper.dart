// lib/src/features/debug/audio_debug_helper.dart
// 🎵 AUDIO DEBUG: Comprehensive audio troubleshooting tool

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AudioDebugHelper {
  static Future<Map<String, dynamic>> runFullAudioDiagnostic() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {},
      'permissions': {},
      'audio_test': {},
      'network_test': {},
      'recommendations': <String>[],
    };

    try {
      // 1. Device Information
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      results['device_info'] = {
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'android_version': androidInfo.version.release,
        'sdk_int': androidInfo.version.sdkInt,
        'security_patch': androidInfo.version.securityPatch,
      };

      // 2. Permission Check
      final permissions = {
        'audio': await Permission.audio.status,
        'storage': await Permission.storage.status,
        'microphone': await Permission.microphone.status,
        'media_library': await Permission.mediaLibrary.status,
      };
      results['permissions'] =
          permissions.map((k, v) => MapEntry(k, v.toString()));

      // 3. Audio Player Test
      final audioTest = await _testAudioPlayer();
      results['audio_test'] = audioTest;

      // 4. Network Audio Test
      final networkTest = await _testNetworkAudio();
      results['network_test'] = networkTest;

      // 5. Generate Recommendations
      results['recommendations'] = _generateRecommendations(results);

      debugPrint('🎵 [AudioDebug] Full diagnostic completed');
      return results;
    } catch (e) {
      results['error'] = e.toString();
      debugPrint('❌ [AudioDebug] Diagnostic failed: $e');
      return results;
    }
  }

  static Future<Map<String, dynamic>> _testAudioPlayer() async {
    final results = <String, dynamic>{};
    AudioPlayer? testPlayer;

    try {
      // Test player initialization
      testPlayer = AudioPlayer();
      results['player_init'] = 'success';

      // Test audio source setup
      try {
        await testPlayer.setAudioSource(
          ConcatenatingAudioSource(children: []),
        );
        results['audio_source_setup'] = 'success';
      } catch (e) {
        results['audio_source_setup'] = 'failed: $e';
      }

      // Test URL handling
      const testUrl =
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      try {
        await testPlayer.setUrl(testUrl).timeout(const Duration(seconds: 10));
        results['url_loading'] = 'success';

        // Test playback
        await testPlayer.play();
        await Future.delayed(const Duration(seconds: 1));
        await testPlayer.stop();
        results['playback'] = 'success';
      } catch (e) {
        results['url_loading'] = 'failed: $e';
        results['playback'] = 'failed';
      }
    } catch (e) {
      results['player_init'] = 'failed: $e';
    } finally {
      testPlayer?.dispose();
    }

    return results;
  }

  static Future<Map<String, dynamic>> _testNetworkAudio() async {
    final results = <String, dynamic>{};

    // Test various audio URL formats
    final testUrls = [
      'https://drive.google.com/uc?export=download&id=test_file_id',
      'https://docs.google.com/uc?export=download&id=test_file_id',
      'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
    ];

    for (final url in testUrls) {
      final urlType = url.contains('drive.google.com')
          ? 'google_drive'
          : url.contains('docs.google.com')
              ? 'google_docs'
              : 'direct';

      try {
        final testPlayer = AudioPlayer();
        await testPlayer.setUrl(url).timeout(const Duration(seconds: 5));
        results[urlType] = 'reachable';
        testPlayer.dispose();
      } catch (e) {
        results[urlType] = 'failed: $e';
      }
    }

    return results;
  }

  static List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];

    // Check Android version
    final deviceInfo = results['device_info'] as Map<String, dynamic>?;
    if (deviceInfo != null) {
      final sdkInt = deviceInfo['sdk_int'] as int?;
      if (sdkInt != null && sdkInt >= 33) {
        recommendations.add(
            '🔧 Android 13+ detected - ensure READ_MEDIA_AUDIO permission is granted');
      }
    }

    // Check permissions
    final permissions = results['permissions'] as Map<String, dynamic>?;
    if (permissions != null) {
      permissions.forEach((key, value) {
        if (value.toString().contains('denied')) {
          recommendations
              .add('⚠️ $key permission denied - request in app settings');
        }
      });
    }

    // Check audio test results
    final audioTest = results['audio_test'] as Map<String, dynamic>?;
    if (audioTest != null) {
      if (audioTest['player_init']?.toString().contains('failed') == true) {
        recommendations.add(
            '❌ Audio player initialization failed - check just_audio dependency');
      }
      if (audioTest['playback']?.toString().contains('failed') == true) {
        recommendations.add(
            '🎵 Audio playback failed - check device audio settings and volume');
      }
    }

    // Check network test
    final networkTest = results['network_test'] as Map<String, dynamic>?;
    if (networkTest != null) {
      if (networkTest['google_drive']?.toString().contains('failed') == true) {
        recommendations.add(
            '🌐 Google Drive URLs failing - check network security config');
      }
    }

    // General recommendations
    recommendations.addAll([
      '🔧 Ensure WAKE_LOCK permission is added to AndroidManifest.xml',
      '🌐 Check network_security_config.xml for cleartext traffic',
      '🎵 Verify audio URLs are accessible from device browser',
      '📱 Test on different device/Android version if possible',
      '🔄 Try restarting app and clearing app cache',
    ]);

    return recommendations;
  }

  /// Quick audio permission check
  static Future<bool> checkAudioPermissions() async {
    try {
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;

      debugPrint('🎵 [AudioDebug] Audio permission: $audioStatus');
      debugPrint('🎵 [AudioDebug] Storage permission: $storageStatus');

      return audioStatus.isGranted || audioStatus.isLimited;
    } catch (e) {
      debugPrint('❌ [AudioDebug] Permission check failed: $e');
      return false;
    }
  }

  /// Request necessary audio permissions
  static Future<bool> requestAudioPermissions() async {
    try {
      final permissions = [
        Permission.audio,
        Permission.storage,
      ];

      final results = await permissions.request();
      final allGranted = results.values
          .every((status) => status.isGranted || status.isLimited);

      debugPrint('🎵 [AudioDebug] Permission request results: $results');
      return allGranted;
    } catch (e) {
      debugPrint('❌ [AudioDebug] Permission request failed: $e');
      return false;
    }
  }
}
