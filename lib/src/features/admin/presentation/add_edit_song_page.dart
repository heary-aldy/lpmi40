// lib/src/features/admin/presentation/add_edit_song_page.dart
// ✅ ENHANCED: Added collection selection and improved song management
// ✅ INTEGRATION: Full collection system support with metadata
// ✅ AUDIO: Maintained existing audio URL functionality
// ✅ FIXED: Corrected constructor calls and method arguments to resolve build errors.

import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';

// ✅ NEW: Collection integration imports
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';

class AddEditSongPage extends StatefulWidget {
  final Song? songToEdit;
  final String? preselectedCollection; // ✅ NEW: For pre-selecting collection

  const AddEditSongPage({
    super.key,
    this.songToEdit,
    this.preselectedCollection,
  });

  @override
  State<AddEditSongPage> createState() => _AddEditSongPageState();
}

class _AddEditSongPageState extends State<AddEditSongPage> {
  final _formKey = GlobalKey<FormState>();
  final SongRepository _songRepository = SongRepository();
  final CollectionService _collectionService = CollectionService(); // ✅ NEW

  bool get _isEditing => widget.songToEdit != null;

  // ✅ EXISTING: Form controllers
  late TextEditingController _numberController;
  late TextEditingController _titleController;
  late TextEditingController _audioUrlController;
  final List<TextEditingController> _verseNumberControllers = [];
  final List<TextEditingController> _verseLyricsControllers = [];

  // ✅ NEW: Collection-related state
  List<SongCollection> _availableCollections = [];
  String? _selectedCollectionId;
  bool _collectionsLoaded = false;
  bool _isLoadingCollections = true;

  final bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCollections();
  }

  void _initializeControllers() {
    _numberController =
        TextEditingController(text: widget.songToEdit?.number ?? '');
    _titleController =
        TextEditingController(text: widget.songToEdit?.title ?? '');
    _audioUrlController =
        TextEditingController(text: widget.songToEdit?.audioUrl ?? '');

    // ✅ NEW: Set initial collection selection
    _selectedCollectionId = widget.preselectedCollection ??
        widget.songToEdit?.collectionId ??
        'LPMI'; // Default to LPMI

    if (widget.songToEdit != null) {
      for (var verse in widget.songToEdit!.verses) {
        _verseNumberControllers.add(TextEditingController(text: verse.number));
        _verseLyricsControllers.add(TextEditingController(text: verse.lyrics));
      }
    } else {
      _addVerseField();
    }
  }

  // ✅ NEW: Load available collections
  Future<void> _loadCollections() async {
    try {
      setState(() => _isLoadingCollections = true);

      final collections = await _collectionService.getAccessibleCollections();

      // Sort by display order from metadata
      collections.sort((a, b) {
        final aOrder = a.metadata?['display_order'] as int? ?? 999;
        final bOrder = b.metadata?['display_order'] as int? ?? 999;

        if (aOrder == bOrder) {
          return a.name.compareTo(b.name);
        }
        return aOrder.compareTo(bOrder);
      });

      if (mounted) {
        setState(() {
          _availableCollections = collections;
          _collectionsLoaded = true;
          _isLoadingCollections = false;

          // Validate selected collection exists
          if (_selectedCollectionId != null &&
              !collections.any((c) => c.id == _selectedCollectionId)) {
            _selectedCollectionId =
                collections.isNotEmpty ? collections.first.id : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCollections = false;
          _collectionsLoaded = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading collections: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _audioUrlController.dispose();
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

  String? _validateAudioUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final url = value.trim();
    final validPatterns = [
      r'^https?://.*\.(mp3|wav|m4a|aac|ogg)(\?.*)?$',
      r'^https://drive\.google\.com/.*',
      r'^https://soundcloud\.com/.*',
      r'^https://.*\.soundcloud\.com/.*',
      r'^https://open\.spotify\.com/.*',
      r'^https://youtube\.com/.*',
      r'^https://youtu\.be/.*',
      r'^https://.*\.youtube\.com/.*',
    ];

    bool isValid = validPatterns
        .any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url));

    if (!isValid) {
      return 'Please enter a valid audio URL or supported streaming link';
    }
    return null;
  }

  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fix the errors in the form."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_selectedCollectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select a collection for this song."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final verses = <Verse>[];
      for (int i = 0; i < _verseNumberControllers.length; i++) {
        if (_verseNumberControllers[i].text.isNotEmpty &&
            _verseLyricsControllers[i].text.isNotEmpty) {
          verses.add(Verse(
            number: _verseNumberControllers[i].text.trim(),
            lyrics: _verseLyricsControllers[i].text.trim(),
          ));
        }
      }

      if (verses.isEmpty) {
        throw Exception("Please add at least one verse with content.");
      }

      // ✅ ENHANCED: Create song with collection context
      // ✅ FIX: Removed the 'createdAt' parameter which was causing the error.
      final song = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
        audioUrl: _audioUrlController.text.trim().isEmpty
            ? null
            : _audioUrlController.text.trim(),
        collectionId: _selectedCollectionId!, // ✅ NEW: Collection assignment
      );

      if (_isEditing) {
        // ✅ FIX: Provided the original song number as the first argument.
        await _songRepository.updateSong(widget.songToEdit!.number, song);

        // ✅ NEW: Handle collection changes
        if (widget.songToEdit!.collectionId != _selectedCollectionId) {
          // Song moved to different collection
          await _handleCollectionChange(song);
        }
      } else {
        await _songRepository.addSong(song);

        // ✅ NEW: Add to selected collection
        await _collectionService.addSongToCollection(
            _selectedCollectionId!, song);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing
              ? 'Song updated successfully!'
              : 'Song added successfully!'),
          backgroundColor: Colors.green,
        ));

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SongManagementPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving song: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ✅ NEW: Handle collection changes for existing songs
  Future<void> _handleCollectionChange(Song song) async {
    try {
      // Remove from old collection
      if (widget.songToEdit!.collectionId != null) {
        await _collectionService.removeSongFromCollection(
            widget.songToEdit!.collectionId!, song.number);
      }

      // Add to new collection
      await _collectionService.addSongToCollection(
          _selectedCollectionId!, song);
    } catch (e) {
      debugPrint('Warning: Collection change failed: $e');
      // Don't throw - song was still saved
    }
  }

  // ✅ NEW: Get collection display info
  Color _getCollectionColor(SongCollection collection) {
    if (collection.metadata?.containsKey('display_color') == true) {
      return _getColorFromName(collection.metadata!['display_color']);
    }

    switch (collection.id) {
      case 'LPMI':
        return Colors.blue;
      case 'SRD':
        return Colors.purple;
      case 'Lagu_belia':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getCollectionIcon(SongCollection collection) {
    if (collection.metadata?.containsKey('display_icon') == true) {
      return _getIconFromName(collection.metadata!['display_icon']);
    }

    switch (collection.id) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      default:
        return Icons.folder_special;
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'library_music':
        return Icons.library_music;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'child_care':
        return Icons.child_care;
      case 'folder_special':
        return Icons.folder_special;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.folder_special;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isSaving
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
                          onPressed: _isSaving ? null : _saveSong,
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
                              // ✅ NEW: Collection Selection Section
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.folder_special,
                                              color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Collection Assignment',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCollectionDropdown(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ✅ EXISTING: Basic Song Information
                              Text(
                                'Song Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _numberController,
                                decoration: const InputDecoration(
                                  labelText: 'Song Number',
                                  hintText: 'e.g., 121',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty
                                    ? 'Song number is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Song Title',
                                  hintText: 'e.g., Amazing Grace',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.title),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? 'Song title is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ✅ EXISTING: Audio URL field
                              TextFormField(
                                controller: _audioUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Audio URL (Optional)',
                                  hintText:
                                      'e.g., https://drive.google.com/uc?export=download&id=...',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.music_note),
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
                                          : null,
                                  helperText:
                                      'Supports MP3, WAV, M4A, AAC, OGG files\nOr links from Google Drive, SoundCloud, YouTube, Spotify',
                                  helperMaxLines: 2,
                                ),
                                keyboardType: TextInputType.url,
                                validator: _validateAudioUrl,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 24),

                              // ✅ EXISTING: Verses section
                              Text(
                                'Verses',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
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
                                onPressed: _isSaving ? null : _saveSong,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.save),
                                label: Text(_isSaving
                                    ? 'Saving...'
                                    : (_isEditing
                                        ? 'Save Changes'
                                        : 'Add Song')),
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

  // ✅ NEW: Build collection dropdown with rich display
  Widget _buildCollectionDropdown() {
    if (_isLoadingCollections) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading collections...'),
        ],
      );
    }

    if (!_collectionsLoaded || _availableCollections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collections Not Available',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                      'Unable to load collections. Using default collection.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadCollections,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCollectionId,
      decoration: const InputDecoration(
        labelText: 'Target Collection',
        border: OutlineInputBorder(),
        helperText: 'Select which collection this song belongs to',
      ),
      items: _availableCollections.map((collection) {
        final color = _getCollectionColor(collection);
        final icon = _getCollectionIcon(collection);

        return DropdownMenuItem<String>(
          value: collection.id,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (collection.description.isNotEmpty)
                      Text(
                        collection.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${collection.songCount} songs',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCollectionId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a collection';
        }
        return null;
      },
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
                  Text(
                    'Verse ${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Verse identifier is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _verseLyricsControllers[i],
                decoration: const InputDecoration(
                  labelText: 'Verse Lyrics',
                  hintText: 'Enter the lyrics for this verse...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'Verse lyrics are required' : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}
