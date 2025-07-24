// Demo page to showcase Premium Offline Audio Download features
// lib/src/features/demo/premium_audio_demo_page.dart

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/audio/widgets/download_audio_button.dart';
import 'package:lpmi40/src/features/audio/presentation/offline_audio_manager.dart';

class PremiumAudioDemoPage extends StatelessWidget {
  const PremiumAudioDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample songs with audio for demo
    final demoSongs = [
      Song(
        number: '001',
        title: 'Demo Song with Audio',
        verses: [
          Verse(
              number: '1',
              lyrics:
                  'This is a demo song with audio URL for testing offline download functionality.',
              order: 0),
        ],
        audioUrl: 'https://example.com/audio/demo-song.mp3',
        collectionId: 'LPMI',
      ),
      Song(
        number: '002',
        title: 'Another Audio Demo',
        verses: [
          Verse(
              number: '1',
              lyrics:
                  'Another demo song to test premium offline audio features.',
              order: 0),
        ],
        audioUrl: 'https://example.com/audio/demo-song-2.mp3',
        collectionId: 'LPMI',
      ),
      Song(
        number: '003',
        title: 'Song Without Audio',
        verses: [
          Verse(
              number: '1',
              lyrics:
                  'This song has no audio URL, so no download button should appear.',
              order: 0),
        ],
        audioUrl: null,
        collectionId: 'LPMI',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Audio Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎵 Premium Offline Audio Features',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Test the new download functionality:',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 4),
                Text(
                  '• Premium users can download audio files',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '• Download progress is shown in real-time',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '• Storage management available',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Demo buttons section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OfflineAudioManager(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text('Offline Manager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Demo songs list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: demoSongs.length,
              itemBuilder: (context, index) {
                final song = demoSongs[index];
                final hasAudio =
                    song.audioUrl != null && song.audioUrl!.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Song number
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  song.number,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Song title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (hasAudio)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.music_note,
                                          size: 12,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Audio Available',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.music_off,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'No Audio',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Download button (only for songs with audio)
                            if (hasAudio) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: DownloadAudioButton(
                                  song: song,
                                  isCompact: true,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Song lyrics preview
                        Text(
                          song.verses.isNotEmpty
                              ? song.verses.first.lyrics
                              : 'No lyrics available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Full-width download button for songs with audio
                        if (hasAudio) ...[
                          const SizedBox(height: 16),
                          DownloadAudioButton(
                            song: song,
                            isCompact: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
