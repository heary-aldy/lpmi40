// lib/src/features/admin/presentation/collection_management_page.dart
// ✅ COMPATIBLE: Works with existing CollectionService (without forceRefresh parameter)
// ✅ FIXED: Proper error handling and loading states
// ✅ FIXED: Working create and edit collection functionality

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // ✅ ADD: For fixing structure
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/services/collection_service.dart';
import 'package:lpmi40/src/features/songbook/services/collection_notifier_service.dart';
import 'package:lpmi40/src/features/songbook/repository/song_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionManagementPage extends StatefulWidget {
  const CollectionManagementPage({super.key});

  @override
  State<CollectionManagementPage> createState() =>
      _CollectionManagementPageState();
}

class _CollectionManagementPageState extends State<CollectionManagementPage> {
  // ✅ FIXED: Use CollectionService instead of repository
  final CollectionService _collectionService = CollectionService();
  final CollectionNotifierService _collectionNotifier =
      CollectionNotifierService();
  final AuthorizationService _authService = AuthorizationService();

  List<SongCollection> _collections = [];
  bool _isLoading = true;
  bool _isAuthorized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
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

  // ✅ COMPATIBLE: Use existing CollectionService without forceRefresh
  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '[CollectionManagement] 🔄 Loading collections via service...');

      // ✅ FORCE CACHE CLEAR FIRST
      CollectionService.invalidateCache();
      await Future.delayed(const Duration(milliseconds: 200));

      // ✅ USE EXISTING SERVICE METHOD
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
    // ✅ CLEAR CACHE AND FORCE FRESH LOAD
    debugPrint('[CollectionManagement] 🔄 Manual refresh triggered');
    CollectionService.invalidateCache();
    await Future.delayed(const Duration(milliseconds: 200));
    await _loadCollections();
  }

  // ✅ NEW: Create collection functionality
  Future<void> _showCreateCollectionDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateCollectionDialog(),
    );

    if (result != null) {
      await _createCollection(result['name']!, result['description']!);
    }
  }

  Future<void> _createCollection(String name, String description) async {
    try {
      setState(() => _isLoading = true);

      debugPrint('[CollectionManagement] 🔧 Creating collection: $name');
      final result =
          await _collectionService.createNewCollection(name, description);

      if (result.success) {
        debugPrint(
            '[CollectionManagement] ✅ Collection created successfully: ${result.operationId}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection "$name" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ FORCE CACHE INVALIDATION AND RELOAD
          debugPrint(
              '[CollectionManagement] 🔄 Force invalidating all caches...');
          CollectionService.invalidateCache();

          // ✅ NOTIFY COLLECTION NOTIFIER SERVICE
          // Create a temporary collection object for notification
          final newCollection = SongCollection(
            id: result.operationId ?? name.toLowerCase().replaceAll(' ', '_'),
            name: name,
            description: description,
            songCount: 0,
            accessLevel: CollectionAccessLevel.public,
            status: CollectionStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          );
          _collectionNotifier.notifyCollectionAdded(newCollection);

          // ✅ WAIT A MOMENT FOR FIREBASE CONSISTENCY
          await Future.delayed(const Duration(milliseconds: 500));

          // ✅ FORCE FRESH LOAD
          await _loadCollections();
        }
      } else {
        throw Exception(result.errorMessage ?? 'Failed to create collection');
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

  // ✅ NEW: Edit collection functionality
  Future<void> _showEditCollectionDialog(SongCollection collection) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditCollectionDialog(collection: collection),
    );

    if (result != null) {
      await _updateCollection(collection, result);
    }
  }

  Future<void> _updateCollection(
      SongCollection original, Map<String, dynamic> updates) async {
    try {
      setState(() => _isLoading = true);

      final updatedCollection = original.copyWith(
        name: updates['name'],
        description: updates['description'],
        accessLevel: updates['accessLevel'],
        status: updates['status'],
        updatedAt: DateTime.now(),
        updatedBy: () => FirebaseAuth.instance.currentUser?.uid,
      );

      final result =
          await _collectionService.updateCollection(updatedCollection);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Collection "${updatedCollection.name}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ NOTIFY COLLECTION NOTIFIER SERVICE
          _collectionNotifier.notifyCollectionUpdated(updatedCollection);

          await _refreshCollections();
        }
      } else {
        throw Exception(result.errorMessage ?? 'Failed to update collection');
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

  // ✅ NEW: Delete collection with confirmation
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

          // ✅ NOTIFY COLLECTION NOTIFIER SERVICE
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

  // ✅ COMPATIBLE: Debug collections method without forceRefresh
  Future<void> _debugCollections() async {
    debugPrint('[CollectionManagement] 🔧 === DEBUG COLLECTIONS START ===');

    try {
      // Check cache status
      final cacheStatus = _collectionService.getCacheStatus();
      debugPrint('[CollectionManagement] 📊 Cache Status: $cacheStatus');

      // Check what SongRepository sees
      final songRepo = SongRepository();
      final separatedData = await songRepo.getCollectionsSeparated();
      debugPrint(
          '[CollectionManagement] 📊 SongRepository sees: ${separatedData.keys.toList()}');

      // ✅ Test direct access to your specific collection
      debugPrint(
          '[CollectionManagement] 🔍 Testing direct access to lagu_krismas_26346...');
      final specificCollection =
          await _collectionService.getCollectionById('lagu_krismas_26346');
      if (specificCollection != null) {
        debugPrint(
            '[CollectionManagement] ✅ Found lagu_krismas_26346: ${specificCollection.name}');
        debugPrint(
            '[CollectionManagement] 📊 Access level: ${specificCollection.accessLevel.value}');
        debugPrint(
            '[CollectionManagement] 📊 Status: ${specificCollection.status.value}');
        debugPrint(
            '[CollectionManagement] 📊 Song count: ${specificCollection.songCount}');
      } else {
        debugPrint(
            '[CollectionManagement] ❌ Could not find lagu_krismas_26346');
      }

      // Force fresh service call by clearing cache
      debugPrint(
          '[CollectionManagement] 🔄 Clearing cache and forcing fresh call...');
      CollectionService.invalidateCache();
      await Future.delayed(const Duration(milliseconds: 100));

      final freshCollections =
          await _collectionService.getAccessibleCollections();
      debugPrint(
          '[CollectionManagement] 📊 Fresh service result: ${freshCollections.length} collections');

      bool foundNewCollection = false;
      for (final collection in freshCollections) {
        debugPrint(
            '[CollectionManagement] - ${collection.id}: ${collection.name}');
        if (collection.id == 'lagu_krismas_26346') {
          foundNewCollection = true;
          debugPrint(
              '[CollectionManagement] ✅ NEW COLLECTION FOUND IN SERVICE RESULT!');
        }
      }

      if (!foundNewCollection) {
        debugPrint(
            '[CollectionManagement] ❌ NEW COLLECTION NOT FOUND IN SERVICE RESULT');
        debugPrint(
            '[CollectionManagement] 🔍 This indicates the repository is not reading it properly');
      }

      // Check current UI state
      debugPrint(
          '[CollectionManagement] 📊 Current UI state: ${_collections.length} collections shown');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Debug completed. Service found ${freshCollections.length} collections. New collection found: $foundNewCollection'),
            backgroundColor: foundNewCollection ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CollectionManagement] ❌ Debug error: $e');
    }

    debugPrint('[CollectionManagement] 🔧 === DEBUG COLLECTIONS END ===');
  }

  // ✅ NEW: Fix collection structure for collections missing songs node
  Future<void> _fixCollectionStructure() async {
    debugPrint(
        '[CollectionFix] 🔧 Fixing collection structure for lagu_krismas_26346...');

    try {
      // Get Firebase database
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

            // Check if songs node exists
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

        // Refresh collections
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

  IconData _getCollectionIcon(SongCollection collection) {
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
                  // ✅ TEMPORARY: Fix collection structure button
                  IconButton(
                    icon: const Icon(Icons.build),
                    onPressed: _isAuthorized ? _fixCollectionStructure : null,
                    tooltip: 'Fix Collection Structure',
                    color: Colors.white,
                  ),
                  // ✅ Debug collections button
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: _isAuthorized ? _debugCollections : null,
                    tooltip: 'Debug Collections',
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

              // ✅ LOADING STATE
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )

              // ✅ UNAUTHORIZED STATE
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

              // ✅ ERROR STATE
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

              // ✅ EMPTY STATE
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

              // ✅ COLLECTIONS LIST
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = _collections[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getCollectionColor(collection)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCollectionIcon(collection),
                              color: _getCollectionColor(collection),
                            ),
                          ),
                          title: Text(
                            collection.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${collection.songCount} songs • Access: ${collection.accessLevel.displayName}'),
                              if (collection.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  collection.description,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(collection.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      collection.status.displayName,
                                      style: TextStyle(
                                        color:
                                            _getStatusColor(collection.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ID: ${collection.id}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditCollectionDialog(collection);
                                  break;
                                case 'delete':
                                  _confirmDeleteCollection(collection);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading:
                                      Icon(Icons.delete, color: Colors.red),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showEditCollectionDialog(collection),
                        ),
                      );
                    },
                    childCount: _collections.length,
                  ),
                ),
            ],
          ),

          // ✅ BACK BUTTON
          if (!_isLoading && _isAuthorized)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: BackButton(
                color: Colors.white,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()),
                  (route) => false,
                ),
              ),
            ),
        ],
      ),

      // ✅ CREATE COLLECTION FAB
      floatingActionButton: _isAuthorized && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _showCreateCollectionDialog,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add),
              label: const Text('Create Collection'),
            )
          : null,
    );
  }
}

// ✅ NEW: Create Collection Dialog
class CreateCollectionDialog extends StatefulWidget {
  const CreateCollectionDialog({super.key});

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Collection'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g., Gospel Songs',
                border: OutlineInputBorder(),
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
                labelText: 'Description (Optional)',
                hintText: 'Brief description of this collection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ✅ NEW: Edit Collection Dialog
class EditCollectionDialog extends StatefulWidget {
  final SongCollection collection;

  const EditCollectionDialog({super.key, required this.collection});

  @override
  State<EditCollectionDialog> createState() => _EditCollectionDialogState();
}

class _EditCollectionDialogState extends State<EditCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late CollectionAccessLevel _selectedAccessLevel;
  late CollectionStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController =
        TextEditingController(text: widget.collection.description);
    _selectedAccessLevel = widget.collection.accessLevel;
    _selectedStatus = widget.collection.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.collection.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CollectionAccessLevel>(
              value: _selectedAccessLevel,
              decoration: const InputDecoration(
                labelText: 'Access Level',
                border: OutlineInputBorder(),
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
            DropdownButtonFormField<CollectionStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
                'accessLevel': _selectedAccessLevel,
                'status': _selectedStatus,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
