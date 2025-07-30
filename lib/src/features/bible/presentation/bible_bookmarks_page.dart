import 'package:flutter/material.dart';
import '../services/bookmark_local_storage.dart';

class BibleBookmarksPage extends StatefulWidget {
  const BibleBookmarksPage({super.key});

  @override
  State<BibleBookmarksPage> createState() => _BibleBookmarksPageState();
}

class _BibleBookmarksPageState extends State<BibleBookmarksPage>
    with RouteAware {
  List<Map<String, dynamic>> _bookmarks = [];
  final BookmarkLocalStorage _bookmarkLocalStorage = BookmarkLocalStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for navigation pop to refresh
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      await _loadBookmarks();
      return true;
    });
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final bookmarks = await _bookmarkLocalStorage.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _deleteBookmark(int index) async {
    setState(() => _isLoading = true);
    try {
      await _bookmarkLocalStorage.removeBookmarkAt(index);
      await _loadBookmarks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tandabuku dipadam'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: Gagal padam tandabuku'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandabuku Alkitab'),
        backgroundColor: isDark 
          ? Colors.grey.shade900 
          : Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  isDark ? Colors.amber.shade600 : Colors.brown,
                ),
              ),
            )
          : _bookmarks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.separated(
                    itemCount: _bookmarks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bm = _bookmarks[index];
                      return ListTile(
                        title: Text(bm['reference'] ?? ''),
                        subtitle: Text(bm['text'] ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bm['note'] != null &&
                                (bm['note'] as String).isNotEmpty)
                              Icon(Icons.sticky_note_2, 
                                   color: isDark ? Colors.amber.shade400 : Colors.amber),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, 
                                 color: isDark ? Colors.grey.shade400 : Colors.grey),
                          ],
                        ),
                        onTap: () {
                          _showBookmarkDetails(bm);
                        },
                        onLongPress: () async {
                          final action = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Padam Tandabuku'),
                                  onTap: () => Navigator.pop(context, 'delete'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close),
                                  title: const Text('Batal'),
                                  onTap: () => Navigator.pop(context, null),
                                ),
                              ],
                            ),
                          );
                          if (action == 'delete') {
                            _deleteBookmark(index);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tiada Tandabuku',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan lama pada ayat untuk menambah tandabuku',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadBookmarks,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Semula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.amber.shade600 : Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarkDetails(Map<String, dynamic> bookmark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bookmark['reference'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark['text'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (bookmark['note'] != null && (bookmark['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Nota:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                bookmark['note'],
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (bookmark['createdAt'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Disimpan: ${_formatDate(bookmark['createdAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to the verse in bible reader
            },
            child: const Text('Buka Ayat'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
