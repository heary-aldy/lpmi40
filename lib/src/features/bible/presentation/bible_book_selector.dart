// 📖 Bible Book Selector
// UI for selecting Bible books organized by Old and New Testament

import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import '../models/bible_models.dart';
import 'bible_main_page.dart';

class BibleBookSelector extends StatefulWidget {
  final BibleService bibleService;
  final BibleCollection collection;
  final String? filterTestament; // 'old', 'new', or null

  const BibleBookSelector({
    super.key,
    required this.bibleService,
    required this.collection,
    this.filterTestament,
  });

  @override
  State<BibleBookSelector> createState() => _BibleBookSelectorState();
}

class _BibleBookSelectorState extends State<BibleBookSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<BibleBook> _allBooks = [];
  List<BibleBook> _oldTestamentBooks = [];
  List<BibleBook> _newTestamentBooks = [];

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Set initial tab based on testament filter
    final initialIndex = widget.filterTestament == 'new' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _loadBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      debugPrint('📖 Loading books for collection: ${widget.collection.id}');
      final books = await widget.bibleService.getBooksForCurrentCollection();
      debugPrint('📖 Loaded ${books.length} books');

      final oldTestamentBooks = books.where((book) => book.isOldTestament).toList();
      final newTestamentBooks = books.where((book) => book.isNewTestament).toList();
      
      debugPrint('📖 Old Testament books: ${oldTestamentBooks.length}');
      debugPrint('📖 New Testament books: ${newTestamentBooks.length}');

      setState(() {
        _allBooks = books;
        _oldTestamentBooks = oldTestamentBooks;
        _newTestamentBooks = newTestamentBooks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading books: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
        backgroundColor: isDark 
          ? Colors.grey.shade900 
          : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.bibleService.clearSelection();
            Navigator.of(context).pop();
          },
        ),
        bottom: _isLoading || _hasError
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(
                    text: 'Perjanjian Lama (${_oldTestamentBooks.length})',
                    icon: const Icon(Icons.menu_book, size: 16),
                  ),
                  Tab(
                    text: 'Perjanjian Baru (${_newTestamentBooks.length})',
                    icon: const Icon(Icons.auto_stories, size: 16),
                  ),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                isDark ? Colors.amber.shade600 : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuatkan kitab-kitab...',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.red.shade400 : Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Ralat Memuatkan Kitab',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.red.shade400 : Colors.red,
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
                onPressed: _loadBooks,
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

    if (_allBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 64,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tiada Kitab Dijumpai',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Koleksi ini tidak mengandungi sebarang kitab',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBooksList(_oldTestamentBooks, 'Perjanjian Lama'),
        _buildBooksList(_newTestamentBooks, 'Perjanjian Baru'),
      ],
    );
  }

  Widget _buildBooksList(List<BibleBook> books, String testament) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tiada kitab dalam $testament',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(BibleBook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware colors for Old/New Testament
    final oldTestamentColors = isDark 
      ? {
          'bg': Colors.amber.shade800.withValues(alpha: 0.3),
          'border': Colors.amber.shade600,
          'text': Colors.amber.shade400,
        }
      : {
          'bg': Colors.brown.shade100,
          'border': Colors.brown.shade300,
          'text': Colors.brown.shade700,
        };
        
    final newTestamentColors = isDark
      ? {
          'bg': Colors.blue.shade800.withValues(alpha: 0.3),
          'border': Colors.blue.shade600,
          'text': Colors.blue.shade400,
        }
      : {
          'bg': Colors.blue.shade100,
          'border': Colors.blue.shade300,
          'text': Colors.blue.shade700,
        };
    
    final colors = book.isOldTestament ? oldTestamentColors : newTestamentColors;
    
    return Card(
      elevation: isDark ? 4 : 2,
      color: isDark ? Colors.grey.shade800 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectBook(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book number circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors['bg'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors['border'] as Color,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    book.bookNumber.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors['text'] as Color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.englishName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          size: 14,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.totalChapters} pasal',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: book.isOldTestament
                                ? Colors.brown.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: book.isOldTestament
                                  ? Colors.brown.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            book.abbreviation,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: book.isOldTestament
                                  ? Colors.brown.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigate arrow
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

  Future<void> _selectBook(BibleBook book) async {
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
              Text('Memuatkan ${book.name}...'),
            ],
          ),
        ),
      );

      await widget.bibleService.selectBook(book.id);

      // Close loading indicator and navigate to chapter selector
      if (mounted) {
        Navigator.of(context).pop();
        
        // Navigate to chapter selector
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BibleChapterSelector(
              bibleService: widget.bibleService,
              book: book,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
