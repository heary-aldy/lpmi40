// lib/src/features/admin/presentation/collection_management_page.dart
// ✅ FIXED: Data structure matches Firebase rules exactly
// ✅ FIXED: FAB positioning doesn't block create button
// ✅ FIXED: Proper error handling and loading states

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/dashboard/presentation/revamped_dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionManagementPage extends StatefulWidget {
  const CollectionManagementPage({super.key});

  @override
  State<CollectionManagementPage> createState() =>
      _CollectionManagementPageState();
}

class _CollectionManagementPageState extends State<CollectionManagementPage> {
  final CollectionService _collectionService = CollectionService();
  final CollectionNotifierService _collectionNotifier =
      CollectionNotifierService();
  final AuthorizationService _authService = AuthorizationService();

  List<SongCollection> _collections = [];
  bool _isLoading = true;
  bool _isAuthorized = false;
  String? _errorMessage;

  // Expanding form state
  String? _expandedCollectionId;
  bool _showCreateForm = false;

  // Form controllers for create/edit
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CollectionAccessLevel _selectedAccessLevel = CollectionAccessLevel.public;
  CollectionStatus _selectedStatus = CollectionStatus.active;

  // Color and icon selection
  Color _selectedColor = Colors.blue;
  String _selectedIcon = 'library_music';
  bool _enableFavorites = true;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    try {
      final authResult = await _authService.canAccessCollectionManagement();
      if (mounted) {
        setState(() => _isAuthorized = authResult.isAuthorized);
        if (_isAuthorized) {
          await _loadCollections();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Access denied. Admin privileges required.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authorization check failed: $e';
        });
      }
    }
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '[CollectionManagement] 🔄 Loading collections via service...');

      // Force cache clear first
      CollectionService.invalidateCache();
      await Future.delayed(const Duration(milliseconds: 200));

      // Use existing service method
      final collections = await _collectionService.getAccessibleCollections();

      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoading = false;
        });

        debugPrint(
            '[CollectionManagement] ✅ Loaded ${collections.length} collections');
        for (final collection in collections) {
          debugPrint(
              '[CollectionManagement] - ${collection.id}: ${collection.name} (${collection.songCount} songs)');
        }

        if (_collections.isEmpty) {
          debugPrint(
              '[CollectionManagement] ⚠️ No collections loaded - this might indicate a data issue');
        }
      }
    } catch (e) {
      debugPrint('[CollectionManagement] ❌ Error loading collections: $e');
      if (mounted) {
        setState(() {
          _collections = [];
          _isLoading = false;
          _errorMessage = 'Failed to load collections: $e';
        });
      }
    }
  }

  Future<void> _refreshCollections() async {
    debugPrint('[CollectionManagement] 🔄 Manual refresh triggered');
    CollectionService.invalidateCache();
    await Future.delayed(const Duration(milliseconds: 200));
    await _loadCollections();
  }

  void _toggleCreateForm() {
    setState(() {
      _showCreateForm = true;
      _expandedCollectionId = null;
      _nameController.clear();
      _descriptionController.clear();
      _selectedAccessLevel = CollectionAccessLevel.public;
      _selectedStatus = CollectionStatus.active;
      _selectedColor = Colors.blue;
      _selectedIcon = 'library_music';
      _enableFavorites = true;
    });
  }

  void _cancelCreateForm() {
    setState(() {
      _showCreateForm = false;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  // ✅ FIXED: Data structure matches Firebase rules exactly
  Future<void> _createCollectionWithSamples() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final collectionId = name
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      debugPrint(
          '[CollectionManagement] 🔧 Creating collection with samples: $name');

      final database = FirebaseDatabase.instance;
      final currentUser = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();

      // ✅ FIXED: Structure matches Firebase rules exactly
      final collectionData = {
        // ✅ MOVED: Main fields go INSIDE metadata per Firebase rules
        'metadata': {
          'name': name,                           // ✅ INSIDE metadata as required
          'description': description,             // ✅ INSIDE metadata as required
          'access_level': _selectedAccessLevel.value, // ✅ INSIDE metadata as required
          'status': _selectedStatus.value,        // ✅ INSIDE metadata as required
          'song_count': 2,                        // ✅ INSIDE metadata as required
          'created_at': now.toIso8601String(),    // ✅ INSIDE metadata as required
          'created_by': currentUser?.uid ?? 'unknown', // ✅ INSIDE metadata as required
          // Additional metadata fields
          'updated_at': now.toIso8601String(),
          'updated_by': currentUser?.uid ?? 'unknown',
          'icon': _selectedIcon,
          'color': _colorToString(_selectedColor),
          'enable_favorites': _enableFavorites,
          'order_index': _collections.length,
          'version': '1.0',
          'last_sync': now.toIso8601String(),
          'total_downloads': 0,
          'is_featured': false,
        },
        // Songs structure remains the same
        'songs': {
          '001': {
            'song_number': '001',
            'song_title': 'SAMPLE SONG WITH CHORUS',
            'verses': [
              {
                'verse_number': '1',
                'lyrics':
                    'This is the first verse of our sample song,\nShowing how verses should be formatted.\nEach line break represents a new line,\nAnd the structure should remain consistent.'
              },
              {
                'verse_number': 'Chorus',
                'lyrics':
                    'This is the chorus that repeats,\nBringing the message home.\nSing it loud and sing it clear,\nLet every voice be known.'
              },
              {
                'verse_number': '2',
                'lyrics':
                    'Here comes the second verse of song,\nContinuing the melody.\nEach verse tells part of the story,\nBuilding the harmony.'
              }
            ],
            'collection_id': collectionId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'created_by': currentUser?.uid ?? 'unknown',
          },
          '002': {
            'song_number': '002',
            'song_title': 'SAMPLE SONG WITHOUT CHORUS',
            'verses': [
              {
                'verse_number': '1',
                'lyrics':
                    'This sample shows a song structure,\nThat flows from verse to verse.\nNo chorus interrupts the flow,\nJust continuous narrative.'
              },
              {
                'verse_number': '2',
                'lyrics':
                    'Each verse builds upon the last,\nCreating one long story.\nThe message weaves throughout each part,\nRevealing truth and glory.'
              },
              {
                'verse_number': '3',
                'lyrics':
                    'This final verse concludes our song,\nWith wisdom for the heart.\nRemember that each song structure,\nPlays its own special part.'
              }
            ],
            'collection_id': collectionId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'created_by': currentUser?.uid ?? 'unknown',
          }
        }
      };

      // Save to Firebase - this will now match the rules exactly
      await database.ref('song_collection/$collectionId').set(collectionData);

      debugPrint(
          '[CollectionManagement] ✅ Collection created with sample songs: $collectionId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collection "$name" created with 2 sample songs!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form and refresh
        setState(() {
          _showCreateForm = false;
          _nameController.clear();
          _descriptionController.clear();
        });

        // Force cache invalidation and reload
        CollectionService.invalidateCache();
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadCollections();
      }
    } catch (e) {
      debugPrint('[CollectionManagement] ❌ Error creating collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditForm(SongCollection collection) {
    setState(() {
      _expandedCollectionId = collection.id;
      _showCreateForm = false;
      _nameController.text = collection.name;
      _descriptionController.text = collection.description;
      _selectedAccessLevel = collection.accessLevel;
      _selectedStatus = collection.status;
      _selectedColor = _getCollectionColor(collection);
      _selectedIcon = _getCollectionIconName(collection.id);
      _enableFavorites = true;
    });
  }

  void _cancelEditForm() {
    setState(() {
      _expandedCollectionId = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  // ✅ FIXED: Edit method with correct data structure
  Future<void> _saveCollectionEdit(String collectionId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // ✅ FIXED: Update fields INSIDE metadata node to match Firebase rules
      final updatedData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'access_level': _selectedAccessLevel.value,
        'status': _selectedStatus.value,
        'icon': _selectedIcon,
        'color': _colorToString(_selectedColor),
        'enable_favorites': _enableFavorites,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      };

      // Update in Firebase - using correct path to metadata
      final database = FirebaseDatabase.instance;
      await database.ref('song_collection/$collectionId/metadata').update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Collection "${_nameController.text}" updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _expandedCollectionId = null;
          _nameController.clear();
          _descriptionController.clear();
        });

        // Force refresh
        CollectionService.invalidateCache();
        await Future.delayed(const Duration(milliseconds: 300));
        await _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDeleteCollection(SongCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${collection.name}"?\n\n'
          'This action cannot be undone and will affect ${collection.songCount} songs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCollection(collection);
    }
  }

  Future<void> _deleteCollection(SongCollection collection) async {
    try {
      setState(() => _isLoading = true);

      final result = await _collectionService.deleteCollection(collection.id);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Collection "${collection.name}" deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          _collectionNotifier.notifyCollectionDeleted(collection.id);
          await _refreshCollections();
        }
      } else {
        throw Exception(result.errorMessage ?? 'Failed to delete collection');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fixCollectionStructure() async {
    debugPrint(
        '[CollectionFix] 🔧 Fixing collection structure for lagu_krismas_26346...');

    try {
      final database = FirebaseDatabase.instance;

      // Add missing songs node to lagu_krismas_26346
      await database.ref('song_collection/lagu_krismas_26346/songs').set({});

      debugPrint(
          '[CollectionFix] ✅ Added missing songs node to lagu_krismas_26346');

      // Also fix any other collections that might be missing songs node
      final allCollectionsRef = database.ref('song_collection');
      final snapshot = await allCollectionsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final collectionsData =
            Map<String, dynamic>.from(snapshot.value as Map);

        for (final collectionId in collectionsData.keys) {
          final collectionData = collectionsData[collectionId];
          if (collectionData is Map) {
            final collectionMap = Map<String, dynamic>.from(collectionData);

            if (!collectionMap.containsKey('songs')) {
              debugPrint(
                  '[CollectionFix] 🔧 Adding missing songs node to $collectionId');
              await database.ref('song_collection/$collectionId/songs').set({});
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection structure fixed! Refreshing...'),
            backgroundColor: Colors.green,
          ),
        );

        await _refreshCollections();
      }
    } catch (e) {
      debugPrint('[CollectionFix] ❌ Error fixing collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.active:
        return Colors.green;
      case CollectionStatus.inactive:
        return Colors.orange;
      case CollectionStatus.archived:
        return Colors.grey;
    }
  }

  Widget _getCollectionIconWidget(SongCollection collection,
      {double size = 24.0}) {
    return Icon(
      _getCollectionIconFromId(collection.id),
      size: size,
    );
  }

  IconData _getCollectionIconFromId(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return Icons.library_music;
      case 'SRD':
        return Icons.auto_stories;
      case 'Lagu_belia':
        return Icons.child_care;
      case 'PPL':
        return Icons.favorite;
      case 'Advent':
        return Icons.star;
      case 'Natal':
        return Icons.celebration;
      case 'Paskah':
        return Icons.brightness_5;
      default:
        return Icons.folder_special;
    }
  }

  Color _getCollectionColor(SongCollection collection) {
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

  String _getCollectionIconName(String collectionId) {
    switch (collectionId) {
      case 'LPMI':
        return 'library_music';
      case 'SRD':
        return 'auto_stories';
      case 'Lagu_belia':
        return 'child_care';
      case 'PPL':
        return 'favorite';
      case 'Advent':
        return 'star';
      case 'Natal':
        return 'celebration';
      case 'Paskah':
        return 'brightness_5';
      default:
        return 'library_music';
    }
  }

  List<Color> _getAvailableColors() {
    return [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
    ];
  }

  List<Map<String, dynamic>> _getAvailableIcons() {
    return [
      {
        'name': 'library_music',
        'icon': Icons.library_music,
        'label': 'Music Library'
      },
      {'name': 'auto_stories', 'icon': Icons.auto_stories, 'label': 'Stories'},
      {'name': 'child_care', 'icon': Icons.child_care, 'label': 'Children'},
      {'name': 'favorite', 'icon': Icons.favorite, 'label': 'Heart'},
      {'name': 'star', 'icon': Icons.star, 'label': 'Star'},
      {
        'name': 'celebration',
        'icon': Icons.celebration,
        'label': 'Celebration'
      },
      {'name': 'brightness_5', 'icon': Icons.brightness_5, 'label': 'Sun'},
      {'name': 'music_note', 'icon': Icons.music_note, 'label': 'Music Note'},
      {
        'name': 'folder_special',
        'icon': Icons.folder_special,
        'label': 'Special Folder'
      },
    ];
  }

  String _colorToString(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.indigo) return 'indigo';
    if (color == Colors.amber) return 'amber';
    if (color == Colors.brown) return 'brown';
    return 'blue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              AdminHeader(
                title: 'Collection Management',
                subtitle: 'Manage song collections and access levels',
                icon: Icons.folder_special,
                primaryColor: Colors.teal,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.build),
                    onPressed: _isAuthorized ? _fixCollectionStructure : null,
                    tooltip: 'Fix Collection Structure',
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isAuthorized && !_isLoading
                        ? _refreshCollections
                        : null,
                    tooltip: 'Refresh Collections',
                    color: Colors.white,
                  ),
                ],
              ),

              // Loading state
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )

              // Unauthorized state
              else if (!_isAuthorized)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage ?? 'Access Denied',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // Error state
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshCollections,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // Empty state
              else if (_collections.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: RefreshIndicator(
                      onRefresh: _refreshCollections,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          const Center(
                            child: Icon(Icons.folder_outlined,
                                size: 64, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'No collections found',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Pull to refresh or create a new collection',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // Collections list with expanding forms
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = _collections[index];
                      final isExpanded = _expandedCollectionId == collection.id;

                      return Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getCollectionColor(collection)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _getCollectionIconWidget(collection,
                                        size: 24),
                                  ),
                                  title: Text(
                                    collection.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${collection.songCount} songs • Access: ${collection.accessLevel.displayName}'),
                                      if (collection
                                          .description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          collection.description,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      collection.status)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              collection.status.displayName,
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                    collection.status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'ID: ${collection.id}',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.edit,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onPressed: () {
                                          if (isExpanded) {
                                            _cancelEditForm();
                                          } else {
                                            _showEditForm(collection);
                                          }
                                        },
                                        tooltip: isExpanded
                                            ? 'Cancel Edit'
                                            : 'Edit Collection',
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'delete':
                                              _confirmDeleteCollection(
                                                  collection);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete,
                                                  color: Colors.red),
                                              title: Text('Delete'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Expanding edit form
                                if (isExpanded) ...[
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Edit Collection',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Collection Name',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.folder),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Collection name is required';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _descriptionController,
                                            decoration: const InputDecoration(
                                              labelText: 'Description',
                                              border: OutlineInputBorder(),
                                              prefixIcon:
                                                  Icon(Icons.description),
                                            ),
                                            maxLines: 3,
                                          ),
                                          const SizedBox(height: 16),
                                          DropdownButtonFormField<
                                              CollectionAccessLevel>(
                                            value: _selectedAccessLevel,
                                            decoration: const InputDecoration(
                                              labelText: 'Access Level',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.security),
                                            ),
                                            items: CollectionAccessLevel.values
                                                .map((level) {
                                              return DropdownMenuItem(
                                                value: level,
                                                child: Text(level.displayName),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() =>
                                                  _selectedAccessLevel =
                                                      value!);
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          DropdownButtonFormField<
                                              CollectionStatus>(
                                            value: _selectedStatus,
                                            decoration: const InputDecoration(
                                              labelText: 'Status',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.flag),
                                            ),
                                            items: CollectionStatus.values
                                                .map((status) {
                                              return DropdownMenuItem(
                                                value: status,
                                                child: Text(status.displayName),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() =>
                                                  _selectedStatus = value!);
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Color selection for edit
                                          const Text(
                                            'Collection Color',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 60,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  _getAvailableColors().length,
                                              itemBuilder: (context, index) {
                                                final color =
                                                    _getAvailableColors()[
                                                        index];
                                                final isSelected =
                                                    color == _selectedColor;

                                                return GestureDetector(
                                                  onTap: () => setState(() =>
                                                      _selectedColor = color),
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: isSelected
                                                          ? Border.all(
                                                              color:
                                                                  Colors.black,
                                                              width: 3)
                                                          : null,
                                                    ),
                                                    child: isSelected
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white)
                                                        : null,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Icon selection for edit
                                          const Text(
                                            'Collection Icon',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 80,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  _getAvailableIcons().length,
                                              itemBuilder: (context, index) {
                                                final iconData =
                                                    _getAvailableIcons()[index];
                                                final isSelected =
                                                    iconData['name'] ==
                                                        _selectedIcon;

                                                return GestureDetector(
                                                  onTap: () => setState(() =>
                                                      _selectedIcon =
                                                          iconData['name']),
                                                  child: Container(
                                                    width: 70,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? _selectedColor
                                                              .withOpacity(0.2)
                                                          : Colors.grey
                                                              .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: isSelected
                                                          ? Border.all(
                                                              color:
                                                                  _selectedColor,
                                                              width: 2)
                                                          : null,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          iconData['icon'],
                                                          color: isSelected
                                                              ? _selectedColor
                                                              : Colors.grey,
                                                          size: 28,
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          iconData['label'],
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isSelected
                                                                ? _selectedColor
                                                                : Colors.grey,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Favorites enabled switch for edit
                                          SwitchListTile(
                                            title:
                                                const Text('Enable Favorites'),
                                            subtitle: const Text(
                                                'Allow users to save songs from this collection as favorites'),
                                            value: _enableFavorites,
                                            onChanged: (value) => setState(
                                                () => _enableFavorites = value),
                                            activeColor: _selectedColor,
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: _cancelEditForm,
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _saveCollectionEdit(
                                                          collection.id),
                                                  child: const Text(
                                                      'Save Changes'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: _collections.length,
                  ),
                ),

              // Create collection expanding form
              if (_showCreateForm)
                SliverToBoxAdapter(
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Create New Collection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Collection Name',
                                hintText: 'e.g., Gospel Songs',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.folder),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Collection name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText:
                                    'Brief description of this collection',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<CollectionAccessLevel>(
                              value: _selectedAccessLevel,
                              decoration: const InputDecoration(
                                labelText: 'Access Level',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.security),
                              ),
                              items: CollectionAccessLevel.values.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedAccessLevel = value!);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Color selection
                            const Text(
                              'Collection Color',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _getAvailableColors().length,
                                itemBuilder: (context, index) {
                                  final color = _getAvailableColors()[index];
                                  final isSelected = color == _selectedColor;

                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedColor = color),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSelected
                                            ? Border.all(
                                                color: Colors.black, width: 3)
                                            : null,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Icon selection
                            const Text(
                              'Collection Icon',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _getAvailableIcons().length,
                                itemBuilder: (context, index) {
                                  final iconData = _getAvailableIcons()[index];
                                  final isSelected =
                                      iconData['name'] == _selectedIcon;

                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedIcon = iconData['name']),
                                    child: Container(
                                      width: 70,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _selectedColor.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: isSelected
                                            ? Border.all(
                                                color: _selectedColor, width: 2)
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            iconData['icon'],
                                            color: isSelected
                                                ? _selectedColor
                                                : Colors.grey,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            iconData['label'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? _selectedColor
                                                  : Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Favorites enabled switch
                            SwitchListTile(
                              title: const Text('Enable Favorites'),
                              subtitle: const Text(
                                  'Allow users to save songs from this collection as favorites'),
                              value: _enableFavorites,
                              onChanged: (value) =>
                                  setState(() => _enableFavorites = value),
                              activeColor: _selectedColor,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<CollectionStatus>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: CollectionStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedStatus = value!);
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info,
                                      color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This will create a collection with 2 sample songs (one with chorus, one without) to ensure proper structure.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelCreateForm,
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _createCollectionWithSamples,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Collection'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ✅ FIXED: Add bottom padding so FAB doesn't block content
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Extra space for FAB
              ),
            ],
          ),

          // Responsive back button only on mobile
          if (!_isLoading &&
              _isAuthorized &&
              MediaQuery.of(context).size.width < 768.0)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const RevampedDashboardPage()),
                  (route) => false,
                ),
              ),
            ),
        ],
      ),

      // ✅ FIXED: Draggable FAB positioned at bottom to avoid blocking content
      floatingActionButton: _isAuthorized && !_isLoading
          ? Draggable<Widget>(
              feedback: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: FloatingActionButton.extended(
                  onPressed: null, // Disabled during drag
                  backgroundColor: Colors.teal.withOpacity(0.8),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Collection'),
                ),
              ),
              childWhenDragging: Container(), // Hide original when dragging
              child: FloatingActionButton.extended(
                onPressed: _toggleCreateForm,
                backgroundColor: Colors.teal,
                icon: const Icon(Icons.add),
                label: const Text('Create Collection'),
                tooltip: 'Tap to create collection, drag to move',
              ),
              onDragEnd: (details) {
                // Optional: You could save the position if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('FAB moved! Tap to create collection.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            )
          : null,
      // ✅ FIXED: Position FAB at bottom center to avoid blocking content
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

