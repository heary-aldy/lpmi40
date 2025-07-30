// 💎 Bible Premium Upgrade Dialog
// Reusable dialog for promoting premium Bible features

import 'package:flutter/material.dart';
import '../../../features/premium/presentation/premium_audio_gate.dart';

class BiblePremiumDialog {
  /// Show premium upgrade dialog for Bible features
  static Future<void> show({
    required BuildContext context,
    required String feature,
    String? description,
    List<String>? benefits,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade300, Colors.amber.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  '$feature - Premium',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  description ?? 
                  'Ciri $feature memerlukan langganan premium untuk pengalaman Alkitab yang lebih kaya.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (benefits != null && benefits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  
                  // Benefits List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Faedah Premium:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...benefits.map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Nanti',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PremiumAudioGate(
                                feature: 'Alkitab $feature',
                                child: const SizedBox.shrink(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Naik Taraf',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Quick dialog for bookmarks feature
  static Future<void> showBookmarksDialog(BuildContext context) {
    return show(
      context: context,
      feature: 'Tandabuku',
      description: 'Simpan dan atur ayat-ayat kesukaan Anda dengan ciri tandabuku premium.',
      benefits: [
        'Simpan ayat tanpa had',
        'Organisasi dengan kategori',
        'Sinkronisasi merentas peranti',
        'Backup automatik',
      ],
    );
  }

  /// Quick dialog for highlights feature
  static Future<void> showHighlightsDialog(BuildContext context) {
    return show(
      context: context,
      feature: 'Sorotan',
      description: 'Sorot ayat-ayat penting dengan warna berbeza untuk mudah rujukan.',
      benefits: [
        'Sorotan warna pelbagai',
        'Nota peribadi pada ayat',
        'Carian sorotan pantas',
        'Eksport ke PDF',
      ],
    );
  }

  /// Quick dialog for AI chat feature
  static Future<void> showAIChatDialog(BuildContext context) {
    return show(
      context: context,
      feature: 'AI Bible Chat',
      description: 'Dapatkan panduan spiritual dan penjelasan Alkitab dari AI yang pintar.',
      benefits: [
        'Tanya soalan tentang ayat',
        'Penjelasan konteks sejarah',
        'Panduan spiritual harian',
        'Doa yang dipersonalisasi',
      ],
    );
  }

  /// Quick dialog for notes feature
  static Future<void> showNotesDialog(BuildContext context) {
    return show(
      context: context,
      feature: 'Nota',
      description: 'Tulis nota dan renungan peribadi untuk setiap ayat.',
      benefits: [
        'Nota tanpa had',
        'Gambar dan media',
        'Pencarian nota',
        'Berkongsi dengan komuniti',
      ],
    );
  }
}