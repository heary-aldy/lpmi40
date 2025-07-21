// lib/src/features/admin/presentation/add_edit_song_page.dart
// ✅ COMPLETE WORKING VERSION: Syntax errors fixed, all methods implemented

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  collection.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${collection.songCount})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _audioUrlController,
                    decoration: InputDecoration(
                      labelText: 'Audio URL (Optional)',
                      hintText: 'e.g., https://... or Google Drive link',
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
                    onChanged: (value) {
                      setState(() {});
                      _autoConvertGoogleDriveLink(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  onPressed: _convertGoogleDriveLinkAction,
                  tooltip: 'Convert Google Drive Link',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
                if (_audioUrlController.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_circle),
                    onPressed: () => _testAudioUrl(_audioUrlController.text),
                    tooltip: 'Test Audio',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getUrlStatusMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getUrlStatusColor(),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_isGoogleDriveLink(_audioUrlController.text) &&
                    !_isConvertedGoogleDriveLink(_audioUrlController.text))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Auto-converted!',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersesList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _verseNumberControllers.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          // Reorder controllers and focus nodes
          final verseNumberController =
              _verseNumberControllers.removeAt(oldIndex);
          final verseLyricsController =
              _verseLyricsControllers.removeAt(oldIndex);
          final focusNode = _verseNumberFocusNodes.removeAt(oldIndex);

          _verseNumberControllers.insert(newIndex, verseNumberController);
          _verseLyricsControllers.insert(newIndex, verseLyricsController);
          _verseNumberFocusNodes.insert(newIndex, focusNode);
        });
      },
      itemBuilder: (context, i) {
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
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
      },
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

  void _convertGoogleDriveLinkAction() {
    final currentUrl = _audioUrlController.text.trim();
    if (currentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a Google Drive link first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final convertedUrl = _convertGoogleDriveLink(currentUrl);
    if (convertedUrl != null) {
      setState(() {
        _audioUrlController.text = convertedUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Drive link converted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid Google Drive link format. Please use a shareable link.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testAudioUrl(String url) {
    if (url.trim().isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AudioTestDialog(url: url),
    );
  }

  void _autoConvertGoogleDriveLink(String value) {
    if (_isGoogleDriveLink(value) && !_isConvertedGoogleDriveLink(value)) {
      final convertedUrl = _convertGoogleDriveLink(value);
      if (convertedUrl != null && convertedUrl != value) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _audioUrlController.text == value) {
            setState(() {
              _audioUrlController.text = convertedUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔄 Google Drive link auto-converted!'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    }
  }

  bool _isGoogleDriveLink(String url) {
    return url.contains('drive.google.com/file/d/') && url.contains('/view');
  }

  bool _isConvertedGoogleDriveLink(String url) {
    return url.contains('drive.google.com/uc?export=download');
  }

  String _getUrlStatusMessage() {
    final url = _audioUrlController.text.trim();
    if (url.isEmpty) {
      return 'Tip: Paste a Google Drive shareable link for auto-conversion, or any audio URL.';
    }
    if (_isConvertedGoogleDriveLink(url)) {
      return '✅ Google Drive link ready for direct download!';
    }
    if (_isGoogleDriveLink(url)) {
      return '🔄 Converting Google Drive link...';
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return '🎬 YouTube link detected - may require special handling.';
    }
    if (url.contains('soundcloud.com')) {
      return '🎵 SoundCloud link detected.';
    }
    if (RegExp(r'\.(mp3|wav|m4a|aac|ogg)(\?.*)?$', caseSensitive: false)
        .hasMatch(url)) {
      return '🎵 Direct audio file detected.';
    }
    return '🔗 Custom audio URL - test to verify functionality.';
  }

  Color _getUrlStatusColor() {
    final url = _audioUrlController.text.trim();
    if (url.isEmpty) return Colors.grey.shade600;
    if (_isConvertedGoogleDriveLink(url)) return Colors.green;
    if (_isGoogleDriveLink(url)) return Colors.blue;
    if (url.contains('youtube.com') || url.contains('youtu.be'))
      return Colors.red.shade600;
    if (url.contains('soundcloud.com')) return Colors.orange;
    if (RegExp(r'\.(mp3|wav|m4a|aac|ogg)(\?.*)?$', caseSensitive: false)
        .hasMatch(url)) return Colors.green;
    return Colors.grey.shade700;
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
                // ✅ RESPONSIVE FIX: Back button only shows on mobile devices to avoid double back buttons
                if (MediaQuery.of(context).size.width < 768.0)
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 8,
                    child: BackButton(
                      color: Theme.of(context).colorScheme.onPrimary,
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
}

/// Audio Test Dialog with actual playback functionality
class AudioTestDialog extends StatefulWidget {
  final String url;

  const AudioTestDialog({super.key, required this.url});

  @override
  State<AudioTestDialog> createState() => _AudioTestDialogState();
}

class _AudioTestDialogState extends State<AudioTestDialog> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioListeners() {
    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (_audioPlayer.playerState.processingState == ProcessingState.idle) {
        // First time loading this URL
        await _audioPlayer.setUrl(widget.url);
      }
      await _audioPlayer.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to play audio: ${e.toString()}';
      });
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to pause audio: ${e.toString()}';
      });
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to stop audio: ${e.toString()}';
      });
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to seek audio: ${e.toString()}';
      });
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.audiotrack,
                      color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Player Test',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Test audio playback functionality',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // URL Display
            const Text(
              'Audio URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                widget.url,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),

            // Audio Player Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  // Play/Pause Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      else
                        Material(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: _isPlaying ? _pauseAudio : _playAudio,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Material(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _stopAudio,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  if (_duration > Duration.zero) ...[
                    Row(
                      children: [
                        Text(
                          _formatDuration(_position),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12.0,
                                ),
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? (_position.inMilliseconds /
                                            _duration.inMilliseconds)
                                        .clamp(0.0, 1.0)
                                    : 0.0,
                                onChanged: (value) {
                                  final newPosition = Duration(
                                    milliseconds:
                                        (value * _duration.inMilliseconds)
                                            .round(),
                                  );
                                  _seekTo(newPosition);
                                },
                                activeColor: Colors.blue,
                                inactiveColor: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Error Display
            if (_hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy URL'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Production Ready: Full audio playback with seeking, play/pause controls, and real-time progress.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
