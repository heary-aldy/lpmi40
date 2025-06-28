import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Collections
  static const String _favoritesCollection = 'user_favorites';
  static const String _usersCollection = 'users';
  static const String _analyticsCollection = 'song_analytics';

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> initializeRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        'premium_features_enabled': false,
        'max_favorites_free': 50,
        'show_upgrade_banner': true,
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config initialization failed: $e');
    }
  }

  // Authentication Methods
  Future<User?> signInWithGoogle() async {
    try {
      // Try email/password fallback approach for testing
      return await _signInFallback();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  // Fallback method for testing without Google Sign-In
  Future<User?> _signInFallback() async {
    try {
      // For now, create anonymous user or use email sign-in
      final UserCredential userCredential = await _auth.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        await _createUserDocument(user);
        await _analytics.logLogin(loginMethod: 'anonymous');
      }

      return user;
    } catch (e) {
      debugPrint('Fallback Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _analytics.logLogin(loginMethod: 'email');
      return userCredential.user;
    } catch (e) {
      debugPrint('Email Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> createUserWithEmailPassword(
      String email, String password, String displayName) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await _createUserDocument(user);
        await _analytics.logSignUp(signUpMethod: 'email');
      }

      return user;
    } catch (e) {
      debugPrint('Create User Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection(_usersCollection).doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'Anonymous User',
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'isPremium': false,
        });
      } else {
        await userDoc.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Create User Document Error: $e');
    }
  }

  // Favorites Management
  Future<void> addToFavorites(String songNumber) async {
    if (!isSignedIn) return;

    try {
      await _firestore
          .collection(_favoritesCollection)
          .doc(currentUser!.uid)
          .collection('songs')
          .doc(songNumber)
          .set({
        'songNumber': songNumber,
        'addedAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'favorite_added',
        parameters: {'song_number': songNumber},
      );
    } catch (e) {
      debugPrint('Add to Favorites Error: $e');
    }
  }

  Future<void> removeFromFavorites(String songNumber) async {
    if (!isSignedIn) return;

    try {
      await _firestore
          .collection(_favoritesCollection)
          .doc(currentUser!.uid)
          .collection('songs')
          .doc(songNumber)
          .delete();

      await _analytics.logEvent(
        name: 'favorite_removed',
        parameters: {'song_number': songNumber},
      );
    } catch (e) {
      debugPrint('Remove from Favorites Error: $e');
    }
  }

  Stream<List<String>> getFavoritesStream() {
    if (!isSignedIn) return Stream.value([]);

    return _firestore
        .collection(_favoritesCollection)
        .doc(currentUser!.uid)
        .collection('songs')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['songNumber'] as String)
          .toList();
    });
  }

  Future<List<String>> getFavorites() async {
    if (!isSignedIn) return [];

    try {
      final snapshot = await _firestore
          .collection(_favoritesCollection)
          .doc(currentUser!.uid)
          .collection('songs')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['songNumber'] as String)
          .toList();
    } catch (e) {
      debugPrint('Get Favorites Error: $e');
      return [];
    }
  }

  Future<void> syncLocalFavorites(List<String> localFavorites) async {
    if (!isSignedIn) return;

    try {
      final batch = _firestore.batch();
      final userFavoritesRef = _firestore
          .collection(_favoritesCollection)
          .doc(currentUser!.uid)
          .collection('songs');

      for (String songNumber in localFavorites) {
        batch.set(userFavoritesRef.doc(songNumber), {
          'songNumber': songNumber,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Sync Local Favorites Error: $e');
    }
  }

  // Analytics Methods
  Future<void> logSongView(String songNumber, String songTitle) async {
    try {
      await _analytics.logEvent(
        name: 'song_viewed',
        parameters: {
          'song_number': songNumber,
          'song_title': songTitle,
        },
      );

      await _firestore.collection(_analyticsCollection).add({
        'event': 'song_viewed',
        'songNumber': songNumber,
        'songTitle': songTitle,
        'userId': currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Log Song View Error: $e');
    }
  }

  Future<void> logSearch(String query, int resultsCount) async {
    try {
      await _analytics.logSearch(searchTerm: query);
    } catch (e) {
      debugPrint('Log Search Error: $e');
    }
  }

  Future<void> logShare(String songNumber, String method) async {
    try {
      await _analytics.logShare(
        contentType: 'song',
        itemId: songNumber,
        method: method,
      );
    } catch (e) {
      debugPrint('Log Share Error: $e');
    }
  }

  // Remote Config Methods
  bool get isPremiumFeaturesEnabled =>
      _remoteConfig.getBool('premium_features_enabled');
  int get maxFavoritesFree => _remoteConfig.getInt('max_favorites_free');
  bool get showUpgradeBanner => _remoteConfig.getBool('show_upgrade_banner');

  // User Management
  Future<bool> isPremiumUser() async {
    if (!isSignedIn) return false;

    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser!.uid)
          .get();
      return userDoc.data()?['isPremium'] ?? false;
    } catch (e) {
      debugPrint('Check Premium Status Error: $e');
      return false;
    }
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    if (!isSignedIn) return;

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(currentUser!.uid)
          .update({
        'isPremium': isPremium,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Update Premium Status Error: $e');
    }
  }
}
