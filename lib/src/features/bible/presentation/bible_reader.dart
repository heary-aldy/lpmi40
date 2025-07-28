// 📖 Bible Reader
// Main reading interface with verse display and navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bible_service.dart';
import '../services/bible_chat_service.dart';
import '../models/bible_models.dart';
import '../models/bible_chat_models.dart';
import 'bible_chat_main_page.dart';
import 'bible_chat_conversation_page.dart';

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
  Set<int> _selectedVerses = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeVerseKeys();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _isSelectionMode ? _buildSelectionFAB() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chapter.reference,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.brown,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_isSelectionMode) {
            _exitSelectionMode();
          } else {
            widget.bibleService.selectChapter(0); // Clear chapter selection
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
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_preferences == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.brown),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chapter.bookName,
            style: TextStyle(
              fontSize: 24 * _preferences!.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pasal ${widget.chapter.chapterNumber}',
            style: TextStyle(
              fontSize: 18 * _preferences!.fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade600,
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
    final isSelected = _selectedVerses.contains(verse.verseNumber);
    final verseKey = _verseKeys[verse.verseNumber]!;

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
              : (_preferences!.enableNightMode
                  ? Colors.grey.shade800
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.brown.shade300, width: 2)
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
                      ? Colors.brown.shade300
                      : Colors.brown.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.brown.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    verse.verseNumber.toString(),
                    style: TextStyle(
                      fontSize: 12 * _preferences!.fontSize,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.brown.shade700,
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
                      ? Colors.white.withOpacity(0.87)
                      : Colors.black87,
                ),
                onSelectionChanged: (selection, cause) {
                  if (selection.baseOffset != selection.extentOffset) {
                    _showTextSelectionDialog(verse, selection);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                color: onPressed != null ? Colors.brown : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: onPressed != null ? Colors.brown : Colors.grey,
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

    return FloatingActionButton.extended(
      onPressed: _showSelectionActions,
      backgroundColor: Colors.brown,
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
    }
  }

  // Navigation methods
  Future<void> _goToPreviousChapter() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.bibleService.goToPreviousChapter();
      if (!success && mounted) {
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
      if (!success && mounted) {
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
          ],
        ),
      ),
    );
  }

  void _showChapterSelector() {
    // This will be implemented later - for now just show a message
    _showMessage('Pemilih pasal akan datang');
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
    // This will be implemented with proper sharing
    _showMessage('Kongsi ayat akan datang');
  }

  void _addBookmark(BibleVerse verse) {
    // This will be implemented with bookmark functionality
    _showMessage('Tandabuku akan datang');
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
    // This will be implemented with proper sharing
    _showMessage('Kongsi pasal akan datang');
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
      _selectedVerses =
          Set.from(widget.chapter.verses.map((v) => v.verseNumber));
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
    // This will be implemented with proper sharing
    _showMessage('Kongsi ayat akan datang');
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
}
