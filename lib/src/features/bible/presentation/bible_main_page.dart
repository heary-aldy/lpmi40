// 📖 Bible Main Page
// Main entry point for Bible features with premium gate

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bible_service.dart';
import '../models/bible_models.dart';
import '../../../core/services/premium_service.dart';
import '../../../features/premium/presentation/premium_audio_gate.dart';
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

      // Always initialize Bible service first
      await _bibleService.initialize();

      // Check premium access (but don't block initialization)
      _hasPremiumAccess = await _premiumService.isPremium();
      debugPrint('📚 Bible premium access: $_hasPremiumAccess');

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
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _hasPremiumAccess
                  ? _buildBibleDashboard(context)
                  : _buildPremiumGate(),
      bottomNavigationBar: _hasPremiumAccess ? _buildBottomNavigation(context) : null,
    );
  }

  Widget _buildBibleDashboard(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Header with Image
          _buildModernHeader(context),
          
          const SizedBox(height: 32),
          
          // Bible Version Selection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Versi Alkitab',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4037), // Deep Brown
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Baca Alkitab dalam Bahasa Melayu dan Indonesia',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 24),
                
                // Bible Version Cards
                _buildBibleVersionCards(context),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Premium Features Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur Premium',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4037),
                      ),
                ),
                const SizedBox(height: 16),
                _buildPremiumFeatureCards(context),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5D4037), // Deep Brown
            const Color(0xFF8D6E63), // Lighter Brown
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/header_image.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.brown.withOpacity(0.7),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation Row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Premium Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _hasPremiumAccess 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _hasPremiumAccess 
                                ? Colors.green.shade300
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasPremiumAccess ? Icons.check_circle : Icons.star,
                              color: _hasPremiumAccess 
                                  ? Colors.green.shade300 
                                  : Colors.amber.shade300,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasPremiumAccess ? 'Premium' : 'Upgrade',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Main Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alkitab Digital',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bahasa Melayu & Indonesia',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBibleVersionCards(BuildContext context) {
    return Column(
      children: [
        _buildVersionCard(
          context,
          title: 'Alkitab Terjemahan Baru',
          subtitle: 'Bahasa Indonesia • TB 1994',
          description: 'Terjemahan modern yang mudah difahami',
          icon: Icons.auto_stories,
          color: const Color(0xFF00695C), // Teal
          collectionId: 'indo_tb',
        ),
        const SizedBox(height: 16),
        _buildVersionCard(
          context,
          title: 'Alkitab Terjemahan Lama',
          subtitle: 'Bahasa Indonesia • TL',
          description: 'Terjemahan klasik dengan bahasa tradisional',
          icon: Icons.book,
          color: const Color(0xFF5D4037), // Deep Brown
          collectionId: 'indo_tm',
        ),
      ],
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required String collectionId,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openBibleVersion(context, collectionId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeatureCards(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildFeatureCard(
          context,
          icon: Icons.auto_awesome,
          label: 'AI Bible Chat',
          color: Colors.purple,
          onTap: _hasPremiumAccess ? _openAIChat : null,
        ),
        _buildFeatureCard(
          context,
          icon: Icons.search,
          label: 'Cari Ayat',
          color: Colors.green,
          onTap: _hasPremiumAccess ? _openSearch : null,
        ),
        _buildFeatureCard(
          context,
          icon: Icons.bookmark,
          label: 'Tandabuku',
          color: Colors.red,
          onTap: _hasPremiumAccess ? _openBookmarks : null,
        ),
        _buildFeatureCard(
          context,
          icon: Icons.settings,
          label: 'Tetapan',
          color: Colors.brown,
          onTap: _hasPremiumAccess ? _openSettings : null,
        ),
      ],
    );
  }


  Widget _buildFeatureCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    
    return SizedBox(
      width: 150,
      height: 100,
      child: Card(
        elevation: isEnabled ? 3 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(isEnabled ? 0.9 : 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur ini memerlukan langganan premium'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(icon, color: Colors.white, size: 32),
                    if (!isEnabled)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Icon(
                          Icons.lock,
                          color: Colors.amber.shade300,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                ),
                if (!isEnabled)
                  Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBibleVersion(BuildContext context, String collectionId) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF5D4037)),
              ),
              const SizedBox(height: 16),
              const Text('Memuatkan versi Alkitab...'),
            ],
          ),
        ),
      );

      // Select the Bible collection
      await _bibleService.selectCollection(collectionId);

      // Close loading indicator
      if (mounted) {
        navigator.pop();
        
        // Navigate directly to book selector - skip collection selector
        final collections = await _bibleService.getAvailableCollections();
        final selectedCollection = collections.firstWhere(
          (c) => c.id == collectionId,
          orElse: () => throw Exception('Collection not found'),
        );
        
        navigator.push(
          MaterialPageRoute(
            builder: (context) => BibleBookSelector(
              bibleService: _bibleService,
              collection: selectedCollection,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        navigator.pop();
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Ralat: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade50, Colors.brown.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.brown),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Memuatkan Alkitab...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.brown,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sila tunggu sebentar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGate() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 80,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'Fitur Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Akses ke Alkitab Digital memerlukan langganan premium. Nikmati bacaan Alkitab yang lengkap dengan terjemahan berbeza.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PremiumAudioGate(
                      feature: 'Alkitab Digital',
                      child: const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('Dapatkan Premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChatMainPage(),
      ),
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

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(
                icon: Icons.search,
                label: 'Cari',
                onTap: _openSearch,
              ),
              _buildBottomNavItem(
                icon: Icons.bookmark,
                label: 'Tandabuku',
                onTap: _openBookmarks,
              ),
              _buildBottomNavItem(
                icon: Icons.auto_awesome,
                label: 'AI Chat',
                onTap: _openAIChat,
              ),
              _buildBottomNavItem(
                icon: Icons.settings,
                label: 'Tetapan',
                onTap: _openSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFF5D4037),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
            // Just navigate back without clearing selection
            Navigator.of(context).pop();
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
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.brown),
                                ),
                                const SizedBox(height: 16),
                                Text('Memuatkan ${book.name} $chapterNumber...'),
                              ],
                            ),
                          ),
                        );

                        await bibleService.selectChapter(chapterNumber);
                        
                        // Get the selected chapter
                        final chapter = bibleService.currentChapter;
                        
                        // Close loading indicator
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          
                          if (chapter != null) {
                            // Navigate to Bible reader
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BibleReader(
                                  bibleService: bibleService,
                                  chapter: chapter,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal memuatkan pasal'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // Close loading indicator
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          
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

// Bible Search Page - Advanced search functionality
class BibleSearchPage extends StatefulWidget {
  final BibleService bibleService;

  const BibleSearchPage({super.key, required this.bibleService});

  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<BibleSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Search filters
  String? _selectedBookId;
  String? _selectedTestament;
  String? _selectedLanguage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Ayat'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input and filters
          _buildSearchSection(),
          
          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Search input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari ayat, kata kunci, atau frasa...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5D4037)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua Kitab',
                  isSelected: _selectedBookId == null,
                  onTap: () => setState(() => _selectedBookId = null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Perjanjian Lama',
                  isSelected: _selectedTestament == 'old',
                  onTap: () => setState(() {
                    _selectedTestament = _selectedTestament == 'old' ? null : 'old';
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Perjanjian Baru',
                  isSelected: _selectedTestament == 'new',
                  onTap: () => setState(() {
                    _selectedTestament = _selectedTestament == 'new' ? null : 'new';
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchController.text.trim().isEmpty || _isSearching
                  ? null
                  : _performSearch,
              icon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Mencari...' : 'Cari'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5D4037),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF5D4037) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF5D4037)),
            ),
            SizedBox(height: 16),
            Text(
              'Mencari ayat...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Cari Ayat Alkitab',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Masukkan kata kunci untuk mencari ayat di seluruh Alkitab',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF5D4037),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tips Pencarian',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Gunakan kata kunci seperti "kasih", "iman", "harapan"\n'
                    '• Cari frasa lengkap dengan tanda petik: "Tuhan adalah gembalaku"\n'
                    '• Filter berdasarkan Perjanjian Lama atau Baru',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Tiada Hasil Ditemukan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada ayat yang mengandungi "${_searchController.text}"\n\n'
              'Cuba:\n'
              '• Periksa ejaan kata kunci\n'
              '• Gunakan sinonim atau kata yang berbeza\n'
              '• Kurangkan filter pencarian',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('Cari Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(BibleSearchResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVerse(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse reference
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.reference,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (action) => _handleSearchResultAction(action, result),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'bookmark',
                        child: ListTile(
                          leading: Icon(Icons.bookmark_add, size: 20),
                          title: Text('Tandabuku'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'highlight',
                        child: ListTile(
                          leading: Icon(Icons.highlight, size: 20),
                          title: Text('Sorot'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 20),
                          title: Text('Salin'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share, size: 20),
                          title: Text('Kongsi'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Verse text with highlights
              Text(
                result.verse.text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await widget.bibleService.searchVerses(
        _searchController.text.trim(),
        bookId: _selectedBookId,
        testament: _selectedTestament,
        language: _selectedLanguage,
        limit: 100,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat mencari: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _selectedBookId = null;
      _selectedTestament = null;
      _selectedLanguage = null;
    });
  }

  void _navigateToVerse(BibleSearchResult result) {
    // Navigate to the specific verse in the Bible reader
    // This would require implementing navigation to specific verse
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pergi ke ${result.reference}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSearchResultAction(String action, BibleSearchResult result) {
    switch (action) {
      case 'bookmark':
        _addBookmark(result);
        break;
      case 'highlight':
        _highlightVerse(result);
        break;
      case 'copy':
        _copyVerse(result);
        break;
      case 'share':
        _shareVerse(result);
        break;
    }
  }

  void _addBookmark(BibleSearchResult result) {
    // Add bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tandabuku ditambah'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _highlightVerse(BibleSearchResult result) {
    // Show highlight color picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayat disorot'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyVerse(BibleSearchResult result) {
    // Copy verse to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayat disalin'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareVerse(BibleSearchResult result) {
    // Share verse functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayat dikongsi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class BibleBookmarksPage extends StatefulWidget {
  final BibleService bibleService;

  const BibleBookmarksPage({super.key, required this.bibleService});

  @override
  State<BibleBookmarksPage> createState() => _BibleBookmarksPageState();
}

class _BibleBookmarksPageState extends State<BibleBookmarksPage> with TickerProviderStateMixin {
  List<BibleBookmark> _bookmarks = [];
  final List<BibleHighlight> _highlights = [];
  final List<BibleNote> _notes = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final bookmarks = await widget.bibleService.getUserBookmarks();
      final highlights = await widget.bibleService.getUserHighlights();
      final notes = await widget.bibleService.getUserNotes();
      
      setState(() {
        _bookmarks = bookmarks;
        _highlights.clear();
        _highlights.addAll(highlights);
        _notes.clear();
        _notes.addAll(notes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat memuatkan data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandabuku & Catatan'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Eksport'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'organize',
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('Kelola Tag'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selection
          Container(
            color: const Color(0xFF5D4037),
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() => _selectedTabIndex = index),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(
                  icon: Icon(Icons.bookmark),
                  text: 'Tandabuku',
                ),
                Tab(
                  icon: Icon(Icons.highlight),
                  text: 'Sorotan',
                ),
                Tab(
                  icon: Icon(Icons.note),
                  text: 'Catatan',
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF5D4037)),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookmarksTab(),
                      _buildHighlightsTab(),
                      _buildNotesTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF5D4037),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'Tiada Tandabuku',
        message: 'Anda belum menyimpan sebarang ayat sebagai tandabuku.\n\nTandabuku membolehkan anda menyimpan ayat kegemaran untuk rujukan mudah.',
        actionText: 'Baca Alkitab',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookmarks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bookmark = _bookmarks[index];
          return _buildBookmarkCard(bookmark);
        },
      ),
    );
  }

  Widget _buildHighlightsTab() {
    if (_highlights.isEmpty) {
      return _buildEmptyState(
        icon: Icons.highlight_off,
        title: 'Tiada Sorotan',
        message: 'Anda belum menyoroti sebarang ayat.\n\nSorotan membolehkan anda menandakan ayat penting dengan warna berbeza.',
        actionText: 'Baca Alkitab',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _highlights.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final highlight = _highlights[index];
          return _buildHighlightCard(highlight);
        },
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.note_alt_outlined,
        title: 'Tiada Catatan',
        message: 'Anda belum menulis sebarang catatan peribadi.\n\nCatatan membolehkan anda menulis refleksi dan pemikiran tentang ayat.',
        actionText: 'Baca Alkitab',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return _buildNoteCard(note);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.auto_stories),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BibleBookmark bookmark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVerse(bookmark.reference),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reference and actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bookmark.reference,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (action) => _handleBookmarkAction(action, bookmark),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 20),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 20),
                          title: Text('Salin'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share, size: 20),
                          title: Text('Kongsi'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 20, color: Colors.red),
                          title: Text('Padam', style: TextStyle(color: Colors.red)),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Verse text
              Text(
                bookmark.verseText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              // Note if available
              if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Tags
              if (bookmark.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: bookmark.tags.map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.grey.shade200,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
              
              // Date
              const SizedBox(height: 8),
              Text(
                'Disimpan ${_formatDate(bookmark.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(BibleHighlight highlight) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVerse(highlight.reference),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getHighlightColor(highlight.color),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference and color indicator
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getHighlightColor(highlight.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      highlight.reference,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (action) => _handleHighlightAction(action, highlight),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'change_color',
                          child: ListTile(
                            leading: Icon(Icons.palette, size: 20),
                            title: Text('Tukar Warna'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 20, color: Colors.red),
                            title: Text('Padam', style: TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Highlighted verse text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getHighlightColor(highlight.color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    highlight.verseText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BibleNote note) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVerse(note.reference),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference
              Text(
                note.reference,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Note content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  note.note,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Verse text (smaller)
              Text(
                note.verseText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHighlightColor(String colorName) {
    switch (colorName) {
      case 'yellow': return Colors.yellow.shade300;
      case 'green': return Colors.green.shade300;
      case 'blue': return Colors.blue.shade300;
      case 'orange': return Colors.orange.shade300;
      case 'pink': return Colors.pink.shade300;
      case 'purple': return Colors.purple.shade300;
      case 'red': return Colors.red.shade300;
      case 'gray': return Colors.grey.shade300;
      default: return Colors.yellow.shade300;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'hari ini';
    } else if (difference.inDays == 1) {
      return 'semalam';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} minggu lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'import':
        _importData();
        break;
      case 'organize':
        _organizeTags();
        break;
    }
  }

  void _handleBookmarkAction(String action, BibleBookmark bookmark) {
    switch (action) {
      case 'edit':
        _editBookmark(bookmark);
        break;
      case 'copy':
        _copyBookmark(bookmark);
        break;
      case 'share':
        _shareBookmark(bookmark);
        break;
      case 'delete':
        _deleteBookmark(bookmark);
        break;
    }
  }

  void _handleHighlightAction(String action, BibleHighlight highlight) {
    switch (action) {
      case 'change_color':
        _changeHighlightColor(highlight);
        break;
      case 'delete':
        _deleteHighlight(highlight);
        break;
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Item Baru'),
        content: const Text('Untuk menambah tandabuku, sorotan, atau catatan, sila baca Alkitab dan gunakan fungsi yang tersedia di halaman bacaan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to main Bible page
            },
            child: const Text('Baca Alkitab'),
          ),
        ],
      ),
    );
  }

  void _navigateToVerse(String reference) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pergi ke $reference'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Bookmark action methods
  void _editBookmark(BibleBookmark bookmark) {
    _showEditBookmarkDialog(bookmark);
  }

  void _copyBookmark(BibleBookmark bookmark) {
    Clipboard.setData(ClipboardData(
      text: '${bookmark.verseText}\n\n${bookmark.reference}',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayat disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareBookmark(BibleBookmark bookmark) {
    final text = '${bookmark.verseText}\n\n${bookmark.reference}';
    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayat disalin untuk dikongsi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteBookmark(BibleBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Tandabuku'),
        content: Text('Adakah anda pasti untuk padam tandabuku ${bookmark.reference}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await widget.bibleService.removeBookmark(bookmark.id);
                await _loadUserData(); // Refresh data
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tandabuku dipadam'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Ralat memadamkan tandabuku: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Padam', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Highlight action methods
  void _changeHighlightColor(BibleHighlight highlight) {
    _showColorPickerDialog(highlight);
  }

  void _deleteHighlight(BibleHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Sorotan'),
        content: Text('Adakah anda pasti untuk padam sorotan ${highlight.reference}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await widget.bibleService.removeHighlight(highlight.id);
                await _loadUserData(); // Refresh data
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sorotan dipadam'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Ralat memadamkan sorotan: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Padam', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showEditBookmarkDialog(BibleBookmark bookmark) {
    final noteController = TextEditingController(text: bookmark.note ?? '');
    final tagsController = TextEditingController(text: bookmark.tags.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tandabuku: ${bookmark.reference}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Tag (dipisahkan dengan koma)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
                final tags = tagsController.text.trim().isEmpty 
                    ? <String>[]
                    : tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                
                await widget.bibleService.updateBookmark(bookmark.id, note, tags);
                await _loadUserData(); // Refresh data
                
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tandabuku dikemaskini'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Ralat mengemaskini tandabuku: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BibleHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna Sorotan'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BibleHighlightColor.values.map((colorOption) {
            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                try {
                  await widget.bibleService.updateHighlightColor(
                    highlight.id,
                    colorOption.value,
                  );
                  await _loadUserData(); // Refresh data
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Warna sorotan ditukar ke ${colorOption.displayName}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ralat menukar warna: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getHighlightColor(colorOption.value),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: highlight.color == colorOption.value
                        ? Colors.black
                        : Colors.grey.shade300,
                    width: highlight.color == colorOption.value ? 3 : 1,
                  ),
                ),
                child: highlight.color == colorOption.value
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Other methods
  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport data akan datang'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import data akan datang'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _organizeTags() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kelola tag akan datang'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class BibleSettingsPage extends StatefulWidget {
  final BibleService bibleService;

  const BibleSettingsPage({super.key, required this.bibleService});

  @override
  State<BibleSettingsPage> createState() => _BibleSettingsPageState();
}

class _BibleSettingsPageState extends State<BibleSettingsPage> {
  BiblePreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = widget.bibleService.userPreferences;
      setState(() {
        _preferences = prefs ?? BiblePreferences(userId: 'default');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat memuatkan tetapan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() => _isSaving = true);
    
    try {
      await widget.bibleService.updateUserPreferences(_preferences!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tetapan disimpan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetapan Alkitab'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _preferences != null)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF5D4037)),
              ),
            )
          : _preferences == null
              ? _buildErrorState()
              : _buildSettingsContent(),
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
              'Ralat Memuatkan Tetapan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Preferences Section
          _buildSectionHeader('Keutamaan Bacaan'),
          _buildReadingPreferencesSection(),
          
          const SizedBox(height: 32),
          
          // Display Settings Section
          _buildSectionHeader('Tetapan Paparan'),
          _buildDisplaySettingsSection(),
          
          const SizedBox(height: 32),
          
          // Language & Translation Section
          _buildSectionHeader('Bahasa & Terjemahan'),
          _buildLanguageSettingsSection(),
          
          const SizedBox(height: 32),
          
          // Audio Settings Section
          _buildSectionHeader('Tetapan Audio'),
          _buildAudioSettingsSection(),
          
          const SizedBox(height: 32),
          
          // Advanced Settings Section
          _buildSectionHeader('Tetapan Lanjutan'),
          _buildAdvancedSettingsSection(),
          
          const SizedBox(height: 32),
          
          // Reset Section
          _buildSectionHeader('Reset', color: Colors.red),
          _buildResetSection(),
          
          const SizedBox(height: 100), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF5D4037),
            ),
      ),
    );
  }

  Widget _buildReadingPreferencesSection() {
    return Column(
      children: [
        // Font Size
        _buildSliderSetting(
          title: 'Saiz Teks',
          subtitle: 'Laraskan saiz teks untuk bacaan yang selesa',
          value: _preferences!.fontSize,
          min: 0.7,
          max: 2.5,
          divisions: 18,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(fontSize: value);
            });
          },
          valueDisplay: '${(_preferences!.fontSize * 100).round()}%',
        ),
        
        const SizedBox(height: 16),
        
        // Font Family
        _buildDropdownSetting<String>(
          title: 'Jenis Huruf',
          subtitle: 'Pilih jenis huruf untuk bacaan',
          value: _preferences!.fontFamily,
          items: const [
            DropdownMenuItem(value: 'Default', child: Text('Default')),
            DropdownMenuItem(value: 'Serif', child: Text('Serif')),
            DropdownMenuItem(value: 'Sans-serif', child: Text('Sans-serif')),
            DropdownMenuItem(value: 'Monospace', child: Text('Monospace')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _preferences = _preferences!.copyWith(fontFamily: value);
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Show Verse Numbers
        _buildSwitchSetting(
          title: 'Tunjukkan Nombor Ayat',
          subtitle: 'Paparkan nombor ayat di sebelah teks',
          value: _preferences!.showVerseNumbers,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(showVerseNumbers: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySettingsSection() {
    return Column(
      children: [
        // Night Mode
        _buildSwitchSetting(
          title: 'Mod Malam',
          subtitle: 'Mod gelap untuk bacaan yang selesa di waktu malam',
          value: _preferences!.enableNightMode,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(enableNightMode: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSettingsSection() {
    return Column(
      children: [
        // Preferred Language
        _buildDropdownSetting<String>(
          title: 'Bahasa Pilihan',
          subtitle: 'Bahasa utama untuk Alkitab',
          value: _preferences!.preferredLanguage,
          items: const [
            DropdownMenuItem(value: 'malay', child: Text('Bahasa Malaysia')),
            DropdownMenuItem(value: 'indonesian', child: Text('Bahasa Indonesia')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _preferences = _preferences!.copyWith(preferredLanguage: value);
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Preferred Translation
        _buildDropdownSetting<String>(
          title: 'Terjemahan Pilihan',
          subtitle: 'Versi terjemahan yang diutamakan',
          value: _preferences!.preferredTranslation,
          items: const [
            DropdownMenuItem(value: 'TB', child: Text('Terjemahan Baru (TB)')),
            DropdownMenuItem(value: 'TL', child: Text('Terjemahan Lama (TL)')),
            DropdownMenuItem(value: 'BIS', child: Text('Bahasa Indonesia Sehari-hari (BIS)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _preferences = _preferences!.copyWith(preferredTranslation: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAudioSettingsSection() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.volume_up,
          title: 'Audio Narasi Premium',
          description: 'Dengar bacaan Alkitab dengan narasi suara profesional. Tersedia untuk pengguna premium.',
          actionText: 'Lihat Premium',
          onAction: () {
            // Navigate to premium page
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.cloud_download,
          title: 'Muat Turun Offline',
          subtitle: 'Muat turun kitab untuk bacaan tanpa internet',
          onTap: () {
            // Navigate to offline download manager
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildActionCard(
          icon: Icons.import_export,
          title: 'Import/Export Data',
          subtitle: 'Backup dan restore tandabuku dan catatan',
          onTap: () {
            // Navigate to import/export page
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildActionCard(
          icon: Icons.sync,
          title: 'Segerak Data',
          subtitle: 'Segerakkan data merentas peranti',
          onTap: () {
            // Sync data
          },
        ),
      ],
    );
  }

  Widget _buildResetSection() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.refresh,
          title: 'Reset Tetapan',
          subtitle: 'Kembalikan semua tetapan ke lalai',
          onTap: _showResetConfirmation,
          textColor: Colors.red,
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueDisplay,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  valueDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF5D4037),
                thumbColor: const Color(0xFF5D4037),
                overlayColor: const Color(0xFF5D4037).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF5D4037),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF5D4037)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFF5D4037)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF5D4037),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tetapan'),
        content: const Text(
          'Adakah anda pasti untuk reset semua tetapan ke lalai? Tindakan ini tidak boleh dibuat asal.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _preferences = BiblePreferences(userId: _preferences!.userId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tetapan telah direset'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
