import 'package:flutter/material.dart';
import '../services/bookmark_local_storage.dart';
import 'dart:convert';

class BibleBookmarksPage extends StatefulWidget {
  const BibleBookmarksPage({super.key});

  @override
  State<BibleBookmarksPage> createState() => _BibleBookmarksPageState();
}

class _BibleBookmarksPageState extends State<BibleBookmarksPage> {
  late Future<List<Map<String, dynamic>>> _bookmarksFuture;
  final BookmarkLocalStorage _bookmarkLocalStorage = BookmarkLocalStorage();

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkLocalStorage.getBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandabuku Alkitab'),
        backgroundColor: Colors.brown,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ralat: ${snapshot.error}'));
          }
          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return const Center(child: Text('Tiada tandabuku.'));
          }
          return ListView.separated(
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bm = bookmarks[index];
              return ListTile(
                title: Text(bm['reference'] ?? ''),
                subtitle: Text(bm['text'] ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing:
                    bm['note'] != null && (bm['note'] as String).isNotEmpty
                        ? const Icon(Icons.sticky_note_2, color: Colors.amber)
                        : null,
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
                    // Remove from local storage
                    final updated = List<Map<String, dynamic>>.from(bookmarks);
                    updated.removeAt(index);
                    await _bookmarkLocalStorage.clearBookmarks();
                    for (final b in updated) {
                      await _bookmarkLocalStorage.addBookmark(b);
                    }
                    setState(() {
                      _bookmarksFuture = _bookmarkLocalStorage.getBookmarks();
                    });
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
