// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import 'package:lpmi40/src/features/songbook/models/song_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/admin/presentation/song_management_page.dart';

/// Page for adding and editing songs in the hymnal
class AddEditSongPage extends StatefulWidget {
  final Song? songToEdit;
  final String? preselectedCollection;

  const AddEditSongPage({
    super.key,
    this.songToEdit,
    this.preselectedCollection,
  });

  @override
  State<AddEditSongPage> createState() => _AddEditSongPageState();
}

class _AddEditSongPageState extends State<AddEditSongPage> {
  // Form and repository
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController();
  final _songRepository = SongRepository();
  final _collectionService = CollectionService();

  // Text controllers
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _audioUrlController;

  // Verse fields
  final _verseNumberControllers = <TextEditingController>[];
  final _verseLyricsControllers = <TextEditingController>[];
  final _verseNumberFocusNodes = <FocusNode>[];

  // Collection state
  final _availableCollections = <SongCollection>[];
  String? _selectedCollectionId;
  bool _collectionsLoaded = false;
  bool _isLoadingCollections = true;
  bool _isSaving = false;

  bool get _isEditing => widget.songToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCollections();
  }

  @override
  void dispose() {
    _formScrollController.dispose();
    _numberController.dispose();
    _titleController.dispose();
    _audioUrlController.dispose();

    for (final controller in _verseNumberControllers) {
      controller.dispose();
    }
    for (final controller in _verseLyricsControllers) {
      controller.dispose();
    }
    for (final node in _verseNumberFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _initializeControllers() {
    _numberController =
        TextEditingController(text: widget.songToEdit?.number ?? '');
    _titleController =
        TextEditingController(text: widget.songToEdit?.title ?? '');
    _audioUrlController =
        TextEditingController(text: widget.songToEdit?.audioUrl ?? '');

    // Set initial collection selection
    _selectedCollectionId = widget.preselectedCollection ??
        widget.songToEdit?.collectionId ??
        'LPMI';

    if (widget.songToEdit != null) {
      for (final verse in widget.songToEdit!.verses) {
        _verseNumberControllers.add(TextEditingController(text: verse.number));
        _verseLyricsControllers.add(TextEditingController(text: verse.lyrics));
        _verseNumberFocusNodes.add(FocusNode());
      }
    } else {
      _addVerseField();
    }
  }

  Future<void> _loadCollections() async {
    try {
      setState(() => _isLoadingCollections = true);

      final collections = await _collectionService.getAccessibleCollections();
      collections.sort((a, b) {
        final aOrder = a.metadata?['display_order'] as int? ?? 999;
        final bOrder = b.metadata?['display_order'] as int? ?? 999;
        return aOrder == bOrder
            ? a.name.compareTo(b.name)
            : aOrder.compareTo(bOrder);
      });

      if (mounted) {
        setState(() {
          _availableCollections
            ..clear()
            ..addAll(collections);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading collections: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addVerseField() {
    setState(() {
      _verseNumberControllers.add(TextEditingController());
      _verseLyricsControllers.add(TextEditingController());
      _verseNumberFocusNodes.add(FocusNode());
    });

    // Auto-focus new verse identifier field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_verseNumberFocusNodes.isNotEmpty) {
        _verseNumberFocusNodes.last.requestFocus();
      }
    });
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

      final song = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
        audioUrl: _audioUrlController.text.trim().isEmpty
            ? null
            : _audioUrlController.text.trim(),
        collectionId: _selectedCollectionId!,
      );

      if (_isEditing) {
        await _songRepository.updateSong(widget.songToEdit!.number, song);
        if (widget.songToEdit!.collectionId != _selectedCollectionId) {
          await _handleCollectionChange(song);
        }
      } else {
        await _songRepository.addSong(song);
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

  Future<void> _handleCollectionChange(Song song) async {
    try {
      if (widget.songToEdit!.collectionId != null) {
        await _collectionService.removeSongFromCollection(
            widget.songToEdit!.collectionId!, song.number);
      }
      await _collectionService.addSongToCollection(
          _selectedCollectionId!, song);
    } catch (e) {
      debugPrint('Warning: Collection change failed: $e');
    }
  }

  void _removeVerseField(int index) {
    if (_verseNumberControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A song must have at least one verse"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _verseNumberControllers[index].dispose();
      _verseLyricsControllers[index].dispose();
      _verseNumberFocusNodes[index].dispose();

      _verseNumberControllers.removeAt(index);
      _verseLyricsControllers.removeAt(index);
      _verseNumberFocusNodes.removeAt(index);
    });
  }

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
        setState(() => _selectedCollectionId = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a collection';
        }
        return null;
      },
    );
  }

  Widget _buildSongInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _numberController,
          decoration: const InputDecoration(
            labelText: 'Song Number',
            hintText: 'e.g., 121',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Song number is required' : null,
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
          validator: (v) => v!.isEmpty ? 'Song title is required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _audioUrlController,
                decoration: InputDecoration(
                  labelText: 'Audio URL (Optional)',
                  hintText: 'e.g., https://...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.music_note),
                  suffixIcon: _audioUrlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _audioUrlController.clear()),
                        )
                      : null,
                ),
                validator: _validateAudioUrl,
                onChanged: (value) => setState(() {}),
              ),
            ),
            if (_audioUrlController.text.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_circle),
                onPressed: () => _previewAudio(_audioUrlController.text),
                tooltip: 'Preview audio',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVersesList() {
    final itemCount = _verseNumberControllers.length;
    final itemHeight = 160.0;
    final maxVisible = 5;
    final height = itemCount <= maxVisible
        ? itemCount * itemHeight
        : maxVisible * itemHeight;

    return SizedBox(
      height: height,
      child: ReorderableListView(
        shrinkWrap: true,
        physics: itemCount <= maxVisible
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final numCtrl = _verseNumberControllers.removeAt(oldIndex);
            final lyrCtrl = _verseLyricsControllers.removeAt(oldIndex);
            final node = _verseNumberFocusNodes.removeAt(oldIndex);
            _verseNumberControllers.insert(newIndex, numCtrl);
            _verseLyricsControllers.insert(newIndex, lyrCtrl);
            _verseNumberFocusNodes.insert(newIndex, node);
          });
        },
        children: List.generate(_verseNumberControllers.length, (i) {
          return Card(
            key: ValueKey('verse_$i'),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verse ${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_verseNumberControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Remove Verse ${i + 1}',
                          onPressed: () => _removeVerseField(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _verseNumberControllers[i],
                    focusNode: _verseNumberFocusNodes[i],
                    decoration: const InputDecoration(
                      labelText: 'Verse Identifier',
                      hintText: 'e.g., 1, 2, Korus',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Verse identifier is required' : null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
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
                    textInputAction: i == _verseNumberControllers.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getCollectionColor(SongCollection collection) {
    if (collection.metadata?.containsKey('display_color') == true) {
      return _getColorFromName(collection.metadata!['display_color'] as String);
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
      return _getIconFromName(collection.metadata!['display_icon'] as String);
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

  String? _convertGoogleDriveLink(String url) {
    final regExp =
        RegExp(r"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view");
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return null;
  }

  void _previewAudio(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text('Copy and test in browser or use a player package.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  controller: _formScrollController,
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCollectionDropdown(),
                              const SizedBox(height: 16),
                              _buildSongInfoSection(),
                              const SizedBox(height: 16),
                              _buildVersesList(),
                              const SizedBox(height: 16),
                              _buildAddVerseButton(),
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
                        builder: (context) => const SongManagementPage(),
                      ),
                      (route) => false,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddVerseButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton.icon(
        onPressed: _addVerseField,
        icon: const Icon(Icons.add),
        label: const Text('Add Verse'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
