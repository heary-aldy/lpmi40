// lib/src/features/admin/presentation/collection_management_page.dart
// ✅ FIXED: Correctly handles the 'CollectionDataResult' type to resolve the assignment error.

import 'package:flutter/material.dart';
import 'package:lpmi40/src/widgets/admin_header.dart';
import 'package:lpmi40/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:lpmi40/src/features/songbook/models/collection_model.dart';
import 'package:lpmi40/src/features/songbook/repository/song_collection_repository.dart';
import 'package:lpmi40/src/core/services/authorization_service.dart';

class CollectionManagementPage extends StatefulWidget {
  const CollectionManagementPage({super.key});

  @override
  State<CollectionManagementPage> createState() =>
      _CollectionManagementPageState();
}

class _CollectionManagementPageState extends State<CollectionManagementPage> {
  final CollectionRepository _collectionRepo = CollectionRepository();
  final AuthorizationService _authService = AuthorizationService();

  List<SongCollection> _collections = [];
  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoad();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    final authResult = await _authService.canAccessCollectionManagement();
    if (mounted) {
      setState(() => _isAuthorized = authResult.isAuthorized);
      if (_isAuthorized) {
        _loadCollections();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      // ✅ FIX: Correctly unpack the result object.
      final result = await _collectionRepo.getAllCollections(userRole: 'admin');
      if (mounted) {
        setState(() {
          _collections = result.collections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading collections: $e'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
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
                    icon: const Icon(Icons.refresh),
                    onPressed: _isAuthorized ? _loadCollections : null,
                    tooltip: 'Refresh Collections',
                  ),
                ],
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_isAuthorized)
                const SliverFillRemaining(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'Access Denied. You must be an admin to manage collections.',
                        textAlign: TextAlign.center),
                  )),
                )
              else if (_collections.isEmpty)
                SliverFillRemaining(
                  child: Center(
                      child: RefreshIndicator(
                    onRefresh: _loadCollections,
                    child: ListView(shrinkWrap: true, children: const [
                      Center(child: Text('No collections found.'))
                    ]),
                  )),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = _collections[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.folder_copy,
                              color: Colors.teal.shade700),
                          title: Text(collection.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${collection.songCount} songs - Access: ${collection.accessLevel.displayName}'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: _getStatusColor(collection.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  collection.status.displayName,
                                  style: TextStyle(
                                      color: _getStatusColor(collection.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                ),
                              )
                            ],
                          ),
                          trailing: const Icon(Icons.edit, color: Colors.grey),
                          onTap: () {
                            // TODO: Implement edit collection functionality
                          },
                        ),
                      );
                    },
                    childCount: _collections.length,
                  ),
                ),
            ],
          ),
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
      floatingActionButton: _isAuthorized
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement create collection functionality
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
