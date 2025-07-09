// lib/src/features/admin/presentation/add_edit_song_page.dart
// ✅ UPDATED: Added audio URL support while maintaining all existing functionality

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';

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
  late TextEditingController _audioUrlController; // ✅ NEW: Audio URL controller
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
    _audioUrlController = // ✅ NEW: Initialize audio URL controller
        TextEditingController(text: widget.songToEdit?.audioUrl ?? '');

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
    _audioUrlController.dispose(); // ✅ NEW: Dispose audio URL controller
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

  // ✅ NEW: Audio URL validation helper
  String? _validateAudioUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Audio URL is optional
    }

    final trimmedValue = value.trim();

    // Basic URL validation
    final uri = Uri.tryParse(trimmedValue);
    if (uri == null || !uri.hasAbsolutePath) {
      return 'Please enter a valid URL';
    }

    // Check for common audio file extensions or streaming URLs
    final lowerUrl = trimmedValue.toLowerCase();
    final validExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
    final validDomains = [
      'drive.google.com',
      'soundcloud.com',
      'youtube.com',
      'youtu.be',
      'spotify.com'
    ];

    bool hasValidExtension =
        validExtensions.any((ext) => lowerUrl.contains(ext));
    bool hasValidDomain =
        validDomains.any((domain) => lowerUrl.contains(domain));

    if (!hasValidExtension && !hasValidDomain) {
      return 'URL should be an audio file or from a supported platform';
    }

    return null;
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

      // ✅ UPDATED: Create song with audio URL support
      final newSong = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
        audioUrl: _audioUrlController.text.trim().isEmpty
            ? null
            : _audioUrlController.text.trim(), // ✅ NEW: Include audio URL
      );

      try {
        if (_isEditing) {
          await _songRepository.updateSong(widget.songToEdit!.number, newSong);
        } else {
          await _songRepository.addSong(newSong);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
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
                              // ✅ EXISTING: Song Number field
                              TextFormField(
                                controller: _numberController,
                                decoration: const InputDecoration(
                                  labelText: 'Song Number',
                                  hintText: 'e.g., 121',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty
                                    ? 'Song number is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ✅ EXISTING: Song Title field
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Song Title',
                                  hintText: 'e.g., Amazing Grace',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? 'Song title is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ✅ NEW: Audio URL field
                              TextFormField(
                                controller: _audioUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Audio URL (Optional)',
                                  hintText:
                                      'e.g., https://drive.google.com/uc?export=download&id=...',
                                  border: const OutlineInputBorder(),
                                  suffixIcon:
                                      _audioUrlController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _audioUrlController.clear();
                                                });
                                              },
                                            )
                                          : const Icon(Icons.music_note),
                                  helperText:
                                      'Supports MP3, WAV, M4A, AAC, OGG files\nOr links from Google Drive, SoundCloud, YouTube, Spotify',
                                  helperMaxLines: 2,
                                ),
                                keyboardType: TextInputType.url,
                                validator: _validateAudioUrl,
                                onChanged: (value) {
                                  setState(
                                      () {}); // Refresh to show/hide clear button
                                },
                              ),
                              const SizedBox(height: 24),

                              // ✅ EXISTING: Verses section
                              Text('Verses',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const Divider(height: 16),
                              ..._buildVerseFields(),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Another Verse'),
                                onPressed: _addVerseField,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveSong,
                                icon: const Icon(Icons.save),
                                label: Text(
                                    _isEditing ? 'Save Changes' : 'Add Song'),
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
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 8,
                  child: BackButton(
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const SongManagementPage()),
                        (route) => false),
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
