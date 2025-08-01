// 📖 Bible Reader
// Main reading interface with verse display and navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/bible_service.dart';
import '../services/bible_chat_service.dart';
import '../services/bible_audio_service.dart';
import '../models/bible_models.dart';
import '../models/bible_chat_models.dart';
import 'bible_chat_main_page.dart';
import 'bible_chat_conversation_page.dart';
import 'bible_bookmarks_page.dart';
import '../widgets/bible_audio_player.dart';
import '../widgets/bible_bottom_audio_player.dart';
import '../services/bookmark_local_storage.dart';
import 'bible_premium_dialog.dart';
import '../../../core/services/premium_service.dart';
import '../../premium/presentation/premium_upgrade_dialog.dart';

class BibleReader extends StatefulWidget {
  final BibleService bibleService;
  final BibleChapter chapter;

  const BibleReader({
    super.key,
    required this.bibleService,
    required this.chapter,
  });

  @override
  State<BibleReader> createState() => _BibleReaderState();
}

class _BibleReaderState extends State<BibleReader> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  BiblePreferences? _preferences;
  bool _isLoading = false;
  final Set<int> _selectedVerses = {};
  bool _isSelectionMode = false;

  final BookmarkLocalStorage _bookmarkLocalStorage = BookmarkLocalStorage();
  final PremiumService _premiumService = PremiumService();
  final BibleAudioService _audioService = BibleAudioService();

  List<BibleHighlight> _highlights = [];
  
  // Theme-aware colors
  Color get _primaryColor => Theme.of(context).brightness == Brightness.dark
    ? Colors.amber.shade600
    : Theme.of(context).primaryColor;
    

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeVerseKeys();
    _loadHighlights();
    _initializeAudioService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _initializeVerseKeys() {
    _verseKeys.clear();
    for (var verse in widget.chapter.verses) {
      _verseKeys[verse.verseNumber] = GlobalKey();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = widget.bibleService.userPreferences;
    if (mounted) {
      setState(() {
        _preferences = prefs ?? BiblePreferences(userId: 'default');
      });
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final highlights = await widget.bibleService.getUserHighlights();
      if (mounted) {
        setState(() {
          _highlights = highlights
              .where((h) =>
                  h.bookId == widget.chapter.bookId &&
                  h.chapterNumber == widget.chapter.chapterNumber)
              .toList();
        });
      }
    } catch (e) {
      // Ignore highlight errors (e.g. not premium)
    }
  }

  BibleHighlight? _getHighlightForVerse(int verseNumber) {
    try {
      return _highlights.firstWhere((h) => h.verseNumber == verseNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const BibleBottomAudioPlayer(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _isSelectionMode ? _buildSelectionFAB() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.chapter.reference,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${widget.chapter.totalVerses} ayat',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      backgroundColor: isDark 
        ? Colors.grey.shade900  
        : Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_isSelectionMode) {
            _exitSelectionMode();
          } else {
            // Navigate back to chapter selector
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAllVerses,
            tooltip: 'Pilih Semua',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _exitSelectionMode,
            tooltip: 'Batal Pilih',
          ),
        ] else ...[
          if (_audioService.isAvailable)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: _playChapterAudioWithPremiumCheck,
              tooltip: 'Dengar Pasal',
            ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _openAIChat,
            tooltip: 'AI Bible Chat',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Cari dalam Pasal',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showFontSizeDialog,
            tooltip: 'Saiz Teks',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_chapter',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Salin Pasal'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'share_chapter',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Kongsi Pasal'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'goto_verse',
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Pergi ke Ayat'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'bookmarks',
                child: ListTile(
                  leading: Icon(Icons.bookmark),
                  title: Text('Tandabuku'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_preferences == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Container(
      color:
          _preferences!.enableNightMode ? Colors.grey.shade900 : Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.chapter.verses.length + 1, // +1 for chapter header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildChapterHeader();
          }

          final verse = widget.chapter.verses[index - 1];
          return _buildVerseWidget(verse);
        },
      ),
    );
  }

  Widget _buildChapterHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chapter.bookName,
            style: TextStyle(
              fontSize: 24 * _preferences!.fontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.amber.shade400 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pasal ${widget.chapter.chapterNumber}',
            style: TextStyle(
              fontSize: 18 * _preferences!.fontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.amber.shade300 : Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.chapter.totalVerses} ayat • ${widget.chapter.translation}',
            style: TextStyle(
              fontSize: 14 * _preferences!.fontSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseWidget(BibleVerse verse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedVerses.contains(verse.verseNumber);
    final verseKey = _verseKeys[verse.verseNumber]!;
    final highlight = _getHighlightForVerse(verse.verseNumber);
    Color? highlightColor;
    if (highlight != null) {
      switch (highlight.color) {
        case 'yellow':
          highlightColor = Colors.yellow.shade200;
          break;
        case 'green':
          highlightColor = Colors.green.shade200;
          break;
        case 'blue':
          highlightColor = Colors.blue.shade200;
          break;
        case 'orange':
          highlightColor = Colors.orange.shade200;
          break;
        case 'pink':
          highlightColor = Colors.pink.shade100;
          break;
        case 'purple':
          highlightColor = Colors.purple.shade100;
          break;
        case 'red':
          highlightColor = Colors.red.shade100;
          break;
        case 'gray':
          highlightColor = Colors.grey.shade300;
          break;
        default:
          highlightColor = Colors.yellow.shade100;
      }
    }
    return GestureDetector(
      key: verseKey,
      onTap: () => _handleVerseTap(verse),
      onLongPress: () => _handleVerseLongPress(verse),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.brown.shade100
              : (highlightColor ??
                  (_preferences!.enableNightMode
                      ? Colors.grey.shade800
                      : Colors.transparent)),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _primaryColor, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse number
            if (_preferences!.showVerseNumbers) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor
                      : (isDark ? Colors.grey.shade700 : Colors.brown.shade100),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    verse.verseNumber.toString(),
                    style: TextStyle(
                      fontSize: 12 * _preferences!.fontSize,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Verse text
            Expanded(
              child: SelectableText(
                verse.text,
                style: TextStyle(
                  fontSize: 16 * _preferences!.fontSize,
                  height: 1.6,
                  fontFamily: _preferences!.fontFamily != 'Default'
                      ? _preferences!.fontFamily
                      : null,
                  color: _preferences!.enableNightMode
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous chapter
              _buildNavButton(
                icon: Icons.arrow_back,
                label: 'Sebelum',
                onPressed: _isLoading ? null : _goToPreviousChapter,
              ),

              // Chapter selector
              _buildNavButton(
                icon: Icons.list,
                label: 'Pasal ${widget.chapter.chapterNumber}',
                onPressed: _isLoading ? null : _showChapterSelector,
              ),

              // Next chapter
              _buildNavButton(
                icon: Icons.arrow_forward,
                label: 'Seterus',
                onPressed: _isLoading ? null : _goToNextChapter,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: onPressed != null ? _primaryColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: onPressed != null ? _primaryColor : Colors.grey,
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

  Widget? _buildSelectionFAB() {
    if (_selectedVerses.isEmpty) return null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FloatingActionButton.extended(
      onPressed: _showSelectionActions,
      backgroundColor: isDark 
        ? Colors.grey.shade700 
        : Theme.of(context).primaryColor,
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      label: Text(
        '${_selectedVerses.length} dipilih',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Event handlers
  void _handleVerseTap(BibleVerse verse) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedVerses.contains(verse.verseNumber)) {
          _selectedVerses.remove(verse.verseNumber);
        } else {
          _selectedVerses.add(verse.verseNumber);
        }

        if (_selectedVerses.isEmpty) {
          _isSelectionMode = false;
        }
      });
    } else {
      _showVerseActions(verse);
    }
  }

  void _handleVerseLongPress(BibleVerse verse) {
    HapticFeedback.mediumImpact();

    setState(() {
      _isSelectionMode = true;
      _selectedVerses.clear();
      _selectedVerses.add(verse.verseNumber);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_chapter':
        _copyChapter();
        break;
      case 'share_chapter':
        _shareChapter();
        break;
      case 'goto_verse':
        _showGoToVerseDialog();
        break;
      case 'bookmarks':
        _openBookmarksPage();
        break;
    }
  }

  // Navigation methods
  Future<void> _goToPreviousChapter() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.bibleService.goToPreviousChapter();
      if (success && mounted) {
        final newChapter = widget.bibleService.currentChapter;
        if (newChapter != null) {
          // Navigate to the new chapter reader
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BibleReader(
                bibleService: widget.bibleService,
                chapter: newChapter,
              ),
            ),
          );
          return; // Don't set loading to false since we're navigating away
        }
      } else if (mounted) {
        _showMessage('Sudah sampai di pasal pertama');
      }
    } catch (e) {
      if (mounted) {
        _showError('Ralat: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToNextChapter() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.bibleService.goToNextChapter();
      if (success && mounted) {
        final newChapter = widget.bibleService.currentChapter;
        if (newChapter != null) {
          // Navigate to the new chapter reader
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BibleReader(
                bibleService: widget.bibleService,
                chapter: newChapter,
              ),
            ),
          );
          return; // Don't set loading to false since we're navigating away
        }
      } else if (mounted) {
        _showMessage('Sudah sampai di pasal terakhir');
      }
    } catch (e) {
      if (mounted) {
        _showError('Ralat: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // AI Chat methods
  Future<void> _openAIChat() async {
    try {
      final chatService = BibleChatService();

      // Check if AI Chat is available (premium feature)
      final isAvailable = await chatService.isAIChatAvailable();
      if (!isAvailable) {
        _showPremiumDialog();
        return;
      }

      // Create context for current reading
      final chatContext = BibleChatContext(
        collectionId:
            widget.chapter.translation, // Use translation as collection
        bookId: widget.chapter.bookId,
        chapter: widget.chapter.chapterNumber,
        verses: _selectedVerses.isNotEmpty ? _selectedVerses.toList() : null,
      );

      if (_selectedVerses.isNotEmpty) {
        // Start chat with selected verses context
        await _startChatWithContext(chatContext);
      } else {
        // Show AI Chat options
        _showAIChatOptions(chatContext);
      }
    } catch (e) {
      _showError('Ralat membuka AI Chat: ${e.toString()}');
    }
  }

  Future<void> _startChatWithContext(BibleChatContext chatContext) async {
    try {
      final chatService = BibleChatService();
      await chatService.initialize();

      final conversation = await chatService.startNewConversation(
        context: chatContext,
        title: 'Chat tentang ${chatContext.getContextDescription()}',
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BibleChatConversationPage(
              conversationId: conversation.id,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Ralat memulakan chat: ${e.toString()}');
    }
  }

  void _showAIChatOptions(BibleChatContext chatContext) {
    showModalBottomSheet(
      context: context,
      builder: (buildContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'AI Bible Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat tentang pasal ini'),
            subtitle:
                Text('Bincang tentang ${chatContext.getContextDescription()}'),
            onTap: () {
              Navigator.of(buildContext).pop();
              _startChatWithContext(chatContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Tanya tentang ayat tertentu'),
            subtitle: const Text('Pilih ayat untuk berbincang'),
            onTap: () {
              Navigator.of(buildContext).pop();
              _enterSelectionMode();
              _showMessage('Pilih ayat yang ingin anda tanya');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Chat terdahulu'),
            subtitle: const Text('Lihat percakapan AI sebelumnya'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BibleChatMainPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Bible Chat - Premium Feature'),
        content: const Text(
          'AI Bible Chat adalah ciri eksklusif untuk pengguna premium. '
          'Dapatkan wawasan spiritual yang dipersonalisasi dan panduan Alkitab yang pintar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to premium upgrade
            },
            child: const Text('Naik Taraf'),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showVerseActions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.chapter.bookName} ${widget.chapter.chapterNumber}:${verse.verseNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Salin Ayat'),
              onTap: () {
                Navigator.pop(context);
                _copyVerse(verse);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Kongsi Ayat'),
              onTap: () {
                Navigator.pop(context);
                _shareVerse(verse);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Tambah Tandabuku'),
              onTap: () {
                Navigator.pop(context);
                _addBookmark(verse);
              },
            ),
            if (_audioService.isAvailable)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Dengar Ayat'),
                onTap: () {
                  Navigator.pop(context);
                  _playVerseAudioWithPremiumCheck(verse);
                },
              ),
            ListTile(
              leading: const Icon(Icons.highlight),
              title: const Text('Sorot (Highlight)'),
              onTap: () {
                Navigator.pop(context);
                _showHighlightColorPicker(verse);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHighlightColorPicker(BibleVerse verse) async {
    // Check premium access
    final isPremium = await _premiumService.isPremium();
    if (!isPremium) {
      if (mounted) {
        BiblePremiumDialog.showHighlightsDialog(context);
      }
      return;
    }
    
    if (!mounted) return;
    final colors = [
      {'color': Colors.yellow.shade200, 'value': 'yellow'},
      {'color': Colors.green.shade200, 'value': 'green'},
      {'color': Colors.blue.shade200, 'value': 'blue'},
      {'color': Colors.orange.shade200, 'value': 'orange'},
      {'color': Colors.pink.shade100, 'value': 'pink'},
      {'color': Colors.purple.shade100, 'value': 'purple'},
      {'color': Colors.red.shade100, 'value': 'red'},
      {'color': Colors.grey.shade300, 'value': 'gray'},
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna Sorotan'),
        content: Wrap(
          spacing: 8,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, c['value'] as String),
              child: CircleAvatar(
                backgroundColor: c['color'] as Color,
                radius: 22,
                child: c['value'] == 'yellow'
                    ? const Icon(Icons.star, color: Colors.orange, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _isLoading = true);
      try {
        await widget.bibleService.addHighlight(
          widget.chapter.bookId,
          widget.chapter.bookName,
          widget.chapter.chapterNumber,
          verse.verseNumber,
          verse.text,
          selected,
        );
        await _loadHighlights();
        if (mounted) _showMessage('Ayat disorot!');
      } catch (e) {
        if (mounted) {
          if (e.toString().contains('permission') || e.toString().contains('Premium')) {
            _showError('Ciri sorotan memerlukan langganan premium atau akses internet');
          } else {
            _showError('Gagal sorot ayat: ${e.toString()}');
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Pilih Pasal',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D4037),
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Chapter grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    controller: scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount:
                        widget.bibleService.currentBook?.totalChapters ?? 0,
                    itemBuilder: (context, index) {
                      final chapterNumber = index + 1;
                      final isCurrentChapter =
                          chapterNumber == widget.chapter.chapterNumber;

                      return InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          if (chapterNumber != widget.chapter.chapterNumber) {
                            setState(() => _isLoading = true);
                            try {
                              await widget.bibleService
                                  .selectChapter(chapterNumber);
                              final newChapter =
                                  widget.bibleService.currentChapter;
                              if (newChapter != null && mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => BibleReader(
                                      bibleService: widget.bibleService,
                                      chapter: newChapter,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                _showError('Ralat: ${e.toString()}');
                                setState(() => _isLoading = false);
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? const Color(0xFF5D4037)
                                : Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentChapter
                                  ? const Color(0xFF5D4037)
                                  : Colors.brown.shade200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              chapterNumber.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentChapter
                                    ? Colors.white
                                    : Colors.brown.shade700,
                              ),
                            ),
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
      ),
    );
  }

  void _showSearchDialog() {
    // This will be implemented later - for now just show a message
    _showMessage('Carian akan datang');
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saiz Teks'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Saiz: ${(_preferences!.fontSize * 100).round()}%'),
                Slider(
                  value: _preferences!.fontSize,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences!.copyWith(fontSize: value);
                    });
                    this.setState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.bibleService.updateUserPreferences(_preferences!);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showGoToVerseDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pergi ke Ayat'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nombor ayat (1-${widget.chapter.totalVerses})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final verseNumber = int.tryParse(controller.text);
              if (verseNumber != null &&
                  verseNumber >= 1 &&
                  verseNumber <= widget.chapter.totalVerses) {
                Navigator.pop(context);
                _scrollToVerse(verseNumber);
              }
            },
            child: const Text('Pergi'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _copyVerse(BibleVerse verse) {
    final text =
        '${verse.text}\n\n${widget.chapter.reference}:${verse.verseNumber}';
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('Ayat disalin');
  }

  void _shareVerse(BibleVerse verse) {
    final text =
        '${widget.chapter.reference} ${verse.verseNumber}\n${verse.text}';
    Share.share(text, subject: 'Kongsi Ayat Alkitab');
  }

  void _addBookmark(BibleVerse verse) async {
    // Check premium access
    final isPremium = await _premiumService.isPremium();
    if (!isPremium) {
      if (mounted) {
        BiblePremiumDialog.showBookmarksDialog(context);
      }
      return;
    }
    
    if (!mounted) return;
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Tambah Tandabuku'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Nota (pilihan)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    setState(() => _isLoading = true);
    final bookmarkData = {
      'bookId': widget.chapter.bookId,
      'bookName': widget.chapter.bookName,
      'chapter': widget.chapter.chapterNumber,
      'verse': verse.verseNumber,
      'text': verse.text,
      'note': note?.isNotEmpty == true ? note : null,
      'reference':
          '${widget.chapter.bookName} ${widget.chapter.chapterNumber}:${verse.verseNumber}',
      'createdAt': DateTime.now().toIso8601String(),
    };
    try {
      // Save to local storage first
      await _bookmarkLocalStorage.addBookmark(bookmarkData);
      // Try saving to Firebase as fallback
      try {
        await widget.bibleService.addBookmark(
          widget.chapter.bookId,
          widget.chapter.bookName,
          widget.chapter.chapterNumber,
          verse.verseNumber,
          verse.text,
          note: note?.isNotEmpty == true ? note : null,
          reference:
              '${widget.chapter.bookName} ${widget.chapter.chapterNumber}:${verse.verseNumber}',
        );
      } catch (e) {
        // Ignore Firebase error, already saved locally
      }
      if (mounted) {
        _showMessage('Tandabuku disimpan secara lokal!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal tambah tandabuku: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyChapter() {
    final text = widget.chapter.verses
        .map((v) => '${v.verseNumber}. ${v.text}')
        .join('\n\n');
    final fullText = '${widget.chapter.reference}\n\n$text';
    Clipboard.setData(ClipboardData(text: fullText));
    _showMessage('Pasal disalin');
  }

  void _shareChapter() {
    final text = widget.chapter.verses
        .map((v) => '${v.verseNumber}. ${v.text}')
        .join('\n\n');
    final fullText = '${widget.chapter.reference}\n\n$text';
    Share.share(fullText, subject: 'Kongsi Pasal Alkitab');
  }

  void _scrollToVerse(int verseNumber) {
    final key = _verseKeys[verseNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Selection mode methods
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedVerses.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedVerses.clear();
    });
  }

  void _selectAllVerses() {
    setState(() {
      _selectedVerses
        ..clear()
        ..addAll(widget.chapter.verses.map((v) => v.verseNumber));
    });
  }

  void _showSelectionActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedVerses.length} ayat dipilih',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Salin Ayat Terpilih'),
              onTap: () {
                Navigator.pop(context);
                _copySelectedVerses();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Kongsi Ayat Terpilih'),
              onTap: () {
                Navigator.pop(context);
                _shareSelectedVerses();
              },
            ),
            if (_audioService.isAvailable)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Dengar Ayat Terpilih'),
                onTap: () {
                  Navigator.pop(context);
                  _playSelectedVersesAudioWithPremiumCheck();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _copySelectedVerses() {
    final selectedVerses = widget.chapter.verses
        .where((v) => _selectedVerses.contains(v.verseNumber))
        .toList();

    final text =
        selectedVerses.map((v) => '${v.verseNumber}. ${v.text}').join('\n\n');

    final fullText = '${widget.chapter.reference}\n\n$text';
    Clipboard.setData(ClipboardData(text: fullText));
    _showMessage('${selectedVerses.length} ayat disalin');
    _exitSelectionMode();
  }

  void _shareSelectedVerses() {
    final selectedVerses = widget.chapter.verses
        .where((v) => _selectedVerses.contains(v.verseNumber))
        .toList();
    final text =
        selectedVerses.map((v) => '${v.verseNumber}. ${v.text}').join('\n\n');
    final fullText = '${widget.chapter.reference}\n\n$text';
    Share.share(fullText, subject: 'Kongsi Ayat Terpilih');
    _exitSelectionMode();
  }

  void _showTextSelectionDialog(BibleVerse verse, TextSelection selection) {
    final selectedText =
        verse.text.substring(selection.baseOffset, selection.extentOffset);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teks Dipilih'),
        content: Text(selectedText),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: selectedText));
              Navigator.pop(context);
              _showMessage('Teks disalin');
            },
            child: const Text('Salin'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Utility methods
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBookmarksPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BibleBookmarksPage(),
      ),
    );
  }

  // Audio methods
  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing audio service: $e');
    }
  }

  Future<void> _playChapterAudioWithPremiumCheck() async {
    final isPremium = await _premiumService.isPremium();
    if (!isPremium) {
      _showPremiumAudioDialog();
      return;
    }
    await _playChapterAudio();
  }

  Future<void> _playVerseAudioWithPremiumCheck(BibleVerse verse) async {
    final isPremium = await _premiumService.isPremium();
    if (!isPremium) {
      _showPremiumAudioDialog();
      return;
    }
    await _playVerseAudio(verse);
  }

  Future<void> _playSelectedVersesAudioWithPremiumCheck() async {
    final isPremium = await _premiumService.isPremium();
    if (!isPremium) {
      _showPremiumAudioDialog();
      return;
    }
    await _playSelectedVersesAudio();
  }

  Future<void> _playChapterAudio() async {
    try {
      await _audioService.playChapter(widget.chapter);
      _showMessage('Memulakan audio pasal...');
    } catch (e) {
      _showError('Gagal main audio: ${e.toString()}');
    }
  }

  Future<void> _playVerseAudio(BibleVerse verse) async {
    try {
      await _audioService.playVerse(verse, widget.chapter.reference);
      _showMessage('Bermain ayat ${verse.verseNumber}...');
    } catch (e) {
      _showError('Gagal main audio ayat: ${e.toString()}');
    }
  }

  Future<void> _playSelectedVersesAudio() async {
    if (_selectedVerses.isEmpty) return;

    try {
      final selectedVerses = widget.chapter.verses
          .where((v) => _selectedVerses.contains(v.verseNumber))
          .toList();
      
      await _audioService.playSelectedVerses(selectedVerses, widget.chapter.reference);
      _showMessage('Bermain ${selectedVerses.length} ayat terpilih...');
      _exitSelectionMode();
    } catch (e) {
      _showError('Gagal main audio ayat terpilih: ${e.toString()}');
    }
  }

  void _showPremiumAudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bible Audio Reading is a premium feature that includes:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Multiple voice styles and genders')),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Adjustable reading speed')),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Chapter and verse playback')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PremiumUpgradeDialogs.showFullUpgradePage(
                context,
                feature: 'bible_audio',
                customMessage: 'Bible Audio Reading is a premium feature with multiple voice styles, adjustable speeds, and enhanced spiritual experience.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Naik Taraf'),
          ),
        ],
      ),
    );
  }
}
