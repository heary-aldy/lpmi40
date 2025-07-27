// 📖 Bible Main Page
// Main entry point for Bible features with premium gate

import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import '../models/bible_models.dart';
import '../../../core/services/premium_service.dart';
import '../../../features/premium/presentation/premium_audio_gate.dart';
import 'bible_collection_selector.dart';
import 'bible_book_selector.dart';
import 'bible_reader.dart';
import 'bible_chat_main_page.dart';

class BibleMainPage extends StatefulWidget {
  const BibleMainPage({super.key});

  @override
  State<BibleMainPage> createState() => _BibleMainPageState();
}

class _BibleMainPageState extends State<BibleMainPage> {
  late final BibleService _bibleService;
  late final PremiumService _premiumService;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasPremiumAccess = false;

  @override
  void initState() {
    super.initState();
    _bibleService = BibleService();
    _premiumService = PremiumService();
    _initializeBibleService();
  }

  Future<void> _initializeBibleService() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Check premium access first
      _hasPremiumAccess = await _premiumService.isPremium();

      if (!_hasPremiumAccess) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Initialize Bible service
      await _bibleService.initialize();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      debugPrint('❌ Error initializing Bible service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alkitab'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _hasPremiumAccess ? _openAIChat : null,
            tooltip: 'AI Bible Chat',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _hasPremiumAccess ? _openSearch : null,
            tooltip: 'Cari Ayat',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: _hasPremiumAccess ? _openBookmarks : null,
            tooltip: 'Tandabuku',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _hasPremiumAccess ? _openSettings : null,
            tooltip: 'Tetapan',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.brown),
            ),
            SizedBox(height: 16),
            Text(
              'Memuatkan Alkitab...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasPremiumAccess) {
      return _buildPremiumGate();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return _buildBibleContent();
  }

  Widget _buildPremiumGate() {
    return PremiumAudioGate(
      feature: 'Alkitab Premium',
      upgradeMessage: 'Akses Penuh Alkitab dengan Premium',
      onUpgradePressed: () async {
        // Handle premium upgrade
        final success = await _premiumService.initiateUpgrade();
        if (success) {
          await _initializeBibleService();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 80,
              color: Colors.brown.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Akses Alkitab Premium',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dapatkan akses lengkap kepada Alkitab dengan langganan premium RM 15.00 sebulan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Ralat Memuatkan Alkitab',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeBibleService,
              icon: const Icon(Icons.refresh),
              label: const Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibleContent() {
    return StreamBuilder<BibleCollection?>(
      stream: _bibleService.currentCollectionStream,
      builder: (context, collectionSnapshot) {
        return StreamBuilder<BibleBook?>(
          stream: _bibleService.currentBookStream,
          builder: (context, bookSnapshot) {
            return StreamBuilder<BibleChapter?>(
              stream: _bibleService.currentChapterStream,
              builder: (context, chapterSnapshot) {
                // Show collection selector if no collection selected
                if (collectionSnapshot.data == null) {
                  return BibleCollectionSelector(
                    bibleService: _bibleService,
                  );
                }

                // Show book selector if no book selected
                if (bookSnapshot.data == null) {
                  return BibleBookSelector(
                    bibleService: _bibleService,
                    collection: collectionSnapshot.data!,
                  );
                }

                // Show chapter selector if no chapter selected
                if (chapterSnapshot.data == null) {
                  return BibleChapterSelector(
                    bibleService: _bibleService,
                    book: bookSnapshot.data!,
                  );
                }

                // Show Bible reader
                return BibleReader(
                  bibleService: _bibleService,
                  chapter: chapterSnapshot.data!,
                );
              },
            );
          },
        );
      },
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleSearchPage(bibleService: _bibleService),
      ),
    );
  }

  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleBookmarksPage(bibleService: _bibleService),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleSettingsPage(bibleService: _bibleService),
      ),
    );
  }

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChatMainPage(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Bible Chapter Selector Widget
class BibleChapterSelector extends StatelessWidget {
  final BibleService bibleService;
  final BibleBook book;

  const BibleChapterSelector({
    super.key,
    required this.bibleService,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.name),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            bibleService.selectBook(''); // Clear book selection
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Pasal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${book.name} mengandungi ${book.totalChapters} pasal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: book.totalChapters,
                itemBuilder: (context, index) {
                  final chapterNumber = index + 1;

                  return InkWell(
                    onTap: () async {
                      try {
                        await bibleService.selectChapter(chapterNumber);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.brown.shade200,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          chapterNumber.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder widgets for other Bible pages
class BibleSearchPage extends StatelessWidget {
  final BibleService bibleService;

  const BibleSearchPage({super.key, required this.bibleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Ayat'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Bible Search Feature\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class BibleBookmarksPage extends StatelessWidget {
  final BibleService bibleService;

  const BibleBookmarksPage({super.key, required this.bibleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandabuku'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Bible Bookmarks Feature\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class BibleSettingsPage extends StatelessWidget {
  final BibleService bibleService;

  const BibleSettingsPage({super.key, required this.bibleService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetapan Alkitab'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Bible Settings Feature\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
