// lib/src/features/admin/presentation/add_edit_song_page.dart
// ✅ COMPLETE WORKING VERSION: Syntax errors fixed, all methods implemented

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
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

  // ✅ ADD: Audio validation caching to prevent excessive logging
  String? _lastValidatedAudioUrl;
  bool _cachedAudioValidationResult = false;

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
    debugPrint('🔧 [AddEditSongPage] Initializing controllers:');
    debugPrint(
        '  songToEdit: ${widget.songToEdit?.number} - ${widget.songToEdit?.title}');
    debugPrint('  songToEdit collection: ${widget.songToEdit?.collectionId}');
    debugPrint('  preselectedCollection: ${widget.preselectedCollection}');
    debugPrint('  isEditing: $_isEditing');

    _numberController =
        TextEditingController(text: widget.songToEdit?.number ?? '');
    _titleController =
        TextEditingController(text: widget.songToEdit?.title ?? '');
    _audioUrlController =
        TextEditingController(text: widget.songToEdit?.audioUrl ?? '');

    // ✅ IMPROVED: Set initial collection selection with better logic
    if (_isEditing && widget.songToEdit?.collectionId != null) {
      _selectedCollectionId = widget.songToEdit!.collectionId;
      debugPrint(
          '✅ [AddEditSongPage] Set collection from existing song: $_selectedCollectionId');
    } else if (widget.preselectedCollection != null) {
      _selectedCollectionId = widget.preselectedCollection!;
      debugPrint(
          '✅ [AddEditSongPage] Set collection from preselected: $_selectedCollectionId');
    } else {
      _selectedCollectionId = 'LPMI'; // Default fallback
      debugPrint(
          '✅ [AddEditSongPage] Set collection to default: $_selectedCollectionId');
    }

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

          // ✅ IMPROVED: Validate and preserve selected collection
          final originalSelection = _selectedCollectionId;
          debugPrint(
              '🔍 [AddEditSongPage] Validating collection selection: $originalSelection');
          debugPrint(
              '🔍 [AddEditSongPage] Available collections: ${collections.map((c) => '${c.id}:${c.name}').toList()}');

          if (_selectedCollectionId != null &&
              !collections.any((c) => c.id == _selectedCollectionId)) {
            debugPrint(
                '⚠️ [AddEditSongPage] Selected collection "$_selectedCollectionId" not found in available collections');
            debugPrint(
                '🔄 [AddEditSongPage] Setting to first available collection');
            _selectedCollectionId =
                collections.isNotEmpty ? collections.first.id : null;
          } else if (_selectedCollectionId != null &&
              collections.any((c) => c.id == _selectedCollectionId)) {
            debugPrint(
                '✅ [AddEditSongPage] Collection "$_selectedCollectionId" is valid and available');
          }

          debugPrint(
              '✅ [AddEditSongPage] Final collection selection: $_selectedCollectionId');
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
    debugPrint('💾 [AddEditSongPage] _saveSong() called');
    debugPrint('  Form valid: ${_formKey.currentState!.validate()}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [AddEditSongPage] Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fix the errors in the form."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_selectedCollectionId == null) {
      debugPrint('❌ [AddEditSongPage] No collection selected');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select a collection for this song."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    debugPrint(
        '✅ [AddEditSongPage] Collection selected: $_selectedCollectionId');

    // ✅ NEW: Check for duplicates when creating new songs
    if (!_isEditing) {
      debugPrint('🔍 [AddEditSongPage] Checking for duplicate songs...');
      try {
        final existingSongs = await _songRepository.getCollectionsSeparated();
        final selectedCollectionSongs =
            existingSongs[_selectedCollectionId] ?? [];
        final newSongNumber = _numberController.text.trim();
        final newSongTitle = _titleController.text.trim();

        // Check for duplicate song number in the same collection
        final duplicateNumber =
            selectedCollectionSongs.any((s) => s.number == newSongNumber);
        if (duplicateNumber) {
          debugPrint(
              '❌ [AddEditSongPage] Duplicate song number found: $newSongNumber in $_selectedCollectionId');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Song #$newSongNumber already exists in ${_getSelectedCollectionName()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'View Existing',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Go back to song management
              },
            ),
          ));
          return;
        }

        // Check for duplicate title in the same collection (optional warning)
        final duplicateTitle = selectedCollectionSongs.any((s) =>
            s.title.toLowerCase().trim() == newSongTitle.toLowerCase().trim());
        if (duplicateTitle) {
          debugPrint(
              '⚠️ [AddEditSongPage] Duplicate song title found: $newSongTitle in $_selectedCollectionId');
          final shouldContinue = await _showDuplicateTitleDialog(newSongTitle);
          if (!shouldContinue) {
            debugPrint(
                '🚫 [AddEditSongPage] User cancelled due to duplicate title');
            return;
          }
        }

        debugPrint(
            '✅ [AddEditSongPage] No duplicates found, proceeding with save');
      } catch (e) {
        debugPrint('❌ [AddEditSongPage] Error checking for duplicates: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error checking for duplicates: $e'),
          backgroundColor: Colors.orange,
        ));
        // Continue with save despite error
      }
    }

    // ✅ NEW: Show confirmation dialog for editing operations
    if (_isEditing) {
      final shouldProceed = await _showEditConfirmationDialog();
      if (!shouldProceed) {
        debugPrint('🚫 [AddEditSongPage] User cancelled the save operation');
        return;
      }
    }

    // ✅ CRITICAL FIX: Ensure Google Drive link is properly converted before saving
    await _ensureAudioUrlIsConverted();

    setState(() => _isSaving = true);

    try {
      final verses = <Verse>[];
      for (int i = 0; i < _verseNumberControllers.length; i++) {
        if (_verseNumberControllers[i].text.isNotEmpty &&
            _verseLyricsControllers[i].text.isNotEmpty) {
          verses.add(Verse(
            number: _verseNumberControllers[i].text.trim(),
            lyrics: _verseLyricsControllers[i].text.trim(),
            order:
                i, // ✅ NEW: Set order based on current position after reordering
          ));
        }
      }

      if (verses.isEmpty) {
        throw Exception("Please add at least one verse with content.");
      }

      final finalAudioUrl = _getFinalAudioUrl();
      debugPrint(
          '🎵 [AddEditSongPage] Final audio URL for saving: "$finalAudioUrl"');

      final song = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
        audioUrl: finalAudioUrl,
        collectionId: _selectedCollectionId!,
      );

      if (_isEditing) {
        debugPrint('🔧 [AddEditSongPage] Updating song:');
        debugPrint('  Original number: ${widget.songToEdit!.number}');
        debugPrint('  New number: ${song.number}');
        debugPrint('  Original collection: ${widget.songToEdit!.collectionId}');
        debugPrint('  New collection: ${song.collectionId}');
        debugPrint('  Is editing mode: $_isEditing');

        // ✅ CRITICAL FIX: Handle in-place updates vs moves/number changes differently
        final originalCollection = widget.songToEdit!.collectionId;
        final originalNumber = widget.songToEdit!.number;
        final newCollection = _selectedCollectionId;
        final newNumber = song.number;

        final collectionsEqual = (originalCollection == newCollection);
        final numbersEqual = (originalNumber == newNumber);
        final isInPlaceUpdate = collectionsEqual && numbersEqual;

        debugPrint('🔍 [AddEditSongPage] Update analysis:');
        debugPrint('  Original: "$originalCollection/$originalNumber"');
        debugPrint('  New: "$newCollection/$newNumber"');
        debugPrint('  Collections equal: $collectionsEqual');
        debugPrint('  Numbers equal: $numbersEqual');
        debugPrint('  Is in-place update: $isInPlaceUpdate');

        if (isInPlaceUpdate) {
          debugPrint(
              '🔄 [AddEditSongPage] Performing in-place update (no duplicates)');
          // For in-place updates, find the song index and update directly
          try {
            final collections = await _songRepository.getCollectionsSeparated();
            final collectionSongs = collections[originalCollection] ?? [];

            // Find the song's array index
            int songIndex = -1;
            for (int i = 0; i < collectionSongs.length; i++) {
              if (collectionSongs[i].number == originalNumber) {
                songIndex = i;
                break;
              }
            }

            if (songIndex >= 0) {
              debugPrint(
                  '🎯 [AddEditSongPage] Found song at index $songIndex, updating directly');
              // Use Firebase database directly to update the specific array index
              final database = FirebaseDatabase.instance;
              final songRef = database
                  .ref('song_collection/$originalCollection/songs/$songIndex');
              final songData = song.toJson();
              // Remove collection_id from the data since it's stored at the collection level
              songData.remove('collection_id');
              await songRef.update(songData);
              debugPrint(
                  '✅ [AddEditSongPage] Direct Firebase update completed');
            } else {
              debugPrint(
                  '❌ [AddEditSongPage] Could not find song index, falling back to full update');
              await _songRepository.updateSong(originalNumber, song);
            }
          } catch (e) {
            debugPrint(
                '❌ [AddEditSongPage] Direct update failed: $e, falling back to full update');
            await _songRepository.updateSong(originalNumber, song);
          }
          debugPrint('✅ [AddEditSongPage] In-place update completed');
        } else {
          debugPrint('🔄 [AddEditSongPage] Performing move/rename operation');
          // For moves or number changes, use full updateSong (which may create duplicates but handles moves)
          await _songRepository.updateSong(originalNumber, song);
          debugPrint('✅ [AddEditSongPage] Move/rename operation completed');
        }
      } else {
        debugPrint(
            '➕ [AddEditSongPage] Creating new song in collection: $_selectedCollectionId');
        // ✅ FIX: Only call addSong() - it already handles collection assignment
        await _songRepository.addSong(song);
        debugPrint('✅ [AddEditSongPage] Song created successfully');
      }

      debugPrint('✅ [AddEditSongPage] Save operation completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing
              ? 'Song updated successfully!'
              : 'Song added successfully!'),
          backgroundColor: Colors.green,
        ));

        debugPrint(
            '🔄 [AddEditSongPage] Navigating back to SongManagementPage');

        // ✅ NEW: Force refresh collections to show updated data without duplicates
        await _songRepository.getCollectionsSeparated(forceRefresh: true);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SongManagementPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AddEditSongPage] Save operation failed: $e');
      debugPrint(
          '❌ [AddEditSongPage] Error stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving song: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      debugPrint(
          '🔄 [AddEditSongPage] Save operation finished, resetting _isSaving');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// ✅ NEW: Show dialog when duplicate title is detected
  Future<bool> _showDuplicateTitleDialog(String title) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Duplicate Title Warning',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A song with the title "$title" already exists in ${_getSelectedCollectionName()}.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This might be a duplicate song. Consider checking the existing song before proceeding.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Do you want to continue anyway?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Cancel this dialog
                    Navigator.of(context).pop(); // Go back to song management
                  },
                  child: const Text(
                    'Check Existing',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue Anyway'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// ✅ NEW: Get the display name of the selected collection
  String _getSelectedCollectionName() {
    if (_selectedCollectionId == null || _selectedCollectionId == 'All') {
      return 'All Collections';
    }

    // Find the collection name from the available collections
    final collection = _availableCollections.firstWhere(
      (c) => c.id == _selectedCollectionId,
      orElse: () => SongCollection(
        id: _selectedCollectionId!,
        name: _selectedCollectionId!,
        description: '',
        accessLevel: CollectionAccessLevel.public,
        status: CollectionStatus.active,
        songCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'unknown',
      ),
    );

    return collection.name;
  }

  /// ✅ NEW: Show confirmation dialog for editing operations
  Future<bool> _showEditConfirmationDialog() async {
    // Check if song number or collection has changed
    final hasNumberChanged =
        _numberController.text.trim() != widget.songToEdit!.number;
    final hasCollectionChanged =
        _selectedCollectionId != widget.songToEdit!.collectionId;
    final hasSignificantChanges = hasNumberChanged || hasCollectionChanged;

    final selectedCollection =
        _availableCollections.firstWhere((c) => c.id == _selectedCollectionId,
            orElse: () => SongCollection(
                  id: _selectedCollectionId!,
                  name: _selectedCollectionId!,
                  description: '',
                  accessLevel: CollectionAccessLevel.public,
                  status: CollectionStatus.active,
                  songCount: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: 'unknown',
                ));

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.save, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Save Song Changes',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are about to save changes to:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : colorScheme.primaryContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.primary.withOpacity(0.5)
                              : colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.music_note,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Song: ${widget.songToEdit!.number} - ${widget.songToEdit!.title}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.folder,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Collection: ${selectedCollection.name}',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (hasSignificantChanges) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.orange.withOpacity(0.5)
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Significant Changes Detected:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.orange.shade200
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (hasNumberChanged)
                              Text(
                                '• Song number: ${widget.songToEdit!.number} → ${_numberController.text.trim()}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade700,
                                ),
                              ),
                            if (hasCollectionChanged)
                              Text(
                                '• Collection: ${widget.songToEdit!.collectionId} → $_selectedCollectionId',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Choose how you want to proceed:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                if (hasSignificantChanges) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(false); // Close dialog first
                      _saveAsNewSong(); // Then create new song
                    },
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Save as New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.save, size: 16),
                  label: Text(hasSignificantChanges
                      ? 'Overwrite Original'
                      : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSignificantChanges
                        ? Colors.orange
                        : colorScheme.primary,
                    foregroundColor: hasSignificantChanges
                        ? Colors.white
                        : colorScheme.onPrimary,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// ✅ NEW: Save current form data as a new song (instead of overwriting)
  Future<void> _saveAsNewSong() async {
    debugPrint('💾 [AddEditSongPage] _saveAsNewSong() called');

    // ✅ CRITICAL FIX: Ensure Google Drive link is properly converted before saving
    await _ensureAudioUrlIsConverted();

    setState(() => _isSaving = true);

    try {
      final verses = <Verse>[];
      for (int i = 0; i < _verseNumberControllers.length; i++) {
        if (_verseNumberControllers[i].text.isNotEmpty &&
            _verseLyricsControllers[i].text.isNotEmpty) {
          verses.add(Verse(
            number: _verseNumberControllers[i].text.trim(),
            lyrics: _verseLyricsControllers[i].text.trim(),
            order: i,
          ));
        }
      }

      if (verses.isEmpty) {
        throw Exception("Please add at least one verse with content.");
      }

      final finalAudioUrl = _getFinalAudioUrl();
      debugPrint(
          '🎵 [AddEditSongPage] Final audio URL for new song: "$finalAudioUrl"');

      final newSong = Song(
        number: _numberController.text.trim(),
        title: _titleController.text.trim(),
        verses: verses,
        audioUrl: finalAudioUrl,
        collectionId: _selectedCollectionId!,
      );

      debugPrint('🆕 [AddEditSongPage] Creating new song:');
      debugPrint('  Number: ${newSong.number}');
      debugPrint('  Title: ${newSong.title}');
      debugPrint('  Collection: ${newSong.collectionId}');

      // Create as new song
      await _songRepository.addSong(newSong);

      debugPrint('✅ [AddEditSongPage] New song created successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'New song "${newSong.number} - ${newSong.title}" created successfully!'),
          backgroundColor: Colors.green,
        ));

        debugPrint(
            '🔄 [AddEditSongPage] Navigating back to SongManagementPage');

        // ✅ NEW: Force refresh collections to show updated data without duplicates
        await _songRepository.getCollectionsSeparated(forceRefresh: true);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SongManagementPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AddEditSongPage] Create new song operation failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error creating new song: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      debugPrint(
          '🔄 [AddEditSongPage] Create new song operation finished, resetting _isSaving');
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCollectionId,
                decoration: InputDecoration(
                  labelText: 'Target Collection',
                  border: const OutlineInputBorder(),
                  helperText: _isEditing
                      ? 'Current collection: ${widget.songToEdit?.collectionId ?? "Unknown"}'
                      : 'Select which collection this song belongs to',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadCollections,
                    tooltip: 'Refresh collections',
                  ),
                ),
                items: _availableCollections.map((collection) {
                  final color = _getCollectionColor(collection);
                  final icon = _getCollectionIcon(collection);
                  final isActiveCollection =
                      collection.status == CollectionStatus.active;

                  return DropdownMenuItem<String>(
                    value: collection.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                collection.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isActiveCollection ? null : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isActiveCollection)
                                Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${collection.songCount} songs',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (collection.accessLevel !=
                                CollectionAccessLevel.public)
                              Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.orange.shade600,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCollectionId = value);
                  debugPrint(
                      '📁 [AddEditSongPage] Collection changed to: $value');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a collection';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_isEditing &&
            _selectedCollectionId != widget.songToEdit?.collectionId) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Collection will be moved from "${widget.songToEdit?.collectionId}" to "$_selectedCollectionId"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          key: ValueKey('verse_$i'),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withOpacity(0.7),
                    ]
                  : [
                      Colors.white,
                      colorScheme.primaryContainer.withOpacity(0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced header with gradient background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.primary.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verse ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ReorderableDragStartListener(
                              index: i,
                              child: const Icon(
                                Icons.drag_handle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_verseNumberControllers.length > 1)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Remove Verse ${i + 1}',
                                onPressed: () => _removeVerseField(i),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Enhanced verse identifier field
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh.withOpacity(0.5)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: TextFormField(
                    controller: _verseNumberControllers[i],
                    focusNode: _verseNumberFocusNodes[i],
                    decoration: InputDecoration(
                      labelText: 'Verse Identifier',
                      hintText: 'e.g., 1, 2, Korus, Bridge',
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Verse identifier is required' : null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Enhanced lyrics field with preview
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verse Lyrics',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHigh.withOpacity(0.5)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: TextFormField(
                        controller: _verseLyricsControllers[i],
                        decoration: InputDecoration(
                          hintText: 'Enter the lyrics for this verse...\nPress Enter for new lines',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            height: 1.4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: null,
                        minLines: 4,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Verse lyrics are required' : null,
                        onChanged: (value) {
                          // Trigger rebuild to update preview
                          setState(() {});
                        },
                      ),
                    ),
                    
                    // Live preview of formatted lyrics
                    if (_verseLyricsControllers[i].text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.primaryContainer.withOpacity(0.1)
                              : colorScheme.primaryContainer.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _verseLyricsControllers[i].text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Helper text
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tip: Press Enter to create new lines in your lyrics',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddVerseButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade600,
              Colors.green.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _addVerseField,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: const Text(
            'Add New Verse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final url = value.trim();

    // ✅ FIX: Only validate if URL actually changed to prevent excessive logging
    if (_lastValidatedAudioUrl != url) {
      debugPrint('🔍 [AddEditSongPage] Validating audio URL: "$url"');
      _lastValidatedAudioUrl = url;

      final validPatterns = [
        r'^https?://.*\.(mp3|wav|m4a|aac|ogg)(\?.*)?$',
        r'^https://drive\.google\.com/.*',
        r'^https://drive\.usercontent\.google\.com/.*', // ✅ FIXED: Support converted Google Drive URLs
        r'^https://soundcloud\.com/.*',
        r'^https://.*\.soundcloud\.com/.*',
        r'^https://open\.spotify\.com/.*',
        r'^https://youtube\.com/.*',
        r'^https://youtu\.be/.*',
        r'^https://.*\.youtube\.com/.*',
      ];

      _cachedAudioValidationResult = validPatterns.any(
          (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url));

      debugPrint(
          '🔍 [AddEditSongPage] Audio URL validation result: $_cachedAudioValidationResult');

      if (_cachedAudioValidationResult) {
        for (int i = 0; i < validPatterns.length; i++) {
          final matches =
              RegExp(validPatterns[i], caseSensitive: false).hasMatch(url);
          if (matches) {
            debugPrint(
                '✅ [AddEditSongPage] Matched pattern ${i + 1}: ${validPatterns[i]}');
            break;
          }
        }
        debugPrint('✅ [AddEditSongPage] Audio URL validation passed');
      } else {
        debugPrint('❌ [AddEditSongPage] Audio URL validation failed');
      }
    }

    if (!_cachedAudioValidationResult) {
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

  // ✅ CRITICAL FIX: Ensure Google Drive link is properly converted before saving
  Future<void> _ensureAudioUrlIsConverted() async {
    final rawUrl = _audioUrlController.text.trim();
    if (rawUrl.isEmpty) return;

    debugPrint(
        '🔍 [AddEditSongPage] Checking audio URL for conversion: "$rawUrl"');

    // If it's a Google Drive link that hasn't been converted yet, convert it now
    if (_isGoogleDriveLink(rawUrl) && !_isConvertedGoogleDriveLink(rawUrl)) {
      debugPrint(
          '🔄 [AddEditSongPage] Converting Google Drive link before save');
      final convertedUrl = _convertGoogleDriveLink(rawUrl);
      if (convertedUrl != null && convertedUrl != rawUrl) {
        debugPrint(
            '✅ [AddEditSongPage] Conversion successful: "$rawUrl" → "$convertedUrl"');

        // Update the controller text and force UI update
        _audioUrlController.text = convertedUrl;

        // Force a rebuild to ensure the UI reflects the change
        if (mounted) {
          setState(() {
            // This forces a rebuild with the new URL
          });

          // Give time for the state to fully update
          await Future.delayed(const Duration(milliseconds: 200));

          // Verify the conversion worked
          final verifyUrl = _audioUrlController.text.trim();
          debugPrint(
              '🔍 [AddEditSongPage] Verification: Controller now has "$verifyUrl"');

          if (verifyUrl == convertedUrl) {
            debugPrint(
                '✅ [AddEditSongPage] URL conversion verified successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Google Drive link converted successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            debugPrint(
                '❌ [AddEditSongPage] URL conversion verification failed');
          }
        }
      } else {
        debugPrint(
            '❌ [AddEditSongPage] Failed to convert Google Drive link or no conversion needed');
      }
    } else if (_isConvertedGoogleDriveLink(rawUrl)) {
      debugPrint(
          '✅ [AddEditSongPage] Audio URL is already a converted Google Drive link');
    } else {
      debugPrint(
          'ℹ️ [AddEditSongPage] Audio URL is not a Google Drive link: "$rawUrl"');
    }
  }

  // ✅ SIMPLIFIED: Get the final audio URL (now that conversion is handled before save)
  String? _getFinalAudioUrl() {
    final url = _audioUrlController.text.trim();
    return url.isEmpty ? null : url;
  }

  bool _isGoogleDriveLink(String url) {
    return url.contains('drive.google.com/file/d/') && url.contains('/view');
  }

  bool _isConvertedGoogleDriveLink(String url) {
    return url.contains('drive.google.com/uc?export=download') ||
        url.contains('drive.usercontent.google.com/download');
  }

  String _getUrlStatusMessage() {
    final url = _audioUrlController.text.trim();
    if (url.isEmpty) {
      return 'Tip: Paste a Google Drive shareable link for auto-conversion, or any audio URL.\n\n📋 Google Drive Requirements:\n• File must be set to "Anyone with the link can view"\n• File should be in MP3, M4A, or WAV format\n• File size should be under 100MB for best performance';
    }
    if (_isConvertedGoogleDriveLink(url)) {
      return '✅ Google Drive link converted! Make sure:\n• File is publicly accessible (Anyone with the link can view)\n• File is a supported audio format (MP3, M4A, WAV)\n• Test playback to verify it works';
    }
    if (_isGoogleDriveLink(url)) {
      return '🔄 Converting Google Drive link...\n\n⚠️ Important: File must be set to "Anyone with the link can view" in Google Drive sharing settings.';
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return '🎬 YouTube link detected - may require special handling or may not work due to copyright restrictions.';
    }
    if (url.contains('soundcloud.com')) {
      return '🎵 SoundCloud link detected - may require special handling.';
    }
    if (RegExp(r'\.(mp3|wav|m4a|aac|ogg)(\?.*)?$', caseSensitive: false)
        .hasMatch(url)) {
      return '🎵 Direct audio file detected - should work well for streaming.';
    }
    return '🔗 Custom audio URL - test to verify functionality.\n\nFor best results, use:\n• Direct MP3/M4A/WAV file links\n• Publicly accessible Google Drive files\n• CDN-hosted audio files';
  }

  Color _getUrlStatusColor() {
    final url = _audioUrlController.text.trim();
    if (url.isEmpty) return Colors.grey.shade600;
    if (_isConvertedGoogleDriveLink(url)) return Colors.green;
    if (_isGoogleDriveLink(url)) return Colors.blue;
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return Colors.red.shade600;
    }
    if (url.contains('soundcloud.com')) return Colors.orange;
    if (RegExp(r'\.(mp3|wav|m4a|aac|ogg)(\?.*)?$', caseSensitive: false)
        .hasMatch(url)) {
      return Colors.green;
    }
    return Colors.grey.shade700;
  }

  String? _convertGoogleDriveLink(String url) {
    // Extract file ID from various Google Drive URL formats
    String? fileId;

    // Try multiple patterns for file ID extraction
    final patterns = [
      // Format 1: https://drive.google.com/file/d/{fileId}/view?usp=sharing
      RegExp(r"https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/view"),
      // Format 2: https://drive.google.com/open?id={fileId}
      RegExp(r'drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)'),
      // Format 3: Any URL containing drive.google.com with file ID pattern
      RegExp(r'drive\.google\.com.*[/=]([a-zA-Z0-9_-]{25,})'),
      // Format 4: Direct file ID in URL
      RegExp(r'/d/([a-zA-Z0-9_-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        fileId = match.group(1);
        break;
      }
    }

    if (fileId != null) {
      // Create direct download URL using the most reliable 2025 format
      debugPrint('🔄 Converting Google Drive link - File ID: $fileId');
      return 'https://drive.usercontent.google.com/download?id=$fileId&export=download&authuser=0';
    }

    debugPrint('❌ Could not extract file ID from Google Drive URL: $url');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                  // ✅ FIXED: Show loading state in save button only
                  _isSaving
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save Song',
                          onPressed: () {
                            debugPrint(
                                '🔘 [AddEditSongPage] Save button pressed');
                            debugPrint('  _isSaving: $_isSaving');
                            _saveSong();
                          },
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
      debugPrint('🎵 Testing audio URL: ${widget.url}');

      if (_audioPlayer.playerState.processingState == ProcessingState.idle) {
        // First time loading this URL
        debugPrint('🔄 Loading audio from URL...');
        await _audioPlayer.setUrl(widget.url);
      }

      debugPrint('▶️ Starting audio playback...');
      await _audioPlayer.play();
      debugPrint('✅ Audio playback started successfully');
    } catch (e) {
      debugPrint('❌ Audio playback failed: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage =
            'Failed to play audio: ${e.toString()}\n\nTroubleshooting:\n• Check if URL is accessible\n• Verify audio format is supported\n• Test URL in browser first';
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
