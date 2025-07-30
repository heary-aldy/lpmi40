import 'package:flutter/material.dart';
import '../services/bible_service.dart';
import '../models/bible_models.dart';

class BibleBookmarksPage extends StatefulWidget {
  final BibleService bibleService;
  const BibleBookmarksPage({Key? key, required this.bibleService})
      : super(key: key);

  @override
  State<BibleBookmarksPage> createState() => _BibleBookmarksPageState();
}

class _BibleBookmarksPageState extends State<BibleBookmarksPage> {
  late Future<List<BibleBookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = widget.bibleService.getUserBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tandabuku Alkitab'),
        backgroundColor: Colors.brown,
      ),
      body: FutureBuilder<List<BibleBookmark>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ralat: ${snapshot.error}'));
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
                title: Text(bm.displayReference),
                subtitle: Text(bm.verseText,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: bm.note != null && bm.note!.isNotEmpty
                    ? const Icon(Icons.sticky_note_2, color: Colors.amber)
                    : null,
                onTap: () {
                  // TODO: Navigate to BibleReader at this verse
                  // Example: You can implement navigation if you have BibleBook/Chapter context
                },
                onLongPress: () async {
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Nota'),
                          onTap: () => Navigator.pop(context, 'edit'),
                        ),
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
                  if (action == 'edit') {
                    final note = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final controller =
                            TextEditingController(text: bm.note ?? '');
                        return AlertDialog(
                          title: const Text('Edit Nota'),
                          content: TextField(
                            controller: controller,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                hintText: 'Nota (pilihan)'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, controller.text),
                              child: const Text('Simpan'),
                            ),
                          ],
                        );
                      },
                    );
                    if (note != null) {
                      await widget.bibleService
                          .updateBookmark(bm.id, note, bm.tags);
                      setState(() {
                        _bookmarksFuture =
                            widget.bibleService.getUserBookmarks();
                      });
                    }
                  } else if (action == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Padam Tandabuku'),
                        content: const Text(
                            'Anda pasti mahu memadam tandabuku ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Padam'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.bibleService.removeBookmark(bm.id);
                      setState(() {
                        _bookmarksFuture =
                            widget.bibleService.getUserBookmarks();
                      });
                    }
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
