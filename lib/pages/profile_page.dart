import 'package:flutter/material.dart';
import 'package:lpmi40/src/core/services/preferences_service.dart';
import 'package:lpmi40/src/features/authentication/repository/sync_repository.dart'; // Import the new service

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Create instances for both services
  late PreferencesService _prefsService;
  late SyncRepository _syncRepository;

  bool _isLoading = true;
  bool _isSyncEnabled = true;
  DateTime? _lastSyncTime;
  List<String> _favoriteSongs = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // Correctly initialize services asynchronously
  Future<void> _initializeServices() async {
    _prefsService = await PreferencesService.init();
    _syncRepository = await SyncRepository.init();

    // Load the initial data from the correct services
    if (mounted) {
      setState(() {
        _isSyncEnabled = _syncRepository.isSyncEnabled();
        _lastSyncTime = _syncRepository.getLastSyncTime();
        _isLoading = false;
      });
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await _syncRepository.getFavoriteSongs();
    if (mounted) {
      setState(() {
        _favoriteSongs = favorites;
      });
    }
  }

  Future<void> _runSync() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Syncing...')));
    await _syncRepository.syncToCloud();
    if (mounted) {
      setState(() {
        _lastSyncTime = _syncRepository.getLastSyncTime();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sync complete!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Sync')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  title: const Text('Enable Cloud Sync'),
                  value: _isSyncEnabled,
                  onChanged: (value) {
                    setState(() => _isSyncEnabled = value);
                    _syncRepository.setSyncEnabled(value);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_sync),
                  title: const Text('Sync Now'),
                  subtitle: Text(_lastSyncTime != null
                      ? 'Last sync: ${_lastSyncTime!.toLocal()}'
                      : 'Never synced'),
                  onTap: _runSync,
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: Text('${_favoriteSongs.length} Favorite Songs'),
                  subtitle: const Text('Synced from the cloud'),
                ),
              ],
            ),
    );
  }
}
