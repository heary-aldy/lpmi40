import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This class will handle all logic related to syncing user data with Firebase.
class SyncRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final SharedPreferences _prefs;

  // Private constructor
  SyncRepository._(this._prefs);

  // Static factory method to create an instance
  static Future<SyncRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SyncRepository._(prefs);
  }

  // --- Methods the Profile Page needs ---

  // Check if sync is enabled in local settings
  bool isSyncEnabled() {
    return _prefs.getBool('sync_enabled') ?? true; // Default to true
  }

  Future<void> setSyncEnabled(bool isEnabled) async {
    await _prefs.setBool('sync_enabled', isEnabled);
  }

  // Get the last sync time from local settings
  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString('last_sync_time');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString('last_sync_time', time.toIso8601String());
  }

  // This would fetch the list of favorite song numbers from Firebase
  Future<List<String>> getFavoriteSongs() async {
    // TODO: Implement the logic to get favorite songs from Firebase Database
    // For now, it returns an empty list.
    print('Fetching favorite songs from Firebase...');
    return [];
  }

  // This would trigger the sync process
  Future<void> syncToCloud() async {
    // TODO: Implement the full cloud sync logic here.
    // 1. Get local favorites.
    // 2. Get cloud favorites.
    // 3. Merge them.
    // 4. Upload the merged list to Firebase.
    print('Syncing to cloud...');
    await setLastSyncTime(DateTime.now());
  }
}
