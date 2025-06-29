import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';

class AddEditSongPage extends StatefulWidget {
  final Song? songToEdit;
  const AddEditSongPage({super.key, this.songToEdit});

  @override
  State<AddEditSongPage> createState() => _AddEditSongPageState();
}

class _AddEditSongPageState extends State<AddEditSongPage> {
  final _formKey = GlobalKey<FormState>();
  final SongRepository _songRepository = SongRepository();
  bool get _isEditing => widget.songToEdit != null;

  late TextEditingController _numberController;
  late TextEditingController _titleController;
  // ✅ FIX: Make controller lists final
  final List<TextEditingController> _verseNumberControllers = [];
  final List<TextEditingController> _verseLyricsControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _numberController =
        TextEditingController(text: widget.songToEdit?.number ?? '');
    _titleController =
        TextEditingController(text: widget.songToEdit?.title ?? '');

    if (widget.songToEdit != null) {
      for (var verse in widget.songToEdit!.verses) {
        _verseNumberControllers.add(TextEditingController(text: verse.number));
        _verseLyricsControllers.add(TextEditingController(text: verse.lyrics));
      }
    } else {
      _addVerseField();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    for (var controller in _verseNumberControllers) {
      controller.dispose();
    }
    for (var controller in _verseLyricsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addVerseField() {
    setState(() {
      _verseNumberControllers.add(TextEditingController());
      _verseLyricsControllers.add(TextEditingController());
    });
  }

  void _removeVerseField(int index) {
    setState(() {
      _verseNumberControllers.removeAt(index).dispose();
      _verseLyricsControllers.removeAt(index).dispose();
    });
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      List<Verse> verses = [];
      for (int i = 0; i < _verseNumberControllers.length; i++) {
        verses.add(Verse(
          number: _verseNumberControllers[i].text,
          lyrics: _verseLyricsControllers[i].text,
        ));
      }

      final newSong = Song(
        number: _numberController.text,
        title: _titleController.text,
        verses: verses,
      );

      try {
        if (_isEditing) {
          await _songRepository.updateSong(widget.songToEdit!.number, newSong);
        } else {
          await _songRepository.addSong(newSong);
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error saving song: $e'),
              backgroundColor: Colors.red));
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'Add Song'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveSong)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Song Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Song Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Verses', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  ..._buildVerseFields(),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Verse'),
                    onPressed: _addVerseField,
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildVerseFields() {
    List<Widget> fields = [];
    for (int i = 0; i < _verseNumberControllers.length; i++) {
      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _verseNumberControllers[i],
                decoration: InputDecoration(labelText: 'Verse #${i + 1}'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _verseLyricsControllers[i],
                decoration: const InputDecoration(labelText: 'Lyrics'),
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeVerseField(i),
            )
          ],
        ),
      ));
    }
    return fields;
  }
}
