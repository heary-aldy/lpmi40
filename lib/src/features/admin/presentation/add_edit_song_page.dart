// lib/src/features/admin/presentation/add_edit_song_page.dart
// UI UPDATED: Using AdminHeader for consistent UI

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/widgets/admin_header.dart'; // ✅ NEW: Import AdminHeader

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
      // If adding a new song, start with one empty verse field.
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
    // Prevent removing the last verse field
    if (_verseNumberControllers.length > 1) {
      setState(() {
        _verseNumberControllers.removeAt(index).dispose();
        _verseLyricsControllers.removeAt(index).dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("A song must have at least one verse."),
        backgroundColor: Colors.orange,
      ));
    }
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      List<Verse> verses = [];
      for (int i = 0; i < _verseNumberControllers.length; i++) {
        verses.add(Verse(
          number: _verseNumberControllers[i].text.trim(),
          lyrics: _verseLyricsControllers[i].text.trim(),
        ));
      }

      final newSong = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
      );

      try {
        if (_isEditing) {
          await _songRepository.updateSong(widget.songToEdit!.number, newSong);
        } else {
          await _songRepository.addSong(newSong);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Song saved successfully!'),
              backgroundColor: Colors.green));
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
    // ✅ UI UPDATE: Replaced the original Scaffold with a CustomScrollView layout
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                AdminHeader(
                  title: _isEditing ? 'Edit Song' : 'Add New Song',
                  subtitle: _isEditing
                      ? 'Editing song #${_numberController.text}'
                      : 'Create a new song for the hymnal',
                  icon: _isEditing ? Icons.edit_note : Icons.add_circle,
                  primaryColor: Colors.green,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save Song',
                      onPressed: _isLoading ? null : _saveSong,
                    )
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _numberController,
                            decoration: const InputDecoration(
                              labelText: 'Song Number',
                              hintText: 'e.g., 121',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Song number is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Song Title',
                              hintText: 'e.g., Amazing Grace',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Song title is required' : null,
                          ),
                          const SizedBox(height: 24),
                          Text('Verses',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Divider(height: 16),
                          ..._buildVerseFields(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Another Verse'),
                            onPressed: _addVerseField,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveSong,
                            icon: const Icon(Icons.save),
                            label:
                                Text(_isEditing ? 'Save Changes' : 'Add Song'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildVerseFields() {
    return List.generate(_verseNumberControllers.length, (i) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Verse ${i + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_verseNumberControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      tooltip: 'Remove Verse ${i + 1}',
                      onPressed: () => _removeVerseField(i),
                    )
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _verseNumberControllers[i],
                decoration: const InputDecoration(
                  labelText: 'Verse Identifier',
                  hintText: 'e.g., 1, 2, Korus',
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Verse identifier is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _verseLyricsControllers[i],
                decoration: const InputDecoration(
                  labelText: 'Lyrics',
                  hintText: 'Enter the lyrics for this verse...',
                ),
                maxLines: 5,
                minLines: 3,
                validator: (v) => v!.isEmpty ? 'Lyrics are required' : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}
